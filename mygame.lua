local WEBHOOK_URL = "https://discord.com/api/webhooks/1573609152549224509/TgrDN2kKASX7-U6mNDfxTZPpzGMXgG5NpzBjH9lGeS3-MDjFmp2aOS6vgUOCKDSBb_WK"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function getRequestFunc()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(http) == "table" and type(http.request) == "function" then return http.request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    return nil
end

-- Build GUI IMMEDIATELY so errors and progress are always visible
local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local existing = parentGui:FindFirstChild("TradableRegistryDumperGui")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TradableRegistryDumperGui"
gui.ResetOnSpawn = false
gui.Parent = parentGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(620, 360)
frame.Position = UDim2.fromOffset(40, 40)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 24)
title.Position = UDim2.fromOffset(10, 6)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(240, 244, 248)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Enum.Font.Code
title.TextSize = 14
title.Text = "Full ItemConfig + Tradable Dumper"
title.Parent = frame

local webhookStatus = Instance.new("TextLabel")
webhookStatus.Size = UDim2.new(1, -20, 0, 20)
webhookStatus.Position = UDim2.fromOffset(10, 30)
webhookStatus.BackgroundTransparency = 1
webhookStatus.TextColor3 = Color3.fromRGB(255, 210, 100)
webhookStatus.TextXAlignment = Enum.TextXAlignment.Left
webhookStatus.Font = Enum.Enum.Font.Code
webhookStatus.TextSize = 12
webhookStatus.Text = "Status: Searching ReplicatedStorage modules..."
webhookStatus.Parent = frame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.fromOffset(190, 28)
searchBox.Position = UDim2.fromOffset(10, 54)
searchBox.BackgroundColor3 = Color3.fromRGB(32, 36, 44)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderText = "Filter (Dark Blade, SKIN)..."
searchBox.Font = Enum.Enum.Font.Code
searchBox.TextSize = 12
searchBox.Text = ""
searchBox.Parent = frame

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.fromOffset(95, 28)
copyBtn.Position = UDim2.fromOffset(208, 54)
copyBtn.BackgroundColor3 = Color3.fromRGB(38, 110, 82)
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Enum.Font.Code
copyBtn.TextSize = 12
copyBtn.Text = "Copy"
copyBtn.Parent = frame

local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.fromOffset(95, 28)
discordBtn.Position = UDim2.fromOffset(310, 54)
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.Font = Enum.Enum.Font.Code
discordBtn.TextSize = 12
discordBtn.Text = "Send .txt"
discordBtn.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(60, 28)
closeBtn.Position = UDim2.new(1, -70, 0, 54)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Enum.Font.Code
closeBtn.TextSize = 12
closeBtn.Text = "Close"
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -98)
scroll.Position = UDim2.fromOffset(10, 90)
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
box.TextSize = 11
box.TextColor3 = Color3.fromRGB(215, 225, 235)
box.Text = "Loading..."
box.Parent = scroll

local function setStatus(msg, isErr)
    webhookStatus.TextColor3 = isErr and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 240, 150)
    webhookStatus.Text = "Status: " .. tostring(msg)
end

