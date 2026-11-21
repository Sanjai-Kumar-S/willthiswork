
--=========================================================
-- BLOX FRUITS - ITEM CATALOGUE / TRADABILITY DUMPER
--=========================================================
-- Reports:
-- ItemId | DisplayName | StorageKey | Type
-- Ownership | Equipped | Tradability
--
-- IMPORTANT:
-- Tradability is only reported when explicit metadata
-- is available. Missing metadata = UNKNOWN.
--=========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local ItemReplicationService = require(
    ReplicatedStorage:WaitForChild("ItemReplicationService")
)

local KEYS = require(
    ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS")
)

local ItemConfig = require(
    ReplicatedStorage:WaitForChild("ItemConfig")
)

--=========================================================
-- GENERAL HELPERS
--=========================================================

local function safeString(value)
    if value == nil then
        return "N/A"
    end

    if type(value) == "table" then
        return "TABLE"
    end

    return tostring(value)
end

local function normalizeKey(value)
    return tostring(value or "")
        :lower()
        :gsub("[%s_%-]", "")
end

local function getDisplayName(cfg)
    if type(cfg) ~= "table" then
        return "N/A"
    end

    if type(cfg.Display) == "table" then
        return safeString(cfg.Display.Name)
    end

    return "N/A"
end

local function getStorageKey(cfg)
    if type(cfg) == "table"
        and type(cfg.Index) == "table" then

        return safeString(cfg.Index.StorageKey)
    end

    return "N/A"
end

local function getItemType(cfg)
    if type(cfg) ~= "table" then
        return "N/A"
    end

    return safeString(
        cfg.Type
        or cfg.Category
        or cfg.ItemType
        or cfg.SubType
    )
end

--=========================================================
-- OWNERSHIP DATA
--=========================================================

local function getOwnershipData()
    local ownership = {}

    local ok, data = pcall(function()
        return ItemReplicationService:GetItems(KEYS.IS_OWNED)
    end)

    if not ok or type(data) ~= "table" then
        return ownership
    end

    for _, entry in pairs(data) do
        if type(entry) == "table" and entry.ItemId ~= nil then

            local id = tostring(entry.ItemId)

            local owned = false

            if entry.Value == true then
                owned = true
            elseif type(entry.Value) == "number"
                and entry.Value > 0 then

                owned = true
            elseif type(entry.Count) == "number"
                and entry.Count > 0 then

                owned = true
            end

            local equipped = nil

            for key, value in pairs(entry) do
                local normalized = normalizeKey(key)

                if normalized == "equipped"
                    or normalized == "isequipped"
                    or normalized == "isequippeditem" then

                    if type(value) == "boolean" then
                        equipped = value
                    end
                end
            end

            ownership[id] = {
                Owned = owned,
                Equipped = equipped,
                Count = entry.Count
            }
        end
    end

    return ownership
end

--=========================================================
-- CANDIDATE ITEM ID COLLECTION
--=========================================================

local function collectCandidateIds()
    local ids = {}
    local seen = {}
    local visited = {}

    local function pushId(value)
        if value == nil then
            return
        end

        local id = tostring(value)

        if id == "" or seen[id] then
            return
        end

        seen[id] = true
        table.insert(ids, value)
    end

    local function scanTable(tbl, depth)
        if type(tbl) ~= "table" then
            return
        end

        if depth > 8 then
            return
        end

        if visited[tbl] then
            return
        end

        visited[tbl] = true

        for key, value in pairs(tbl) do
            if type(value) == "table" then

                if value.ItemId ~= nil then
                    pushId(value.ItemId)

                elseif value.Display ~= nil
                    or value.Index ~= nil then

                    pushId(key)
                end

                scanTable(value, depth + 1)
            end
        end
    end

    -- Scan ItemConfig catalogue.
    scanTable(ItemConfig, 0)

    -- Scan replicated item data if the method exists.
    if type(ItemReplicationService.GetAllItems) == "function" then

        local ok, allItems = pcall(function()
            return ItemReplicationService:GetAllItems()
        end)

        if ok and type(allItems) == "table" then
            scanTable(allItems, 0)
        end
    end

    return ids
end

--=========================================================
-- TRADEABILITY METADATA INSPECTION
--=========================================================

