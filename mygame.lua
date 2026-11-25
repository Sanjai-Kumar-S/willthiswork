
-- =========================================================
-- BLOX FRUITS TRADE ADDER - VERSION 5
-- Multi-ID + StorageKey Fallback Resolver
-- Uses Version 4 Remote and Inventory Modules
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

local isAdding = false
local lastText = ""
local lastTime = 0

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
-- 2. COMPLETE ITEM REGISTRY
-- Format: { numeric IDs in priority order, string keys }
-- =========================================================

local ItemList = {

    -- =====================================================
    -- PHYSICAL FRUITS
    -- =====================================================

    ["rocket"]              = {1390, 4, "Rocket-Rocket"},
    ["spin"]                = {1411, 128, "Spin-Spin"},
    ["blade"]               = {1399, 31, "Blade-Blade"},
    ["chop"]                = {1399, 31, "Blade-Blade"},
    ["spring"]              = {1402, 46, "Spring-Spring"},
    ["bomb"]                = {1397, 25, "Bomb-Bomb"},
    ["smoke"]               = {1400, 32, "Smoke-Smoke"},
    ["spike"]               = {1398, 26, "Spike-Spike"},

    ["flame"]               = {1394, 18, "Flame-Flame"},
    ["ice"]                 = {1392, 13, "Ice-Ice"},
    ["sand"]                = {1404, 53, "Sand-Sand"},
    ["dark"]                = {1395, 20, "Dark-Dark"},
    ["eagle"]               = {1425, 400, "Eagle-Eagle"},
    ["falcon"]              = {1425, 133, "Eagle-Eagle"},
    ["diamond"]             = {1421, 208, "Diamond-Diamond"},

    ["light"]               = {1407, 80, "Light-Light"},
    ["rubber"]              = {1396, 24, "Rubber-Rubber"},
    ["ghost"]               = {1412, 158, "Ghost-Ghost"},
    ["revive"]              = {1412, 158, "Ghost-Ghost"},
    ["magma"]               = {1391, 8, "Magma-Magma"},

    ["quake"]               = {1389, 3, "Quake-Quake"},
    ["buddha"]              = {1393, 14, "Buddha-Buddha"},
    ["love"]                = {1408, 86, 132, "Love-Love"},
    ["creation"]            = {1426, 402, "Creation-Creation"},
    ["barrier"]             = {1426, 58, "Creation-Creation"},
    ["spider"]              = {1403, 48, "Spider-Spider"},
    ["sound"]               = {1419, 193, "Sound-Sound"},
    ["phoenix"]             = {1401, 43, "Phoenix-Phoenix"},
    ["portal"]              = {1414, 170, "Portal-Portal"},
    ["door"]                = {1414, 129, "Portal-Portal"},
    ["lightning"]           = {1427, 448, "Lightning-Lightning"},
    ["rumble"]              = {1427, 50, "Lightning-Lightning"},
    ["pain"]                = {1406, 57, "Pain-Pain"},
    ["paw"]                 = {1406, 57, "Pain-Pain"},
    ["blizzard"]            = {1416, 184, "Blizzard-Blizzard"},

    ["gravity"]             = {1405, 54, "Gravity-Gravity"},
    ["mammoth"]              = {1418, 191, "Mammoth-Mammoth"},
    ["trex"]                 = {1420, 204, "T-Rex-T-Rex"},
    ["t-rex"]                = {1420, 204, "T-Rex-T-Rex"},
    ["dough"]                = {1417, 188, "Dough-Dough"},
    ["shadow"]               = {1413, 163, "Shadow-Shadow"},
    ["venom"]                = {1410, 127, "Venom-Venom"},
    ["gas"]                  = {1422, 220, "Gas-Gas"},
    ["spirit"]               = {1415, 181, "Spirit-Spirit"},
    ["soul"]                 = {1415, 185, "Spirit-Spirit"},
    ["tiger"]                = {1430, 833, "Tiger-Tiger"},
    ["leopard"]              = {1430, 64, "Tiger-Tiger"},
    ["yeti"]                 = {1424, 229, "Yeti-Yeti"},
    ["magnet"]               = {1515, 1516, "Magnet-Magnet"},
    ["kitsune"]              = {1423, 221, "Kitsune-Kitsune"},
    ["control"]              = {1409, 95, "Control-Control"},
    ["dragon west"]          = {1435, 884, "Dragon (West)-Dragon (West)"},
    ["west dragon"]          = {1435, 884, "Dragon (West)-Dragon (West)"},
    ["dragon east"]          = {1436, 885, "Dragon (East)-Dragon (East)"},
    ["east dragon"]          = {1436, 885, "Dragon (East)-Dragon (East)"},
    ["dragon"]               = {1447, 222, 254, "Dragon-Dragon"},

    -- =====================================================
    -- PERMANENT FRUITS
    -- =====================================================

    ["perm rocket"]          = {357, "Permanent Rocket-Rocket"},
    ["perm spin"]            = {360, "Permanent Spin-Spin"},
    ["perm blade"]           = {350, "Permanent Blade-Blade"},
    ["perm spring"]          = {381, "Permanent Spring-Spring"},
    ["perm bomb"]            = {344, "Permanent Bomb-Bomb"},
    ["perm smoke"]           = {379, "Permanent Smoke-Smoke"},
    ["perm spike"]           = {378, "Permanent Spike-Spike"},
    ["perm flame"]           = {347, "Permanent Flame-Flame"},
    ["perm ice"]             = {359, "Permanent Ice-Ice"},
    ["perm sand"]            = {353, "Permanent Sand-Sand"},
    ["perm dark"]            = {371, "Permanent Dark-Dark"},
    ["perm eagle"]           = {401, "Permanent Eagle-Eagle"},
    ["perm diamond"]         = {351, "Permanent Diamond-Diamond"},
    ["perm light"]           = {345, "Permanent Light-Light"},
    ["perm rubber"]          = {369, "Permanent Rubber-Rubber"},
    ["perm ghost"]           = {341, "Permanent Ghost-Ghost"},
    ["perm magma"]           = {349, "Permanent Magma-Magma"},
    ["perm quake"]           = {366, "Permanent Quake-Quake"},
    ["perm buddha"]          = {372, "Permanent Buddha-Buddha"},
    ["perm love"]            = {342, "Permanent Love-Love"},
    ["perm creation"]        = {403, "Permanent Creation-Creation"},
    ["perm spider"]          = {380, "Permanent Spider-Spider"},
    ["perm sound"]           = {346, "Permanent Sound-Sound"},
    ["perm phoenix"]         = {370, "Permanent Phoenix-Phoenix"},
    ["perm portal"]          = {368, "Permanent Portal-Portal"},
    ["perm lightning"]       = {449, "Permanent Lightning-Lightning"},
    ["perm pain"]            = {361, "Permanent Pain-Pain"},
    ["perm blizzard"]        = {352, "Permanent Blizzard-Blizzard"},
    ["perm gravity"]         = {365, "Permanent Gravity-Gravity"},
    ["perm mammoth"]         = {354, "Permanent Mammoth-Mammoth"},
    ["perm trex"]            = {375, "Permanent T-Rex-T-Rex"},
    ["perm dough"]           = {373, "Permanent Dough-Dough"},
    ["perm shadow"]          = {367, "Permanent Shadow-Shadow"},
    ["perm venom"]           = {348, "Permanent Venom-Venom"},
    ["perm gas"]             = {363, "Permanent Gas-Gas"},
    ["perm spirit"]          = {383, "Permanent Spirit-Spirit"},
    ["perm tiger"]           = {834, "Permanent Tiger-Tiger"},
    ["perm yeti"]             = {343, "Permanent Yeti-Yeti"},
    ["perm magnet"]          = {1517, "Permanent Magnet-Magnet"},
    ["perm kitsune"]         = {374, "Permanent Kitsune-Kitsune"},
    ["perm control"]         = {358, "Permanent Control-Control"},
    ["perm dragon"]          = {399, 355, 356, "Permanent Dragon-Dragon"},
    ["perm dragon token"]    = {844, "Permanent Dragon Token"},

    -- =====================================================
    -- GAMEPASSES & ITEMS
    -- =====================================================

    ["fruit notifier"]       = {233, "Fruit Notifier"},
    ["dark blade"]           = {190, 255, 1250, "Dark Blade"},
    ["2x mastery"]           = {234, "2x Mastery"},
    ["2x money"]             = {242, "2x Money"},
    ["2x boss drops"]        = {244, "2x Boss Drops"},
    ["fast boats"]           = {245, "Fast Boats"},
    ["fruit storage"]        = {235, "+1 Fruit Storage"},
    ["dragon token"]         = {240, 844, "Dragon Token (Tradable)"},

    -- =====================================================
    -- LIMITED SKINS & MUTATIONS
    -- =====================================================

    ["ember"]                = {305, 298, 264, "EmberChromaticDragon", "WSTDSKINember", "ESTDSKINember"},
    ["eclipse"]              = {303, 271, 281, "EclipseChromaticDragon", "WSTDSKINeclipse", "ESTDSKINeclipse"},
    ["blood moon"]           = {306, 286, 273, "BloodmoonChromaticDragon", "WSTDSKINbloodmoon", "ESTDSKINbloodmoon"},
    ["phoenix sky"]          = {302, 268, 274, "PhoenixSkyChromaticDragon", "WSTDSKINphoenixsky", "ESTDSKINphoenixsky"},
    ["violet night"]         = {304, 258, 299, "VioletNightChromaticDragon", "WSTDSKINvioletnight", "ESTDSKINvioletnight"},
    ["crimson"]              = {1045, "KYUKONSKINcrimson"},
    ["galaxy"]               = {1046, 1042, "KYUKONSKINgalaxy"},
    ["empyrean kitsune"]     = {1433, 1041, "Empyrean (Kitsune)-Empyrean (Kitsune)"},
    ["sadness"]              = {479, "Sadness Pain"},
    ["torment"]              = {491, "Torment Pain"},
    ["frustration"]          = {492, "Frustration Pain"},
    ["celestial"]            = {500, 498, "PAINSKINcelestial"},
    ["super spirit"]         = {538, 541, "PAINSKINsuperspirit"},
    ["divine"]               = {1049, 1048, "PORTALSKINdivine"},
    ["emerald"]              = {456, 471, "DIAMONDSKINgreen"},
    ["rose quartz"]          = {472, 470, "DIAMONDSKINpoudretteite"},
    ["topaz"]                = {473, 469, "DIAMONDSKINtopaz"},
    ["ruby"]                 = {455, 468, "DIAMONDSKINred"},
    ["glacier"]              = {499, 496, "FALCSKINglacier"},
    ["requiem"]              = {501, 495, "FALCSKINrequiem"},
    ["matrix"]               = {497, 502, "FALCSKINmatrix"},
    ["parrot"]               = {404, "FALCSKINparrot"},
    ["nuclear"]               = {506, 508, "BOMBSKINnuclear"},
    ["thermite"]             = {528, 511, "BOMBSKINthermite"},
    ["azura"]                = {529, 512, "BOMBSKINazura"},
    ["celebration"]          = {536, 539, "BOMBSKINcelebration"},
    ["arcsteel"]             = {1538, 1525, "MAGNETSKINarksteel"},
    ["runic"]                = {1532, 1522, "FIENDSKINsealed"},
    ["fiend"]                = {1063, 1434, "YETISKINfiend", "Fiend (Yeti)-Fiend (Yeti)"},
    ["starlight"]            = {1534, 1523, "GRAVITYSKINheavenly"},
    ["lime"]                 = {1540, 1526, "BLADESKINlime"},
    ["werewolf"]             = {818, 1432, "TIGERSKINwerewolf", "Werewolf (Tiger)-Werewolf (Tiger)"},
    ["hellfire"]             = {1604, 1601, "HELLFIRESKINdefault", "Hellfire (Gas)-Hellfire (Gas)"},

    -- =====================================================
    -- LIMITED BANNERS & SWORD SKINS
    -- =====================================================

    ["dog blade"]            = {1482, 1483, "The Sword Of The Brat"},
    ["sword of the brat"]    = {1482, "The Sword Of The Brat"},
    ["rabid skin"]           = {1487, 1484, "BRATSKINslayer"},
    ["dog house"]            = {1485, "DogHouseGacha26"},
    ["vibe"]                 = {1479, "Heartbreak"},
}

