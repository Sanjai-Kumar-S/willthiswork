
-- =========================================================
-- BLOX FRUITS TRADE ADDER - VERSION 5 FINAL
-- Direct StorageKey-Based Resolver
-- Registry: User-supplied Full Registry Dump
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
-- 2. COMPLETE STORAGE KEY REGISTRY
-- =========================================================

local ItemKeys = {

    -- =====================================================
    -- PHYSICAL FRUITS
    -- =====================================================

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
    ["falcon"] = "Falcon-Falcon",
    ["diamond"] = "Diamond-Diamond",

    ["light"] = "Light-Light",
    ["rubber"] = "Rubber-Rubber",
    ["ghost"] = "Ghost-Ghost",
    ["magma"] = "Magma-Magma",

    ["quake"] = "Quake-Quake",
    ["buddha"] = "Buddha-Buddha",
    ["love"] = "Love-Love",
    ["love2"] = "Love2-Love2",
    ["creation"] = "Creation-Creation",
    ["barrier"] = "Barrier-Barrier",
    ["spider"] = "Spider-Spider",
    ["sound"] = "Sound-Sound",
    ["phoenix"] = "Phoenix-Phoenix",
    ["portal"] = "Portal-Portal",
    ["door"] = "Door-Door",
    ["lightning"] = "Lightning-Lightning",
    ["rumble"] = "Rumble-Rumble",
    ["pain"] = "Pain-Pain",
    ["blizzard"] = "Blizzard-Blizzard",

    ["gravity"] = "Gravity-Gravity",
    ["mammoth"] = "Mammoth-Mammoth",
    ["t-rex"] = "T-Rex-T-Rex",
    ["trex"] = "T-Rex-T-Rex",
    ["dough"] = "Dough-Dough",
    ["shadow"] = "Shadow-Shadow",
    ["venom"] = "Venom-Venom",
    ["gas"] = "Gas-Gas",
    ["spirit"] = "Spirit-Spirit",
    ["soul"] = "Soul-Soul",
    ["tiger"] = "Tiger-Tiger",
    ["leopard"] = "Leopard-Leopard",
    ["yeti"] = "Yeti-Yeti",
    ["magnet"] = "Magnet-Magnet",
    ["kitsune"] = "Kitsune-Kitsune",
    ["control"] = "Control-Control",

    ["dragon"] = "Dragon-Dragon",
    ["dragon west"] = "Dragon (West)-Dragon (West)",
    ["dragon east"] = "Dragon (East)-Dragon (East)",
    ["dragon classic"] = "Dragon (Classic)-Dragon (Classic)",

    -- Special tradable fruit entries
    ["empyrean"] = "Empyrean (Kitsune)-Empyrean (Kitsune)",
    ["empyrean kitsune"] = "Empyrean (Kitsune)-Empyrean (Kitsune)",

    ["fiend"] = "Fiend (Yeti)-Fiend (Yeti)",
    ["fiend yeti"] = "Fiend (Yeti)-Fiend (Yeti)",

    ["werewolf"] = "Werewolf (Tiger)-Werewolf (Tiger)",
    ["werewolf tiger"] = "Werewolf (Tiger)-Werewolf (Tiger)",

    ["hellfire"] = "Hellfire (Gas)-Hellfire (Gas)",
    ["hellfire gas"] = "Hellfire (Gas)-Hellfire (Gas)",

    -- =====================================================
    -- PERMANENT FRUITS
    -- =====================================================

    ["perm rocket"] = "Permanent Rocket-Rocket",
    ["permanent rocket"] = "Permanent Rocket-Rocket",

    ["perm spin"] = "Permanent Spin-Spin",
    ["permanent spin"] = "Permanent Spin-Spin",

    ["perm blade"] = "Permanent Blade-Blade",
    ["permanent blade"] = "Permanent Blade-Blade",
    ["perm chop"] = "Permanent Blade-Blade",

    ["perm spring"] = "Permanent Spring-Spring",
    ["permanent spring"] = "Permanent Spring-Spring",

    ["perm bomb"] = "Permanent Bomb-Bomb",
    ["permanent bomb"] = "Permanent Bomb-Bomb",

    ["perm smoke"] = "Permanent Smoke-Smoke",
    ["permanent smoke"] = "Permanent Smoke-Smoke",

    ["perm spike"] = "Permanent Spike-Spike",
    ["permanent spike"] = "Permanent Spike-Spike",

    ["perm flame"] = "Permanent Flame-Flame",
    ["permanent flame"] = "Permanent Flame-Flame",

    ["perm ice"] = "Permanent Ice-Ice",
    ["permanent ice"] = "Permanent Ice-Ice",

    ["perm sand"] = "Permanent Sand-Sand",
    ["permanent sand"] = "Permanent Sand-Sand",

    ["perm dark"] = "Permanent Dark-Dark",
    ["permanent dark"] = "Permanent Dark-Dark",

    ["perm eagle"] = "Permanent Eagle-Eagle",
    ["permanent eagle"] = "Permanent Eagle-Eagle",

    ["perm falcon"] = "Permanent Falcon-Falcon",
    ["permanent falcon"] = "Permanent Falcon-Falcon",

    ["perm diamond"] = "Permanent Diamond-Diamond",
    ["permanent diamond"] = "Permanent Diamond-Diamond",

    ["perm light"] = "Permanent Light-Light",
    ["permanent light"] = "Permanent Light-Light",

    ["perm rubber"] = "Permanent Rubber-Rubber",
    ["permanent rubber"] = "Permanent Rubber-Rubber",

    ["perm ghost"] = "Permanent Ghost-Ghost",
    ["permanent ghost"] = "Permanent Ghost-Ghost",

    ["perm magma"] = "Permanent Magma-Magma",
    ["permanent magma"] = "Permanent Magma-Magma",

    ["perm quake"] = "Permanent Quake-Quake",
    ["permanent quake"] = "Permanent Quake-Quake",

    ["perm buddha"] = "Permanent Buddha-Buddha",
    ["permanent buddha"] = "Permanent Buddha-Buddha",

    ["perm love"] = "Permanent Love-Love",
    ["permanent love"] = "Permanent Love-Love",

    ["perm creation"] = "Permanent Creation-Creation",
    ["permanent creation"] = "Permanent Creation-Creation",

    ["perm barrier"] = "Permanent Barrier-Barrier",
    ["permanent barrier"] = "Permanent Barrier-Barrier",

    ["perm spider"] = "Permanent Spider-Spider",
    ["permanent spider"] = "Permanent Spider-Spider",

    ["perm sound"] = "Permanent Sound-Sound",
    ["permanent sound"] = "Permanent Sound-Sound",

    ["perm phoenix"] = "Permanent Phoenix-Phoenix",
    ["permanent phoenix"] = "Permanent Phoenix-Phoenix",

    ["perm portal"] = "Permanent Portal-Portal",
    ["permanent portal"] = "Permanent Portal-Portal",

    ["perm lightning"] = "Permanent Lightning-Lightning",
    ["permanent lightning"] = "Permanent Lightning-Lightning",

    ["perm rumble"] = "Permanent Rumble-Rumble",
    ["permanent rumble"] = "Permanent Rumble-Rumble",

    ["perm pain"] = "Permanent Pain-Pain",
    ["permanent pain"] = "Permanent Pain-Pain",

    ["perm blizzard"] = "Permanent Blizzard-Blizzard",
    ["permanent blizzard"] = "Permanent Blizzard-Blizzard",

    ["perm gravity"] = "Permanent Gravity-Gravity",
    ["permanent gravity"] = "Permanent Gravity-Gravity",

    ["perm mammoth"] = "Permanent Mammoth-Mammoth",
    ["permanent mammoth"] = "Permanent Mammoth-Mammoth",

    ["perm t-rex"] = "Permanent T-Rex-T-Rex",
    ["perm trex"] = "Permanent T-Rex-T-Rex",
    ["permanent t-rex"] = "Permanent T-Rex-T-Rex",

    ["perm dough"] = "Permanent Dough-Dough",
    ["permanent dough"] = "Permanent Dough-Dough",

    ["perm shadow"] = "Permanent Shadow-Shadow",
    ["permanent shadow"] = "Permanent Shadow-Shadow",

    ["perm venom"] = "Permanent Venom-Venom",
    ["permanent venom"] = "Permanent Venom-Venom",

    ["perm gas"] = "Permanent Gas-Gas",
    ["permanent gas"] = "Permanent Gas-Gas",

    ["perm spirit"] = "Permanent Spirit-Spirit",
    ["permanent spirit"] = "Permanent Spirit-Spirit",

    ["perm soul"] = "Permanent Soul-Soul",
    ["permanent soul"] = "Permanent Soul-Soul",

    ["perm tiger"] = "Permanent Tiger-Tiger",
    ["permanent tiger"] = "Permanent Tiger-Tiger",

    ["perm leopard"] = "Permanent Leopard-Leopard",
    ["permanent leopard"] = "Permanent Leopard-Leopard",

    ["perm yeti"] = "Permanent Yeti-Yeti",
    ["permanent yeti"] = "Permanent Yeti-Yeti",

    ["perm magnet"] = "Permanent Magnet-Magnet",
    ["permanent magnet"] = "Permanent Magnet-Magnet",

    ["perm kitsune"] = "Permanent Kitsune-Kitsune",
    ["permanent kitsune"] = "Permanent Kitsune-Kitsune",

    ["perm control"] = "Permanent Control-Control",
    ["permanent control"] = "Permanent Control-Control",

    ["perm dragon"] = "Permanent Dragon-Dragon",
    ["permanent dragon"] = "Permanent Dragon-Dragon",

    ["perm dragon west"] = "Permanent Dragon (West)-Dragon (West)",
    ["permanent dragon west"] = "Permanent Dragon (West)-Dragon (West)",

    ["perm dragon east"] = "Permanent Dragon (East)-Dragon (East)",
    ["permanent dragon east"] = "Permanent Dragon (East)-Dragon (East)",

    ["perm dragon classic"] = "Permanent Dragon (Classic)-Dragon (Classic)",
    ["permanent dragon classic"] = "Permanent Dragon (Classic)-Dragon (Classic)",

    ["perm dragon token"] = "Permanent Dragon Token",

    ["discounted perm dragon"] = "Discounted Permanent Dragon",

    -- =====================================================
    -- DRAGON LIMITED SKINS
    -- =====================================================

    -- Ember
    ["ember west"] = "WSTDSKINember",
    ["ember dragon west"] = "WSTDSKINember",
    ["ember east"] = "ESTDSKINember",
    ["ember dragon east"] = "ESTDSKINember",
    ["ember chromatic"] = "EmberChromaticDragon",
    ["ember dragon chromatic"] = "EmberChromaticDragon",

    -- Eclipse
    ["eclipse west"] = "WSTDSKINeclipse",
    ["eclipse dragon west"] = "WSTDSKINeclipse",
    ["eclipse east"] = "ESTDSKINeclipse",
    ["eclipse dragon east"] = "ESTDSKINeclipse",
    ["eclipse chromatic"] = "EclipseChromaticDragon",
    ["eclipse dragon chromatic"] = "EclipseChromaticDragon",

    -- Blood Moon
    ["blood moon west"] = "WSTDSKINbloodmoon",
    ["blood moon dragon west"] = "WSTDSKINbloodmoon",
    ["blood moon east"] = "ESTDSKINbloodmoon",
    ["blood moon dragon east"] = "ESTDSKINbloodmoon",
    ["blood moon chromatic"] = "BloodmoonChromaticDragon",

    -- Phoenix Sky
    ["phoenix sky west"] = "WSTDSKINphoenixsky",
    ["phoenix sky dragon west"] = "WSTDSKINphoenixsky",
    ["phoenix sky east"] = "ESTDSKINphoenixsky",
    ["phoenix sky dragon east"] = "ESTDSKINphoenixsky",
    ["phoenix sky chromatic"] = "PhoenixSkyChromaticDragon",

    -- Violet Night
    ["violet night west"] = "WSTDSKINvioletnight",
    ["violet night dragon west"] = "WSTDSKINvioletnight",
    ["violet night east"] = "ESTDSKINvioletnight",
    ["violet night dragon east"] = "ESTDSKINvioletnight",
    ["violet night chromatic"] = "VioletNightChromaticDragon",

    -- =====================================================
    -- KITSUNE LIMITED SKINS
    -- =====================================================

    ["crimson"] = "KYUKONSKINcrimson",
    ["crimson kitsune"] = "KYUKONSKINcrimson",
    ["kitsune crimson"] = "KYUKONSKINcrimson",

    ["galaxy"] = "KYUKONSKINgalaxy",
    ["galaxy kitsune skin"] = "KYUKONSKINgalaxy",
    ["kitsune galaxy"] = "KYUKONSKINgalaxy",

    -- =====================================================
    -- PAIN LIMITED SKINS
    -- =====================================================

    ["celestial pain skin"] = "PAINSKINcelestial",
    ["pain celestial"] = "PAINSKINcelestial",

    ["super spirit pain skin"] = "PAINSKINsuperspirit",
    ["pain super spirit"] = "PAINSKINsuperspirit",

    -- =====================================================
    -- LIGHTNING LIMITED SKINS
    -- =====================================================

    ["purple lightning"] = "LIGHTNINGSKINpurple",
    ["yellow lightning"] = "LIGHTNINGSKINyellow",
    ["green lightning"] = "LIGHTNINGSKINgreen",
    ["red lightning"] = "LIGHTNINGSKINred",
    ["blue lightning"] = "LIGHTNINGSKINblue",

    -- =====================================================
    -- PORTAL LIMITED SKINS
    -- =====================================================

    ["divine portal"] = "PORTALSKINdivine",
    ["portal divine"] = "PORTALSKINdivine",

    ["pink portal"] = "PORTALSKINpink",
    ["portal pink"] = "PORTALSKINpink",

    ["orange portal"] = "PORTALSKINorange",
    ["portal orange"] = "PORTALSKINorange",

    ["blue portal"] = "PORTALSKINblue",
    ["portal blue"] = "PORTALSKINblue",

    -- =====================================================
    -- DIAMOND LIMITED SKINS
    -- =====================================================

    ["emerald diamond skin"] = "DIAMONDSKINgreen",
    ["diamond emerald"] = "DIAMONDSKINgreen",

    ["rose quartz"] = "DIAMONDSKINpoudretteite",
    ["rose quartz diamond"] = "DIAMONDSKINpoudretteite",

    ["topaz diamond skin"] = "DIAMONDSKINtopaz",
    ["diamond topaz"] = "DIAMONDSKINtopaz",

    ["ruby diamond skin"] = "DIAMONDSKINred",
    ["diamond ruby"] = "DIAMONDSKINred",

    -- =====================================================
    -- EAGLE LIMITED SKINS
    -- =====================================================

    ["glacier eagle"] = "FALCSKINglacier",
    ["eagle glacier"] = "FALCSKINglacier",

    ["requiem eagle"] = "FALCSKINrequiem",
    ["eagle requiem"] = "FALCSKINrequiem",

    ["matrix eagle"] = "FALCSKINmatrix",
    ["eagle matrix"] = "FALCSKINmatrix",

    ["parrot eagle"] = "FALCSKINparrot",
    ["eagle parrot"] = "FALCSKINparrot",

    -- =====================================================
    -- BOMB LIMITED SKINS
    -- =====================================================

    ["nuclear bomb"] = "BOMBSKINnuclear",
    ["bomb nuclear"] = "BOMBSKINnuclear",

    ["thermite bomb"] = "BOMBSKINthermite",
    ["bomb thermite"] = "BOMBSKINthermite",

    ["azura bomb"] = "BOMBSKINazura",
    ["bomb azura"] = "BOMBSKINazura",

    ["celebration bomb"] = "BOMBSKINcelebration",
    ["bomb celebration"] = "BOMBSKINcelebration",

    -- =====================================================
    -- MAGNET LIMITED SKIN
    -- =====================================================

    ["arcsteel"] = "MAGNETSKINarksteel",
    ["arcsteel magnet"] = "MAGNETSKINarksteel",
    ["magnet arcsteel"] = "MAGNETSKINarksteel",

    -- =====================================================
    -- YETI / FIEND LIMITED SKINS
    -- =====================================================

    ["runic"] = "FIENDSKINsealed",
    ["runic fiend"] = "FIENDSKINsealed",
    ["sealed fiend skin"] = "FIENDSKINsealed",

    ["fiend skin"] = "YETISKINfiend",
    ["yeti fiend skin"] = "YETISKINfiend",

    ["fiend mutation"] = "YETIMUTFiend",
    ["yeti fiend mutation"] = "YETIMUTFiend",

    -- =====================================================
    -- GRAVITY LIMITED SKIN
    -- =====================================================

    ["starlight"] = "GRAVITYSKINheavenly",
    ["starlight gravity"] = "GRAVITYSKINheavenly",
    ["heavenly gravity"] = "GRAVITYSKINheavenly",

    -- =====================================================
    -- TIGER LIMITED SKINS
    -- =====================================================

    ["werewolf skin"] = "TIGERSKINwerewolf",
    ["tiger werewolf skin"] = "TIGERSKINwerewolf",

    ["werewolf mutation"] = "TIGERMUTWerewolf",
    ["tiger werewolf mutation"] = "TIGERMUTWerewolf",

    -- =====================================================
    -- GAS LIMITED SKINS
    -- =====================================================

    ["hellfire skin"] = "HELLFIRESKINdefault",
    ["gas hellfire skin"] = "HELLFIRESKINdefault",

    ["hellfire mutation"] = "GASMUTHellfire",
    ["gas hellfire mutation"] = "GASMUTHellfire",

    -- =====================================================
    -- DOG BLADE TRADABLE SKIN
    -- =====================================================

    ["rabid"] = "BRATSKINslayer",
    ["rabid dog blade"] = "BRATSKINslayer",
    ["dog blade rabid"] = "BRATSKINslayer",

    -- =====================================================
    -- GAMEPASSES
    -- =====================================================

    ["fruit notifier"] = "Fruit Notifier",
    ["notifier"] = "Fruit Notifier",

    ["dark blade"] = "Dark Blade",
    ["yama gamepass"] = "Dark Blade",

    ["2x mastery"] = "2x Mastery",
    ["double mastery"] = "2x Mastery",

    ["2x money"] = "2x Money",
    ["double money"] = "2x Money",

    ["2x boss drops"] = "2x Boss Drops",
    ["double boss drops"] = "2x Boss Drops",

    ["fast boats"] = "Fast Boats",

    ["storage"] = "+1 Fruit Storage",
    ["+1 storage"] = "+1 Fruit Storage",
    ["fruit storage"] = "+1 Fruit Storage",
    ["+1 fruit storage"] = "+1 Fruit Storage",

    -- =====================================================
    -- SPECIAL TRADABLE TOKENS
    -- =====================================================

    ["dragon token"] = "Dragon Token (Tradable)",
    ["tradable dragon token"] = "Dragon Token (Tradable)",

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

    name = name:gsub("%s+", " ")

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

    -- Exact alias lookup
    local storageKey = ItemKeys[query]

    if storageKey then
        return storageKey, "exact"
    end

    -- Unique partial alias matching
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
-- 5. CHAT COMMAND HANDLER
-- =========================================================

local lastText = ""
local lastTime = 0

local function handleChatCommand(rawText)

    if type(rawText) ~= "string" then
        return
    end

    local cleanText = rawText:match("^%s*(.-)%s*$")
    local lowerText = cleanText:lower()

    if lowerText:sub(1, #COMMAND_PREFIX)
        ~= COMMAND_PREFIX then
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

    local storageKey, matchType =
        findStorageKey(targetInput)

    if not storageKey then

        if matchType == "ambiguous" then

            warn(
                "[Trade] Multiple matching items:",
                targetInput,
                "| Use a more specific name."
            )

        elseif matchType == "invalid" then

            warn("[Trade] Invalid item name.")

        else

            warn(
                "[Trade] Item not found:",
                targetInput
            )

        end

        return
    end

    -- =====================================================
    -- DIRECT STORAGE KEY TRADE REQUEST
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
            "[Trade] Add request sent:",
            targetInput,
            "| StorageKey:",
            storageKey,
            "| Match:",
            matchType
        )

    else

        warn(
            "[Trade] InvokeServer failed:",
            result
        )

    end

end

-- =========================================================
-- 6. CHAT LISTENER
-- =========================================================

if TextChatService
    and TextChatService.ChatVersion
        == Enum.ChatVersion.TextChatService then

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
-- 7. READY
-- =========================================================

local totalAliases = 0

for _ in pairs(ItemKeys) do
    totalAliases += 1
end

print("========================================")
print("[Trade] VERSION 5 FINAL LOADED!")
print("[Trade] Direct StorageKey resolver active.")
print("[Trade] Registry aliases:", totalAliases)
print("[Trade] Physical fruits enabled.")
print("[Trade] Permanent fruits enabled.")
print("[Trade] Limited skins enabled.")
print("[Trade] Special items enabled.")
print("[Trade] Tradable gamepasses enabled.")
print("[Trade] Exact key lookup enabled.")
print("[Trade] Unique partial matching enabled.")
print("[Trade] Commands: !add <item>")
print("========================================")
