-- Debug Tools Module for imgui-rbx
-- Features: Upvalue Finder, Function Spy, Live Stats, Code Generation, Deep Search

local DebugTools = {}
DebugTools.__index = DebugTools

-- Configuration
DebugTools.Config = {
    AutoRefresh = true,
    RefreshRate = 0.5, -- seconds
    ShowNilUpvalues = false,
    MaxUpvaluesDisplay = 100,
    EnableFunctionHooking = true,
    ShowBytecodeInfo = false,
    DeepSearchEnabled = true,
    MaxDepth = 10,
    CacheResults = true,
    LazyLoading = true,
    SearchBufferSize = 1000
}

-- Storage for tracked functions
DebugTools.TrackedFunctions = {}
DebugTools.FunctionHistory = {}
DebugTools.UpvalueCache = {}
DebugTools.StatsHistory = {}
DebugTools.SearchCache = {}
DebugTools.LastSearchTime = 0

-- Utility functions
local function secureToString(value)
    if value == nil then return "nil" end
    local success, result = pcall(tostring, value)
    if success then
        return result
    end
    return "<unable to convert>"
end

local function getValueType(value)
    if value == nil then
        return "nil"
    end
    local t = type(value)
    if t == "table" then
        return "table"
    elseif t == "function" then
        return "function"
    elseif t == "userdata" then
        return "userdata"
    elseif t == "number" then
        if math.floor(value) == value then
            return "integer"
        end
        return "number"
    elseif t == "string" then
        if #value > 50 then
            return "string (long)"
        end
        return "string"
    elseif t == "boolean" then
        return "boolean"
    elseif t == "thread" then
        return "thread"
    end
    return t
end

local function truncateString(str, maxLen)
    if not str then return "" end
    if #str > maxLen then
        return string.sub(str, 1, maxLen) .. "..."
    end
    return str
end

-- Optimized cache management
local function clearOldCache()
    local currentTime = tick()
    for key, data in pairs(DebugTools.SearchCache) do
        if currentTime - data.timestamp > 60 then -- Clear cache older than 1 minute
            DebugTools.SearchCache[key] = nil
        end
    end
end

-- Deep search through table contents
local function deepSearchTable(tbl, searchQuery, currentPath, depth, results, visited)
    if depth > DebugTools.Config.MaxDepth or visited[tbl] then
        return
    end
    visited[tbl] = true
    
    for key, value in pairs(tbl) do
        local newPath = currentPath and (currentPath .. "." .. tostring(key)) or tostring(key)
        
        -- Check if key or value matches search
        local keyStr = tostring(key)
        local valueStr = secureToString(value)
        local matches = false
        
        if searchQuery == "" or 
           string.find(string.lower(keyStr), string.lower(searchQuery)) or
           string.find(string.lower(valueStr), string.lower(searchQuery)) then
            matches = true
        end
        
        if matches then
            table.insert(results, {
                path = newPath,
                key = key,
                value = value,
                valueType = getValueType(value),
                displayValue = valueStr,
                depth = depth,
                isTable = type(value) == "table"
            })
            
            if #results >= DebugTools.Config.SearchBufferSize then
                return -- Stop if buffer is full
            end
        end
        
        -- Recursively search nested tables
        if type(value) == "table" and DebugTools.Config.DeepSearchEnabled then
            deepSearchTable(value, searchQuery, newPath, depth + 1, results, visited)
        end
    end
end

-- Get upvalues from a function with caching for performance
function DebugTools:GetUpvalues(func, useCache)
    if type(func) ~= "function" then
        return {}, "Not a function"
    end
    
    -- Use cache if enabled and available
    if useCache ~= false and self.Config.CacheResults then
        local cacheKey = tostring(func)
        if self.UpvalueCache[cacheKey] then
            local cached = self.UpvalueCache[cacheKey]
            if tick() - cached.timestamp < 1.0 then -- Cache valid for 1 second
                return cached.upvalues
            end
        end
    end
    
    local upvalues = {}
    local i = 1
    while true do
        local name, value = debug.getupvalue(func, i)
        if not name then
            break
        end
        
        table.insert(upvalues, {
            index = i,
            name = name,
            value = value,
            valueType = getValueType(value),
            stringValue = secureToString(value),
            realValue = value -- Store actual value for deep inspection
        })
        
        if i >= self.Config.MaxUpvaluesDisplay then
            break
        end
        i = i + 1
    end
    
    -- Cache the result
    if self.Config.CacheResults then
        local cacheKey = tostring(func)
        self.UpvalueCache[cacheKey] = {
            upvalues = upvalues,
            timestamp = tick()
        }
    end
    
    return upvalues
