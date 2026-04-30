# Debug Tools for Roblox - Rayfield UI Edition

A powerful upvalue finder and function spy tool with **Rayfield UI** featuring an amazing dark blue & sky blue design.

## 🎨 Features

### Core Functionality
- 🔍 **Upvalue Finder** - Find and inspect all upvalues in functions
- 🕵️ **Function Spy** - Track function execution and detect changes
- 🌊 **Deep Search** - Search through nested tables with real values (LAG-FREE)
- ✏️ **Real-time Editing** - Modify upvalues directly with immediate effect
- 📝 **Code Generation** - Auto-generate modification code snippets
- 📊 **Live Stats** - Memory usage, change counts, performance metrics

### Performance Optimizations (NO LAG!)
- Smart caching with 1-second TTL
- Configurable search depth limits (default: 8 levels)
- Result buffer limits (default: 500 results)
- Automatic cache cleanup
- Lazy loading support

### Beautiful Rayfield UI Design
- **Dark Blue Theme** - Professional dark blue background (#0F1423)
- **Sky Blue Accents** - Vibrant deep sky blue highlights (#00BFFF)
- **Hover Effects** - Smooth color transitions on interaction
- **Draggable Window** - Move the UI anywhere on screen
- **Scrollable Content** - Handle large result sets smoothly
- **Modern Icons** - Emoji-based visual indicators

## 📁 File Structure

```
ReplicatedStorage/
├── debug_tools.lua          # Core module
└── examples/
    └── rayfield_debug_tools.lua  # Rayfield UI implementation
```

## 🚀 How to Use in Roblox

### Step 1: Install Files
1. Create a `ModuleScript` named `debug_tools` in `ReplicatedStorage`
2. Copy the contents of `debug_tools.lua` into it
3. Create another `ModuleScript` named `RayfieldDebug` in `ReplicatedStorage`
4. Copy the contents of `rayfield_debug_tools.lua` into it

### Step 2: Load the Tool
Create a `LocalScript` in `StarterPlayerScripts`:

```lua
-- LocalScript in StarterPlayerScripts
local RayfieldDebug = require(script.Parent.RayfieldDebug)

-- The UI will automatically appear when you play!
```

### Step 3: Play and Use
1. Press **F9** or click Play in Roblox Studio
2. The "Debug Tools | Upvalue Finder" window will appear
3. Use the UI to search, edit, and track functions

## 🎯 Usage Examples

### Basic Tracking
```lua
local DebugTools = require(script.Parent.debug_tools)
local debugger = setmetatable({}, DebugTools)

-- Track a function
debugger:TrackFunction(myFunction, "MyFunc")

-- Get upvalues
local upvalues = debugger:GetUpvalues(myFunction)
for _, upv in ipairs(upvalues) do
    print(upv.name, "=", upv.stringValue)
end
```

### Deep Search (No Lag)
```lua
-- Configure for performance
debugger.Config.MaxDepth = 8
debugger.Config.SearchBufferSize = 500

-- Search all tracked functions
local results, stats = debugger:SearchAllFunctions("password", {
    maxResults = 50,
    includeNested = true
})

print(string.format("Found %d results in %.4fs", 
    stats.totalResults, stats.totalTime))
```

### Edit Upvalues
```lua
-- Select function and upvalue
debugger:setSelectedFunction(myFunction)
debugger:setSelectedUpvalue({name = "secretValue", index = 1})
debugger:setEditValue("newValue")

-- Apply the change
local success, err = debugger:applyEdit()
if success then
    print("✅ Updated!")
else
    warn("❌ Error:", err)
end
```

### Generate Code
```lua
local code = debugger:GenerateUpvalueCode(myFunction, "MyFunc")
print(code)
-- Output:
-- -- Upvalue modification code for: MyFunc
-- debug.setupvalue(MyFunc, 1, <new_value>)
```

## 🎨 Color Palette

| Element | Color | RGB |
|---------|-------|-----|
| Background | Very Dark Blue | (15, 20, 35) |
| Main Panel | Dark Blue | (25, 35, 60) |
| Elements | Medium Blue | (35, 45, 75) |
| Accent | Sky Blue | (0, 191, 255) |
| Text | White | (255, 255, 255) |
| Success | Green | (0, 255, 150) |
| Warning | Yellow | (255, 200, 0) |
| Danger | Red | (255, 80, 80) |

## ⚙️ Configuration

```lua
debugger.Config = {
    MaxDepth = 8,              -- Max recursion depth for deep search
    SearchBufferSize = 500,    -- Max results to return
    CacheDuration = 1.0,       -- Cache TTL in seconds
    AutoRefresh = true,        -- Enable auto-refresh
    RefreshRate = 0.5          -- Refresh interval in seconds
}
```

## 📊 API Reference

### Core Methods
- `GetUpvalues(func)` - Get all upvalues from a function
- `DeepSearchUpvalues(func, query)` - Deep search within function upvalues
- `SearchAllFunctions(query, options)` - Search across all tracked functions
- `SetUpvalue(func, index, newValue)` - Set an upvalue
- `TrackFunction(func, name)` - Start tracking a function
- `CheckTrackedFunctions()` - Check for changes in tracked functions
- `GenerateUpvalueCode(func, name)` - Generate modification code
- `GetLiveStats()` - Get current statistics
- `ClearCaches()` - Clear all caches (free memory)

### UI State Methods
- `setSelectedFunction(func)` - Set the currently selected function
- `setSelectedUpvalue(upvalue)` - Set the currently selected upvalue
- `setEditValue(value)` - Set the edit input value
- `applyEdit()` - Apply the edited value to the selected upvalue
- `toggleAutoRefresh()` - Toggle auto-refresh on/off

## 🔥 Performance Tips

1. **Limit Search Depth**: Set `MaxDepth = 8` or lower for faster searches
2. **Use Buffer Limits**: Keep `SearchBufferSize` at 500 or less
3. **Clear Caches**: Call `ClearCaches()` periodically if searching frequently
4. **Disable Auto-Refresh**: Turn off when not needed to save resources
5. **Cache Results**: Enable `CacheResults = true` (default) for repeated queries

## 🛠️ Troubleshooting

**UI not appearing?**
- Make sure the script is a LocalScript in StarterPlayerScripts
- Check that debug library access is enabled in your game

**Search returning no results?**
- Try broader search terms
- Increase `SearchBufferSize` if needed
- Make sure functions are tracked first

**Lag during search?**
- Reduce `MaxDepth` to 5-6
- Lower `SearchBufferSize` to 200-300
- Click "Clear Caches" button

## 📄 License

MIT License - Free to use in any project!

## 🎉 Credits

- Debug Tools Core Module
- Rayfield UI Implementation (Dark Blue & Sky Blue Theme)
- Optimized for zero-lag deep searching

Enjoy hacking those upvalues! 🚀
