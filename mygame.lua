local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

local GUI_NAME = "ItemInspectorGUI"
if CoreGui:FindFirstChild(GUI_NAME) then CoreGui[GUI_NAME]:Destroy() end
if PlayerGui:FindFirstChild(GUI_NAME) then PlayerGui[GUI_NAME]:Destroy() end

local ownedLookup = {}
local allOwnedItems = {}

local function refreshInventoryCache()
    table.clear(ownedLookup)
    table.clear(allOwnedItems)

    local ownedItems = ItemReplicationService:GetItems(KEYS.IS_OWNED)
    if type(ownedItems) ~= "table" then return end

    for _, item in pairs(ownedItems) do
        if item.Value == true and item.ItemId then
            local ok, cfg = pcall(ItemConfig.tryGet, item.ItemId)
            if ok and type(cfg) == "table" and cfg.Display then
                local entry = {
                    Display = tostring(cfg.Display.Name or "Unknown"),
                    ItemId = tostring(item.ItemId),
                    StorageKey = tostring((cfg.Index and cfg.Index.StorageKey) or "N/A"),
                    Category = tostring((cfg.Index and cfg.Index.Type) or (cfg.Type) or "Item")
                }

                ownedLookup[entry.Display:lower()] = entry
                ownedLookup[entry.ItemId:lower()] = entry
                if entry.StorageKey ~= "N/A" then
                    ownedLookup[entry.StorageKey:lower()] = entry
                end

                table.insert(allOwnedItems, entry)
            end
        end
    end

    -- Sort perms/vouchers/gamepasses to the top, then alphabetical
    table.sort(allOwnedItems, function(a, b)
        local aPerm = a.Display:lower():find("perm") or a.Category:lower():find("voucher") or a.Category:lower():find("gamepass")
        local bPerm = b.Display:lower():find("perm") or b.Category:lower():find("voucher") or b.Category:lower():find("gamepass")
        if (aPerm ~= nil) ~= (bPerm ~= nil) then
            return aPerm ~= nil
        end
        return a.Display < b.Display
    end)
end

refreshInventoryCache()

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local okParent = pcall(function() ScreenGui.Parent = CoreGui end)
if not okParent then ScreenGui.Parent = PlayerGui end

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 310)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 65, 82)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- Title Bar + Custom Smooth Drag (works on both PC and Mobile Touch)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

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

-- Selected Item Display Card
local SelectedBox = Instance.new("Frame")
SelectedBox.Size = UDim2.new(1, -20, 0, 108)
SelectedBox.Position = UDim2.new(0, 10, 0, 40)
SelectedBox.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
SelectedBox.BorderSizePixel = 0
SelectedBox.Parent = MainFrame
Instance.new("UICorner", SelectedBox).CornerRadius = UDim.new(0, 6)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -16, 0, 66)
InfoLabel.Position = UDim2.new(0, 8, 0, 6)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Tap any item in your inventory or list below:\nDisplay: -\nItemId: - | Key: -"
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
        if btn and btn.Parent then btn.Text = originalLabel end
    end)
end

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
    if currentSelected then setClipboardSafe(currentSelected.Display, CopyDisplayBtn, "Copy Display") end
end)

CopyIdBtn.MouseButton1Click:Connect(function()
    if currentSelected then setClipboardSafe(currentSelected.ItemId, CopyIdBtn, "Copy ItemId") end
end)

local function selectItem(entry)
    currentSelected = entry
    InfoLabel.Text = string.format(
        "Display: %s\nItemId: %s\nKey: %s  (%s)",
        entry.Display,
        entry.ItemId,
        entry.StorageKey,
        entry.Category
    )
end

-- Search Box + Scrollable List of Owned Items
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -20, 0, 24)
SearchBox.Position = UDim2.new(0, 10, 0, 154)
SearchBox.BackgroundColor3 = Color3.fromRGB(32, 35, 45)
SearchBox.PlaceholderText = "Filter owned items (e.g. perm, dragon, storage)..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(235, 240, 250)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -20, 0, 116)
ScrollList.Position = UDim2.new(0, 10, 0, 184)
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

local function populateList(filterText)
    for _, child in ipairs(ScrollList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local query = (filterText or ""):lower():match("^%s*(.-)%s*$")
    local count = 0

    for _, entry in ipairs(allOwnedItems) do
        if query == "" or entry.Display:lower():find(query, 1, true) or entry.ItemId:lower():find(query, 1, true) then
            count += 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 25)
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

    if count == 0 then
        local emptyBtn = Instance.new("TextButton")
        emptyBtn.Size = UDim2.new(1, -6, 0, 25)
        emptyBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
        emptyBtn.Text = "No matching items found"
        emptyBtn.TextColor3 = Color3.fromRGB(160, 165, 180)
        emptyBtn.Font = Enum.Font.Gotham
        emptyBtn.TextSize = 11
        emptyBtn.Parent = ScrollList
        Instance.new("UICorner", emptyBtn).CornerRadius = UDim.new(0, 4)
    end
end

populateList("")
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    populateList(SearchBox.Text)
end)

RefreshBtn.MouseButton1Click:Connect(function()
    refreshInventoryCache()
    populateList(SearchBox.Text)
end)

-- Scan visible PlayerGui text labels after any click/tap (handles icon-only tiles whose name appears in the side panel)
local function scanVisibleInventorySelection(clickPos)
    local inset = GuiService:GetGuiInset()
    local objectsAtPos = PlayerGui:GetGuiObjectsAtPosition(clickPos.X + inset.X, clickPos.Y + inset.Y)

    -- 1. Check objects directly under the tap/click
    for _, obj in ipairs(objectsAtPos) do
        if obj:IsDescendantOf(ScreenGui) then continue end
        local candidates = { obj.Name }
        for _, v in pairs(obj:GetAttributes()) do
            if type(v) == "string" then table.insert(candidates, v) end
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

    -- 2. Fallback: Check the inventory detail header text that updates after clicking an icon tile
    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Visible and not desc:IsDescendantOf(ScreenGui) then
            local clean = desc.Text:lower():match("^%s*(.-)%s*$")
            if ownedLookup[clean] then
                selectItem(ownedLookup[clean])
                return
            end
        end
    end
end

local inputConn = UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        task.delay(0.08, function()
            if ScreenGui and ScreenGui.Parent then
                scanVisibleInventorySelection(pos)
            end
        end)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if inputConn then inputConn:Disconnect() end
    ScreenGui:Destroy()
end)
