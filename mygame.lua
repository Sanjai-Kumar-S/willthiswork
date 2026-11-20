-- lang: Luau, file: resolver.lua, target: Roblox / Blox Fruits Automation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local TradeFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TradeFunction")

local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Clean up old connections on re-execute
if _G.TradeConnections then
    for _, conn in ipairs(_G.TradeConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
_G.TradeConnections = {}

local COMMAND_PREFIX = "!add "

local MasterItemDictionary = {
    -- =========================================================================
    -- 1. LIMITED & CHROMATIC SKINS
    -- =========================================================================
    ["ember dragon"]             = "ember <dragon (west)>",
    ["ember"]                    = "ember <dragon (west)>",

    ["galaxy kitsune"]           = "galaxy <empyrean (kitsune)>",
    ["galaxy empyrean"]          = "galaxy <empyrean (kitsune)>",
    ["crimson kitsune"]          = "crimson kitsune",
    ["empyrean"]                 = "empyrean",

    ["divine portal"]            = "divine <portal>",
    ["divine"]                   = "divine <portal>",

    ["runic fiend"]              = "runic fiend",
    ["fiend"]                    = "fiend",
    ["werewolf"]                 = "werewolf",

    ["arcsteel magnet"]          = "arcsteel magnet",
    ["arcsteel"]                 = "arcsteel magnet",
    ["starlight gravity"]        = "starlight gravity",
    ["starlight"]                = "starlight gravity",

    ["purple lightning"]         = "purple lightning",
    ["yellow lightning"]         = "yellow lightning",
    ["red lightning"]            = "red lightning",
    ["green lightning"]          = "green lightning",

    ["nuclear bomb"]             = "nuclear bomb",
    ["thermite bomb"]            = "thermite bomb",
    ["azura bomb"]               = "azura bomb",
    ["celebration bomb"]         = "celebration bomb",

    ["emerald diamond"]          = "emerald diamond",
    ["ruby diamond"]             = "ruby diamond",
    ["topaz diamond"]            = "topaz diamond",
    ["rose quartz diamond"]      = "rose quartz diamond",
    ["rose quartz"]              = "rose quartz diamond",

    ["super spirit pain"]        = "super spirit pain",
    ["super spirit"]             = "super spirit pain",
    ["celestial pain"]           = "celestial pain",
    ["torment pain"]             = "torment pain",
    ["sadness pain"]             = "sadness pain",
    ["frustration pain"]         = "frustration pain",

    ["dog blade"]                = "dog blade",
    ["lime blade"]               = "lime blade",
    ["requiem eagle"]            = "requiem eagle",
    ["glacier eagle"]            = "glacier eagle",

    ["doghouse"]                 = "doghouse (frame break)",
    ["doghouse frame break"]     = "doghouse (frame break)",
    ["vibes"]                    = "vibes (frame break)",
    ["vibes frame break"]        = "vibes (frame break)",
    ["rabid"]                    = "rabid",
    ["scarlet ghost"]            = "scarlet ghost",

    -- =========================================================================
    -- 2. FRUIT NICKNAMES
    -- =========================================================================
    ["trex"]                     = "t-rex",
    ["leo"]                      = "leopard",
    ["chop"]                     = "blade",

    -- =========================================================================
    -- 3. GAMEPASSES & SPECIAL REDEEMABLES
    -- =========================================================================
    ["storage"]                  = "+1 Fruit Storage",
    ["+1 storage"]               = "+1 Fruit Storage",
    ["fruit storage"]            = "+1 Fruit Storage",
    ["dark blade"]               = "Dark Blade",
    ["fruit notifier"]           = "Fruit Notifier",
    ["fast boats"]               = "Fast Boats",
    ["2x mastery"]               = "2x Mastery",
    ["2x money"]                 = "2x Money",
    ["2x boss drops"]            = "2x Boss Drops"
}

local PermFruitAliases = {
    leo   = "leopard",
    trex  = "t-rex",
    chop  = "blade"
}

local function resolveItemKey(userInput)
    if type(userInput) ~= "string" then return nil end

    local query = userInput:lower():match("^%s*(.-)%s*$")
    query = query:gsub("^<(.-)>$", "%1"):match("^%s*(.-)%s*$")
    if query == "" then return nil end

    if query:sub(1, 5) == "perm " then
        local fruitName = query:sub(6):match("^%s*(.-)%s*$")
        fruitName = PermFruitAliases[fruitName] or fruitName
        return "permanent " .. fruitName
    end

    return MasterItemDictionary[query] or query
end

local function collectAllOwnedItems()
    local results = {}
    local seenIds = {}

    -- Physical fruits & stackables live in KEYS.COUNT; skins, perms & passes live in KEYS.IS_OWNED
    local targetKeys = { KEYS.COUNT, KEYS.IS_OWNED }
    for _, keyType in ipairs(targetKeys) do
        if keyType ~= nil then
            local ok, bucket = pcall(function()
                return ItemReplicationService:GetItems(keyType)
            end)
            if ok and type(bucket) == "table" then
                for _, item in pairs(bucket) do
                    if type(item) == "table" and item.ItemId and not seenIds[item.ItemId] then
                        local owned = (item.Value == true) or (type(item.Value) == "number" and item.Value > 0)
                        if owned then
                            seenIds[item.ItemId] = true
                            table.insert(results, item)
                        end
                    end
                end
            end
        end
    end

    return results
end

local function findItemId(targetName)
    local resolvedQuery = resolveItemKey(targetName)
    if not resolvedQuery then return nil end

    local queryLower = resolvedQuery:lower()
    local hyphenForm = queryLower .. "-" .. queryLower
    local isPermQuery = queryLower:sub(1, 10) == "permanent "

    local ownedItems = collectAllOwnedItems()
    local partialId, partialName = nil, nil

    for _, item in ipairs(ownedItems) do
        local ok, cfg = pcall(ItemConfig.tryGet, item.ItemId)
        if ok and type(cfg) == "table" and cfg.Display then
            local displayName = (cfg.Display.Name or ""):lower()
            local storageKey = (cfg.Index and cfg.Index.StorageKey or ""):lower()
            local itemIdLower = tostring(item.ItemId):lower()

            local itemIsPerm = displayName:find("permanent", 1, true) ~= nil
            if isPermQuery == itemIsPerm then
                -- Exact match first (prevents "bomb" from matching "celebration bomb")
                if displayName == queryLower
                    or storageKey == queryLower
                    or storageKey == hyphenForm
                    or itemIdLower == queryLower
                then
                    return item.ItemId, cfg.Display.Name or resolvedQuery
                end

                -- Substring fallback
                if not partialId and (displayName:find(queryLower, 1, true) or storageKey:find(queryLower, 1, true)) then
                    partialId = item.ItemId
                    partialName = cfg.Display.Name or resolvedQuery
                end
            end
        end
    end

    return partialId, partialName
end

-- Simple time-based lock: guarantees 1 execution per command regardless of how many chat events fire
local lastExecTime = 0
local lastExecText = ""

local function handleChatCommand(rawText)
    if type(rawText) ~= "string" then return end

    local lowerText = rawText:lower():match("^%s*(.-)%s*$")
    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then return end

    local now = os.clock()
    if lowerText == lastExecText and (now - lastExecTime) < 1.0 then
        return
    end
    lastExecTime = now
    lastExecText = lowerText

    local targetInput = rawText:match("^%s*(.-)%s*$"):sub(#COMMAND_PREFIX + 1)
    local itemId, resolvedName = findItemId(targetInput)

    if itemId then
        local ok, err = pcall(function()
            TradeFunction:InvokeServer("addItem", itemId, 1)
        end)
        if ok then
            print("[Trade] Added:", resolvedName, "| ItemId:", itemId)
        else
            warn("[Trade] InvokeServer failed:", err)
        end
    else
        warn("[Trade] Not found:", targetInput, "| Resolved:", tostring(resolveItemKey(targetInput)))
    end
end

-- Hook both chat systems safely; the 1.0s debounce prevents double-firing
table.insert(_G.TradeConnections, LocalPlayer.Chatted:Connect(handleChatCommand))

if TextChatService then
    table.insert(_G.TradeConnections, TextChatService.MessageReceived:Connect(function(msg)
        if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then
            handleChatCommand(msg.Text)
        end
    end))
end

print("[Trade] Active! Type '!add <item>' at a trade table.")
