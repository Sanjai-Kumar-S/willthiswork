local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local results = {}
local seen = {}

local function extractField(tbl, key)
    if type(tbl) ~= "table" then return nil end
    local ok, val = pcall(function() return tbl[key] end)
    return ok and val or nil
end

local function scanTable(tbl, depth)
    if depth > 5 or type(tbl) ~= "table" or seen[tbl] then
        return
    end
    seen[tbl] = true

    local itemId = extractField(tbl, "ItemId") or extractField(tbl, "Id")
    local display = extractField(tbl, "Display")
    local index = extractField(tbl, "Index")

    local displayName = extractField(display, "Name") or extractField(tbl, "DisplayName") or extractField(tbl, "Name")
    local storageKey = extractField(index, "StorageKey") or extractField(tbl, "StorageKey")

    if itemId and (displayName or storageKey) then
        local itemType = extractField(tbl, "Type") or extractField(index, "Type") or extractField(tbl, "Category")
        local isTradable = extractField(tbl, "Tradable")
        if isTradable == nil then
            isTradable = extractField(index, "Tradable")
        end

        table.insert(results, {
            ItemId = itemId,
            DisplayName = tostring(displayName or ""),
            StorageKey = tostring(storageKey or ""),
            Type = tostring(itemType or "Unknown"),
            Tradable = isTradable,
            IsPerm = extractField(tbl, "IsPerm") or extractField(index, "IsPerm") or false,
            GamepassId = extractField(tbl, "GamepassId") or extractField(tbl, "ProductId")
        })
    end

    for _, v in next, tbl do
        if type(v) == "table" then
            scanTable(v, depth + 1)
        end
    end
end

for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
    if inst:IsA("ModuleScript") then
        local ok, mod = pcall(require, inst)
        if ok and type(mod) == "table" then
            scanTable(mod, 0)
        end
    end
end

if #results == 0 and getgc then
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" then
            scanTable(obj, 0)
        end
    end
end

table.sort(results, function(a, b)
    return tostring(a.ItemId) < tostring(b.ItemId)
end)

local jsonPayload = HttpService:JSONEncode(results)

-- GUI setup
local guiParent = (gethui and gethui()) or CoreGui
local oldGui = guiParent:FindFirstChild("BFItemDumperGui")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BFItemDumperGui"
screenGui.ResetOnSpawn = false
local okParent = pcall(function() screenGui.Parent = guiParent end)
if not okParent then
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 520, 0, 380)
frame.Position = UDim2.new(0.5, -260, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 29)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 34)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = string.format("Item Registry Dump (%d entries)", #results)
title.TextColor3 = Color3.fromRGB(235, 238, 245)
title.Font = Enum.Font.Code
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 56)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(220, 90, 90)
closeBtn.Font = Enum.Font.Code
closeBtn.TextSize = 14
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -86)
scroll.Position = UDim2.new(0, 12, 0, 38)
scroll.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 4)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = scroll

for i = 1, math.min(#results, 300) do
    local item = results[i]
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -10, 0, 20)
    row.BackgroundTransparency = 1
    row.Text = string.format("[%s] %s | Key: %s | Type: %s",
        tostring(item.ItemId),
        item.DisplayName,
        item.StorageKey,
        item.Type
    )
    row.TextColor3 = Color3.fromRGB(190, 200, 215)
    row.Font = Enum.Font.Code
    row.TextSize = 12
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextTruncate = Enum.TextTruncate.AtEnd
    row.Parent = scroll
end

local copyJsonBtn = Instance.new("TextButton")
copyJsonBtn.Size = UDim2.new(0.48, 0, 0, 32)
copyJsonBtn.Position = UDim2.new(0, 12, 1, -40)
copyJsonBtn.BackgroundColor3 = Color3.fromRGB(46, 125, 80)
copyJsonBtn.Text = "Copy All (JSON)"
copyJsonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyJsonBtn.Font = Enum.Font.Code
copyJsonBtn.TextSize = 13
copyJsonBtn.Parent = frame
Instance.new("UICorner", copyJsonBtn).CornerRadius = UDim.new(0, 4)

local copyLuaBtn = Instance.new("TextButton")
copyLuaBtn.Size = UDim2.new(0.48, 0, 0, 32)
copyLuaBtn.Position = UDim2.new(0.52, -12, 1, -40)
copyLuaBtn.BackgroundColor3 = Color3.fromRGB(58, 95, 160)
copyLuaBtn.Text = "Copy All (Lua Table)"
copyLuaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyLuaBtn.Font = Enum.Font.Code
copyLuaBtn.TextSize = 13
copyLuaBtn.Parent = frame
Instance.new("UICorner", copyLuaBtn).CornerRadius = UDim2.new(0, 4)

local function buildLuaTable()
    local lines = { "local ItemRegistry = {" }
    for _, item in ipairs(results) do
        table.insert(lines, string.format(
            '    { ItemId = %q, Name = %q, StorageKey = %q, Type = %q },',
            tostring(item.ItemId),
            item.DisplayName,
            item.StorageKey,
            item.Type
        ))
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

copyJsonBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(jsonPayload)
        copyJsonBtn.Text = "Copied JSON!"
        task.delay(1.5, function() copyJsonBtn.Text = "Copy All (JSON)" end)
    else
        copyJsonBtn.Text = "No setclipboard"
    end
end)

copyLuaBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(buildLuaTable())
        copyLuaBtn.Text = "Copied Lua!"
        task.delay(1.5, function() copyLuaBtn.Text = "Copy All (Lua Table)" end)
    else
        copyLuaBtn.Text = "No setclipboard"
    end
end)
