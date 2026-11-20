local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Clean up old instance if re-executed
local GUI_NAME = "ItemInspectorGUI"
if CoreGui:FindFirstChild(GUI_NAME) then
    CoreGui[GUI_NAME]:Destroy()
elseif LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME) then
    LocalPlayer.PlayerGui[GUI_NAME]:Destroy()
end

-- Build lookup table of owned items by Display Name, StorageKey, and ItemId
local ownedLookup = {}
local permItems = {}

local function refreshInventoryCache()
    table.clear(ownedLookup)
    table.clear(permItems)

    local ownedItems = ItemReplicationService:GetItems(KEYS.IS_OWNED)
    if type(ownedItems) ~= "table" then return end

    for _, item in pairs(ownedItems) do
        if item.Value == true and item.ItemId then
            local ok, cfg = pcall(ItemConfig.tryGet, item.ItemId)
            if ok and type(cfg) == "table" and cfg.Display then
                local entry = {
                    Display = tostring(cfg.Display.Name or "Unknown"),
                    ItemId = tostring(item.ItemId),
                    StorageKey = tostring((cfg.Index and cfg.Index.StorageKey) or "N/A")
                }

                ownedLookup[entry.Display:lower()] = entry
                ownedLookup[entry.ItemId:lower()] = entry
                if entry.StorageKey ~= "N/A" then
                    ownedLookup[entry.StorageKey:lower()] = entry
                end

                if entry.Display:lower():find("perm") or entry.StorageKey:lower():find("perm") then
                    table.insert(permItems, entry)
                end
            end
        end
    end
end

refreshInventoryCache()

-- Create ScreenGui (prefer CoreGui, fallback to PlayerGui)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local okParent = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not okParent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 290)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 60, 75)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -65, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Item / Perm Inspector"
TitleLabel.TextColor3 = Color3.fromRGB(235, 240, 250)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Refresh Button
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0, 24, 0, 22)
RefreshBtn.Position = UDim2.new(1, -56, 0, 5)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
RefreshBtn.Text = "↻"
RefreshBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 14
RefreshBtn.Parent = TitleBar
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 5)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 55, 65)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Selected Item Display Card
local SelectedBox = Instance.new("Frame")
SelectedBox.Size = UDim2.new(1, -20, 0, 105)
SelectedBox.Position = UDim2.new(0, 10, 0, 40)
SelectedBox.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
SelectedBox.BorderSizePixel = 0
SelectedBox.Parent = MainFrame
Instance.new("UICorner", SelectedBox).CornerRadius = UDim.new(0, 6)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -16, 0, 62)
InfoLabel.Position = UDim2.new(0, 8, 0, 6)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Click any perm/item in your inventory or below:\nDisplay: -\nItemId: - | Key: -"
InfoLabel.TextColor3 = Color3.fromRGB(210, 220, 235)
InfoLabel.Font = Enum.Font.GothamMedium
InfoLabel.TextSize = 12
InfoLabel.TextWrapped = true
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = SelectedBox

local currentSelected = nil

local function setClipboardSafe(text, btn, originalLabel)
    if not text or text == "" then return end
    if typeof(setclipboard) == "function" then
        setclipboard(text)
    elseif typeof(toclipboard) == "function" then
        toclipboard(text)
    end
    btn.Text = "Copied!"
    task.delay(1.2, function()
        if btn and btn.Parent then
            btn.Text = originalLabel
        end
    end)
end

-- Copy Display Name Button
local CopyDisplayBtn = Instance.new("TextButton")
CopyDisplayBtn.Size = UDim2.new(0.48, -4, 0, 26)
CopyDisplayBtn.Position = UDim2.new(0, 8, 1, -32)
CopyDisplayBtn.BackgroundColor3 = Color3.fromRGB(48, 115, 220)
CopyDisplayBtn.Text = "Copy Display"
CopyDisplayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyDisplayBtn.Font = Enum.Font.GothamBold
CopyDisplayBtn.TextSize = 11
CopyDisplayBtn.Parent = SelectedBox
Instance.new("UICorner", CopyDisplayBtn).CornerRadius = UDim.new(0, 5)

