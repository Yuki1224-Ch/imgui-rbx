-- Example usage of DebugTools with imgui-rbx
-- This file demonstrates how to integrate the upvalue finder and function spy
-- Includes deep search functionality with real-time value inspection

-- Load required modules
local ImGui = require(script.Parent.main) -- Assuming main.lua is the imgui-rbx module
local DebugTools = require(script.Parent.debug_tools)

-- Initialize the debug tools
local debugger = setmetatable({}, DebugTools)

-- Configure for optimal performance (no lag)
debugger.Config.MaxDepth = 8 -- Limit recursion depth
debugger.Config.SearchBufferSize = 500 -- Limit results
debugger.Config.CacheResults = true -- Enable caching
debugger.Config.LazyLoading = true -- Load results on demand

-- Example: Create a test function with nested upvalues for demonstration
local function createTestFunction()
    local secretValue = 42
    local playerName = "Player1"
    local multiplier = 1.5
    local configTable = {
        enabled = true, 
        maxItems = 100,
        nested = {
            deepValue = "secret_data",
            numbers = {1, 2, 3, 4, 5}
        }
    }
    
    return function()
        return secretValue * multiplier
    end
end

local testFunc = createTestFunction()

-- Track the test function
debugger:TrackFunction(testFunc, "testFunction")