local function inspectTradeMetadata(cfg)

    local result = {
        Status = "UNKNOWN",
        Evidence = "No explicit trade metadata found"
    }

    local visited = {}

    local function scan(tbl, depth)
        if type(tbl) ~= "table" then
            return
        end

        if depth > 6 or visited[tbl] then
            return
        end

        visited[tbl] = true

        for key, value in pairs(tbl) do

            local normalized = normalizeKey(key)

            local isTradeField =
                normalized == "tradable"
                or normalized == "tradeable"
                or normalized == "istradable"
                or normalized == "istradeable"
                or normalized == "cantrade"
                or normalized == "canbetraded"
                or normalized == "istradableitem"
                or normalized == "canbetradable"

            if isTradeField then

                if value == true then
                    result.Status = "TRADABLE"
                    result.Evidence = tostring(key)
                    return true

                elseif value == false then
                    result.Status = "NON-TRADABLE"
                    result.Evidence = tostring(key)
                    return true

                elseif type(value) == "string" then
                    local text = value:lower()

                    if text == "true"
                        or text == "tradable"
                        or text == "tradeable" then

                        result.Status = "TRADABLE"
                        result.Evidence = tostring(key)
                        return true

                    elseif text == "false"
                        or text == "non-tradable"
                        or text == "nontradable" then

                        result.Status = "NON-TRADABLE"
                        result.Evidence = tostring(key)
                        return true
                    end
                end
            end

            if type(value) == "table" then
                if scan(value, depth + 1) then
                    return true
                end
            end
        end

        return false
    end

    scan(cfg, 0)

    return result
end

--=========================================================
-- EQUIPPED STATUS
--=========================================================

local function getEquippedStatus(ownershipEntry)

    if not ownershipEntry or not ownershipEntry.Owned then
        return "N/A (UNOWNED)"
    end

    if ownershipEntry.Equipped == true then
        return "EQUIPPED"
    end

    if ownershipEntry.Equipped == false then
        return "NOT EQUIPPED"
    end

    return "UNKNOWN"
end

--=========================================================
-- MAIN DUMP
--=========================================================

local function dumpItems()

    local results = {}

    local candidateIds = collectCandidateIds()
    local ownership = getOwnershipData()

    for _, id in ipairs(candidateIds) do

        local ok, cfg = pcall(function()
            return ItemConfig.tryGet(id)
        end)

        if ok and type(cfg) == "table" then

            local idString = tostring(id)

            local tradeInfo = inspectTradeMetadata(cfg)
            local ownerInfo = ownership[idString]

            local ownedStatus = "UNOWNED"

            if ownerInfo and ownerInfo.Owned then
                ownedStatus = "OWNED"
            end

            local row = {
                ItemId = idString,

                DisplayName = getDisplayName(cfg),

                StorageKey = getStorageKey(cfg),

                ItemType = getItemType(cfg),

                Ownership = ownedStatus,

                Equipped = getEquippedStatus(ownerInfo),

                Tradability = tradeInfo.Status,

                TradeEvidence = tradeInfo.Evidence
            }

            table.insert(results, row)
        end
    end

    table.sort(results, function(a, b)

        local nameA = a.DisplayName:lower()
        local nameB = b.DisplayName:lower()

        if nameA == nameB then
            return a.ItemId < b.ItemId
        end

        return nameA < nameB
    end)

    return results
end

--=========================================================
-- OUTPUT FORMAT
--=========================================================

