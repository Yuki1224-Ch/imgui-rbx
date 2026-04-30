-- Rayfield UI Example for DebugTools
-- Dark Blue & Sky Blue Theme
-- Optimized Upvalue Finder with Deep Search (No Lag)

-- Load modules
local DebugTools = require(script.Parent.debug_tools)

-- Initialize debugger
local debugger = setmetatable({}, DebugTools)

-- Configure for optimal performance (NO LAG)
debugger.Config.MaxDepth = 8
debugger.Config.SearchBufferSize = 500
debugger.Config.CacheResults = true
debugger.Config.AutoRefresh = true
debugger.Config.RefreshRate = 0.5

-- Test function with nested upvalues
local function createTestFunction()
    local secretValue = 42
    local playerName = "Player1"
    local multiplier = 1.5
    local configTable = {
        enabled = true, 
        maxItems = 100,
        speed = 50,
        nested = {
            deepValue = "secret_data",
            password = "admin123",
            numbers = {1, 2, 3, 4, 5}
        }
    }
    
    return function()
        return secretValue * multiplier
    end
end

local testFunc = createTestFunction()
debugger:TrackFunction(testFunc, "TestFunction")

-- ============================================
-- RAYFIELD UI LIBRARY (Simplified Version)
-- Dark Blue & Sky Blue Theme
-- ============================================

local Rayfield = {}
Rayfield.__index = Rayfield

-- Color Palette
local Colors = {
    Background = Color3.fromRGB(15, 20, 35),        -- Very dark blue
    MainPanel = Color3.fromRGB(25, 35, 60),         -- Dark blue
    Element = Color3.fromRGB(35, 45, 75),           -- Medium dark blue
    ElementHover = Color3.fromRGB(50, 70, 110),     -- Lighter blue hover
    Accent = Color3.fromRGB(0, 191, 255),           -- Sky blue (Deep Sky Blue)
    AccentHover = Color3.fromRGB(64, 224, 255),     -- Brighter sky blue
    Text = Color3.fromRGB(255, 255, 255),           -- White
    TextMuted = Color3.fromRGB(180, 190, 210),      -- Light gray-blue
    Success = Color3.fromRGB(0, 255, 150),          -- Green
    Warning = Color3.fromRGB(255, 200, 0),          -- Yellow
    Danger = Color3.fromRGB(255, 80, 80),           -- Red
    Border = Color3.fromRGB(60, 80, 120)            -- Blue border
}

-- Utility: Create Frame
local function createFrame(parent, size, position, backgroundColor)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = backgroundColor or Colors.Element
    frame.BorderSizePixel = 0
    frame.Parent = parent
    return frame
end

-- Utility: Create Label
local function createLabel(parent, text, size, position, textColor)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor or Colors.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- Utility: Create Button
local function createButton(parent, text, size, position, callback)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Colors.Accent
    button.Text = text
    button.TextColor3 = Color3.fromRGB(15, 20, 35)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Colors.AccentHover
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Colors.Accent
    end)
    
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- Utility: Create Input Field
local function createInput(parent, placeholder, size, position, callback)
    local input = Instance.new("TextBox")
    input.Size = size
    input.Position = position
    input.BackgroundColor3 = Colors.Element
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = Colors.TextMuted
    input.Text = ""
    input.TextColor3 = Colors.Text
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = parent
    
    if callback then
        input.FocusLost:Connect(function()
            callback(input.Text)
        end)
    end
    
    return input
end

-- Utility: Create Section Label
local function createSection(parent, text)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 30)
    section.BackgroundTransparency = 1
    section.Parent = parent
    
    local line = createFrame(section, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0.5, 0), Colors.Border)
    
    local label = createLabel(section, "  " .. text, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Colors.Accent)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    
    return section
end