end

-- Deep search upvalues for specific values
function DebugTools:DeepSearchUpvalues(func, searchQuery)
    if type(func) ~= "function" then
        return {}, "Not a function"
    end
    
    clearOldCache() -- Clean old cache entries
    
    local upvalues = self:GetUpvalues(func, false) -- Bypass cache for fresh data
    local results = {}
    
    for _, upvalue in ipairs(upvalues) do
        local nameMatch = string.find(string.lower(upvalue.name), string.lower(searchQuery))
        local valueMatch = string.find(string.lower(upvalue.stringValue), string.lower(searchQuery))
        
        if nameMatch or valueMatch then
            table.insert(results, {
                upvalue = upvalue,
                matchType = nameMatch and valueMatch and "both" or (nameMatch and "name" or "value"),
                depth = 0
            })
            
            -- Deep search if value is a table
            if type(upvalue.value) == "table" and DebugTools.Config.DeepSearchEnabled then
                local visited = {}
                local nestedResults = {}
                deepSearchTable(upvalue.value, searchQuery, upvalue.name, 1, nestedResults, visited)
                
                for _, nested in ipairs(nestedResults) do
                    table.insert(results, {
                        upvalue = upvalue,
                        nestedPath = nested.path,
                        nestedValue = nested.value,
                        nestedValueType = nested.valueType,
                        nestedDisplayValue = nested.displayValue,
                        matchType = "nested",
                        depth = nested.depth
                    })
                end
            end
        end
    end
    
    return results
end

-- Search all tracked functions for specific upvalue patterns
function DebugTools:SearchAllFunctions(searchQuery, options)
    options = options or {}
    local maxResults = options.maxResults or 100
    local includeNested = options.includeNested ~= false
    
    clearOldCache()
    
    local startTime = tick()
    local results = {}
    local visited = {}
    
    for func, data in pairs(self.TrackedFunctions) do
        if #results >= maxResults then
            break
        end
        
        local upvalues = self:GetUpvalues(func, false)
        
        for _, upvalue in ipairs(upvalues) do
            local nameMatch = string.find(string.lower(upvalue.name), string.lower(searchQuery))
            local valueMatch = string.find(string.lower(upvalue.stringValue), string.lower(searchQuery))
            
            if nameMatch or valueMatch then
                table.insert(results, {
                    functionName = data.name,
                    func = func,
                    upvalue = upvalue,
                    matchType = nameMatch and valueMatch and "both" or (nameMatch and "name" or "value")
                })
            end
            
            -- Deep search nested tables
            if includeNested and type(upvalue.value) == "table" then
                local nestedResults = {}
                deepSearchTable(upvalue.value, searchQuery, upvalue.name, 1, nestedResults, visited)
                
                for _, nested in ipairs(nestedResults) do
                    if #results >= maxResults then
                        break
                    end
                    table.insert(results, {
                        functionName = data.name,
                        func = func,
                        upvalue = upvalue,
                        nestedPath = nested.path,
                        nestedValue = nested.value,
                        nestedValueType = nested.valueType,
                        nestedDisplayValue = nested.displayValue,
                        matchType = "nested",
                        depth = nested.depth
                    })
                end
            end
        end
    end
    
    self.LastSearchTime = tick() - startTime
    
    return results, {
        totalTime = self.LastSearchTime,
        totalResults = #results,
        cacheSize = #self.SearchCache
    }
end

-- Set upvalue for a function
function DebugTools:SetUpvalue(func, upvalueIndex, newValue)
    if type(func) ~= "function" then
        return false, "Not a function"
    end
    
    local success, err = pcall(debug.setupvalue, func, upvalueIndex, newValue)
    if success then
        return true, "Upvalue updated successfully"
    else
        return false, err or "Failed to set upvalue"
    end
end

-- Get function info
function DebugTools:GetFunctionInfo(func)
    if type(func) ~= "function" then
        return nil, "Not a function"
    end
    
    local info = debug.getinfo(func, "nSu")
    local upvalues = self:GetUpvalues(func)
    
    return {
        name = info.name or "(anonymous)",
        source = info.source or "unknown",
        linedefined = info.linedefined or 0,
        what = info.what or "unknown",
        upvalueCount = #upvalues,
        upvalues = upvalues,
        func = func
    }
end