local function formatDump(rows)

    local lines = {}

    table.insert(lines, "========== BLOX FRUITS ITEM DUMP ==========")
    table.insert(lines, "Total Items: " .. tostring(#rows))
    table.insert(lines, "")

    for _, item in ipairs(rows) do

        table.insert(lines, string.format(
            "ItemId: %s | Name: %s | Key: %s | Type: %s | Owned: %s | Equipped: %s | Tradable: %s | Evidence: %s",

            item.ItemId,
            item.DisplayName,
            item.StorageKey,
            item.ItemType,
            item.Ownership,
            item.Equipped,
            item.Tradability,
            item.TradeEvidence
        ))
    end

    return table.concat(lines, "\n")
end

--=========================================================
-- CLIPBOARD
--=========================================================

local function copyText(str)

    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, str)
        return ok
    end

    if type(toclipboard) == "function" then
        local ok = pcall(toclipboard, str)
        return ok
    end

    return false
end

--=========================================================
-- GUI
--=========================================================

local function buildGui()

    local parentGui

    if type(gethui) == "function" then
        local ok, result = pcall(gethui)

        if ok and result then
            parentGui = result
        end
    end

    parentGui = parentGui
        or CoreGui
        or LocalPlayer:WaitForChild("PlayerGui")

    local existing = parentGui:FindFirstChild(
        "ItemTradabilityDumperGui"
    )

    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ItemTradabilityDumperGui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parentGui

    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(850, 520)
    frame.Position = UDim2.new(0.5, -425, 0.5, -260)
    frame.BackgroundColor3 = Color3.fromRGB(22, 24, 29)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 35)
    title.Position = UDim2.fromOffset(10, 5)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(240, 244, 248)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.Code
    title.TextSize = 17
    title.Text = "Blox Fruits - Item Tradability Dumper"
    title.Parent = frame

    -- Refresh
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.fromOffset(100, 32)
    refreshBtn.Position = UDim2.fromOffset(10, 45)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 145)
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.Code
    refreshBtn.TextSize = 13
    refreshBtn.Text = "Refresh"
    refreshBtn.Parent = frame

    -- Copy
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.fromOffset(110, 32)
    copyBtn.Position = UDim2.fromOffset(120, 45)
    copyBtn.BackgroundColor3 = Color3.fromRGB(38, 110, 82)
    copyBtn.TextColor3 = Color3.new(1, 1, 1)
    copyBtn.Font = Enum.Font.Code
    copyBtn.TextSize = 13
    copyBtn.Text = "Copy All"
    copyBtn.Parent = frame

    -- Count
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, -360, 0, 32)
    countLabel.Position = UDim2.fromOffset(240, 45)
    countLabel.BackgroundTransparency = 1
    countLabel.TextColor3 = Color3.fromRGB(180, 190, 205)
    countLabel.TextXAlignment = Enum.TextXAlignment.Right
    countLabel.Font = Enum.Font.Code
    countLabel.TextSize = 13
    countLabel.Text = "Waiting..."
    countLabel.Parent = frame

    -- Close
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(32, 32)
    closeBtn.Position = UDim2.new(1, -42, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(145, 48, 48)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.Code
    closeBtn.TextSize = 16
    closeBtn.Text = "X"
    closeBtn.Parent = frame

    -- Scrolling output
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -95)
    scroll.Position = UDim2.fromOffset(10, 85)
    scroll.BackgroundColor3 = Color3.fromRGB(13, 15, 19)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 7
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 0, 100)
    box.Position = UDim2.fromOffset(6, 5)
    box.BackgroundTransparency = 1
    box.ClearTextOnFocus = false
    box.MultiLine = true
    box.TextEditable = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextWrapped = false
    box.Font = Enum.Font.Code
    box.TextSize = 12
    box.TextColor3 = Color3.fromRGB(215, 225, 235)
    box.Text = "Press Refresh to scan item definitions."
    box.Parent = scroll

    local currentFormatted = ""

    -- Refresh function
    local function reload()

        countLabel.Text = "Scanning..."

        local ok, rows = pcall(dumpItems)

        if not ok then
            box.Text = "ERROR WHILE SCANNING:\n" .. tostring(rows)
            countLabel.Text = "Scan failed"
            return
        end

        currentFormatted = formatDump(rows)
        box.Text = currentFormatted

        local heightPx = math.max(#rows, 1) * 19 + 30

        box.Size = UDim2.new(1, -12, 0, heightPx)
        scroll.CanvasSize = UDim2.fromOffset(0, heightPx)

        local tradable = 0
        local nonTradable = 0
        local unknown = 0

        for _, item in ipairs(rows) do
            if item.Tradability == "TRADABLE" then
                tradable = tradable + 1
            elseif item.Tradability == "NON-TRADABLE" then
                nonTradable = nonTradable + 1
            else
                unknown = unknown + 1
            end
        end

        countLabel.Text = string.format(
            "%d Items | T:%d NT:%d ?: %d",
            #rows,
            tradable,
            nonTradable,
            unknown
        )
    end

    refreshBtn.MouseButton1Click:Connect(reload)

    copyBtn.MouseButton1Click:Connect(function()

        if currentFormatted == "" then
            copyBtn.Text = "Nothing to Copy"
            return
        end

        if copyText(currentFormatted) then
            copyBtn.Text = "Copied!"
        else
            copyBtn.Text = "Clipboard Error"
        end

        task.delay(1.5, function()
            if copyBtn and copyBtn.Parent then
                copyBtn.Text = "Copy All"
            end
        end)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    reload()
end

--=========================================================
-- START
--=========================================================

buildGui()