-- =========================================================
-- 3. ITEM ALIASES
-- =========================================================

local Aliases = {
    ["leo"] = "leopard",
    ["t rex"] = "trex",
    ["lighting"] = "lightning",
    ["perm chop"] = "perm blade",
    ["perm falcon"] = "perm eagle",
    ["perm revive"] = "perm ghost",
    ["perm barrier"] = "perm creation",
    ["perm door"] = "perm portal",
    ["perm rumble"] = "perm lightning",
    ["perm paw"] = "perm pain",
    ["perm soul"] = "perm spirit",
    ["perm leopard"] = "perm tiger",
    ["perm falcon"] = "perm eagle",
}

local function normalizeName(name)
    name = tostring(name or ""):lower()
    name = name:match("^%s*(.-)%s*$") or ""
    name = name:gsub("^<(.-)>$", "%1")
    name = name:match("^%s*(.-)%s*$") or ""

    return Aliases[name] or name
end

-- =========================================================
-- 4. GET OWNED INVENTORY
-- =========================================================

local function getItemMetadata(itemId)
    local ok, cfg = pcall(function()
        return ItemConfig.tryGet(itemId)
    end)

    if not ok or type(cfg) ~= "table" then
        return "", ""
    end

    local display = ""
    local storage = ""

    if cfg.Display and cfg.Display.Name then
        display = tostring(cfg.Display.Name):lower()
    end

    if cfg.Index and cfg.Index.StorageKey then
        storage = tostring(cfg.Index.StorageKey):lower()
    end

    return display, storage