-- Copy ItemId Button
local CopyIdBtn = Instance.new("TextButton")
CopyIdBtn.Size = UDim2.new(0.48, -4, 0, 26)
CopyIdBtn.Position = UDim2.new(0.52, -4, 1, -32)
CopyIdBtn.BackgroundColor3 = Color3.fromRGB(45, 155, 110)
CopyIdBtn.Text = "Copy ItemId"
CopyIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyIdBtn.Font = Enum.Font.GothamBold
CopyIdBtn.TextSize = 11
CopyIdBtn.Parent = SelectedBox
Instance.new("UICorner", CopyIdBtn).CornerRadius = UDim.new(0, 5)

CopyDisplayBtn.MouseButton1Click:Connect(function()
    if currentSelected then
        setClipboardSafe(currentSelected.Display, CopyDisplayBtn, "Copy Display")
    end
end)

CopyIdBtn.MouseButton1Click:Connect(function()
    if currentSelected then
        setClipboardSafe(currentSelected.ItemId, CopyIdBtn, "Copy ItemId")
    end
end)

local function selectItem(entry)
    currentSelected = entry
    InfoLabel.Text = string.format(
        "Display: %s\nItemId: %s\nStorageKey: %s",
        entry.Display,
        entry.ItemId,
        entry.StorageKey
    )
end

-- Scrollable List of Owned Perms
local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, -20, 0, 18)
ListLabel.Position = UDim2.new(0, 10, 0, 150)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "Owned Perms (Click to Select):"
ListLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
ListLabel.Font = Enum.Font.GothamBold
ListLabel.TextSize = 11
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Parent = MainFrame

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -20, 0, 110)
ScrollList.Position = UDim2.new(0, 10, 0, 170)
ScrollList.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
ScrollList.BorderSizePixel = 0
ScrollList.ScrollBarThickness = 4
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.Parent = MainFrame
Instance.new("UICorner", ScrollList).CornerRadius = UDim.new(0, 6)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollList

local function populatePermList()
    for _, child in ipairs(ScrollList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if #permItems == 0 then
        local emptyBtn = Instance.new("TextButton")
        emptyBtn.Size = UDim2.new(1, -6, 0, 26)
        emptyBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
        emptyBtn.Text = "No perms found (Click any inv slot in-game)"
        emptyBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
        emptyBtn.Font = Enum.Font.Gotham
        emptyBtn.TextSize = 11
        emptyBtn.Parent = ScrollList
        Instance.new("UICorner", emptyBtn).CornerRadius = UDim.new(0, 4)
        return
    end

    for _, entry in ipairs(permItems) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(38, 42, 54)
        btn.Text = "  " .. entry.Display .. "  [" .. entry.ItemId .. "]"
        btn.TextColor3 = Color3.fromRGB(230, 235, 245)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = ScrollList
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            selectItem(entry)
        end)
    end
end

populatePermList()

RefreshBtn.MouseButton1Click:Connect(function()
    refreshInventoryCache()
    populatePermList()
end)

-- Detect clicks/touches on any in-game inventory slot
local function inspectClickedGuiAt(x, y)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local guiObjects = playerGui:GetGuiObjectsAtPosition(x, y)
    for _, obj in ipairs(guiObjects) do
        -- Ignore our own inspector UI
        if obj:IsDescendantOf(ScreenGui) then continue end

        -- Check button/frame names, attributes, and child TextLabels
        local candidates = { obj.Name }
        for _, attrVal in pairs(obj:GetAttributes()) do
            if type(attrVal) == "string" then
                table.insert(candidates, attrVal)
            end
        end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            table.insert(candidates, obj.Text)
        end
        for _, desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                table.insert(candidates, desc.Text)
            end
        end

        for _, raw in ipairs(candidates) do
            local clean = tostring(raw):lower():match("^%s*(.-)%s*$")
            if ownedLookup[clean] then
                selectItem(ownedLookup[clean])
                return
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        task.defer(function()
            inspectClickedGuiAt(input.Position.X, input.Position.Y)
        end)
    end
end)