-- Run dump logic inside pcall so any error displays in the GUI instead of crashing
task.spawn(function()
    local okRun, errRun = pcall(function()
        -- Recursively find modules inside ReplicatedStorage (avoids infinite WaitForChild hang)
        local repMod = ReplicatedStorage:FindFirstChild("ItemReplicationService", true)
        local cfgMod = ReplicatedStorage:FindFirstChild("ItemConfig", true)

        if not repMod or not cfgMod then
            setStatus("Module missing! rep=" .. tostring(repMod) .. " cfg=" .. tostring(cfgMod), true)
            return
        end

        local keysMod = repMod:FindFirstChild("KEYS", true) or ReplicatedStorage:FindFirstChild("KEYS", true)
        local ItemReplicationService = require(repMod)
        local ItemConfig = require(cfgMod)
        local KEYS = keysMod and require(keysMod) or {}

        setStatus("Scanning items...", false)

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

        local function inspectConfig(cfg)
            local info = { Category = "nil", Tradable = "unknown", ExtraFlags = {} }
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

        local allRows = {}
        local allLines = {}

        for id = 1, 2000 do
            local ok, cfg = pcall(function() return ItemConfig.tryGet(id) end)
            if ok and type(cfg) == "table" then
                local idStr = tostring(id)
                local dispName = (cfg.Display and cfg.Display.Name) or "nil"
                local storageKey = (cfg.Index and cfg.Index.StorageKey) or "nil"
                local meta = inspectConfig(cfg)

                local repTags = {}
                if lookup[idStr] then
                    for kName, val in pairs(lookup[idStr]) do
                        table.insert(repTags, kName .. "=" .. tostring(val))
                    end
                    table.sort(repTags)
                end

                local flagStr = (#meta.ExtraFlags > 0) and table.concat(meta.ExtraFlags, ", ") or "none"
                local repStr = (#repTags > 0) and table.concat(repTags, ", ") or "UNOWNED"

                local line = string.format(
                    "[%s] Id=%d | Cat=%s | Tradable=%s | Display=%s | Key=%s | Flags=[%s]",
                    repStr, id, meta.Category, meta.Tradable, tostring(dispName), tostring(storageKey), flagStr
                )
                table.insert(allRows, line)
                table.insert(allLines, line)
            end
        end

        local fullDumpText = table.concat(allLines, "\n")
        local currentFilteredText = fullDumpText

        if type(writefile) == "function" then
            pcall(writefile, "bf_item_dump.txt", fullDumpText)
        end

        local function applyFilter()
            local q = searchBox.Text:lower()
            local out = {}
            for _, line in ipairs(allRows) do
                if q == "" or line:lower():find(q, 1, true) then
                    table.insert(out, line)
                end
            end
            currentFilteredText = table.concat(out, "\n")
            box.Text = currentFilteredText
            local heightPx = math.max(#out, 1) * 15 + 16
            box.Size = UDim2.new(1, -12, 0, heightPx)
            scroll.CanvasSize = UDim2.fromOffset(0, heightPx)
        end

        local function sendTxtToDiscord(textToSend, count)
            local req = getRequestFunc()
            if not req then
                setStatus("No HTTP request() in executor", true)
                return
            end
            setStatus("Uploading " .. tostring(count) .. " items to Discord...", false)
            local boundary = "------------------------" .. HttpService:GenerateGUID(false):gsub("%-", "")
            local fileName = string.format("bf_item_dump_%s_%d.txt", LocalPlayer.Name, os.time())
            local payloadJson = HttpService:JSONEncode({
                content = string.format("📦 **Blox Fruits ItemConfig Dump** (`%s`) — **%d** items", LocalPlayer.Name, count)
            })
            local body = table.concat({
                "--" .. boundary,
                'Content-Disposition: form-data; name="payload_json"',
                "Content-Type: application/json",
                "",
                payloadJson,
                "--" .. boundary,
                string.format('Content-Disposition: form-data; name="file"; filename="%s"', fileName),
                "Content-Type: text/plain",
                "",
                textToSend,
                "--" .. boundary .. "--",
                ""
            }, "\r\n")

            local ok, res = pcall(function()
                return req({
                    Url = WEBHOOK_URL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
                    Body = body
                })
            end)

            if not ok then
                setStatus("HTTP Error: " .. tostring(res):sub(1, 70), true)
            elseif type(res) ~= "table" then
                setStatus("Empty HTTP response", true)
            else
                local code = tonumber(res.StatusCode) or 0
                if code >= 200 and code < 300 then
                    setStatus("Sent .txt to Discord! (HTTP " .. tostring(code) .. ")", false)
                else
                    setStatus("Discord HTTP " .. tostring(code) .. ": " .. tostring(res.Body or ""):sub(1, 60), true)
                end
            end
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
        copyBtn.MouseButton1Click:Connect(function()
            local clip = setclipboard or toclipboard
            if clip then
                clip(currentFilteredText)
                copyBtn.Text = "Copied!"
                task.delay(1.2, function() if copyBtn then copyBtn.Text = "Copy" end end)
            end
        end)
        discordBtn.MouseButton1Click:Connect(function()
            local count = select(2, currentFilteredText:gsub("\n", "\n")) + 1
            sendTxtToDiscord(currentFilteredText, count)
        end)

        applyFilter()
        sendTxtToDiscord(fullDumpText, #allRows)
    end)

    if not okRun then
        setStatus("Script Error: " .. tostring(errRun), true)
    end
end)