end

local function buildOwnedInventory()
    local ownedIds = {}
    local ownedStorageKeys = {}

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
                            local itemId = item.ItemId
                            ownedIds[itemId] = true

                            local _, storage = getItemMetadata(itemId)

                            if storage ~= "" then
                                ownedStorageKeys[storage] = true
                            end
                        end
                    end
                end
            end
        end
    end

    return ownedIds, ownedStorageKeys
end

-- =========================================================
-- 5. RESOLVE REGISTRY ENTRY
-- =========================================================

local function getRegistryEntry(rawInput)
    local query = normalizeName(rawInput)

    if query == "" then
        return nil, nil, "invalid"
    end

    -- Support: !add phy rocket
    -- Support: !add base rocket
    local physicalName = query:match("^phy%s+(.+)$")
        or query:match("^base%s+(.+)$")

    if physicalName then
        query = normalizeName(physicalName)
    end

    local entry = ItemList[query]

    if not entry then
        return nil, nil, "not_found"
    end

    return entry, query, "found"
end

-- =========================================================
-- 6. TRY ADDING ITEM
-- =========================================================

local function tryAddIdentifier(identifier)
    local callOk, result = pcall(function()
        return TradeFunction:InvokeServer(
            "addItem",
            identifier,
            1
        )
    end)

    if not callOk then
        warn(
            "[Trade] Remote call error. Stopping to avoid duplicate:",
            result
        )

        return "error"
    end

    -- An explicit false means the server rejected this identifier.
    if result == false then
        return "rejected"
    end

    -- This assumes the remote uses false for rejection and any other
    -- return value (including nil) for an accepted request.
    return "success"
