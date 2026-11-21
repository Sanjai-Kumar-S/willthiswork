local WEBHOOK_URL = "https://discord.com/api/webhooks/1573609152549224509/TgrDN2kKASX7-U6mNDfxTZPpzGMXgG5NpzBjH9lGeS3-MDjFmp2aOS6vgUOCKDSBb_WK"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

local requestFunc = (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request

-- Check all KEYS in ItemReplicationService (e.g., IS_OWNED, IS_TRADABLE, COUNT, etc.)
local function buildReplicationLookup()
    local lookup = {}
    for keyName, keyVal in pairs(KEYS) do
        local ok, items = pcall(function()
            return ItemReplicationService:GetItems(keyVal)
        end)
        if ok and type(items) == "table" then
            for _, entry in pairs(items) do
                if type(entry) == "table" and entry.ItemId ~= nil then
                    local idStr = tostring(entry.ItemId)
                    lookup[idStr] = lookup[idStr] or {}
                    lookup[idStr][tostring(keyName)] = entry.Value ~= nil and entry.Value or entry.Count
                end
            end
        end
    end
    return lookup
end

-- Recursively inspect ItemConfig entry for Category, Tradable flags, and internal tags
local function inspectConfig(cfg)
    local info = {
        Category = "nil",
        Tradable = "unknown",
        ExtraFlags = {}
    }
    if type(cfg) ~= "table" then return info end

    if type(cfg.Index) == "table" then
        info.Category = tostring(cfg.Index.Category or cfg.Index.Type or cfg.Index.Kind or "nil")
        if cfg.Index.Tradable ~= nil then
            info.Tradable = tostring(cfg.Index.Tradable)
        end
    end

    local function scanTable(tbl, prefix)
        for k, v in pairs(tbl) do
            local kStr = tostring(k)
            local kLow = kStr:lower()
            if type(v) ~= "table" then
                if kLow:find("trad") or kLow:find("gift") or kLow:find("store")
                    or kLow:find("equip") or kLow:find("categ") or kLow:find("type")
                    or kLow:find("kind") or kLow:find("max") then
                    table.insert(info.ExtraFlags, prefix .. kStr .. "=" .. tostring(v))
                end
                if kLow:find("trad") and type(v) == "boolean" then
                    info.Tradable = tostring(v)
                end
            elseif prefix == "" and kStr ~= "Display" then
                scanTable(v, kStr .. ".")
            end
        end
    end

    scanTable(cfg, "")
    return info
end

local function dumpAllRegistry()
    local repLookup = buildReplicationLookup()
    local rows = {}

    for id = 1, 2000 do
        local ok, cfg = pcall(function()
            return ItemConfig.tryGet(id)
        end)
        if ok and type(cfg) == "table" then
            local idStr = tostring(id)
            local dispName = (cfg.Display and cfg.Display.Name) or "nil"
            local storageKey = (cfg.Index and cfg.Index.StorageKey) or "nil"
            local meta = inspectConfig(cfg)

            local repTags = {}
            if repLookup[idStr] then
                for kName, val in pairs(repLookup[idStr]) do
                    table.insert(repTags, kName .. "=" .. tostring(val))
                end
                table.sort(repTags)
            end

            local flagStr = (#meta.ExtraFlags > 0) and table.concat(meta.ExtraFlags, ", ") or "none"
            local repStr = (#repTags > 0) and table.concat(repTags, ", ") or "UNOWNED"

            table.insert(rows, {
                Id = id,
                Line = string.format(
                    "[%s] Id=%d | Cat=%s | Tradable=%s | Display=%s | Key=%s | Flags=[%s]",
                    repStr,
                    id,
                    meta.Category,
                    meta.Tradable,
                    tostring(dispName),
                    tostring(storageKey),
                    flagStr
                )
            })
        end
    end

    return rows
end

local function sendTxtToDiscord(fileContent, totalCount)
    if not requestFunc then
        return false, "Executor missing HTTP request function"
    end
    if WEBHOOK_URL == "" or WEBHOOK_URL == "YOUR_DISCORD_WEBHOOK_URL" then
        return false, "Set WEBHOOK_URL first"
    end

    local boundary = "----RobloxDumperBoundary" .. tostring(math.random(100000, 999999))
    local fileName = string.format("bf_item_dump_%s_%d.txt", LocalPlayer.Name, os.time())

    local payloadJson = HttpService:JSONEncode({
        username = "BF Registry Dumper",
        content = string.format(
            "📦 **Blox Fruits ItemConfig Dump** (`%s`)\nTotal Entries: **%d**",
            LocalPlayer.Name,
            totalCount
        )
    })

    local bodyParts = {
        "--" .. boundary,
        'Content-Disposition: form-data; name="payload_json"',
        "Content-Type: application/json",
        "",
        payloadJson,
        "--" .. boundary,
        string.format('Content-Disposition: form-data; name="files[0]"; filename="%s"', fileName),
        "Content-Type: text/plain; charset=utf-8",
        "",
        fileContent,
        "--" .. boundary .. "--",
        ""
    }

    local body = table.concat(bodyParts, "\r\n")

    local ok, res = pcall(function()
        return requestFunc({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
            },
            Body = body
        })
    end)

    if not ok or not res then
        return false, "HTTP call failed"
    end
    if res.StatusCode >= 200 and res.StatusCode < 300 then
        return true, "Sent .txt (" .. tostring(res.StatusCode) .. ")"
    end
    return false, "HTTP " .. tostring(res.StatusCode) .. ": " .. tostring(res.Body):sub(1, 80)
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
    local existing = parentGui:FindFirstChild("TradableRegistryDumperGui")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TradableRegistryDumperGui"
    gui.ResetOnSpawn = false
    gui.Parent = parentGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(780, 430)
    frame.Position = UDim2.fromOffset(60, 60)
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
    title.Text = "Full ItemConfig + Tradable Dumper (Auto Discord .txt)"
    title.Parent = frame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.fromOffset(210, 28)
    searchBox.Position = UDim2.fromOffset(10, 42)
    searchBox.BackgroundColor3 = Color3.fromRGB(32, 36, 44)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.PlaceholderText = "Filter (Dark Blade, SKIN, Brat)..."
    searchBox.Font = Enum.Enum.Font.Code
    searchBox.TextSize = 12
    searchBox.Text = ""
    searchBox.Parent = frame

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.fromOffset(75, 28)
    refreshBtn.Position = UDim2.fromOffset(228, 42)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 64)
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.Font = Enum.Enum.Font.Code
    refreshBtn.TextSize = 12
    refreshBtn.Text = "Refresh"
    refreshBtn.Parent = frame

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.fromOffset(105, 28)
    copyBtn.Position = UDim2.fromOffset(310, 42)
    copyBtn.BackgroundColor3 = Color3.fromRGB(38, 110, 82)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Font = Enum.Enum.Font.Code
    copyBtn.TextSize = 12
    copyBtn.Text = "Copy Filtered"
    copyBtn.Parent = frame

    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.fromOffset(115, 28)
    discordBtn.Position = UDim2.fromOffset(422, 42)
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordBtn.Font = Enum.Enum.Font.Code
    discordBtn.TextSize = 12
    discordBtn.Text = "Send .txt"
    discordBtn.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -552, 0, 28)
    statusLabel.Position = UDim2.fromOffset(544, 42)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(170, 180, 195)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Font = Enum.Enum.Font.Code
    statusLabel.TextSize = 11
    statusLabel.Text = "Ready"
    statusLabel.Parent = frame

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

    local allRows = {}
    local fullDumpText = ""
    local currentFilteredText = ""

    local function applyFilter()
        local q = searchBox.Text:lower()
        local out = {}
        for _, r in ipairs(allRows) do
            if q == "" or r.Line:lower():find(q, 1, true) then
                table.insert(out, r.Line)
            end
        end
        currentFilteredText = table.concat(out, "\n")
        box.Text = currentFilteredText
        statusLabel.Text = tostring(#out) .. "/" .. tostring(#allRows)
        local heightPx = math.max(#out, 1) * 16 + 16
        box.Size = UDim2.new(1, -12, 0, heightPx)
        scroll.CanvasSize = UDim2.fromOffset(0, heightPx)
    end

    local function pushToDiscord(textToSend, count)
        statusLabel.Text = "Uploading .txt..."
        task.spawn(function()
            local ok, msg = sendTxtToDiscord(textToSend, count)
            statusLabel.Text = ok and ("✅ " .. msg) or ("❌ " .. msg)
        end)
    end

    local function reload(autoSend)
        allRows = dumpAllRegistry()
        local allLines = {}
        for _, r in ipairs(allRows) do
            table.insert(allLines, r.Line)
        end
        fullDumpText = table.concat(allLines, "\n")
        applyFilter()
        if autoSend then
            pushToDiscord(fullDumpText, #allRows)
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
    refreshBtn.MouseButton1Click:Connect(function()
        reload(false)
    end)
    discordBtn.MouseButton1Click:Connect(function()
        local linesCount = select(2, currentFilteredText:gsub("\n", "\n")) + 1
        pushToDiscord(currentFilteredText, linesCount)
    end)
    copyBtn.MouseButton1Click:Connect(function()
        if copyText(currentFilteredText) then
            copyBtn.Text = "Copied!"
            task.delay(1.2, function()
                if copyBtn then copyBtn.Text = "Copy Filtered" end
            end)
        else
            copyBtn.Text = "No Clipboard"
        end
    end)

    -- Runs immediately on execution and automatically sends the full .txt dump to Discord
    reload(true)
end

buildGui()
