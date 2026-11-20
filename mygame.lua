-- lang: Luau, file: resolver.lua, target: Roblox / Blox Fruits Automation
-- fixes duplicate listener stacking (_G cleanup), double MessageReceived firing, and physical fruit lookup

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

-- Clean up any old chat listener if you re-executed the script
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

local function isItemOwned(val)
    return val == true or (type(val) == "number" and val > 0)
end

local function findItemId(targetName)
    local resolvedQuery = resolveItemKey(targetName)
    if not resolvedQuery then return nil end

    local queryLower = resolvedQuery:lower()
    local hyphenForm = queryLower .. "-" .. queryLower
    local isPermQuery = queryLower:sub(1, 10) == "permanent "

    -- 1. Search ItemReplicationService across all KEYS buckets (IS_OWNED, COUNT, etc.)
    local bucketsToScan = {}
    if type(KEYS) == "table" then
        for _, keyVal in pairs(KEYS) do
            local ok, items = pcall(function()
                return ItemReplicationService:GetItems(keyVal)
            end)
            if ok and type(items) == "table" then
                table.insert(bucketsToScan, items)
            end
        end
    end

    local partialId, partialName = nil, nil

    for _, itemBucket in ipairs(bucketsToScan) do
        for _, item in pairs(itemBucket) do
            if type(item) == "table" and isItemOwned(item.Value) and item.ItemId then
                local ok, cfg = pcall(ItemConfig.tryGet, item.ItemId)
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
                        then
                            return item.ItemId, cfg.Display.Name or resolvedQuery
                        end

                        if not partialId and (displayName:find(queryLower, 1, true) or storageKey:find(queryLower, 1, true)) then
                            partialId = item.ItemId
                            partialName = cfg.Display.Name or resolvedQuery
                        end
                    end
                end
            end
        end
    end

    if partialId then
        return partialId, partialName
    end

    -- 2. Fallback: Check CommF_ getInventory for physical fruits stored as "Venom-Venom"
    if not isPermQuery then
        local ok, inv = pcall(function()
            return CommF_:InvokeServer("getInventory")
        end)
        if ok and type(inv) == "table" then
            for _, entry in ipairs(inv) do
                if type(entry) == "table" and entry.Name then
                    local entryLower = entry.Name:lower()
                    if entryLower == queryLower
                        or entryLower == hyphenForm
                        or entryLower:find(queryLower, 1, true)
                    then
                        return entry.Name, entry.Name
                    end
                end
            end
        end
    end

    return nil
end

-- Strict debounce so a single chat message can never invoke TradeFunction twice
local lastMessageId = nil
local lastExecTime = 0

local function handleChatCommand(rawText, messageId)
    if type(rawText) ~= "string" then return end

    local lowerText = rawText:lower()
    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then return end

    local now = os.clock()
    if (messageId and messageId == lastMessageId) or (now - lastExecTime < 0.8) then
        return
    end
    lastMessageId = messageId
    lastExecTime = now

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
            -- Fire only once on initial send, ignore the replicated Success echo
            if textChatMessage.Status == Enum.TextChatMessageStatus.Sending then
                handleChatCommand(textChatMessage.Text, textChatMessage.MessageId)
            end
        end
    end)
else
    _G.TradeAddListener = LocalPlayer.Chatted:Connect(function(msg)
        handleChatCommand(msg, nil)
    end)
end

print("[Trade] Chat listener active (old listeners cleared). Type '!add <item>' at a trade table.")