end

local function addItem(rawInput)
    if isAdding then
        warn("[Trade] Another add request is already running.")
        return
    end

    local entry, itemName, status = getRegistryEntry(rawInput)

    if not entry then
        warn("[Trade] Item not found in registry:", rawInput)
        return
    end

    isAdding = true

    local ownedIds, ownedStorageKeys = buildOwnedInventory()

    local numericCandidates = {}
    local stringCandidates = {}

    -- Keep the registry's original order.
    for _, value in ipairs(entry) do
        if type(value) == "number" then
            table.insert(numericCandidates, value)
        elseif type(value) == "string" then
            table.insert(stringCandidates, value)
        end
    end

    local attempted = {}
    local added = false
    local uncertain = false

    -- -----------------------------------------------------
    -- A. Try owned numeric IDs, in registry order
    -- -----------------------------------------------------

    for _, itemId in ipairs(numericCandidates) do
        if ownedIds[itemId] and not attempted[itemId] then
            attempted[itemId] = true

            print("[Trade] Trying numeric ID:", itemId, itemName)

            local result = tryAddIdentifier(itemId)

            if result == "success" then
                print(
                    "[Trade] Successfully added:",
                    itemName,
                    "| Identifier:",
                    itemId
                )

                added = true
                break

            elseif result == "error" then
                uncertain = true
                break
            end

            print("[Trade] ID rejected; trying next candidate:", itemId)
        end
    end

    -- -----------------------------------------------------
    -- B. If numeric IDs failed, try owned string keys
    -- -----------------------------------------------------

    if not added and not uncertain then
        for _, storageKey in ipairs(stringCandidates) do
            local normalizedKey = storageKey:lower()

            if ownedStorageKeys[normalizedKey]
                and not attempted[storageKey] then

                attempted[storageKey] = true

                print(
                    "[Trade] Trying StorageKey:",
                    storageKey,
                    itemName
                )

                local result = tryAddIdentifier(storageKey)

                if result == "success" then
                    print(
                        "[Trade] Successfully added:",
                        itemName,
                        "| StorageKey:",
                        storageKey
                    )

                    added = true
                    break

                elseif result == "error" then
                    uncertain = true
                    break
                end

                print(
                    "[Trade] StorageKey rejected:",
                    storageKey
                )
            end
        end
    end

    -- -----------------------------------------------------
    -- C. Final result
    -- -----------------------------------------------------

    if added then
        print("[Trade] Finished:", itemName)

    elseif uncertain then
        warn(
            "[Trade] Result uncertain for:",
            itemName,
            "| Stopped to prevent a possible duplicate."
        )

    else
        warn(
            "[Trade] No matching owned ID or StorageKey found:",
            itemName
        )
    end

    isAdding = false
