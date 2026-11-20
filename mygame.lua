-- lang: Luau, file: resolver.lua, target: Roblox / Blox Fruits Automation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TradeFunction = Remotes:WaitForChild("TradeFunction")
local CommF_ = Remotes:WaitForChild("CommF_")

local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Disconnect previous instance on re-execute
if _G.TradeAddListener then
    pcall(function() _G.TradeAddListener:Disconnect() end)
    _G.TradeAddListener = nil
end

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

local function findItemId(targetName)
    local resolvedQuery = resolveItemKey(targetName)
    if not resolvedQuery then return nil end

    local queryLower = resolvedQuery:lower()
    local hyphenForm = queryLower .. "-" .. queryLower
    local isPermQuery = queryLower:sub(1, 10) == "permanent "

    -- 1. Primary lookup: KEYS.IS_OWNED (handles skins, perms, gamepasses, and replicated fruits)
    local ownedItems = ItemReplicationService:GetItems(KEYS.IS_OWNED)
    if type(ownedItems) == "table" then
        for _, item in pairs(ownedItems) do
            if (item.Value == true or (type(item.Value) == "number" and item.Value > 0)) and item.ItemId then
                local ok, cfg = pcall(function()
                    return ItemConfig.tryGet(item.ItemId)
                end)

                if ok and type(cfg) == "table" and cfg.Display then
                    local displayName = (cfg.Display.Name or ""):lower()
                    local storageKey = (cfg.Index and cfg.Index.StorageKey or ""):lower()
                    local itemIdLower = tostring(item.ItemId):lower()

                    local itemIsPerm = displayName:find("permanent", 1, true) ~= nil
                    if isPermQuery == itemIsPerm then
                        if displayName == queryLower
                            or storageKey == queryLower
                            or storageKey == hyphenForm
                            or itemIdLower == queryLower
                            or displayName:find(queryLower, 1, true)
                            or storageKey:find(queryLower, 1, true)
                        then
                            return item.ItemId, cfg.Display.Name or resolvedQuery
                        end
                    end
                end
            end
        end
    end

    -- 2. Fallback lookup: CommF_ getInventory (handles physical fruits like Venom-Venom)
    if not isPermQuery then
        local ok, inv = pcall(function()
            return CommF_:InvokeServer("getInventory")
        end)
        if ok and type(inv) == "table" then
            for _, entry in ipairs(inv) do
                if type(entry) == "table" and entry.Name then
                    local nameLower = entry.Name:lower()
                    if nameLower == queryLower
                        or nameLower == hyphenForm
                        or nameLower:find(queryLower, 1, true)
                    then
                        return entry.Name, entry.Name
                    end
                end
            end
        end
    end

    return nil
end

-- Deduplicate by MessageId + 0.5s cooldown so it fires once on whichever Status arrives first
local seenMessages = {}
local lastTime = 0

local function handleChatCommand(rawText, messageId)
    if type(rawText) ~= "string" then return end

    local lowerText = rawText:lower()
    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then return end

    if messageId then
        if seenMessages[messageId] then return end
        seenMessages[messageId] = true
    else
        local now = os.clock()
        if now - lastTime < 0.5 then return end
        lastTime = now
    end

    local targetInput = rawText:sub(#COMMAND_PREFIX + 1)
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
        warn("[Trade] Item not found in inventory:", targetInput, "(Resolved:", tostring(resolveItemKey(targetInput)) .. ")")
    end
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    _G.TradeAddListener = TextChatService.MessageReceived:Connect(function(textChatMessage)
        if textChatMessage.TextSource and textChatMessage.TextSource.UserId == LocalPlayer.UserId then
            handleChatCommand(textChatMessage.Text, textChatMessage.MessageId)
        end
    end)
else
    _G.TradeAddListener = LocalPlayer.Chatted:Connect(function(msg)
        handleChatCommand(msg, nil)
    end)
end

print("[Trade] Chat listener active. Type '!add <item>' while seated at a trade table.")
