local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local TradeFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TradeFunction")

local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

local COMMAND_PREFIX = "!add "

local MasterItemDictionary = {
    -- =========================================================================
    -- 1. LIMITED & CHROMATIC SKINS (Exact tbl14 & tbl15 dump)
    -- =========================================================================
    -- Dragon Skins
    ["ember dragon"]             = "ember <dragon (west)>",
    ["ember"]                    = "ember <dragon (west)>",

    -- Kitsune & Empyrean Skins
    ["galaxy kitsune"]           = "galaxy <empyrean (kitsune)>",
    ["galaxy empyrean"]          = "galaxy <empyrean (kitsune)>",
    ["crimson kitsune"]          = "crimson kitsune",
    ["empyrean"]                 = "empyrean",

    -- Portal Skins
    ["divine portal"]            = "divine <portal>",
    ["divine"]                   = "divine <portal>",

    -- Yeti & Mutation Skins
    ["runic fiend"]              = "runic fiend",
    ["fiend"]                    = "fiend",
    ["werewolf"]                 = "werewolf",

    -- Magnet & Gravity Skins
    ["arcsteel magnet"]          = "arcsteel magnet",
    ["arcsteel"]                 = "arcsteel magnet",
    ["starlight gravity"]        = "starlight gravity",
    ["starlight"]                = "starlight gravity",

    -- Lightning (Rumble) Skins
    ["purple lightning"]         = "purple lightning",
    ["yellow lightning"]         = "yellow lightning",
    ["red lightning"]            = "red lightning",
    ["green lightning"]          = "green lightning",

    -- Bomb Skins
    ["nuclear bomb"]             = "nuclear bomb",
    ["thermite bomb"]            = "thermite bomb",
    ["azura bomb"]               = "azura bomb",
    ["celebration bomb"]         = "celebration bomb",

    -- Diamond Gemstone Skins
    ["emerald diamond"]          = "emerald diamond",
    ["ruby diamond"]             = "ruby diamond",
    ["topaz diamond"]            = "topaz diamond",
    ["rose quartz diamond"]      = "rose quartz diamond",
    ["rose quartz"]              = "rose quartz diamond",

    -- Pain / Celestial Skins
    ["super spirit pain"]        = "super spirit pain",
    ["super spirit"]             = "super spirit pain",
    ["celestial pain"]           = "celestial pain",
    ["torment pain"]             = "torment pain",
    ["sadness pain"]             = "sadness pain",
    ["frustration pain"]         = "frustration pain",

    -- Sword & Weapon Skins
    ["dog blade"]                = "dog blade",
    ["lime blade"]               = "lime blade",
    ["requiem eagle"]            = "requiem eagle",
    ["glacier eagle"]            = "glacier eagle",

    -- Profile / Banner Frame Breaks & Entities
    ["doghouse"]                 = "doghouse (frame break)",
    ["doghouse frame break"]     = "doghouse (frame break)",
    ["vibes"]                    = "vibes (frame break)",
    ["vibes frame break"]        = "vibes (frame break)",
    ["rabid"]                    = "rabid",
    ["scarlet ghost"]            = "scarlet ghost",

    -- =========================================================================
    -- 7. GAMEPASSES & SPECIAL REDEEMABLES (Hardcoded & Dynamic Filter)
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
    if query == "" then return nil end

    -- Expand "perm <fruit>" -> "permanent <fruit>" (matches Display "Permanent Rocket" & StorageKey "Permanent Rocket-Rocket")
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
    local ownedItems = ItemReplicationService:GetItems(KEYS.IS_OWNED)
    if type(ownedItems) ~= "table" then return nil end

    for _, item in pairs(ownedItems) do
        if item.Value == true and item.ItemId then
            local ok, cfg = pcall(function()
                return ItemConfig.tryGet(item.ItemId)
            end)

            if ok and type(cfg) == "table" and cfg.Display then
                local displayName = (cfg.Display.Name or ""):lower()
                local storageKey = (cfg.Index and cfg.Index.StorageKey or ""):lower()
                local itemIdLower = tostring(item.ItemId):lower()

                if displayName == queryLower
                    or storageKey == queryLower
                    or itemIdLower == queryLower
                    or displayName:find(queryLower, 1, true)
                    or storageKey:find(queryLower, 1, true)
                then
                    return item.ItemId, cfg.Display.Name or resolvedQuery
                end
            end
        end
    end

    return nil
end

local function handleChatCommand(rawText)
    if type(rawText) ~= "string" then return end

    local lowerText = rawText:lower()
    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then return end

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

-- Hook only the active chat system so commands don't fire twice
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        if textChatMessage.TextSource and textChatMessage.TextSource.UserId == LocalPlayer.UserId then
            handleChatCommand(textChatMessage.Text)
        end
    end)
else
    LocalPlayer.Chatted:Connect(handleChatCommand)
end

print("[Trade] Chat listener active. Type '!add <fruit/perm/skin/gamepass>' while seated at a trade table.")
