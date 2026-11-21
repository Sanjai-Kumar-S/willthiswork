
--=========================================================
-- BLOX FRUITS - ITEM CATALOGUE DIAGNOSTIC DUMPER
--=========================================================
-- Displays:
-- 1. ItemConfig structure
-- 2. ItemReplicationService structure
-- 3. KEYS structure
-- 4. MasterItemDictionary availability
-- 5. Candidate item IDs discovered
-- 6. Any item definitions successfully resolved
--
-- Diagnostics appear directly in the GUI.
-- No executor console required.
--=========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--=========================================================
-- MODULES
--=========================================================

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
-- STATE
--=========================================================

local scanDiagnostics = ""
local currentFormatted = ""

--=========================================================
-- HELPERS
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
    if type(cfg) == "table"
        and type(cfg.Display) == "table" then

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
-- DIAGNOSTIC TABLE INSPECTION
--=========================================================

local function inspectTable(name, tbl, lines)

    table.insert(lines, "")
    table.insert(lines, "========== " .. name .. " ==========")
    table.insert(lines, "Type: " .. typeof(tbl))

    if type(tbl) ~= "table" then
        table.insert(lines, "Not a Lua table")
        return
    end

    local count = 0

    for key, value in pairs(tbl) do

        count = count + 1

        local valueType = typeof(value)
        local valueText = ""

        if type(value) == "function" then
            valueText = "FUNCTION"
        elseif type(value) == "table" then
            valueText = "TABLE"
        else
            valueText = tostring(value)
        end

        table.insert(
            lines,
            tostring(key) .. " | " ..
            valueType .. " | " .. valueText
        )

        if count >= 40 then
            table.insert(lines, "Stopped after 40 entries")
            break
        end
    end

    table.insert(lines, "Entries inspected: " .. count)
end

--=========================================================
-- CANDIDATE ITEM ID COLLECTION + DIAGNOSTICS
--=========================================================