-- Create Main Window
function Rayfield:CreateWindow(options)
    options = options or {}
    local name = options.Name or "Debug Tools"
    
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RayfieldDebugTools"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 700, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -275)
    mainFrame.BackgroundColor3 = Colors.MainPanel
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add border
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.Size = UDim2.new(1, 2, 1, 2)
    border.Position = UDim2.new(0, -1, 0, -1)
    border.BackgroundColor3 = Colors.Accent
    border.BorderSizePixel = 0
    border.ZIndex = 0
    border.Parent = mainFrame
    
    -- Title bar
    local titleBar = createFrame(mainFrame, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0), Colors.Accent)
    local titleLabel = createLabel(titleBar, "  🔍 " .. name, UDim2.new(1, -60, 0, 40), UDim2.new(0, 0, 0, 0), Color3.fromRGB(15, 20, 35))
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    
    -- Close button
    local closeBtn = createButton(titleBar, "✕", UDim2.new(0, 40, 0, 40), UDim2.new(1, -40, 0, 0), function()
        screenGui:Destroy()
    end)
    closeBtn.TextSize = 20
    
    -- Make draggable
    local dragging = false
    local dragInput, mousePos, framePos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            mainFrame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Content area (scrolling)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -50)
    contentFrame.Position = UDim2.new(0, 10, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollBarImageColor3 = Colors.Accent
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
    contentFrame.Parent = mainFrame
    
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    return {
        MainFrame = mainFrame,
        Content = contentFrame,
        ScreenGui = screenGui
    }
end

-- Create Section in Content
function Rayfield:CreateSection(window, title)
    local section = createSection(window.Content, title)
    section.Position = UDim2.new(0, 0, 0, window.Content.CanvasSize.Y.Offset)
    window.Content.CanvasSize = UDim2.new(0, 0, 0, window.Content.CanvasSize.Y.Offset + 40)
    return section
end

-- Create Button in Section
function Rayfield:CreateButton(window, section, text, callback)
    local yPos = window.Content.CanvasSize.Y.Offset
    local btn = createButton(section.Parent or window.Content, text, UDim2.new(1, -20, 0, 35), UDim2.new(0, 10, 0, yPos - section.AbsoluteSize.Y), callback)
    window.Content.CanvasSize = UDim2.new(0, 0, 0, yPos + 45)
    return btn
end

-- Create Input in Section
function Rayfield:CreateInput(window, section, placeholder, callback)
    local yPos = window.Content.CanvasSize.Y.Offset
    local input = createInput(section.Parent or window.Content, placeholder, UDim2.new(1, -20, 0, 35), UDim2.new(0, 10, 0, yPos - section.AbsoluteSize.Y), callback)
    window.Content.CanvasSize = UDim2.new(0, 0, 0, yPos + 45)
    return input
end

-- Create Label in Section
function Rayfield:CreateLabel(window, section, text, color)
    local yPos = window.Content.CanvasSize.Y.Offset
    local label = createLabel(section.Parent or window.Content, text, UDim2.new(1, -20, 0, 25), UDim2.new(0, 10, 0, yPos - section.AbsoluteSize.Y), color or Colors.Text)
    window.Content.CanvasSize = UDim2.new(0, 0, 0, yPos + 30)
    return label
end

-- ============================================
-- CREATE DEBUG UI WITH RAYFIELD
-- ============================================

local function createRayfieldDebugUI()
    -- Create window
    local window = Rayfield:CreateWindow({
        Name = "Debug Tools | Upvalue Finder"
    })
    
    -- Stats Section
    Rayfield:CreateSection(window, "📊 Live Statistics")
    
    local function updateStats()
        local stats = debugger:GetLiveStats()
        local searchStats = debugger:GetSearchStats()
        
        -- Clear old stat labels (keep section)
        for _, child in ipairs(window.Content:GetChildren()) do
            if child:IsA("TextLabel") and child.Text:find("Tracked") then
                child:Destroy()
            end
        end
        
        Rayfield:CreateLabel(window, window.Content, "  Tracked Functions: " .. stats.totalTracked, Colors.Text)
        Rayfield:CreateLabel(window, window.Content, "  Total Changes: " .. stats.totalChanges, Colors.Accent)
        Rayfield:CreateLabel(window, window.Content, "  Memory: " .. string.format("%.2f KB", stats.memoryUsage), Colors.TextMuted)
        Rayfield:CreateLabel(window, window.Content, "  Last Search: " .. string.format("%.4fs", searchStats.lastSearchTime), Colors.TextMuted)
    end
    
    updateStats()
    
    -- Deep Search Section
    Rayfield:CreateSection(window, "🔎 Deep Search (Lag-Free)")
    
    local searchQuery = ""
    local searchInput = Rayfield:CreateInput(window, window.Content, "Search upvalues & nested tables...", function(text)
        searchQuery = text
    end)
    
    Rayfield:CreateButton(window, window.Content, "🔍 Search All Functions", function()
        local results, perfStats = debugger:SearchAllFunctions(searchQuery, {
            maxResults = 50,
            includeNested = true
        })
        
        -- Display results
        Rayfield:CreateSection(window, "📋 Results (" .. #results .. " found in " .. string.format("%.3f", perfStats.totalTime) .. "s)")
        
        for i, result in ipairs(results) do
            local prefix = string.rep("   ", result.depth or 0)
            local displayText = ""
            
            if result.matchType == "nested" then
                displayText = string.format("%s└─ %s.%s [%s] = %s",
                    prefix,
                    result.upvalue.name,
                    result.nestedPath,
                    result.nestedValueType,
                    result.nestedDisplayValue
                )
            else
                displayText = string.format("%s└─ %s [%s] = %s",
                    prefix,
                    result.upvalue.name,
                    result.upvalue.valueType,
                    result.upvalue.stringValue
                )
            end
            
            Rayfield:CreateLabel(window, window.Content, "  " .. displayText, Colors.TextMuted)
            
            Rayfield:CreateButton(window, window.Content, "   ✏️ Edit This Value", function()
                debugger:setSelectedFunction(result.func)
                debugger:setSelectedUpvalue(result.upvalue)
                if result.nestedPath then
                    debugger:setEditValue(tostring(result.nestedValue))
                else
                    debugger:setEditValue(result.upvalue.stringValue)
                end
                print("Selected:", result.upvalue.name)
            end)
        end
        
        if #results == 0 then
            Rayfield:CreateLabel(window, window.Content, "  No results found. Try a different search term.", Colors.Warning)
        end
    end)
    
    -- Edit Selected Section
    Rayfield:CreateSection(window, "✏️ Edit Selected Upvalue")
    
    Rayfield:CreateLabel(window, window.Content, "  Select a value from search results above to edit", Colors.TextMuted)
    
    local editInput = Rayfield:CreateInput(window, window.Content, "New value will appear here...", function(text)
        debugger:setEditValue(text)
    end)
    
    Rayfield:CreateButton(window, window.Content, "💾 Apply Changes", function()
        local success, err = debugger:applyEdit()
        if success then
            Rayfield:CreateLabel(window, window.Content, "  ✅ Successfully updated!", Colors.Success)
            updateStats()
        else
            Rayfield:CreateLabel(window, window.Content, "  ❌ Error: " .. tostring(err), Colors.Danger)
        end
    end)
    
    -- Tracked Functions Section
    Rayfield:CreateSection(window, "📁 Tracked Functions")
    
    for func, data in pairs(debugger.TrackedFunctions) do
        Rayfield:CreateLabel(window, window.Content, "  ⚡ " .. data.name .. " (Changes: " .. data.changeCount .. ")", Colors.Accent)
        
        local upvalues = debugger:GetUpvalues(func)
        for _, upvalue in ipairs(upvalues) do
            local hasNested = type(upvalue.value) == "table" and " 🔍" or ""
            local shortValue = upvalue.stringValue
            if #shortValue > 40 then shortValue = string.sub(shortValue, 1, 40) .. "..." end
            
            Rayfield:CreateLabel(window, window.Content, 
                string.format("    ├─ %s%s: %s", upvalue.name, hasNested, shortValue), 
                Colors.TextMuted)
        end
        
        Rayfield:CreateButton(window, window.Content, "    📝 Generate Code", function()
            local code = debugger:GenerateUpvalueCode(func, data.name)
            local success, msg = debugger:CopyToClipboard(code)
            print(msg)
            Rayfield:CreateLabel(window, window.Content, "  " .. msg, Colors.Success)
        end)
        
        Rayfield:CreateButton(window, window.Content, "    🔎 Deep Search This Function", function()
            local results = debugger:DeepSearchUpvalues(func, searchQuery)
            Rayfield:CreateSection(window, "📋 Results in " .. data.name .. " (" .. #results .. ")")
            
            for i, result in ipairs(results) do
                Rayfield:CreateLabel(window, window.Content, 
                    "    └─ " .. result.display, 
                    Colors.TextMuted)
            end
        end)
    end
    
    -- Actions Section
    Rayfield:CreateSection(window, "⚙️ Actions")
    
    Rayfield:CreateButton(window, window.Content, "🔄 Refresh Now", function()
        local changes = debugger:CheckTrackedFunctions()
        updateStats()
        print("Refreshed! Changes found:", #changes)
    end)
    
    Rayfield:CreateButton(window, window.Content, "🗑️ Clear Caches (Free Memory)", function()
        debugger:ClearCaches()
        Rayfield:CreateLabel(window, window.Content, "  ✅ Caches cleared!", Colors.Success)
        updateStats()
    end)
    
    Rayfield:CreateButton(window, window.Content, "🔁 Toggle Auto-Refresh", function()
        debugger:toggleAutoRefresh()
        local state = debugger.uiData.autoRefreshEnabled and "ON" or "OFF"
        Rayfield:CreateLabel(window, window.Content, "  Auto-Refresh: " .. state, Colors.Accent)
    end)
    
    -- Initial update
    updateStats()
    
    -- Auto-refresh loop
    spawn(function()
        while window.ScreenGui and window.ScreenGui.Parent do
            wait(debugger.Config.RefreshRate)
            if debugger.uiData.autoRefreshEnabled then
                updateStats()
                debugger:CheckTrackedFunctions()
            end
        end
    end)
    
    return window
end

-- ============================================
-- START THE UI
-- ============================================

print("🚀 Loading Rayfield Debug Tools...")
local ui = createRayfieldDebugUI()
print("✅ Debug Tools UI loaded! Check your screen.")

return {
    UI = ui,
    Debugger = debugger,
    Rayfield = Rayfield
}