end

-- =========================================================
-- 7. CHAT COMMAND HANDLER
-- =========================================================

local function handleChatCommand(rawText)
    if type(rawText) ~= "string" then
        return
    end

    local cleanText = rawText:match("^%s*(.-)%s*$")
    local lowerText = cleanText:lower()

    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then
        return
    end

    -- Duplicate message protection
    local now = os.clock()

    if lowerText == lastText
        and (now - lastTime) < DUPLICATE_COOLDOWN then
        return
    end

    lastText = lowerText
    lastTime = now

    local targetInput = cleanText:sub(#COMMAND_PREFIX + 1)
    targetInput = targetInput:match("^%s*(.-)%s*$")

    if targetInput == "" then
        warn("[Trade] Usage: !add <item name>")
        return
    end

    addItem(targetInput)
end

-- =========================================================
-- 8. CHAT LISTENERS
-- =========================================================

if TextChatService
    and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then

    table.insert(
        _G.TradeAddConnections,

        TextChatService.MessageReceived:Connect(function(message)
            if message.TextSource
                and message.TextSource.UserId == LocalPlayer.UserId then

                handleChatCommand(message.Text)
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
-- 9. READY
-- =========================================================

print("========================================")
print("[Trade] Version 5 loaded!")
print("[Trade] Multi-ID resolver active.")
print("[Trade] StorageKey fallback active.")
print("[Trade] Physical / Permanent / Gamepasses")
print("[Trade] Limited skins / Mutations / Items")
print("[Trade] Command: !add <item>")
print("[Trade] Example: !add dragon")
print("[Trade] Example: !add perm dragon")
print("[Trade] Example: !add phy rocket")
print("========================================")