-- Example UI creation function that integrates with imgui-rbx
local function createDebugUI()
    local windowOptions = {
        Name = "Debug Tools | Upvalue Finder & Function Spy",
        Width = 800,
        Height = 600
    }
    
    local handler = ImGui:Begin(windowOptions)
    
    if not handler then
        warn("Failed to create ImGui window")
        return
    end
    
    -- Create UI elements for DebugTools
    local stats = debugger:GetLiveStats()
    local searchStats = debugger:GetSearchStats()
    
    -- Stats Section
    handler:Separator()
    handler:Text(string.format("Tracked Functions: %d", stats.totalTracked))
    handler:Text(string.format("Total Changes Detected: %d", stats.totalChanges))
    handler:Text(string.format("Functions with Changes: %d", stats.functionsWithChanges))
    handler:Text(string.format("Memory Usage: %.2f KB", stats.memoryUsage))
    handler:Text(string.format("Last Search Time: %.4fs", searchStats.lastSearchTime))
    handler:Separator()
    
    -- Deep Search Section
    handler:TextColored(1, 1, 0, 1, "Deep Search (Lag-Free)")
    handler:Text("Search through all upvalues and nested tables:")
    
    local searchQuery = debugger.uiData.deepSearchQuery or ""
    local changed, newQuery = handler:InputText("##DeepSearchField", searchQuery, 256)
    if changed then
        debugger:setDeepSearchQuery(newQuery)
    end
    
    -- Show search button
    if handler:Button("Search") then
        local results, perfStats = debugger:SearchAllFunctions(searchQuery, {
            maxResults = 50,
            includeNested = true
        })
        print(string.format("Search completed in %.4fs, found %d results", 
            perfStats.totalTime, perfStats.totalResults))
    end
    
    -- Display search results
    if #debugger.uiData.deepSearchResults > 0 then
        handler:Separator()
        handler:TextColored(0, 1, 0, 1, string.format("Found %d results:", 
            #debugger.uiData.deepSearchResults))
        
        for i, result in ipairs(debugger.uiData.deepSearchResults) do
            local prefix = string.rep("  ", result.depth or 0)
            local displayText = ""
            
            if result.matchType == "nested" then
                displayText = string.format("%s%s.%s [%s] = %s",
                    prefix,
                    result.upvalue.name,
                    result.nestedPath,
                    result.nestedValueType,
                    result.nestedDisplayValue
                )
            else
                displayText = string.format("%s%s [%s] = %s",
                    prefix,
                    result.upvalue.name,
                    result.upvalue.valueType,
                    result.upvalue.stringValue
                )
            end
            
            handler:Text(truncateString(displayText, 100))
            
            -- Edit button for each result
            if handler:Button(string.format("Edit##%d", i)) then
                debugger:setSelectedFunction(result.func)
                debugger:setSelectedUpvalue(result.upvalue)
            end
            
            if i < #debugger.uiData.deepSearchResults then
                handler:Separator()
            end
        end
    end
    
    -- Edit Selected Upvalue Section
    if debugger.uiData.selectedUpvalue then
        handler:Separator()
        handler:TextColored(1, 0, 0, 1, "Edit Selected Upvalue")
        handler:Text(string.format("Function: %s", 
            debugger.uiData.selectedFunction and "selected" or "none"))
        handler:Text(string.format("Upvalue: %s", debugger.uiData.selectedUpvalue.name))
        handler:Text(string.format("Current Value: %s", debugger.uiData.selectedUpvalue.stringValue))
        
        local editValue = debugger.uiData.editValue or ""
        local changed, newValue = handler:InputText("##EditValue", editValue, 512)
        if changed then
            debugger:setEditValue(newValue)
        end
        
        if handler:Button("Apply Changes") then
            local success, err = debugger:applyEdit()
            if success then
                print("Upvalue updated successfully!")
            else
                warn("Failed to update upvalue:", err)
            end
        end
        
        if handler:Button("Cancel") then
            debugger:setSelectedUpvalue(nil)
        end
    end
    
    handler:Separator()
    
    -- Function List Section
    handler:Text("Tracked Functions:")
    
    for func, data in pairs(debugger.TrackedFunctions) do
        handler:Text(string.format("  • %s (Changes: %d)", data.name, data.changeCount))
        
        -- Show upvalues with deep search indicator
        local upvalues = debugger:GetUpvalues(func)
        for _, upvalue in ipairs(upvalues) do
            local hasNested = type(upvalue.value) == "table" and "🔍" or ""
            handler:Text(string.format("    %s - %s [%s]: %s", 
                hasNested,
                upvalue.name, 
                upvalue.valueType, 
                truncateString(upvalue.stringValue, 50)
            ))
        end
        
        -- Button to modify upvalue
        if handler:Button(string.format("Edit##%s", data.name)) then
            debugger:setSelectedFunction(func)
            print("Edit clicked for:", data.name)
        end
        
        -- Button to generate code
        if handler:Button(string.format("Generate Code##%s", data.name)) then
            local code = debugger:GenerateUpvalueCode(func, data.name)
            local success, msg = debugger:CopyToClipboard(code)
            print(msg)
        end
        
        -- Deep search this function
        if handler:Button(string.format("Deep Search##%s", data.name)) then
            local results = debugger:DeepSearchUpvalues(func, "")
            print(string.format("Found %d matches in %s", #results, data.name))
        end
        
        handler:Separator()
    end
    
    -- Recent Changes Section
    if stats.totalChanges > 0 then
        handler:Text("Recent Changes:")
        for funcName, history in pairs(debugger.FunctionHistory) do
            local recentCount = #history
            if recentCount > 0 then
                local lastChange = history[recentCount]
                if lastChange.changeType then
                    handler:Text(string.format("  ⚠ %s: %s", funcName, lastChange.changeType))
                end
            end
        end
    end
    
    -- Search/Filter Section
    handler:Separator()
    handler:Text("Quick Filter:")
    local filterQuery = debugger.uiData.searchQuery or ""
    local changed, newFilter = handler:InputText("##SearchField", filterQuery, 128)
    if changed then
        debugger:setSearchQuery(newFilter)
    end
    
    -- Auto-refresh toggle
    local refreshText = debugger.uiData.autoRefreshEnabled and "Auto-Refresh: ON" or "Auto-Refresh: OFF"
    if handler:Button(refreshText) then
        debugger:toggleAutoRefresh()
    end
    
    -- Manual refresh button
    if handler:Button("Refresh Now") then
        local changes = debugger:CheckTrackedFunctions()
        print("Manual refresh completed. Changes found:", #changes)
    end
    
    -- Clear caches button (for performance)
    if handler:Button("Clear Caches") then
        debugger:ClearCaches()
        print("Caches cleared!")
    end
    
    -- Helper function to truncate strings
    function truncateString(str, maxLen)
        if not str then return "" end
        if #str > maxLen then
            return string.sub(str, 1, maxLen) .. "..."
        end
        return str
    end
end

-- Advanced: Hook into a function to monitor it
local function hookFunction(originalFunc, callback)
    local hookedFunc = function(...)
        -- Call callback before original function
        callback("before", ...)
        
        -- Call original function
        local results = {originalFunc(...)}
        
        -- Call callback after original function
        callback("after", ...)
        
        return unpack(results)
    end
    
    return hookedFunc
end

-- Example: Monitor a function's execution
local function monitorFunction(func, name)
    debugger:TrackFunction(func, name)
    
    local executionCount = 0
    local lastExecutionTime = 0
    
    local monitorCallback = function(event, ...)
        executionCount = executionCount + 1
        lastExecutionTime = tick()
        
        if event == "before" then
            print(string.format("[%s] Called (count: %d)", name, executionCount))
        elseif event == "after" then
            local changes = debugger:CheckTrackedFunctions()
            if #changes > 0 then
                print(string.format("[%s] Upvalues changed!", name))
                for _, change in ipairs(changes) do
                    print(string.format("  - %s.%s: %s -> %s", 
                        change.functionName,
                        change.upvalueName or "unknown",
                        truncateString(change.oldValue, 30),
                        truncateString(change.newValue, 30)
                    ))
                end
            end
        end
    end
    
    return hookFunction(func, monitorCallback)
end

-- Utility: Find and display all global functions
local function scanGlobalFunctions()
    local found = debugger:FindFunctionsInTable(_G, "_G")
    
    print(string.format("Found %d global functions:", #found))
    for i, item in ipairs(found) do
        print(string.format("%d. %s (upvalues: %d)", 
            i, 
            item.path, 
            item.info.upvalueCount
        ))
    end
    
    return found
end

-- Quick start guide
local function quickStart()
    print("=== DebugTools Quick Start ===")
    print("1. Track a function: debugger:TrackFunction(yourFunc, 'name')")
    print("2. View upvalues: debugger:GetUpvalues(yourFunc)")
    print("3. Modify upvalue: debugger:SetUpvalue(yourFunc, index, newValue)")
    print("4. Check for changes: debugger:CheckTrackedFunctions()")
    print("5. Generate code: debugger:GenerateUpvalueCode(yourFunc, 'name')")
    print("6. Get stats: debugger:GetLiveStats()")
    print("===============================")
end

-- Run the quick start guide
quickStart()

-- Create the debug UI (call this in your main loop)
-- createDebugUI()

return {
    Debugger = debugger,
    CreateDebugUI = createDebugUI,
    MonitorFunction = monitorFunction,
    ScanGlobalFunctions = scanGlobalFunctions,
    QuickStart = quickStart
}