-- Track a function for monitoring
function DebugTools:TrackFunction(func, name)
    if type(func) ~= "function" then
        return false, "Not a function"
    end
    
    local funcName = name or debug.getinfo(func, "n").name or secureToString(func)
    
    self.TrackedFunctions[func] = {
        name = funcName,
        originalFunc = func,
        upvalueSnapshot = self:GetUpvalues(func),
        lastChecked = tick(),
        changeCount = 0
    }
    
    self.FunctionHistory[funcName] = self.FunctionHistory[funcName] or {}
    table.insert(self.FunctionHistory[funcName], {
        timestamp = tick(),
        action = "tracking_started",
        upvalues = self:GetUpvalues(func)
    })
    
    return true, "Function tracked: " .. funcName
end

-- Check for changes in tracked functions
function DebugTools:CheckTrackedFunctions()
    local changes = {}
    
    for func, data in pairs(self.TrackedFunctions) do
        local currentUpvalues = self:GetUpvalues(func)
        local previousUpvalues = data.upvalueSnapshot
        
        if #currentUpvalues ~= #previousUpvalues then
            table.insert(changes, {
                functionName = data.name,
                changeType = "upvalue_count_changed",
                oldCount = #previousUpvalues,
                newCount = #currentUpvalues,
                timestamp = tick()
            })
            data.changeCount = data.changeCount + 1
        else
            for i = 1, #currentUpvalues do
                local curr = currentUpvalues[i]
                local prev = previousUpvalues[i]
                
                if curr and prev then
                    if curr.stringValue ~= prev.stringValue then
                        table.insert(changes, {
                            functionName = data.name,
                            changeType = "upvalue_changed",
                            upvalueIndex = i,
                            upvalueName = curr.name,
                            oldValue = prev.stringValue,
                            newValue = curr.stringValue,
                            timestamp = tick()
                        })
                        data.changeCount = data.changeCount + 1
                    end
                end
            end
        end
        
        data.upvalueSnapshot = currentUpvalues
        data.lastChecked = tick()
    end
    
    -- Record history
    for _, change in ipairs(changes) do
        if self.FunctionHistory[change.functionName] then
            table.insert(self.FunctionHistory[change.functionName], change)
        end
    end
    
    return changes
end

