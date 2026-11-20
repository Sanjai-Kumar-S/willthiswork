local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

local function isOwned(itemId)
    local ok, owned = pcall(function()
        return ItemReplicationService:GetItems(KEYS.IS_OWNED)
    end)
    if not ok or type(owned) ~= "table" then return false end

    for _, entry in pairs(owned) do
        if entry and tostring(entry.ItemId) == tostring(itemId) then
            if entry.Value == true then return true end
            if type(entry.Value) == "number" and entry.Value > 0 then return true end
            if type(entry.Count) == "number" and entry.Count > 0 then return true end
        end
    end
    return false
end

local function isFruitEntry(id, cfg)
    if type(cfg) ~= "table" then return false end
    local idStr = tostring(id or ""):lower()
    local dispName = (cfg.Display and cfg.Display.Name and tostring(cfg.Display.Name):lower()) or ""
    local storageKey = (cfg.Index and cfg.Index.StorageKey and tostring(cfg.Index.StorageKey):lower()) or ""
    local itemType = (cfg.Type or cfg.Category or cfg.ItemType or "")
    itemType = tostring(itemType):lower()

    if itemType:find("fruit", 1, true) or itemType:find("blox", 1, true) then
        return true
    end
    -- Standard Blox Fruits physical/perm keys often look like "Phoenix-Phoenix" or "Permanent Phoenix-Phoenix"
    if idStr:find("-", 1, true) or storageKey:find("-", 1, true) or dispName:find("fruit", 1, true) then
        return true
    end
    return false
end

local function collectCandidateIds()
    local seen = {}
    local ids = {}

    local function pushId(v)
        if v == nil then return end
        local key = tostring(v)
        if not seen[key] then
            seen[key] = true
            table.insert(ids, v)
        end
    end

    -- Scan known ItemConfig tables/methods if present
    for k, v in pairs(ItemConfig) do
        if type(v) == "table" then
            for subK, subV in pairs(v) do
                if type(subV) == "table" and subV.ItemId ~= nil then
                    pushId(subV.ItemId)
                elseif type(subV) == "table" and subV.Display then
                    pushId(subK)
                end
            end
        end
    end

    -- Also check any keys in ItemReplicationService if exposed
    if type(ItemReplicationService.GetAllItems) == "function" then
        local ok, all = pcall(function() return ItemReplicationService:GetAllItems() end)
        if ok and type(all) == "table" then
            for _, entry in pairs(all) do
                if type(entry) == "table" and entry.ItemId ~= nil then
                    pushId(entry.ItemId)
                end
            end
        end
    end

    return ids
end

local function dumpUnownedFruits()
    local results = {}
    local candidateIds = collectCandidateIds()

    for _, id in ipairs(candidateIds) do
        local ok, cfg = pcall(function()
            return ItemConfig.tryGet(id)
        end)
        if ok and type(cfg) == "table" and isFruitEntry(id, cfg) then
            if not isOwned(id) then
                local displayName = (cfg.Display and cfg.Display.Name) or "N/A"
                local storageKey = (cfg.Index and cfg.Index.StorageKey) or "N/A"
                table.insert(results, {
                    ItemId = tostring(id),
                    DisplayName = tostring(displayName),
                    StorageKey = tostring(storageKey)
                })
            end
        end
    end

    table.sort(results, function(a, b)
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    return results
end

local function formatDump(rows)
    local lines = {}
    for _, r in ipairs(rows) do
        table.insert(lines, string.format('ItemId: %s | Display.Name: %s | Index.StorageKey: %s', r.ItemId, r.DisplayName, r.StorageKey))
    end
    return table.concat(lines, "\n")
end

local function copyText(str)
    if type(setclipboard) == "function" then
        setclipboard(str)
        return true
    elseif type(toclipboard) == "function" then
        toclipboard(str)
        return true
    end
    return false
end

local function buildGui()
    local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    local existing = parentGui:FindFirstChild("UnownedFruitDumperGui")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "UnownedFruitDumperGui"
    gui.ResetOnSpawn = false
    gui.Parent = parentGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(540, 340)
    frame.Position = UDim2.fromOffset(80, 80)
    frame.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 28)
    title.Position = UDim2.fromOffset(10, 8)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(240, 244, 248)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Enum.Font.Code
    title.TextSize = 14
    title.Text = "Unowned Fruits Dumper"
    title.Parent = frame

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.fromOffset(90, 28)
    refreshBtn.Position = UDim2.fromOffset(10, 42)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 64)
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.Font = Enum.Enum.Font.Code
    refreshBtn.TextSize = 13
    refreshBtn.Text = "Refresh"
    refreshBtn.Parent = frame

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.fromOffset(110, 28)
    copyBtn.Position = UDim2.fromOffset(108, 42)
    copyBtn.BackgroundColor3 = Color3.fromRGB(38, 110, 82)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Font = Enum.Enum.Font.Code
    copyBtn.TextSize = 13
    copyBtn.Text = "Copy All"
    copyBtn.Parent = frame

    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, -236, 0, 28)
    countLabel.Position = UDim2.fromOffset(226, 42)
    countLabel.BackgroundTransparency = 1
    countLabel.TextColor3 = Color3.fromRGB(170, 180, 195)
    countLabel.TextXAlignment = Enum.TextXAlignment.Right
    countLabel.Font = Enum.Enum.Font.Code
    countLabel.TextSize = 12
    countLabel.Text = "0 items"
    countLabel.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -86)
    scroll.Position = UDim2.fromOffset(10, 78)
    scroll.BackgroundColor3 = Color3.fromRGB(15, 17, 20)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 0, 2000)
    box.Position = UDim2.fromOffset(6, 4)
    box.BackgroundTransparency = 1
    box.ClearTextOnFocus = false
    box.MultiLine = true
    box.TextEditable = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextWrapped = false
    box.Font = Enum.Enum.Font.Code
    box.TextSize = 12
    box.TextColor3 = Color3.fromRGB(215, 225, 235)
    box.Text = ""
    box.Parent = scroll

    local currentFormatted = ""

    local function reload()
        local rows = dumpUnownedFruits()
        currentFormatted = formatDump(rows)
        box.Text = currentFormatted
        countLabel.Text = tostring(#rows) .. " unowned"
        local lineCount = math.max(#rows, 1)
        local heightPx = lineCount * 16 + 16
        box.Size = UDim2.new(1, -12, 0, heightPx)
        scroll.CanvasSize = UDim2.fromOffset(0, heightPx)
    end

    refreshBtn.MouseButton1Click:Connect(reload)
    copyBtn.MouseButton1Click:Connect(function()
        if copyText(currentFormatted) then
            copyBtn.Text = "Copied!"
            task.delay(1.2, function()
                if copyBtn then copyBtn.Text = "Copy All" end
            end)
        else
            copyBtn.Text = "No Clipboard"
        end
    end)

    reload()
end

buildGui()
