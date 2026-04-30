-- Debug Tools Module for imgui-rbx
-- Features: Upvalue Finder, Function Spy, Live Stats, Code Generation

local DebugTools = {}
DebugTools.__index = DebugTools

-- Configuration
DebugTools.Config = {
    AutoRefresh = true,
    RefreshRate = 0.5, -- seconds
    ShowNilUpvalues = false,
    MaxUpvaluesDisplay = 50,
    EnableFunctionHooking = true,
    ShowBytecodeInfo = false
}

-- Storage for tracked functions
DebugTools.TrackedFunctions = {}
DebugTools.FunctionHistory = {}
DebugTools.UpvalueCache = {}
DebugTools.StatsHistory = {}

-- Utility functions
local function secureToString(value)
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
        if getgenv and getgenv().isinstance then
            -- Roblox instance check
        end
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

-- Get upvalues from a function
function DebugTools:GetUpvalues(func)
    if type(func) ~= "function" then
        return {}, "Not a function"
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
            stringValue = secureToString(value)
        })
        
        if i >= self.Config.MaxUpvaluesDisplay then
            break
        end
        i = i + 1
    end
    
    return upvalues
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

-- Create UI panel for DebugTools
function DebugTools:CreateUI(parent, elementHandler)
    if not parent or not elementHandler then
        return nil, "Invalid parent or elementHandler"
    end
    
    local uiData = {
        selectedFunction = nil,
        searchQuery = "",
        showChangesOnly = false,
        autoRefreshEnabled = true
    }
    
    -- Helper to refresh the UI
    local function refreshUI()
        -- This would be called periodically when auto-refresh is enabled
        return self:CheckTrackedFunctions()
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
        
        -- Methods to interact with UI
        setSelectedFunction = function(func)
            uiData.selectedFunction = func
        end,
        
        setSearchQuery = function(query)
            uiData.searchQuery = query
        end,
        
        toggleShowChangesOnly = function()
            uiData.showChangesOnly = not uiData.showChangesOnly
        end,
        
        toggleAutoRefresh = function()
            uiData.autoRefreshEnabled = not uiData.autoRefreshEnabled
        end
    }
end

-- Export for use
return DebugTools