local function collectCandidateIds()

    local ids = {}
    local seen = {}
    local lines = {}

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

    -- Inspect important modules.
    inspectTable("ItemConfig", ItemConfig, lines)

    inspectTable(
        "ItemReplicationService",
        ItemReplicationService,
        lines
    )

    inspectTable("KEYS", KEYS, lines)

    -- Scan ItemConfig recursively.
    local visited = {}

    local function scanTable(tbl, depth)

        if type(tbl) ~= "table" then
            return
        end

        if depth > 8 or visited[tbl] then
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

    scanTable(ItemConfig, 0)

    -- Check GetAllItems if exposed.
    local getAllItemsAvailable =
        type(ItemReplicationService.GetAllItems) == "function"

    table.insert(lines, "")
    table.insert(
        lines,
        "GetAllItems available: " ..
        tostring(getAllItemsAvailable)
    )

    if getAllItemsAvailable then

        local ok, allItems = pcall(function()
            return ItemReplicationService:GetAllItems()
        end)

        table.insert(
            lines,
            "GetAllItems successful: " .. tostring(ok)
        )

        if ok and type(allItems) == "table" then

            inspectTable("GetAllItems result", allItems, lines)

            scanTable(allItems, 0)

        elseif not ok then

            table.insert(lines, "GetAllItems error: " .. tostring(allItems))
        end
    end

    -- Check MasterItemDictionary.
    local master = ReplicatedStorage:FindFirstChild(
        "MasterItemDictionary"
    )

    table.insert(lines, "")
    table.insert(
        lines,
        "MasterItemDictionary exists: " .. tostring(master ~= nil)
    )

    if master then

        table.insert(
            lines,
            "MasterItemDictionary class: " .. master.ClassName
        )

        if master:IsA("ModuleScript") then

            local ok, result = pcall(require, master)

            table.insert(
                lines,
                "MasterItemDictionary require successful: " ..
                tostring(ok)
            )

            if ok and type(result) == "table" then

                inspectTable(
                    "MasterItemDictionary contents",
                    result,
                    lines
                )

                scanTable(result, 0)

            elseif not ok then

                table.insert(
                    lines,
                    "Require error: " .. tostring(result)
                )
            end
        end
    end

    table.insert(lines, "")
    table.insert(lines, "========== DISCOVERY SUMMARY ==========")
    table.insert(
        lines,
        "Candidate IDs discovered: " .. tostring(#ids)
    )

    scanDiagnostics = table.concat(lines, "\n")

    return ids
end

--=========================================================
-- ITEM DEFINITION SCAN
--=========================================================

local function dumpItems()

    local results = {}
    local candidateIds = collectCandidateIds()

    local resolved = 0
    local failed = 0

    for _, id in ipairs(candidateIds) do

        local ok, cfg = pcall(function()
            return ItemConfig.tryGet(id)
        end)

        if ok and type(cfg) == "table" then

            resolved = resolved + 1

            table.insert(results, {

                ItemId = tostring(id),

                DisplayName = getDisplayName(cfg),

                StorageKey = getStorageKey(cfg),

                ItemType = getItemType(cfg)

            })

        else

            failed = failed + 1
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

    return results, #candidateIds, resolved, failed
end

--=========================================================
-- OUTPUT FORMAT
--=========================================================

local function formatDump(rows, candidateCount, resolved, failed)

    local lines = {}

    table.insert(lines, "========== BLOX FRUITS DIAGNOSTIC DUMP ==========")

    table.insert(lines, "")
    table.insert(lines, "Candidate IDs: " .. tostring(candidateCount))
    table.insert(lines, "Resolved items: " .. tostring(resolved))
    table.insert(lines, "Failed resolutions: " .. tostring(failed))
    table.insert(lines, "Total displayed items: " .. tostring(#rows))

    table.insert(lines, "")
    table.insert(lines, "========== DIAGNOSTIC INFORMATION ==========")
    table.insert(lines, scanDiagnostics)

    table.insert(lines, "")
    table.insert(lines, "========== ITEM RESULTS ==========")

    if #rows == 0 then

        table.insert(
            lines,
            "No item definitions were resolved."
        )

    else

        for _, item in ipairs(rows) do

            table.insert(lines, string.format(
                "ItemId: %s | Name: %s | Key: %s | Type: %s",

                item.ItemId,
                item.DisplayName,
                item.StorageKey,
                item.ItemType
            ))
        end
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

    title.Size = UDim2.new(1, -60, 0, 35)
    title.Position = UDim2.fromOffset(10, 5)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(240, 244, 248)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.Code
    title.TextSize = 17
    title.Text = "Blox Fruits - Item Catalogue Diagnostics"
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
    box.Text = "Press Refresh to inspect item definitions."
    box.Parent = scroll

    --=====================================================
    -- RELOAD
    --=====================================================

    local isScanning = false

    local function reload()

        if isScanning then
            return
        end

        isScanning = true
        refreshBtn.Text = "Scanning..."
        countLabel.Text = "Inspecting..."

        local ok, rows, candidateCount, resolved, failed =
            pcall(dumpItems)

        if not ok then

            box.Text = "SCAN ERROR:\n" .. tostring(rows)

            countLabel.Text = "Scan failed"
            refreshBtn.Text = "Refresh"
            isScanning = false

            return
        end

        currentFormatted = formatDump(
            rows,
            candidateCount,
            resolved,
            failed
        )

        box.Text = currentFormatted

        local lineCount = 1

        for _ in currentFormatted:gmatch("\n") do
            lineCount = lineCount + 1
        end

        local heightPx = math.max(lineCount * 16 + 20, 100)

        box.Size = UDim2.new(1, -12, 0, heightPx)

        scroll.CanvasSize = UDim2.fromOffset(
            0,
            heightPx
        )

        countLabel.Text = string.format(
            "Candidates: %d | Resolved: %d",
            candidateCount,
            resolved
        )

        refreshBtn.Text = "Refresh"
        isScanning = false
    end

    --=====================================================
    -- BUTTONS
    --=====================================================

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

    -- Initial scan
    reload()
end

--=========================================================
-- START
--=========================================================

buildGui()
