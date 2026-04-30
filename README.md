# ImGui RBX 

A Dear ImGui clone for roblox.
`This is an alpha release of imgui-rbx, expect some bugs and more elements being added soon`

Contact: `cdy#8803`

![made-in-luau](https://user-images.githubusercontent.com/111649405/230965208-a68cca3a-9ef3-4e06-9408-5116994f570e.svg)


![Example](https://cdn.discordapp.com/attachments/1089941257117257731/1094674670030172290/image.png)

Resizing feature (gyazo made it look buggy)


![](https://user-images.githubusercontent.com/111649405/230788331-c3af0e11-5ac7-4fdb-8a85-427b66f63232.gif)


ColorPicker3 Example

![](https://user-images.githubusercontent.com/111649405/230796228-78263db7-4066-4ca8-aa1e-ce69865b44b6.gif)


Radio Toggle Example

![](https://user-images.githubusercontent.com/111649405/230799997-33fad637-3ed8-45ef-be07-4aaa7fa8132f.gif)


SinWaveGraph Example (Visualize your random values)

![](https://user-images.githubusercontent.com/111649405/230933404-89e9836f-0717-4b03-87d9-d43922af44df.gif)


Final Example

![](https://user-images.githubusercontent.com/111649405/230902091-64b606ad-ff28-4b1e-8021-7617dee9dab1.gif)

## Current Theme: Legacy (More will be added soon)
Some info on themes: Themes will have different components and styles, for example there will be rounded elements and boxxed elements, and there will be custom themes and light themes for ImGui-RBX

# Progress

| Element Type              | Added | Functional | Bugs (?)             |
|---------------------------|-------|------------|----------------------|
| Themes                    | false | false      | only legacy theme    |
| Text / Label              | true  | true       | none                 |
| Checkbox / Toggle         | true  | true       | none                 |
| Slider/s (Integer, Float) | true  | semi       | none                 |
| Seperator                 | true  | true       | none                 |
| Color Picker              | true  | true       | added logic, fixings |
| Radio Toggles             | true  | true       | none                 |
| Input Text                | true  | true       | none                 |
| SinWaveGraph              | true  | semi       | returning bad value  |
| Menu Bar                  | false | false      | none                 |
| Text Colored              | false | false      | none                 |
| Mini Windows              | false | false      | none                 |
| Drodown Lists             | false | false      | none                 |
| Sections                  | false | false      | none                 |


# Information 
To make it feel more like ImGui,
creating and handling elements will be very similar to ImGui in C++.
For example, handling and creating a button
```lua
if (Window:Button("Hello")) then 
    My_function();
end
```
Things like this will be implemented.

# Todo
Fix up code, make it more clean and readable.


# Requiring
```lua
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/wiIlow/imgui-rbx/main/main.lua", true))()
```

# Documentation
Check `examples` on how to use each feature.

# Debug Tools (NEW!)
A powerful debugging module featuring:
- **Upvalue Finder**: Inspect and modify function upvalues in real-time
- **Function Spy**: Track function execution and detect upvalue changes
- **Live Stats**: Monitor memory usage, change counts, and recent modifications
- **Code Generation**: Auto-generate code snippets for upvalue modifications
- **Clipboard Support**: Copy generated code directly to clipboard

## Features

### Upvalue Finder
- View all upvalues of any function with type information
- Edit upvalues in real-time with immediate effect
- Filter and search through tracked functions
- Automatic change detection with history tracking

### Function Spy
- Track multiple functions simultaneously
- Detect when upvalues change during execution
- Get notifications on modifications
- View change history with timestamps

### Live Stats Dashboard
- Total tracked functions count
- Total changes detected across all functions
- Memory usage monitoring
- Recent changes list with details

### Code Generation
- Generate ready-to-use code snippets for upvalue modification
- Supports all Lua types (number, string, boolean, table)
- Copy to clipboard or save to file
- Includes comments with source information

## Usage Example

```lua
-- Load the debug tools
local DebugTools = require(script.Parent.debug_tools)
local debugger = setmetatable({}, DebugTools)

-- Track a function
debugger:TrackFunction(yourFunction, "myFunction")

-- View upvalues
local upvalues = debugger:GetUpvalues(yourFunction)
for _, upvalue in ipairs(upvalues) do
    print(string.format("%s [%s]: %s", 
        upvalue.name, 
        upvalue.valueType, 
        upvalue.stringValue
    ))
end

-- Modify an upvalue
debugger:SetUpvalue(yourFunction, 1, newValue)

-- Check for changes
local changes = debugger:CheckTrackedFunctions()

-- Generate code snippet
local code = debugger:GenerateUpvalueCode(yourFunction, "myFunction")
debugger:CopyToClipboard(code)

-- Get live statistics
local stats = debugger:GetLiveStats()
print("Tracked:", stats.totalTracked)
print("Changes:", stats.totalChanges)
```

## Integration with ImGui-RBX

The debug tools include full integration with imgui-rbx for a visual interface:

```lua
local ImGui = require(script.Parent.main)
local DebugTools = require(script.Parent.debug_tools)
local debugger = setmetatable({}, DebugTools)

-- Create your ImGui window
local handler = ImGui:Begin({Name = "Debug Tools", Width = 700, Height = 500})

-- Display stats
handler:Text("Tracked Functions: " .. debugger:GetLiveStats().totalTracked)

-- List tracked functions with edit buttons
for func, data in pairs(debugger.TrackedFunctions) do
    handler:Text(data.name)
    
    -- Show upvalues
    local upvalues = debugger:GetUpvalues(func)
    for _, uv in ipairs(upvalues) do
        handler:Text(string.format("  %s: %s", uv.name, uv.stringValue))
    end
    
    -- Edit button
    if handler:Button("Edit##" .. data.name) then
        -- Open edit dialog
    end
    
    -- Generate code button
    if handler:Button("Copy Code##" .. data.name) then
        local code = debugger:GenerateUpvalueCode(func, data.name)
        debugger:CopyToClipboard(code)
    end
end
```

See `examples/debug_tools_example.lua` for complete usage examples.

## API Reference

### Core Functions
- `debugger:TrackFunction(func, name)` - Start tracking a function
- `debugger:GetUpvalues(func)` - Get all upvalues from a function
- `debugger:SetUpvalue(func, index, newValue)` - Modify an upvalue
- `debugger:CheckTrackedFunctions()` - Check for changes in tracked functions
- `debugger:GetFunctionInfo(func)` - Get detailed function information

### Utility Functions
- `debugger:GenerateUpvalueCode(func, name)` - Generate modification code
- `debugger:CopyToClipboard(text)` - Copy text to clipboard
- `debugger:GetLiveStats()` - Get current statistics
- `debugger:FindFunctionsInTable(tbl, path)` - Find functions in a table

### Configuration
```lua
DebugTools.Config = {
    AutoRefresh = true,        -- Auto-check for changes
    RefreshRate = 0.5,         -- Check interval in seconds
    ShowNilUpvalues = false,   -- Show nil upvalues
    MaxUpvaluesDisplay = 50,   -- Maximum upvalues to display
    EnableFunctionHooking = true,
    ShowBytecodeInfo = false
}
```
