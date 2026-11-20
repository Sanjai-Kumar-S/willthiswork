local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

local GUI_NAME = "FullRegistryDumperGUI"
if CoreGui:FindFirstChild(GUI_NAME) then CoreGui[GUI_NAME]:Destroy() end
if PlayerGui:FindFirstChild(GUI_NAME) then PlayerGui[GUI_NAME]:Destroy() end

-- Build owned lookup across IS_OWNED and COUNT
local ownedSet = {}
for _, keyVal in pairs(KEYS) do
    local ok, items = pcall(function() return ItemReplicationService:GetItems(keyVal) end)
    if ok and type(items) == "table" then
        for _, item in pairs(items) do
            if type(item) == "table" and item.ItemId and (item.Value == true or (type(item.Value) == "number" and item.Value > 0)) then
                ownedSet[item.ItemId] = true
            end
        end
    end
end

-- Dump full ItemConfig registry (1 to 3000)
local allEntries = {}
for id = 1, 3000 do
    local ok, cfg = pcall(ItemConfig.tryGet, id)
    if ok and type(cfg) == "table" and cfg.Display then
        local dName = tostring(cfg.Display.Name or "nil")
        local sKey = tostring((cfg.Index and cfg.Index.StorageKey) or "nil")
        local iType = tostring((cfg.Index and cfg.Index.Type) or cfg.Type or "nil")
        local status = ownedSet[id] and "OWNED" or "UNOWNED"

        table.insert(allEntries, {
            Id = id,
            Display = dName,
            StorageKey = sKey,
            Type = iType,
            Status = status,
            Formatted = string.format("[%s] Id=%d | Type=%s | Display=%s | Key=%s", status, id, iType, dName, sKey)
        })
    end
end

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
MainFrame.Size = UDim2.new(0, 380, 0, 340)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(58, 64, 80)
Stroke.Thickness = 1.2
Stroke.Parent = MainFrame

-- Title Bar + Smooth PC/Mobile Drag
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
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
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = string.format("ItemConfig Registry (%d Items)", #allEntries)
TitleLabel.TextColor3 = Color3.fromRGB(235, 240, 250)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(185, 55, 65)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Search Box
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -20, 0, 26)
SearchBox.Position = UDim2.new(0, 10, 0, 40)
SearchBox.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
SearchBox.PlaceholderText = "Search name, key, or ID (e.g. venom, perm, 357)..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(240, 245, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

-- Scrollable Registry Preview
local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -20, 0, 218)
ScrollList.Position = UDim2.new(0, 10, 0, 72)
ScrollList.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
ScrollList.BorderSizePixel = 0
ScrollList.ScrollBarThickness = 5
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.Parent = MainFrame
Instance.new("UICorner", ScrollList).CornerRadius = UDim.new(0, 6)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 3)
ListLayout.Parent = ScrollList

local currentFilteredLines = {}
local selectedEntry = nil

-- Bottom Action Buttons
local CopySelectedBtn = Instance.new("TextButton")
CopySelectedBtn.Size = UDim2.new(0.48, -4, 0, 32)
CopySelectedBtn.Position = UDim2.new(0, 10, 1, -40)
CopySelectedBtn.BackgroundColor3 = Color3.fromRGB(45, 155, 110)
CopySelectedBtn.Text = "Copy Selected"
CopySelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopySelectedBtn.Font = Enum.Font.GothamBold
CopySelectedBtn.TextSize = 12
CopySelectedBtn.Parent = MainFrame
Instance.new("UICorner", CopySelectedBtn).CornerRadius = UDim.new(0, 6)

local CopyAllBtn = Instance.new("TextButton")
CopyAllBtn.Size = UDim2.new(0.48, -4, 0, 32)
CopyAllBtn.Position = UDim2.new(0.52, -6, 1, -40)
CopyAllBtn.BackgroundColor3 = Color3.fromRGB(48, 115, 220)
CopyAllBtn.Text = "Copy All Listed"
CopyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyAllBtn.Font = Enum.Font.GothamBold
CopyAllBtn.TextSize = 12
CopyAllBtn.Parent = MainFrame
Instance.new("UICorner", CopyAllBtn).CornerRadius = UDim.new(0, 6)

local function copyText(str, btn, defaultText)
    if not str or str == "" then return end
    if typeof(setclipboard) == "function" then
        setclipboard(str)
    elseif typeof(toclipboard) == "function" then
        toclipboard(str)
    end
    btn.Text = "Copied!"
    task.delay(1.2, function()
        if btn and btn.Parent then btn.Text = defaultText end
    end)
end

CopySelectedBtn.MouseButton1Click:Connect(function()
    if selectedEntry then
        copyText(selectedEntry.Formatted, CopySelectedBtn, "Copy Selected")
    end
end)

CopyAllBtn.MouseButton1Click:Connect(function()
    if #currentFilteredLines > 0 then
        copyText(table.concat(currentFilteredLines, "\n"), CopyAllBtn, "Copy All Listed")
    end
end)

local function renderList(query)
    for _, child in ipairs(ScrollList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    table.clear(currentFilteredLines)

    local q = (query or ""):lower():match("^%s*(.-)%s*$")
    local renderedCount = 0

    for _, entry in ipairs(allEntries) do
        local searchable = entry.Formatted:lower()
        if q == "" or searchable:find(q, 1, true) then
            table.insert(currentFilteredLines, entry.Formatted)

            -- Cap visible UI buttons at 150 to keep scrolling smooth; "Copy All Listed" still copies 100% of matches
            if renderedCount < 150 then
                renderedCount += 1
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -6, 0, 24)
                row.BackgroundColor3 = entry.Status == "OWNED" and Color3.fromRGB(36, 48, 44) or Color3.fromRGB(35, 38, 48)
                row.Text = string.format(" [%s] %d | %s (%s)", entry.Status == "OWNED" and "✓" or " ", entry.Id, entry.Display, entry.StorageKey)
                row.TextColor3 = entry.Status == "OWNED" and Color3.fromRGB(165, 240, 195) or Color3.fromRGB(215, 220, 235)
                row.Font = Enum.Font.GothamMedium
                row.TextSize = 11
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.Parent = ScrollList
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

                row.MouseButton1Click:Connect(function()
                    selectedEntry = entry
                    CopySelectedBtn.Text = "Copy Id: " .. tostring(entry.Id)
                end)
            end
        end
    end

    CopyAllBtn.Text = string.format("Copy All (%d)", #currentFilteredLines)
end

renderList("")

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    renderList(SearchBox.Text)
end)