-- Generate code snippet for upvalue modification
function DebugTools:GenerateUpvalueCode(func, funcName)
    if type(func) ~= "function" then
        return "-- Invalid function"
    end
    
    local upvalues = self:GetUpvalues(func)
    local name = funcName or debug.getinfo(func, "n").name or "unknown_function"
    
    local code = string.format("-- Upvalue modification code for: %s\n", name)
    code = code .. string.format("-- Source: %s\n", debug.getinfo(func, "S").source or "unknown")
    code = code .. string.format("-- Total upvalues: %d\n\n", #upvalues)
    
    for i, upvalue in ipairs(upvalues) do
        code = code .. string.format(
            '-- Upvalue %d: %s (type: %s)\n',
            upvalue.index,
            upvalue.name,
            upvalue.valueType
        )
        
        if upvalue.valueType == "number" or upvalue.valueType == "integer" then
            code = code .. string.format(
                'debug.setupvalue(%s, %d, <new_value>)\n',
                name,
                upvalue.index
            )
        elseif upvalue.valueType == "string" then
            code = code .. string.format(
                'debug.setupvalue(%s, %d, "<new_string>")\n',
                name,
                upvalue.index
            )
        elseif upvalue.valueType == "boolean" then
            code = code .. string.format(
                'debug.setupvalue(%s, %d, <true/false>)\n',
                name,
                upvalue.index
            )
        elseif upvalue.valueType == "table" then
            code = code .. string.format(
                '-- Table upvalue, modify contents directly\n'
            )
        else
            code = code .. string.format(
                'debug.setupvalue(%s, %d, <new_value>)\n',
                name,
                upvalue.index
            )
        end
        code = code .. "\n"
    end
    
    return code
end

-- Copy code to clipboard (if available)
function DebugTools:CopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
        return true, "Copied to clipboard"
    elseif writefile then
        writefile("debug_tools_snippet.txt", text)
        return true, "Saved to debug_tools_snippet.txt"
    else
        return false, "Clipboard not available"
    end
end

-- Get live stats
function DebugTools:GetLiveStats()
    local stats = {
        totalTracked = #self.TrackedFunctions,
        totalChanges = 0,
        functionsWithChanges = 0,
        recentChanges = {},
        memoryUsage = collectgarbage("count")
    }
    
    for func, data in pairs(self.TrackedFunctions) do
        stats.totalChanges = stats.totalChanges + data.changeCount
        if data.changeCount > 0 then
            stats.functionsWithChanges = stats.functionsWithChanges + 1
        end
    end
    
    -- Get recent changes from history
    for funcName, history in pairs(self.FunctionHistory) do
        local recentCount = #history
        if recentCount > 0 then
            local lastChange = history[recentCount]
            if lastChange.timestamp and (tick() - lastChange.timestamp) < 10 then
                table.insert(stats.recentChanges, {
                    functionName = funcName,
                    changeType = lastChange.changeType or "unknown",
                    timestamp = lastChange.timestamp
                })
            end
        end
    end
    
    return stats
end

-- Find all functions in a table/environment
function DebugTools:FindFunctionsInTable(tbl, path)
    path = path or "_G"
    local found = {}
    local visited = {}
    
    local function scan(current, currentPath, depth)
        if depth > 5 or visited[current] then
            return
        end
        visited[current] = true
        
        if type(current) ~= "table" then
            return
        end
        
        for key, value in pairs(current) do
            local newPath = string.format("%s[%s]", currentPath, 
                type(key) == "string" and string.format("%q", key) or tostring(key))
            
            if type(value) == "function" then
                table.insert(found, {
                    path = newPath,
                    func = value,
                    info = self:GetFunctionInfo(value)
                })
            elseif type(value) == "table" then
                scan(value, newPath, depth + 1)
            end
        end
    end
    
    scan(tbl, path, 0)
    
    return found
end

-- Create UI panel for DebugTools with deep search
function DebugTools:CreateUI(parent, elementHandler)
    if not parent or not elementHandler then
        return nil, "Invalid parent or elementHandler"
    end
    
    local uiData = {
        selectedFunction = nil,
        searchQuery = "",
        deepSearchQuery = "",
        showChangesOnly = false,
        autoRefreshEnabled = true,
        deepSearchResults = {},
        showDeepSearch = false,
        selectedUpvalue = nil,
        editValue = ""
    }
    
    -- Helper to refresh the UI
    local function refreshUI()
        -- This would be called periodically when auto-refresh is enabled
        return self:CheckTrackedFunctions()
    end
    
    -- Perform deep search
    local function performDeepSearch(query)
        if not query or query == "" then
            uiData.deepSearchResults = {}
            return {}
        end
        
        local results, stats = self:SearchAllFunctions(query, {
            maxResults = 50,
            includeNested = true
        })
        
        uiData.deepSearchResults = results
        return results, stats
    end
    
    -- Start auto-refresh loop
    if self.Config.AutoRefresh then
        spawn(function()
            while uiData.autoRefreshEnabled do
                wait(self.Config.RefreshRate)
                refreshUI()
            end
        end)
    end
    
    return {
        handler = self,
        uiData = uiData,
        refresh = refreshUI,
        performDeepSearch = performDeepSearch,
        
        -- Methods to interact with UI
        setSelectedFunction = function(func)
            uiData.selectedFunction = func
        end,
        
        setSearchQuery = function(query)
            uiData.searchQuery = query
        end,
        
        setDeepSearchQuery = function(query)
            uiData.deepSearchQuery = query
            return performDeepSearch(query)
        end,
        
        toggleShowChangesOnly = function()
            uiData.showChangesOnly = not uiData.showChangesOnly
        end,
        
        toggleAutoRefresh = function()
            uiData.autoRefreshEnabled = not uiData.autoRefreshEnabled
        end,
        
        toggleDeepSearch = function()
            uiData.showDeepSearch = not uiData.showDeepSearch
        end,
        
        setSelectedUpvalue = function(upvalue)
            uiData.selectedUpvalue = upvalue
            if upvalue then
                uiData.editValue = upvalue.stringValue
            end
        end,
        
        setEditValue = function(value)
            uiData.editValue = value
        end,
        
        applyEdit = function()
            if uiData.selectedFunction and uiData.selectedUpvalue then
                local success, err = self:SetUpvalue(
                    uiData.selectedFunction,
                    uiData.selectedUpvalue.index,
                    uiData.editValue
                )
                return success, err
            end
            return false, "No function or upvalue selected"
        end
    }
end

-- Get search performance stats
function DebugTools:GetSearchStats()
    return {
        lastSearchTime = self.LastSearchTime,
        cacheSize = #self.SearchCache,
        upvalueCacheSize = 0,
        trackedFunctions = #self.TrackedFunctions,
        config = {
            maxDepth = self.Config.MaxDepth,
            searchBufferSize = self.Config.SearchBufferSize,
            cacheEnabled = self.Config.CacheResults,
            deepSearchEnabled = self.Config.DeepSearchEnabled
        }
    }
end

-- Clear all caches
function DebugTools:ClearCaches()
    self.UpvalueCache = {}
    self.SearchCache = {}
    collectgarbage("collect")
end

-- Export for use
return DebugTools
