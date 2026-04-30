-- Example usage of DebugTools with imgui-rbx
-- This file demonstrates how to integrate the upvalue finder and function spy

-- Load required modules
local ImGui = require(script.Parent.main) -- Assuming main.lua is the imgui-rbx module
local DebugTools = require(script.Parent.debug_tools)

-- Initialize the debug tools
local debugger = setmetatable({}, DebugTools)

-- Example: Create a simple test function with upvalues for demonstration
local function createTestFunction()
    local secretValue = 42
    local playerName = "Player1"
    local multiplier = 1.5
    local configTable = {enabled = true, maxItems = 100}
    
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
        Width = 700,
        Height = 500
    }
    
    local handler = ImGui:Begin(windowOptions)
    
    if not handler then
        warn("Failed to create ImGui window")
        return
    end
    
    -- Create UI elements for DebugTools
    local stats = debugger:GetLiveStats()
    
    -- Stats Section
    handler:Separator()
    handler:Text(string.format("Tracked Functions: %d", stats.totalTracked))
    handler:Text(string.format("Total Changes Detected: %d", stats.totalChanges))
    handler:Text(string.format("Functions with Changes: %d", stats.functionsWithChanges))
    handler:Text(string.format("Memory Usage: %.2f KB", stats.memoryUsage))
    handler:Separator()
    
    -- Function List Section
    handler:Text("Tracked Functions:")
    
    for func, data in pairs(debugger.TrackedFunctions) do
        handler:Text(string.format("  • %s (Changes: %d)", data.name, data.changeCount))
        
        -- Show upvalues
        local upvalues = debugger:GetUpvalues(func)
        for _, upvalue in ipairs(upvalues) do
            handler:Text(string.format("    - %s [%s]: %s", 
                upvalue.name, 
                upvalue.valueType, 
                truncateString(upvalue.stringValue, 50)
            ))
        end
        
        -- Button to modify upvalue
        if handler:Button(string.format("Edit##%s", data.name)) then
            -- This would open an edit dialog
            print("Edit clicked for:", data.name)
        end
        
        -- Button to generate code
        if handler:Button(string.format("Generate Code##%s", data.name)) then
            local code = debugger:GenerateUpvalueCode(func, data.name)
            local success, msg = debugger:CopyToClipboard(code)
            print(msg)
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
    handler:Text("Search:")
    handler:InputText("##SearchField", "", function(text)
        debugger.uiData.searchQuery = text
    end)
    
    -- Auto-refresh toggle
    local refreshText = debugger.uiData.autoRefreshEnabled and "Auto-Refresh: ON" or "Auto-Refresh: OFF"
    if handler:Button(refreshText) then
        debugger.uiData.autoRefreshEnabled = not debugger.uiData.autoRefreshEnabled
    end
    
    -- Manual refresh button
    if handler:Button("Refresh Now") then
        local changes = debugger:CheckTrackedFunctions()
        print("Manual refresh completed. Changes found:", #changes)
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
