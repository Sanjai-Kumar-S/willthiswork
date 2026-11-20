
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

local COMMAND_PREFIX = "!add "
local DUPLICATE_COOLDOWN = 0.6

-- =========================================================
-- 1. MASTER ITEM DICTIONARY
-- =========================================================

local MasterItemDictionary = {

    -- Dragon skins
    ["ember dragon"] = "ember <dragon (west)>",
    ["ember"] = "ember <dragon (west)>",

    -- Kitsune skins
    ["galaxy kitsune"] = "galaxy <empyrean (kitsune)>",
    ["galaxy empyrean"] = "galaxy <empyrean (kitsune)>",
    ["crimson kitsune"] = "crimson kitsune",
    ["empyrean"] = "empyrean",

    -- Portal skins
    ["divine portal"] = "divine <portal>",
    ["divine"] = "divine <portal>",

    -- Yeti / Mutation skins
    ["runic fiend"] = "runic fiend",
    ["fiend"] = "fiend",
    ["werewolf"] = "werewolf",

    -- Magnet / Gravity skins
    ["arcsteel magnet"] = "arcsteel magnet",
    ["arcsteel"] = "arcsteel magnet",
    ["starlight gravity"] = "starlight gravity",
    ["starlight"] = "starlight gravity",

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

    -- Sword / Weapon skins
    ["dog blade"] = "dog blade",
    ["lime blade"] = "lime blade",
    ["requiem eagle"] = "requiem eagle",
    ["glacier eagle"] = "glacier eagle",

    -- Frame breaks / Entities
    ["doghouse"] = "doghouse (frame break)",
    ["doghouse frame break"] = "doghouse (frame break)",
    ["vibes"] = "vibes (frame break)",
    ["vibes frame break"] = "vibes (frame break)",
    ["rabid"] = "rabid",
    ["scarlet ghost"] = "scarlet ghost",

    -- Gamepasses / Redeemables
    ["storage"] = "+1 Fruit Storage",
    ["+1 storage"] = "+1 Fruit Storage",
    ["fruit storage"] = "+1 Fruit Storage",
    ["dark blade"] = "Dark Blade",
    ["fruit notifier"] = "Fruit Notifier",
    ["fast boats"] = "Fast Boats",
    ["2x mastery"] = "2x Mastery",
    ["2x money"] = "2x Money",
    ["2x boss drops"] = "2x Boss Drops"
}

-- =========================================================
-- 2. FRUIT ALIASES
-- =========================================================

local FruitAliases = {
    leo = "leopard",
    trex = "t-rex",
    chop = "blade",
    lighting = "lightning",
    barrier = "creation",
    rumble = "lightning"
}

local function normalizeFruit(name)
    local clean = name:lower():match("^%s*(.-)%s*$")
    return FruitAliases[clean] or clean
end

-- =========================================================
-- 3. ITEM QUERY RESOLVER
-- =========================================================

local function resolveItemQuery(userInput)

    if type(userInput) ~= "string" then
        return nil, false
    end

    local query = userInput:lower():match("^%s*(.-)%s*$")

    query = query:gsub("^<(.-)>$", "%1")
    query = query:match("^%s*(.-)%s*$")

    if query == "" then
        return nil, false
    end

    -- Permanent fruit
    if query:sub(1, 5) == "perm " then

        local fruitName = normalizeFruit(query:sub(6))

        return "permanent " .. fruitName, false
    end

    -- Physical fruit preference
    if query:sub(1, 4) == "phy "
        or query:sub(1, 5) == "base " then

        local prefixLength =
            query:sub(1, 4) == "phy " and 5 or 6

        local fruitName = normalizeFruit(
            query:sub(prefixLength)
        )

        return fruitName, true
    end

    -- Dictionary lookup
    local mapped = MasterItemDictionary[query]

    if mapped then
        return mapped:lower(), false
    end

    -- Normal fruit lookup
    return normalizeFruit(query), false
end

-- =========================================================
-- 4. OWNERSHIP VALIDATION
-- =========================================================

local function isItemOwned(item)

    if type(item) ~= "table" or not item.ItemId then
        return false
    end

    if item.Value == true then
        return true
    end

    if type(item.Value) == "number" and item.Value > 0 then
        return true
    end

    if type(item.Count) == "number" and item.Count > 0 then
        return true
    end

    return false
end

-- =========================================================
-- 5. COLLECT ITEMS FROM BOTH INVENTORY BUCKETS
-- =========================================================

local function getAllOwnedItems()

    local combined = {}
    local seen = {}

    local buckets = {
        KEYS.IS_OWNED,
        KEYS.COUNT
    }

    for _, key in ipairs(buckets) do

        if key ~= nil then

            local ok, items = pcall(function()
                return ItemReplicationService:GetItems(key)
            end)

            if ok and type(items) == "table" then

                for _, item in pairs(items) do

                    if isItemOwned(item) then

                        local itemId = item.ItemId

                        if not seen[itemId] then

                            seen[itemId] = true
                            table.insert(combined, item)

                        end
                    end
                end
            end
        end
    end

    return combined
