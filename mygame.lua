
-- =========================================================
-- BLOX FRUITS TRADE ADDER - VERSION 4
-- Verified ItemId-based resolver
-- =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer

local TradeFunction = ReplicatedStorage
    :WaitForChild("Remotes")
    :WaitForChild("TradeFunction")

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

local COMMAND_PREFIX = "!add "
local DUPLICATE_COOLDOWN = 1.0

-- Disconnect old listeners when re-executed
if _G.TradeAddConnections then
    for _, connection in ipairs(_G.TradeAddConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

_G.TradeAddConnections = {}

-- =========================================================
-- 2. VERIFIED PHYSICAL FRUIT IDS
-- =========================================================

local TradablePhysicalIds = {
    ["quake"] = 1389,
    ["rocket"] = 1390,
    ["magma"] = 1391,
    ["ice"] = 1392,
    ["buddha"] = 1393,
    ["flame"] = 1394,
    ["dark"] = 1395,
    ["rubber"] = 1396,
    ["bomb"] = 1397,
    ["spike"] = 1398,
    ["blade"] = 1399,
    ["chop"] = 1399,
    ["smoke"] = 1400,
    ["phoenix"] = 1401,
    ["spring"] = 1402,
    ["spider"] = 1403,
    ["sand"] = 1404,
    ["gravity"] = 1405,
    ["pain"] = 1406,
    ["light"] = 1407,
    ["love"] = 1408,
    ["control"] = 1409,
    ["venom"] = 1410,
    ["spin"] = 1411,
    ["ghost"] = 1412,
    ["shadow"] = 1413,
    ["portal"] = 1414,
    ["spirit"] = 1415,
    ["blizzard"] = 1416,
    ["dough"] = 1417,
    ["mammoth"] = 1418,
    ["sound"] = 1419,
    ["t-rex"] = 1420,
    ["trex"] = 1420,
    ["diamond"] = 1421,
    ["gas"] = 1422,
    ["kitsune"] = 1423,
    ["yeti"] = 1424,
    ["eagle"] = 1425,
    ["falcon"] = 1425,
    ["creation"] = 1426,
    ["barrier"] = 1426,
    ["lightning"] = 1427,
    ["rumble"] = 1427,
    ["lighting"] = 1427,
    ["celestial"] = 1428,
    ["oni"] = 1429,
    ["tiger"] = 1430,
    ["leopard"] = 1430,
    ["leo"] = 1430,
    ["meme"] = 1431,
    ["werewolf"] = 1432,
    ["empyrean"] = 1433,
    ["fiend"] = 1434,
    ["dragon west"] = 1435,
    ["dragon east"] = 1436,
    ["dragon"] = 1447,
    ["magnet"] = 1515,
    ["hellfire"] = 1601,
    ["hellfire gas"] = 1601
}

-- =========================================================
-- 3. VERIFIED PERMANENT FRUIT IDS
-- =========================================================

local TradablePermIds = {
    ["ghost"] = 341,
    ["love"] = 342,
    ["yeti"] = 343,
    ["bomb"] = 344,
    ["light"] = 345,
    ["sound"] = 346,
    ["flame"] = 347,
    ["venom"] = 348,
    ["magma"] = 349,
    ["blade"] = 350,
    ["chop"] = 350,
    ["diamond"] = 351,
    ["blizzard"] = 352,
    ["sand"] = 353,
    ["mammoth"] = 354,
    ["dragon east"] = 355,
    ["dragon west"] = 356,
    ["rocket"] = 357,
    ["control"] = 358,
    ["ice"] = 359,
    ["spin"] = 360,
    ["pain"] = 361,
    ["lightning"] = 362,
    ["rumble"] = 362,
    ["gas"] = 363,
    ["tiger"] = 364,
    ["leopard"] = 364,
    ["leo"] = 364,
    ["gravity"] = 365,
    ["quake"] = 366,
    ["shadow"] = 367,
    ["portal"] = 368,
    ["rubber"] = 369,
    ["phoenix"] = 370,
    ["dark"] = 371,
    ["buddha"] = 372,
    ["dough"] = 373,
    ["kitsune"] = 374,
    ["t-rex"] = 375,
    ["trex"] = 375,
    ["creation"] = 376,
    ["barrier"] = 376,
    ["eagle"] = 377,
    ["falcon"] = 377,
    ["spike"] = 378,
    ["smoke"] = 379,
    ["spider"] = 380,
    ["spring"] = 381,
    ["dragon"] = 382,
    ["spirit"] = 383,
    ["celestial"] = 605,
    ["oni"] = 606,
    ["magnet"] = 1517
}

-- =========================================================
-- 4. MASTER ITEM DICTIONARY
-- =========================================================

local MasterItemDictionary = {

    -- Dragon / Kitsune
    ["ember dragon"] = "ember dragon (west)",
    ["ember"] = "ember dragon (west)",

    ["galaxy kitsune"] = "galaxy empyrean kitsune",
    ["galaxy empyrean"] = "galaxy empyrean kitsune",
    ["galaxy"] = "galaxy empyrean kitsune",

    ["crimson kitsune"] = "kyukonskincrimson",
    ["crimson"] = "kyukonskincrimson",

    -- Portal
    ["divine portal"] = "divine portal",
    ["divine"] = "divine portal",
    ["pink portal"] = "pink portal",
    ["orange portal"] = "orange portal",

    -- Other skins
    ["runic fiend"] = "runic fiend",
    ["starlight gravity"] = "starlight gravity",
    ["starlight"] = "starlight gravity",
    ["arcsteel magnet"] = "arcsteel magnet",
    ["arcsteel"] = "arcsteel magnet",
    ["scarlet ghost"] = "scarlet ghost",

    -- Lightning skins
    ["purple lightning"] = "purple lightning",
    ["yellow lightning"] = "yellow lightning",
    ["red lightning"] = "red lightning",
    ["green lightning"] = "green lightning",

    -- Bomb skins
    ["nuclear bomb"] = "nuclear bomb",
    ["thermite bomb"] = "thermite bomb",
    ["azura bomb"] = "azura bomb",
    ["celebration bomb"] = "celebration bomb",

    -- Diamond skins
    ["emerald diamond"] = "emerald diamond",
    ["ruby diamond"] = "ruby diamond",
    ["topaz diamond"] = "topaz diamond",
    ["rose quartz diamond"] = "rose quartz diamond",
    ["rose quartz"] = "rose quartz diamond",

    -- Pain skins
    ["super spirit pain"] = "super spirit pain",
    ["super spirit"] = "super spirit pain",
    ["celestial pain"] = "celestial pain",
    ["torment pain"] = "torment pain",
    ["sadness pain"] = "sadness pain",
    ["frustration pain"] = "frustration pain",

    -- Eagle / Blade skins
    ["requiem eagle"] = "requiem eagle",
    ["glacier eagle"] = "glacier eagle",
    ["matrix eagle"] = "matrix eagle",
    ["parrot eagle"] = "falcskinparrot",
    ["dog blade"] = "dog blade",
    ["lime blade"] = "lime blade",
    ["rabid"] = "rabid",

    -- Frame breaks
    ["doghouse"] = "doghouse (frame break)",
    ["doghouse frame break"] = "doghouse (frame break)",
    ["vibes"] = "vibes (frame break)",
    ["vibes frame break"] = "vibes (frame break)",

    -- Gamepasses / Redeemables
    ["storage"] = "+1 fruit storage",
    ["+1 storage"] = "+1 fruit storage",
    ["fruit storage"] = "+1 fruit storage",
    ["dark blade"] = "dark blade",
    ["fruit notifier"] = "fruit notifier",
    ["fast boats"] = "fast boats",
    ["2x mastery"] = "2x mastery",
    ["2x money"] = "2x money",
    ["2x boss drops"] = "2x boss drops",
    ["legendary scroll"] = "legendary scroll",
    ["mythical scroll"] = "mythical scroll"
}

-- =========================================================
-- 5. FRUIT ALIASES
-- =========================================================

local FruitAliases = {
    ["leo"] = "leopard",
    ["trex"] = "t-rex",
    ["chop"] = "blade",
    ["lighting"] = "lightning",
    ["barrier"] = "creation",
    ["rumble"] = "lightning"
}

local function normalizeFruit(name)
    return FruitAliases[name] or name
end

-- =========================================================
-- 6. COLLECT OWNED ITEM IDS
-- =========================================================

local function buildOwnedIdSet()

    local owned = {}

    local buckets = {
        KEYS.IS_OWNED,
        KEYS.COUNT
    }

    for _, keyType in ipairs(buckets) do

        if keyType ~= nil then

            local ok, items = pcall(function()
                return ItemReplicationService:GetItems(keyType)
            end)

            if ok and type(items) == "table" then

                for _, item in pairs(items) do

                    if type(item) == "table" and item.ItemId then

                        local hasValue =
                            item.Value == true
                            or (
                                type(item.Value) == "number"
                                and item.Value > 0
                            )
                            or (
                                type(item.Count) == "number"
                                and item.Count > 0
                            )

                        if hasValue then
                            owned[item.ItemId] = true
                        end

                    end
                end
            end
        end
    end

    return owned
end

-- =========================================================
-- 7. ITEM METADATA
-- =========================================================

local function getItemMetadata(itemId)

    local ok, cfg = pcall(function()
        return ItemConfig.tryGet(itemId)
    end)

    if not ok or type(cfg) ~= "table" then
        return "", "", tostring(itemId):lower(), tostring(itemId)
    end

    local display =
        (cfg.Display and cfg.Display.Name)
        or ""

    local storage =
        (cfg.Index and cfg.Index.StorageKey)
        or ""

    return
        tostring(display):lower(),
        tostring(storage):lower(),
        tostring(itemId):lower(),
        display ~= "" and display or storage
end

-- =========================================================
-- 8. RESOLVE ITEM
-- =========================================================

local function findItemId(rawInput)

    if type(rawInput) ~= "string" then
        return nil, nil, "invalid"
    end

    local query = rawInput:lower():match("^%s*(.-)%s*$")

    query = query:gsub("^<(.-)>$", "%1")
    query = query:match("^%s*(.-)%s*$")

    if query == "" then
        return nil, nil, "invalid"
    end

    local ownedSet = buildOwnedIdSet()

    -- -----------------------------------------------------
    -- A. Permanent fruit
    -- -----------------------------------------------------

    local permFruit = query:match("^perm%s+(.+)$")
        or query:match("^permanent%s+(.+)$")

    if permFruit then

        permFruit = normalizeFruit(
            permFruit:match("^%s*(.-)%s*$")
        )

        local permId = TradablePermIds[permFruit]

        if permId and ownedSet[permId] then

            local _, _, _, label = getItemMetadata(permId)

            return permId, label, "permanent"

        end

        return nil, nil, "not_found"
    end

    -- -----------------------------------------------------
    -- B. Physical fruit
    -- -----------------------------------------------------

    local physicalFruit = query:match("^phy%s+(.+)$")
        or query:match("^base%s+(.+)$")

    local isPhysicalCommand = physicalFruit ~= nil

    if isPhysicalCommand then

        query = normalizeFruit(
            physicalFruit:match("^%s*(.-)%s*$")
        )

    else
        query = normalizeFruit(query)
    end

    local physId = TradablePhysicalIds[query]

    if physId then

        if ownedSet[physId] then

            local _, _, _, label = getItemMetadata(physId)

            return physId, label, "physical"

        end

        -- Check alternate registered physical fruit IDs.
        -- This preserves Script 1's fallback behavior.

        for id in pairs(ownedSet) do

            if type(id) == "number"
                and (id >= 1389 or id == 254) then

                local display, _, _, label =
                    getItemMetadata(id)

                if display == query then
                    return id, label, "physical"
                end

            end
        end

        return nil, nil, "not_found"
    end

    if isPhysicalCommand then
        return nil, nil, "not_found"
    end

    -- -----------------------------------------------------
    -- C. Skins / Mutations / Gamepasses / Special items
    -- -----------------------------------------------------

    local targetTerm =
        MasterItemDictionary[query] or query

    targetTerm = targetTerm:lower()

    local exactMatches = {}
    local partialMatches = {}

    for id in pairs(ownedSet) do

        local display, storage, idString, label =
            getItemMetadata(id)

        local isExact =
            display == targetTerm
            or storage == targetTerm
            or idString == targetTerm

        if isExact then

            exactMatches[id] = label

        elseif
            (display ~= "" and display:find(targetTerm, 1, true))
            or (storage ~= "" and storage:find(targetTerm, 1, true))
        then

            partialMatches[id] = label

        end
    end

    -- Exact matching has priority.

    local exactCount = 0
    local exactId
    local exactLabel

    for id, label in pairs(exactMatches) do
        exactCount = exactCount + 1
        exactId = id
        exactLabel = label
    end

    if exactCount == 1 then
        return exactId, exactLabel, "exact"
    elseif exactCount > 1 then
        return nil, nil, "ambiguous"
    end

    -- Partial matching is accepted only if unique.

    local partialCount = 0
    local partialId
    local partialLabel

    for id, label in pairs(partialMatches) do
        partialCount = partialCount + 1
        partialId = id
        partialLabel = label
    end

    if partialCount == 1 then
        return partialId, partialLabel, "partial"
    elseif partialCount > 1 then
        return nil, nil, "ambiguous"
    end

    return nil, nil, "not_found"
end

-- =========================================================
-- 9. CHAT COMMAND HANDLER
-- =========================================================

local lastText = ""
local lastTime = 0

local function handleChatCommand(rawText)

    if type(rawText) ~= "string" then
        return
    end

    local cleanText =
        rawText:match("^%s*(.-)%s*$")

    local lowerText = cleanText:lower()

    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then
        return
    end

    -- Duplicate command protection

    local now = os.clock()

    if lowerText == lastText
        and (now - lastTime) < DUPLICATE_COOLDOWN then
        return
    end

    lastText = lowerText
    lastTime = now

    local targetInput =
        cleanText:sub(#COMMAND_PREFIX + 1)

    local itemId, resolvedName, matchType =
        findItemId(targetInput)

    if itemId then

        local ok, err = pcall(function()

            TradeFunction:InvokeServer(
                "addItem",
                itemId,
                1
            )

        end)

        if ok then

            print(
                "[Trade] Added:",
                resolvedName,
                "| ItemId:",
                itemId,
                "| Match:",
                matchType
            )

        else

            warn(
                "[Trade] InvokeServer failed:",
                err
            )

        end

    else

        if matchType == "ambiguous" then

            warn(
                "[Trade] Multiple matching items found:",
                targetInput,
                "| Use a more specific name."
            )

        else

            warn(
                "[Trade] Item not found or not owned:",
                targetInput
            )

        end

    end
end

-- =========================================================
-- 10. CHAT LISTENER
-- =========================================================

if TextChatService
    and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then

    table.insert(
        _G.TradeAddConnections,

        TextChatService.MessageReceived:Connect(function(msg)

            if msg.TextSource
                and msg.TextSource.UserId == LocalPlayer.UserId then

                handleChatCommand(msg.Text)

            end

        end)
    )

else

    table.insert(
        _G.TradeAddConnections,
        LocalPlayer.Chatted:Connect(handleChatCommand)
    )

end

-- =========================================================
-- 11. READY
-- =========================================================

print("========================================")
print("[Trade] Version 4 loaded!")
print("[Trade] Verified ItemId resolver active.")
print("[Trade] Physical / Permanent / Special items")
print("[Trade] Commands: !add <item>")
print("[Trade] Commands: !add perm <fruit>")
print("[Trade] Commands: !add phy <fruit>")
print("[Trade] Commands: !add base <fruit>")
print("========================================")