end

-- =========================================================
-- 6. ITEM METADATA
-- =========================================================

local function getItemMeta(itemId)

    local ok, cfg = pcall(function()
        return ItemConfig.tryGet(itemId)
    end)

    if not ok or type(cfg) ~= "table" then

        local fallback = tostring(itemId)

        return
            fallback:lower(),
            "",
            fallback:lower(),
            fallback,
            fallback:lower():find("permanent", 1, true) ~= nil,
            fallback:find("-", 1, true) ~= nil
    end

    local displayRaw =
        (cfg.Display and cfg.Display.Name)
        or tostring(itemId)

    local storageRaw =
        (cfg.Index and cfg.Index.StorageKey)
        or ""

    local displayLower = tostring(displayRaw):lower()
    local storageLower = tostring(storageRaw):lower()
    local idLower = tostring(itemId):lower()

    local isPermanent =
        displayLower:find("permanent", 1, true) ~= nil
        or storageLower:find("permanent", 1, true) ~= nil
        or idLower:find("permanent", 1, true) ~= nil

    -- Physical item ID heuristic
    local isPhysical =
        idLower:find("-", 1, true) ~= nil
        and not isPermanent

    return
        displayLower,
        storageLower,
        idLower,
        displayRaw,
        isPermanent,
        isPhysical
end

-- =========================================================
-- 7. ITEM SEARCH ENGINE
-- =========================================================

local function findItemId(targetName)

    local resolvedQuery, preferPhysical =
        resolveItemQuery(targetName)

    if not resolvedQuery or resolvedQuery == "" then
        return nil, nil, "invalid"
    end

    local queryLower = resolvedQuery:lower()

    local hyphenForm = queryLower .. "-" .. queryLower

    local isPermQuery =
        queryLower:sub(1, 10) == "permanent "

    local ownedItems = getAllOwnedItems()

    local partialMatches = {}

    -- Pass 1: Exact matching
    for _, item in ipairs(ownedItems) do

        local dispLower, storLower, idLower, dispRaw,
            itemIsPerm, isPhysical = getItemMeta(item.ItemId)

        -- Separate permanent and non-permanent items
        if itemIsPerm == isPermQuery then

            -- Physical-only filter
            if not preferPhysical or isPhysical then

                local exactMatch =
                    dispLower == queryLower
                    or storLower == queryLower
                    or storLower == hyphenForm
                    or idLower == queryLower

                if exactMatch then

                    return item.ItemId, dispRaw, "exact"

                end
            end
        end
    end

    -- Pass 2: Partial matching
    for _, item in ipairs(ownedItems) do

        local dispLower, storLower, idLower, dispRaw,
            itemIsPerm, isPhysical = getItemMeta(item.ItemId)

        if itemIsPerm == isPermQuery then

            if not preferPhysical or isPhysical then

                local partialMatch =
                    dispLower:find(queryLower, 1, true)
                    or storLower:find(queryLower, 1, true)
                    or idLower:find(queryLower, 1, true)

                if partialMatch then

                    partialMatches[item.ItemId] = {
                        name = dispRaw,
                        id = item.ItemId
                    }

                end
            end
        end
    end

    -- Return only an unambiguous partial match
    local matchCount = 0
    local selectedMatch = nil

    for _, match in pairs(partialMatches) do

        matchCount = matchCount + 1
        selectedMatch = match

    end

    if matchCount == 1 then

        return
            selectedMatch.id,
            selectedMatch.name,
            "partial"

    elseif matchCount > 1 then

        return nil, nil, "ambiguous"

    end

    return nil, nil, "not_found"
end

-- =========================================================
-- 8. CHAT COMMAND HANDLER
-- =========================================================

local lastText = ""
local lastTime = 0

local function handleChatCommand(rawText)

    if type(rawText) ~= "string" then
        return
    end

    local trimmedText =
        rawText:match("^%s*(.-)%s*$")

    local lowerText = trimmedText:lower()

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
        trimmedText:sub(#COMMAND_PREFIX + 1)

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

        local resolvedQuery =
            resolveItemQuery(targetInput)

        if matchType == "ambiguous" then

            warn(
                "[Trade] Multiple matching items found:",
                targetInput,
                "| Use a more specific name."
            )

        else

            warn(
                "[Trade] Item not found:",
                targetInput,
                "| Query:",
                tostring(resolvedQuery)
            )

        end
    end
end

-- =========================================================
-- 9. CHAT LISTENER
-- =========================================================

if TextChatService.ChatVersion ==
    Enum.ChatVersion.TextChatService then

    TextChatService.MessageReceived:Connect(
        function(textChatMessage)

            if textChatMessage.TextSource
                and textChatMessage.TextSource.UserId
                    == LocalPlayer.UserId then

                handleChatCommand(textChatMessage.Text)

            end
        end
    )

else

    LocalPlayer.Chatted:Connect(handleChatCommand)

end

print(
    "[Trade] Version 3 active.",
    "Use !add <item>, !add perm <fruit>,",
    "!add phy <fruit>, or !add base <fruit>."
)
