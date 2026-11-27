-- =========================================================
-- BLOX FRUITS TRADE ADDER - VERSION 5 (FULL REGISTRY)
-- Multi-ID + StorageKey Fallback Resolver
-- Uses Version 4 Remote and Inventory Modules
-- =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
local REMOVE_PREFIX = "!remove "
local RESET_PREFIX = "!reset "
local DUPLICATE_COOLDOWN = 1.0

local AuthorizedUsers = { "BLACKGOKU_0707", "Aid3no" }

local function IsAuthorized(username)
	for _, name in ipairs(AuthorizedUsers) do
		if name == username then
			return true
		end
	end
	return false
end

local isAdding = false
local isRemoving = false
local isResetting = false
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
-- Format: { numeric IDs, string keys } from full registry dump
-- =========================================================

local ItemList = {

	-- =====================================================
	-- PHYSICAL FRUITS
	-- =====================================================

	["rocket"]              = {4, 1390, 384, "Rocket-Rocket", "Physical Rocket Fruit"},
	["spin"]                = {128, 1411, "Spin-Spin"},
	["blade"]               = {31, 1399, "Blade-Blade"},
	["chop"]                = {31, 1399, "Blade-Blade"},
	["spring"]              = {46, 1402, "Spring-Spring"},
	["bomb"]                = {25, 1397, "Bomb-Bomb"},
	["smoke"]               = {32, 1400, "Smoke-Smoke"},
	["spike"]               = {26, 1398, "Spike-Spike"},

	["flame"]               = {18, 1394, "Flame-Flame"},
	["ice"]                 = {13, 1392, "Ice-Ice"},
	["sand"]                = {53, 1404, "Sand-Sand"},
	["dark"]                = {20, 1395, "Dark-Dark"},
	["eagle"]               = {400, 1425, 133, "Eagle-Eagle", "Falcon-Falcon"},
	["falcon"]              = {133, 400, 1425, "Falcon-Falcon", "Eagle-Eagle"},
	["diamond"]             = {208, 1421, "Diamond-Diamond"},

	["light"]               = {80, 1407, "Light-Light"},
	["rubber"]              = {24, 1396, "Rubber-Rubber"},
	["ghost"]               = {158, 1412, "Ghost-Ghost"},
	["revive"]              = {158, 1412, "Ghost-Ghost"},
	["magma"]               = {8, 1391, "Magma-Magma"},

	["quake"]               = {3, 1389, "Quake-Quake"},
	["buddha"]              = {14, 1393, "Buddha-Buddha"},
	["love"]                = {86, 1408, 132, "Love-Love", "Love2-Love2"},
	["creation"]            = {402, 1426, 58, "Creation-Creation", "Barrier-Barrier"},
	["barrier"]             = {58, 402, 1426, "Barrier-Barrier", "Creation-Creation"},
	["spider"]              = {48, 1403, "Spider-Spider"},
	["sound"]               = {193, 1419, "Sound-Sound"},
	["phoenix"]             = {43, 1401, "Phoenix-Phoenix"},
	["portal"]              = {170, 1414, 129, "Portal-Portal", "Door-Door"},
	["door"]                = {129, 170, 1414, "Door-Door", "Portal-Portal"},
	["lightning"]           = {448, 1427, 50, "Lightning-Lightning", "Rumble-Rumble"},
	["rumble"]              = {50, 448, 1427, "Rumble-Rumble", "Lightning-Lightning"},
	["pain"]                = {57, 1406, "Pain-Pain"},
	["paw"]                 = {57, 1406, "Pain-Pain"},
	["blizzard"]            = {184, 1416, "Blizzard-Blizzard"},

	["gravity"]             = {54, 1405, "Gravity-Gravity"},
	["mammoth"]             = {191, 1418, "Mammoth-Mammoth"},
	["trex"]                = {204, 1420, "T-Rex-T-Rex"},
	["t-rex"]               = {204, 1420, "T-Rex-T-Rex"},
	["dough"]               = {188, 1417, "Dough-Dough"},
	["shadow"]              = {163, 1413, "Shadow-Shadow"},
	["venom"]               = {127, 1410, "Venom-Venom"},
	["gas"]                 = {220, 1422, "Gas-Gas"},
	["spirit"]              = {181, 1415, 185, "Spirit-Spirit", "Soul-Soul"},
	["soul"]                = {185, 181, 1415, "Soul-Soul", "Spirit-Spirit"},
	["tiger"]               = {833, 1430, 64, "Tiger-Tiger", "Leopard-Leopard"},
	["leopard"]             = {64, 833, 1430, "Leopard-Leopard", "Tiger-Tiger"},
	["leo"]                 = {833, 1430, 64, "Tiger-Tiger", "Leopard-Leopard"},
	["yeti"]                = {229, 1424, "Yeti-Yeti"},
	["magnet"]              = {1515, 1516, "Magnet-Magnet"},
	["kitsune"]             = {221, 1423, "Kitsune-Kitsune"},
	["control"]             = {95, 1409, "Control-Control"},
	["dragon west"]         = {884, 1435, "Dragon (West)-Dragon (West)"},
	["west dragon"]         = {884, 1435, "Dragon (West)-Dragon (West)"},
	["dragon east"]         = {885, 1436, "Dragon (East)-Dragon (East)"},
	["east dragon"]         = {885, 1436, "Dragon (East)-Dragon (East)"},
	["dragon"]              = {222, 254, 1447, 117, "Dragon-Dragon", "Dragon (Classic)-Dragon (Classic)"},

	-- =====================================================
	-- PERMANENT FRUITS
	-- =====================================================

	["perm rocket"]          = {357, "Permanent Rocket-Rocket"},
	["perm spin"]            = {360, "Permanent Spin-Spin"},
	["perm blade"]           = {350, "Permanent Blade-Blade"},
	["perm chop"]            = {350, "Permanent Blade-Blade"},
	["perm spring"]          = {381, "Permanent Spring-Spring"},
	["perm bomb"]            = {344, "Permanent Bomb-Bomb"},
	["perm smoke"]           = {379, "Permanent Smoke-Smoke"},
	["perm spike"]           = {378, "Permanent Spike-Spike"},
	["perm flame"]           = {347, "Permanent Flame-Flame"},
	["perm ice"]             = {359, "Permanent Ice-Ice"},
	["perm sand"]            = {353, "Permanent Sand-Sand"},
	["perm dark"]            = {371, "Permanent Dark-Dark"},
	["perm eagle"]           = {401, 377, "Permanent Eagle-Eagle", "Permanent Falcon-Falcon"},
	["perm falcon"]          = {377, 401, "Permanent Falcon-Falcon", "Permanent Eagle-Eagle"},
	["perm diamond"]         = {351, "Permanent Diamond-Diamond"},
	["perm light"]           = {345, "Permanent Light-Light"},
	["perm rubber"]          = {369, "Permanent Rubber-Rubber"},
	["perm ghost"]           = {341, "Permanent Ghost-Ghost"},
	["perm revive"]          = {341, "Permanent Ghost-Ghost"},
	["perm magma"]           = {349, "Permanent Magma-Magma"},
	["perm quake"]           = {366, "Permanent Quake-Quake"},
	["perm buddha"]          = {372, "Permanent Buddha-Buddha"},
	["perm love"]            = {342, "Permanent Love-Love"},
	["perm creation"]        = {403, 376, "Permanent Creation-Creation", "Permanent Barrier-Barrier"},
	["perm barrier"]         = {376, 403, "Permanent Barrier-Barrier", "Permanent Creation-Creation"},
	["perm spider"]          = {380, "Permanent Spider-Spider"},
	["perm sound"]           = {346, "Permanent Sound-Sound"},
	["perm phoenix"]         = {370, "Permanent Phoenix-Phoenix"},
	["perm portal"]          = {368, "Permanent Portal-Portal"},
	["perm door"]            = {368, "Permanent Portal-Portal"},
	["perm lightning"]       = {449, 362, "Permanent Lightning-Lightning", "Permanent Rumble-Rumble"},
	["perm rumble"]          = {362, 449, "Permanent Rumble-Rumble", "Permanent Lightning-Lightning"},
	["perm pain"]            = {361, "Permanent Pain-Pain"},
	["perm paw"]             = {361, "Permanent Pain-Pain"},
	["perm blizzard"]        = {352, "Permanent Blizzard-Blizzard"},
	["perm gravity"]         = {365, "Permanent Gravity-Gravity"},
	["perm mammoth"]         = {354, "Permanent Mammoth-Mammoth"},
	["perm trex"]            = {375, "Permanent T-Rex-T-Rex"},
	["perm t-rex"]           = {375, "Permanent T-Rex-T-Rex"},
	["perm dough"]           = {373, "Permanent Dough-Dough"},
	["perm shadow"]          = {367, "Permanent Shadow-Shadow"},
	["perm venom"]           = {348, "Permanent Venom-Venom"},
	["perm gas"]             = {363, "Permanent Gas-Gas"},
	["perm spirit"]          = {383, "Permanent Spirit-Spirit"},
	["perm soul"]            = {383, "Permanent Spirit-Spirit"},
	["perm tiger"]           = {834, 364, "Permanent Tiger-Tiger", "Permanent Leopard-Leopard"},
	["perm leopard"]         = {364, 834, "Permanent Leopard-Leopard", "Permanent Tiger-Tiger"},
	["perm leo"]             = {834, 364, "Permanent Tiger-Tiger", "Permanent Leopard-Leopard"},
	["perm yeti"]            = {343, "Permanent Yeti-Yeti"},
	["perm magnet"]          = {1517, "Permanent Magnet-Magnet"},
	["perm kitsune"]         = {374, "Permanent Kitsune-Kitsune"},
	["perm control"]         = {358, "Permanent Control-Control"},
	["perm dragon"]          = {399, 844, 355, 356, 236, 382, "Permanent Dragon-Dragon", "Permanent Dragon Token", "Permanent Dragon (East)-Dragon (East)", "Permanent Dragon (West)-Dragon (West)", "Discounted Permanent Dragon", "Permanent Dragon (Classic)-Dragon (Classic)"},
	["perm dragon token"]    = {844, "Permanent Dragon Token"},

	-- =====================================================
	-- GAMEPASSES, SCROLLS & TOKENS
	-- =====================================================

	["fruit notifier"]       = {233, "Fruit Notifier"},
	["notifier"]             = {233, "Fruit Notifier"},
	["dark blade"]           = {190, 255, 1250, "Dark Blade"},
	["db"]                   = {190, 255, 1250, "Dark Blade"},
	["2x mastery"]           = {234, "2x Mastery"},
	["2x money"]             = {242, "2x Money"},
	["2x boss drops"]        = {244, "2x Boss Drops"},
	["fast boats"]           = {245, "Fast Boats"},
	["fruit storage"]        = {235, "+1 Fruit Storage"},
	["+1 fruit storage"]     = {235, "+1 Fruit Storage"},
	["+1 storage"]           = {235, "+1 Fruit Storage"},
	["storage"]              = {235, "+1 Fruit Storage"},
	["3x mythical scrolls"]  = {397, "3x Mythical Scrolls"},
	["5x legendary scrolls"] = {395, "5x Legendary Scrolls"},
	["mythical scroll"]      = {397, 239, 396, 399, 858, "3x Mythical Scrolls", "Mythical Scroll"},
	["legendary scroll"]     = {395, 238, 398, 401, 857, "5x Legendary Scrolls", "Legendary Scroll"},
	["dragon token"]         = {240, 844, 841, "Dragon Token (Tradable)", "Permanent Dragon Token", "Dragon Token (Physical)"},
	["permanent dragon token"] = {844, "Permanent Dragon Token"},

	-- =====================================================
	-- LIMITED SKINS & MUTATIONS
	-- =====================================================

	-- Dragon
	["ember"]                = {298, 334, 982, 264, 332, 948, 305, 387, 989, "WSTDSKINember", "ESTDSKINember", "EmberChromaticDragon"},
	["ember dragon"]         = {298, 334, 982, 264, 332, 948, 305, 387, 989, "WSTDSKINember", "ESTDSKINember", "EmberChromaticDragon"},
	["west ember"]           = {298, 334, 982, "WSTDSKINember"},
	["east ember"]           = {264, 332, 948, "ESTDSKINember"},

	["eclipse"]              = {271, 331, 955, 281, 333, 965, 303, 385, 987, "WSTDSKINeclipse", "ESTDSKINeclipse", "EclipseChromaticDragon"},
	["eclipse dragon"]       = {271, 331, 955, 281, 333, 965, 303, 385, 987, "WSTDSKINeclipse", "ESTDSKINeclipse", "EclipseChromaticDragon"},
	["west eclipse"]         = {271, 331, 955, "WSTDSKINeclipse"},
	["east eclipse"]         = {281, 333, 965, "ESTDSKINeclipse"},

	["blood moon"]           = {286, 336, 970, 273, 337, 957, 306, 389, 990, "WSTDSKINbloodmoon", "ESTDSKINbloodmoon", "BloodmoonChromaticDragon"},
	["blood moon dragon"]    = {286, 336, 970, 273, 337, 957, 306, 389, 990, "WSTDSKINbloodmoon", "ESTDSKINbloodmoon", "BloodmoonChromaticDragon"},
	["west blood moon"]      = {286, 336, 970, "WSTDSKINbloodmoon"},
	["east blood moon"]      = {273, 337, 957, "ESTDSKINbloodmoon"},

	["phoenix sky"]          = {268, 330, 952, 274, 328, 958, 302, 386, 986, "WSTDSKINphoenixsky", "ESTDSKINphoenixsky", "PhoenixSkyChromaticDragon"},
	["phoenix sky dragon"]   = {268, 330, 952, 274, 328, 958, 302, 386, 986, "WSTDSKINphoenixsky", "ESTDSKINphoenixsky", "PhoenixSkyChromaticDragon"},
	["west phoenix sky"]     = {268, 330, 952, "WSTDSKINphoenixsky"},
	["east phoenix sky"]     = {274, 328, 958, "ESTDSKINphoenixsky"},

	["violet night"]         = {258, 329, 942, 299, 335, 983, 304, 388, 988, "WSTDSKINvioletnight", "ESTDSKINvioletnight", "VioletNightChromaticDragon"},
	["violet night dragon"]  = {258, 329, 942, 299, 335, 983, 304, 388, 988, "WSTDSKINvioletnight", "ESTDSKINvioletnight", "VioletNightChromaticDragon"},
	["west violet night"]    = {258, 329, 942, "WSTDSKINvioletnight"},
	["east violet night"]    = {299, 335, 983, "ESTDSKINvioletnight"},

	-- Kitsune
	["crimson"]              = {1045, 1055, "KYUKONSKINcrimson"},
	["crimson kitsune"]      = {1045, 1055, "KYUKONSKINcrimson"},
	["galaxy"]               = {1046, 1056, 1042, "KYUKONSKINgalaxy", "Galaxy Empyrean Kitsune"},
	["galaxy kitsune"]       = {1046, 1056, 1042, "KYUKONSKINgalaxy", "Galaxy Empyrean Kitsune"},
	["empyrean kitsune"]     = {1041, 1059, 1433, "Empyrean (Kitsune)-Empyrean (Kitsune)"},
	["empyrean"]             = {1041, 1059, 1433, "Empyrean (Kitsune)-Empyrean (Kitsune)"},

	-- Pain
	["sadness"]              = {479, "Sadness Pain"},
	["sadness pain"]         = {479, "Sadness Pain"},
	["torment"]              = {491, "Torment Pain"},
	["torment pain"]         = {491, "Torment Pain"},
	["frustration"]          = {492, "Frustration Pain"},
	["frustration pain"]     = {492, "Frustration Pain"},
	["celestial"]            = {500, 1019, 498, "PAINSKINcelestial", "Celestial Pain"},
	["celestial pain"]       = {500, 1019, 498, "PAINSKINcelestial", "Celestial Pain"},
	["super spirit"]         = {538, 1029, 541, "PAINSKINsuperspirit", "Super Spirit Pain"},
	["super spirit pain"]    = {538, 1029, 541, "PAINSKINsuperspirit", "Super Spirit Pain"},

	-- Lightning Skins
	["yellow lightning"]     = {451, 998, 450, "LIGHTNINGSKINyellow", "Yellow Lightning"},
	["purple lightning"]     = {464, 1005, 460, "LIGHTNINGSKINpurple", "Purple Lightning"},
	["green lightning"]      = {465, 1006, 462, "LIGHTNINGSKINgreen", "Green Lightning"},
	["red lightning"]        = {537, 1028, 540, "LIGHTNINGSKINred", "Red Lightning"},
	["blue lightning"]       = {461, 1004, "LIGHTNINGSKINblue"},

	-- Portal
	["divine"]               = {1049, 1057, 1048, "PORTALSKINdivine", "Divine Portal"},
	["divine portal"]        = {1049, 1057, 1048, "PORTALSKINdivine", "Divine Portal"},
	["pink portal"]          = {453, 1000, "PORTALSKINpink"},
	["orange portal"]        = {457, 1003, "PORTALSKINorange"},
	["blue portal"]          = {466, 1007, "PORTALSKINblue"},

	-- Diamond
	["emerald"]              = {456, 1002, 471, "DIAMONDSKINgreen", "Emerald Diamond"},
	["emerald diamond"]      = {456, 1002, 471, "DIAMONDSKINgreen", "Emerald Diamond"},
	["rose quartz"]          = {472, 1008, 470, "DIAMONDSKINpoudretteite", "Rose Quartz Diamond"},
	["rose quartz diamond"]  = {472, 1008, 470, "DIAMONDSKINpoudretteite", "Rose Quartz Diamond"},
	["topaz"]                = {473, 1009, 469, "DIAMONDSKINtopaz", "Topaz Diamond"},
	["topaz diamond"]        = {473, 1009, 469, "DIAMONDSKINtopaz", "Topaz Diamond"},
	["ruby"]                 = {455, 1001, 468, "DIAMONDSKINred", "Ruby Diamond"},
	["ruby diamond"]         = {455, 1001, 468, "DIAMONDSKINred", "Ruby Diamond"},

	-- Eagle
	["glacier"]              = {499, 1018, 496, "FALCSKINglacier", "Glacier Eagle"},
	["glacier eagle"]        = {499, 1018, 496, "FALCSKINglacier", "Glacier Eagle"},
	["requiem"]              = {501, 1020, 495, "FALCSKINrequiem", "Requiem Eagle"},
	["requiem eagle"]        = {501, 1020, 495, "FALCSKINrequiem", "Requiem Eagle"},
	["matrix"]               = {497, 1017, 502, "FALCSKINmatrix", "Matrix Eagle"},
	["matrix eagle"]         = {497, 1017, 502, "FALCSKINmatrix", "Matrix Eagle"},
	["matrix parrot"]        = {497, 1017, 502, 404, 991, "FALCSKINmatrix", "Matrix Eagle", "FALCSKINparrot"},
	["parrot"]               = {404, 991, "FALCSKINparrot"},
	["parrot eagle"]         = {404, 991, "FALCSKINparrot"},

	-- Bomb
	["nuclear"]              = {506, 1021, 508, "BOMBSKINnuclear", "Nuclear Bomb"},
	["nuclear bomb"]         = {506, 1021, 508, "BOMBSKINnuclear", "Nuclear Bomb"},
	["thermite"]             = {528, 1025, 511, "BOMBSKINthermite", "Thermite Bomb"},
	["thermite bomb"]        = {528, 1025, 511, "BOMBSKINthermite", "Thermite Bomb"},
	["azura"]                = {529, 1026, 512, "BOMBSKINazura", "Azura Bomb"},
	["azura bomb"]           = {529, 1026, 512, "BOMBSKINazura", "Azura Bomb"},
	["celebration"]          = {536, 1027, 539, "BOMBSKINcelebration", "Celebration Bomb"},
	["celebration bomb"]     = {536, 1027, 539, "BOMBSKINcelebration", "Celebration Bomb"},

	-- Magnet / Yeti / Gravity / Blade / Tiger / Gas
	["arcsteel"]             = {1538, 1525, "MAGNETSKINarksteel", "Arcsteel Magnet"},
	["arcsteel magnet"]      = {1538, 1525, "MAGNETSKINarksteel", "Arcsteel Magnet"},
	["runic"]                = {1532, 1522, "FIENDSKINsealed", "Sealed Fiend"},
	["runic yeti"]           = {1532, 1522, "FIENDSKINsealed", "Sealed Fiend"},
	["runic fiend"]          = {1532, 1522, "FIENDSKINsealed", "Sealed Fiend"},
	["fiend"]                = {1063, 1068, 1061, 1066, 1060, 1065, 1434, "YETISKINfiend", "YETIMUTFiend", "Fiend (Yeti)-Fiend (Yeti)"},
	["fiend yeti"]           = {1063, 1068, 1061, 1066, 1060, 1065, 1434, "YETISKINfiend", "YETIMUTFiend", "Fiend (Yeti)-Fiend (Yeti)"},
	["starlight"]            = {1534, 1523, "GRAVITYSKINheavenly", "Heavenly Gravity"},
	["starlight gravity"]    = {1534, 1523, "GRAVITYSKINheavenly", "Heavenly Gravity"},
	["heavenly gravity"]     = {1534, 1523, "GRAVITYSKINheavenly", "Heavenly Gravity"},
	["lime"]                 = {1540, 1526, "BLADESKINlime", "Lime Blade"},
	["lime blade"]           = {1540, 1526, "BLADESKINlime", "Lime Blade"},
	["werewolf"]             = {818, 1033, 815, 1030, 814, 1058, 1432, "TIGERSKINwerewolf", "TIGERMUTWerewolf", "Werewolf (Tiger)-Werewolf (Tiger)"},
	["werewolf tiger"]       = {818, 1033, 815, 1030, 814, 1058, 1432, "TIGERSKINwerewolf", "TIGERMUTWerewolf", "Werewolf (Tiger)-Werewolf (Tiger)"},
	["hellfire"]             = {1604, 1603, 1606, 1601, 1602, "HELLFIRESKINdefault", "GASMUTHellfire", "Hellfire (Gas)-Hellfire (Gas)"},
	["hellfire gas"]         = {1604, 1603, 1606, 1601, 1602, "HELLFIRESKINdefault", "GASMUTHellfire", "Hellfire (Gas)-Hellfire (Gas)"},

	-- =====================================================
	-- LIMITED BANNERS & SWORD SKINS
	-- =====================================================

	["dog blade"]            = {1482, 1486, 1483, "The Sword Of The Brat", "BRATSKINdefault"},
	["the sword of the brat"]= {1482, 1486, 1483, "The Sword Of The Brat", "BRATSKINdefault"},
	["sword of the brat"]    = {1482, 1486, "The Sword Of The Brat"},
	["rabid"]                = {1487, 1484, "BRATSKINslayer"},
	["rabid skin"]           = {1487, 1484, "BRATSKINslayer"},
	["dog house"]            = {1485, 1488, 1489, 1490, "DogHouseGacha26", "Doge"},
	["doghouse"]             = {1485, 1488, 1489, 1490, "DogHouseGacha26", "Doge"},
	["dog house (frame break)"] = {1485, 1488, 1489, 1490, "DogHouseGacha26", "Doge"},
	["doghouse (frame break)"]  = {1485, 1488, 1489, 1490, "DogHouseGacha26", "Doge"},
	["vibe"]                 = {1479, 1481, 1478, "Heartbreak", "Aurora Sky", "Lover"},
	["vibes"]                = {1479, 1481, 1478, "Heartbreak", "Aurora Sky", "Lover"},
	["vibe (frame break)"]   = {1479, 1481, 1478, "Heartbreak", "Aurora Sky", "Lover"},
	["vibes (frame break)"]  = {1479, 1481, 1478, "Heartbreak", "Aurora Sky", "Lover"},
}

-- =========================================================
-- 3. ITEM ALIASES & NORMALIZER
-- =========================================================

local Aliases = {
	["leo"]            = "leopard",
	["t rex"]          = "trex",
	["t-rex"]          = "trex",
	["lighting"]       = "lightning",
	["perm chop"]      = "perm blade",
	["perm falcon"]    = "perm eagle",
	["perm revive"]    = "perm ghost",
	["perm barrier"]   = "perm creation",
	["perm door"]      = "perm portal",
	["perm rumble"]    = "perm lightning",
	["perm paw"]       = "perm pain",
	["perm soul"]      = "perm spirit",
	["perm leopard"]   = "perm tiger",
	["perm leo"]       = "perm tiger",
	["perm t-rex"]     = "perm trex",
	["perm t rex"]     = "perm trex",
}

local function normalizeName(name)
	name = tostring(name or ""):lower()
	name = name:match("^%s*(.-)%s*$") or ""
	name = name:gsub("^<(.-)>$", "%1")
	name = name:match("^%s*(.-)%s*$") or ""

	-- Automatically handle "permanent " prefix to "perm "
	name = name:gsub("^permanent%s+", "perm ")

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

	-- Support: !add phy rocket / !add base rocket
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
-- 6. TRY ADDING ITEM (With Sequential Testing)
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

	-- Server returns false when the item cannot be added
	if result == false then
		return "rejected"
	end

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
	-- A. Try owned numeric IDs first (in registry order)
	-- -----------------------------------------------------

	for _, itemId in ipairs(numericCandidates) do
		if ownedIds[itemId] and not attempted[itemId] then
			attempted[itemId] = true

			print("[Trade] Trying owned numeric ID:", itemId, itemName)

			local result = tryAddIdentifier(itemId)

			if result == "success" then
				print(
					"[Trade] [+] Successfully added:",
					itemName,
					"| ItemId:",
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
	-- B. Try owned string StorageKeys
	-- -----------------------------------------------------

	if not added and not uncertain then
		for _, storageKey in ipairs(stringCandidates) do
			local normalizedKey = storageKey:lower()

			if ownedStorageKeys[normalizedKey] and not attempted[storageKey] then
				attempted[storageKey] = true

				print("[Trade] Trying owned StorageKey:", storageKey, itemName)

				local result = tryAddIdentifier(storageKey)

				if result == "success" then
					print(
						"[Trade] [+] Successfully added:",
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

				print("[Trade] StorageKey rejected:", storageKey)
			end
		end
	end

	-- -----------------------------------------------------
	-- C. Fallback: If client cache didn't flag it as owned,
	--    try all candidate IDs and keys sequentially anyway
	-- -----------------------------------------------------

	if not added and not uncertain then
		for _, candidate in ipairs(entry) do
			if not attempted[candidate] then
				attempted[candidate] = true

				print("[Trade] Testing fallback identifier:", candidate, "(" .. type(candidate) .. ")")

				local result = tryAddIdentifier(candidate)

				if result == "success" then
					print(
						"[Trade] [+] Successfully added via fallback:",
						itemName,
						"| Identifier:",
						candidate
					)
					added = true
					break
				elseif result == "error" then
					uncertain = true
					break
				end

				task.wait(0.1)
			end
		end
	end

	-- -----------------------------------------------------
	-- D. Final Result
	-- -----------------------------------------------------

	if added then
		print("[Trade] Finished adding:", itemName)
	elseif uncertain then
		warn(
			"[Trade] Result uncertain for:",
			itemName,
			"| Stopped to prevent possible duplicate."
		)
	else
		warn(
			"[Trade] Could not add item (not in inventory or table full):",
			itemName
		)
	end

	isAdding = false
end

-- =========================================================
-- 6A2. TRY REMOVING ITEM FROM TRADE TABLE
-- =========================================================

local function tryRemoveIdentifier(identifier)
	local callOk, result = pcall(function()
		return TradeFunction:InvokeServer(
			"removeItem",
			identifier
		)
	end)

	if not callOk then
		warn(
			"[Trade] Remove remote call error:",
			result
		)
		return "error"
	end

	if result == false or result == nil then
		return "rejected"
	end

	return "success"
end

local function removeItem(rawInput)
	if isRemoving then
		warn("[Trade] Another remove request is already running.")
		return
	end

	local entry, itemName, status = getRegistryEntry(rawInput)

	if not entry then
		warn("[Trade] Item not found in registry:", rawInput)
		return
	end

	isRemoving = true

	local removed = false
	local uncertain = false

	for _, candidate in ipairs(entry) do
		print("[Trade] Trying remove identifier:", candidate, itemName)

		local result = tryRemoveIdentifier(candidate)

		if result == "success" then
			print(
				"[Trade] [-] Successfully removed:",
				itemName,
				"| Identifier:",
				candidate
			)
			removed = true
			break
		elseif result == "error" then
			uncertain = true
			break
		end

		task.wait(0.1)
	end

	if removed then
		print("[Trade] Finished removing:", itemName)
	elseif uncertain then
		warn(
			"[Trade] Remove result uncertain for:",
			itemName
		)
	else
		warn(
			"[Trade] Could not remove item from trade table:",
			itemName
		)
	end

	isRemoving = false
end

-- =========================================================
-- 6B. TRADE ACTION HANDLER (!accept / !cancel)
-- =========================================================

local function InvokeTradeAction(action)
	if not TradeFunction then
		warn("[ERROR] TradeFunction remote missing!")
		return
	end

	print("[DEBUG] Processing action via verified remote layout:", action)

	pcall(function()
		if action == "accept" or action == "!accept" then
			local args = { "accept" }
			TradeFunction:InvokeServer(unpack(args))
			print("[TRADE] !accept command executed")
		elseif action == "cancel" or action == "!cancel" then
			local args = { "cancel" }
			TradeFunction:InvokeServer(unpack(args))
			print("[TRADE] !cancel command executed")
		else
			warn("[TRADE] Unknown command:", action)
		end
	end)
end

-- =========================================================
-- 6C. RESET FRUIT / SKIN FROM TREASURE
-- =========================================================

local ResetDisplayNames = {
	-- Physical Fruits
	["rocket"] = "Rocket",
	["spin"] = "Spin",
	["blade"] = "Blade",
	["chop"] = "Blade",
	["spring"] = "Spring",
	["bomb"] = "Bomb",
	["smoke"] = "Smoke",
	["spike"] = "Spike",
	["flame"] = "Flame",
	["ice"] = "Ice",
	["sand"] = "Sand",
	["dark"] = "Dark",
	["eagle"] = "Eagle",
	["falcon"] = "Eagle",
	["diamond"] = "Diamond",
	["light"] = "Light",
	["rubber"] = "Rubber",
	["ghost"] = "Ghost",
	["revive"] = "Ghost",
	["magma"] = "Magma",
	["quake"] = "Quake",
	["buddha"] = "Buddha",
	["love"] = "Love",
	["creation"] = "Creation",
	["barrier"] = "Creation",
	["spider"] = "Spider",
	["sound"] = "Sound",
	["phoenix"] = "Phoenix",
	["portal"] = "Portal",
	["door"] = "Portal",
	["lightning"] = "Lightning",
	["rumble"] = "Lightning",
	["pain"] = "Pain",
	["paw"] = "Pain",
	["blizzard"] = "Blizzard",
	["gravity"] = "Gravity",
	["mammoth"] = "Mammoth",
	["trex"] = "T-Rex",
	["t-rex"] = "T-Rex",
	["dough"] = "Dough",
	["shadow"] = "Shadow",
	["venom"] = "Venom",
	["gas"] = "Gas",
	["spirit"] = "Spirit",
	["soul"] = "Spirit",
	["tiger"] = "Tiger",
	["leopard"] = "Tiger",
	["leo"] = "Tiger",
	["yeti"] = "Yeti",
	["magnet"] = "Magnet",
	["kitsune"] = "Kitsune",
	["control"] = "Control",
	["dragon west"] = "Dragon (West)",
	["west dragon"] = "Dragon (West)",
	["dragon east"] = "Dragon (East)",
	["east dragon"] = "Dragon (East)",
	["dragon"] = "Dragon",

	-- Limited Fruit Skins
	["ember"] = "Ember",
	["ember dragon"] = "Ember",
	["west ember"] = "West Ember",
	["east ember"] = "East Ember",
	["eclipse"] = "Eclipse",
	["eclipse dragon"] = "Eclipse",
	["west eclipse"] = "West Eclipse",
	["east eclipse"] = "East Eclipse",
	["blood moon"] = "Blood Moon",
	["blood moon dragon"] = "Blood Moon",
	["west blood moon"] = "West Blood Moon",
	["east blood moon"] = "East Blood Moon",
	["phoenix sky"] = "Phoenix Sky",
	["phoenix sky dragon"] = "Phoenix Sky",
	["west phoenix sky"] = "West Phoenix Sky",
	["east phoenix sky"] = "East Phoenix Sky",
	["violet night"] = "Violet Night",
	["violet night dragon"] = "Violet Night",
	["west violet night"] = "West Violet Night",
	["east violet night"] = "East Violet Night",

	["crimson"] = "Crimson",
	["crimson kitsune"] = "Crimson Kitsune",
	["galaxy"] = "Galaxy",
	["galaxy kitsune"] = "Galaxy Kitsune",
	["empyrean kitsune"] = "Empyrean Kitsune",
	["empyrean"] = "Empyrean",

	["sadness"] = "Sadness",
	["sadness pain"] = "Sadness Pain",
	["torment"] = "Torment",
	["torment pain"] = "Torment Pain",
	["frustration"] = "Frustration",
	["frustration pain"] = "Frustration Pain",
	["celestial"] = "Celestial",
	["celestial pain"] = "Celestial Pain",
	["super spirit"] = "Super Spirit",
	["super spirit pain"] = "Super Spirit Pain",

	["yellow lightning"] = "Yellow Lightning",
	["purple lightning"] = "Purple Lightning",
	["green lightning"] = "Green Lightning",
	["red lightning"] = "Red Lightning",
	["blue lightning"] = "Blue Lightning",

	["divine"] = "Divine",
	["divine portal"] = "Divine Portal",
	["pink portal"] = "Pink Portal",
	["orange portal"] = "Orange Portal",
	["blue portal"] = "Blue Portal",

	["emerald"] = "Emerald",
	["emerald diamond"] = "Emerald Diamond",
	["rose quartz"] = "Rose Quartz",
	["rose quartz diamond"] = "Rose Quartz Diamond",
	["topaz"] = "Topaz",
	["topaz diamond"] = "Topaz Diamond",
	["ruby"] = "Ruby",
	["ruby diamond"] = "Ruby Diamond",

	["glacier"] = "Glacier",
	["glacier eagle"] = "Glacier Eagle",
	["requiem"] = "Requiem",
	["requiem eagle"] = "Requiem Eagle",
	["matrix"] = "Matrix",
	["matrix eagle"] = "Matrix Eagle",
	["matrix parrot"] = "Matrix Parrot",
	["parrot"] = "Parrot",
	["parrot eagle"] = "Parrot Eagle",

	["nuclear"] = "Nuclear",
	["nuclear bomb"] = "Nuclear Bomb",
	["thermite"] = "Thermite",
	["thermite bomb"] = "Thermite Bomb",
	["azura"] = "Azura",
	["azura bomb"] = "Azura Bomb",
	["celebration"] = "Celebration",
	["celebration bomb"] = "Celebration Bomb",

	["arcsteel"] = "Arcsteel",
	["arcsteel magnet"] = "Arcsteel Magnet",
	["runic"] = "Runic",
	["runic yeti"] = "Runic Yeti",
	["runic fiend"] = "Runic Fiend",
	["fiend"] = "Fiend",
	["fiend yeti"] = "Fiend Yeti",
	["starlight"] = "Starlight",
	["starlight gravity"] = "Starlight Gravity",
	["heavenly gravity"] = "Heavenly Gravity",
	["lime"] = "Lime",
	["lime blade"] = "Lime Blade",
	["werewolf"] = "Werewolf",
	["werewolf tiger"] = "Werewolf Tiger",
	["hellfire"] = "Hellfire",
	["hellfire gas"] = "Hellfire Gas",
}

local function resetNormalize(text)
	return tostring(text or "")
		:lower()
		:gsub("%s+", " ")
		:match("^%s*(.-)%s*$")
end

local function isResetGuiVisible(gui)
	if not gui then
		return false
	end
	local cur = gui
	while cur and cur ~= PlayerGui do
		if cur:IsA("ScreenGui") and not cur.Enabled then
			return false
		end
		if cur:IsA("GuiObject") and not cur.Visible then
			return false
		end
		cur = cur.Parent
	end
	if gui:IsA("GuiObject") then
		return gui.AbsoluteSize.X > 1 and gui.AbsoluteSize.Y > 1
	end
	return true
end

local function clickResetButton(button)
	if not button or not button:IsA("GuiObject") then
		return false
	end

	if typeof(firesignal) == "function" then
		pcall(function() firesignal(button.MouseButton1Click) end)
		pcall(function() firesignal(button.Activated) end)
	end
	if button:IsA("GuiButton") then
		pcall(function() button:Activate() end)
	end

	local inset = GuiService:GetGuiInset()
	local pos = button.AbsolutePosition
	local size = button.AbsoluteSize
	local x = pos.X + (size.X * 0.5)
	local y = pos.Y + (size.Y * 0.5) + inset.Y

	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
		task.wait(0.05)
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
	end)

	return true
end

local function findResetTextBox(parent)
	if not parent then
		return nil
	end
	if parent:IsA("TextBox") then
		return parent
	end
	for _, obj in ipairs(parent:GetDescendants()) do
		if obj:IsA("TextBox") then
			return obj
		end
	end
	return nil
end

local function openResetTreasure()
	local invGui = PlayerGui:FindFirstChild("Inventory")
	local invInner = invGui and invGui:FindFirstChild("Inventory")
	local main = invInner and invInner:FindFirstChild("Main")

	if not isResetGuiVisible(main) then
		local menuBtn = PlayerGui:FindFirstChild("HUDRoot")
			and PlayerGui.HUDRoot:FindFirstChild("Menu", true)
		local itemsBtn = PlayerGui:FindFirstChild("HUDRoot")
			and PlayerGui.HUDRoot:FindFirstChild("Items", true)

		local menuExact = PlayerGui:FindFirstChild("HUDRoot")
		if menuExact then
			local m = menuExact:FindFirstChild("Menu", true)
			local it = menuExact:FindFirstChild("Items", true)
			if m and not isResetGuiVisible(it) then
				clickResetButton(m)
				task.wait(0.35)
				it = menuExact:FindFirstChild("Items", true)
			end
			if it and isResetGuiVisible(it) then
				clickResetButton(it)
				task.wait(0.45)
			end
		end

		invGui = PlayerGui:FindFirstChild("Inventory")
		invInner = invGui and invGui:FindFirstChild("Inventory")
		main = invInner and invInner:FindFirstChild("Main")
	end

	if not invInner or not main then
		warn("[Reset] Inventory Main panel not found.")
		return nil, nil
	end

	local nav = main:FindFirstChild("NavigationRail")
	local treasureButton = nav and nav:FindFirstChild("Category2")

	if not treasureButton then
		warn("[Reset] Treasure button (Category2) not found.")
		return nil, nil
	end

	clickResetButton(treasureButton)
	task.wait(0.4)

	local pageContent = main:FindFirstChild("PageContent")
	local grid = pageContent and pageContent:FindFirstChild("TileGrid")

	if not grid then
		warn("[Reset] Treasure TileGrid not found.")
		return nil, nil
	end

	return invInner, grid
end

local function searchResetTreasure(invInner, query)
	local main = invInner and invInner:FindFirstChild("Main")
	local pageContent = main and main:FindFirstChild("PageContent")
	local toolbar = pageContent and pageContent:FindFirstChild("ToolBar")
	local searchField = toolbar and toolbar:FindFirstChild("SearchTextField")

	if not searchField then
		warn("[Reset] SearchTextField not found.")
		return false
	end

	clickResetButton(searchField)
	task.wait(0.15)

	local searchBox = findResetTextBox(searchField) or findResetTextBox(toolbar)
	if not searchBox then
		warn("[Reset] Search TextBox not found.")
		return false
	end

	searchBox:CaptureFocus()
	searchBox.Text = query
	searchBox:ReleaseFocus(true)

	task.wait(0.35)
	return true
end

local function getResetTileName(tile)
	local details = tile:FindFirstChild("Details")
	if not details then
		return ""
	end

	local line1 = details:FindFirstChild("Line-1")
	local line2 = details:FindFirstChild("Line-2")

	local first = (line1 and line1:IsA("TextLabel") and line1.Text) or ""
	local second = (line2 and line2:IsA("TextLabel") and line2.Text) or ""

	if first ~= "" and second ~= "" then
		return resetNormalize(first .. " " .. second)
	end

	return resetNormalize(first ~= "" and first or second)
end

local function findResetTile(grid, displayName)
	local wanted = resetNormalize(displayName)

	for _, tile in ipairs(grid:GetChildren()) do
		if tile:IsA("GuiButton") and isResetGuiVisible(tile) then
			local details = tile:FindFirstChild("Details")
			local category = details and details:FindFirstChild("Category")
			local categoryName = (category and category:IsA("TextLabel") and category.Text) or ""

			local tileName = getResetTileName(tile)

			if resetNormalize(categoryName) == "blox fruit" and tileName == wanted then
				return tile
			end
		end
	end

	return nil
end

local function equipResetTile(invInner, tile, displayName)
	if not tile then
		return false
	end

	clickResetButton(tile)
	task.wait(0.4)

	local rightCard = invInner and invInner:FindFirstChild("RightCard")
	if not rightCard or not isResetGuiVisible(rightCard) then
		warn("[Reset] RightCard not found or not visible.")
		return false
	end

	-- Verify RightCard title matches requested displayName before equipping
	local wanted = resetNormalize(displayName)
	local titleMatched = false
	for _, lbl in ipairs(rightCard:GetDescendants()) do
		if lbl:IsA("TextLabel") and isResetGuiVisible(lbl) and resetNormalize(lbl.Text) == wanted then
			titleMatched = true
			break
		end
	end
	if not titleMatched then
		warn("[Reset] RightCard title did not match expected item:", displayName)
		return false
	end

	local itemCard = rightCard:FindFirstChild("ItemCard")
	local buttons = itemCard and itemCard:FindFirstChild("Buttons")
	local equipButton = buttons and buttons:FindFirstChild("Action-EquipFruit")

	if not equipButton or not isResetGuiVisible(equipButton) then
		warn("[Reset] Action-EquipFruit button is unavailable.")
		return false
	end

	return clickResetButton(equipButton)
end

local function resetCharacterAndWait()
	local oldCharacter = LocalPlayer.Character

	if not oldCharacter then
		warn("[Reset] Character not found.")
		return false
	end

	local humanoid = oldCharacter:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		warn("[Reset] Character cannot be reset.")
		return false
	end

	local newCharacter = nil
	local connection = LocalPlayer.CharacterAdded:Connect(function(character)
		if character ~= oldCharacter then
			newCharacter = character
		end
	end)

	humanoid.Health = 0

	local startTime = os.clock()

	while not newCharacter and os.clock() - startTime < 15 do
		task.wait(0.1)
	end

	connection:Disconnect()

	if not newCharacter then
		warn("[Reset] Respawn timed out.")
		return false
	end

	local newHumanoid = newCharacter:WaitForChild("Humanoid", 10)

	if not newHumanoid then
		warn("[Reset] New Humanoid not found.")
		return false
	end

	print("[Reset] Character respawned successfully.")
	return true
end

local function resetFruitItem(rawInput)
	if isResetting then
		warn("[Reset] Another reset is already running.")
		return
	end

	local entry, itemName, status = getRegistryEntry(rawInput)

	if not entry or status ~= "found" then
		warn("[Reset] Item not found in registry:", rawInput)
		return
	end

	local displayName = ResetDisplayNames[itemName]
	if not displayName then
		warn("[Reset] Item type is not supported by !reset:", itemName)
		return
	end

	isResetting = true

	local success, result = pcall(function()
		print("[Reset] Searching Treasure for:", displayName)

		local invInner, grid = openResetTreasure()

		if not invInner or not grid then
			return false
		end

		if not searchResetTreasure(invInner, displayName) then
			return false
		end

		local tile = findResetTile(grid, displayName)

		if not tile then
			warn("[Reset] Exact Treasure item not found:", displayName)
			return false
		end

		print("[Reset] Matching Treasure tile:", displayName)

		if not equipResetTile(invInner, tile, displayName) then
			warn("[Reset] Could not equip:", displayName)
			return false
		end

		task.wait(0.5)

		print("[Reset] Equipped. Resetting character...")

		return resetCharacterAndWait()
	end)

	isResetting = false

	if not success then
		warn("[Reset] Error:", result)
	elseif result then
		print("[Reset] Completed:", itemName)
	else
		warn("[Reset] Failed:", itemName)
	end
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

	if lowerText == "!accept" or lowerText == "!cancel" then
		local now = os.clock()
		if lowerText == lastText and (now - lastTime) < DUPLICATE_COOLDOWN then
			return
		end
		lastText = lowerText
		lastTime = now
		InvokeTradeAction(lowerText)
		return
	end

	-- !reset <fruitname>
	if lowerText:sub(1, #RESET_PREFIX) == RESET_PREFIX then
		local now = os.clock()

		if lowerText == lastText
			and (now - lastTime) < DUPLICATE_COOLDOWN then
			return
		end

		lastText = lowerText
		lastTime = now

		local targetInput = cleanText:sub(#RESET_PREFIX + 1)
		targetInput = targetInput:match("^%s*(.-)%s*$")

		if targetInput == "" then
			warn("[Reset] Usage: !reset <fruit name>")
			return
		end

		task.spawn(function()
			resetFruitItem(targetInput)
		end)

		return
	end

	if lowerText:sub(1, #REMOVE_PREFIX) == REMOVE_PREFIX then
		local now = os.clock()
		if lowerText == lastText and (now - lastTime) < DUPLICATE_COOLDOWN then
			return
		end
		lastText = lowerText
		lastTime = now

		local targetInput = cleanText:sub(#REMOVE_PREFIX + 1)
		targetInput = targetInput:match("^%s*(.-)%s*$")

		if targetInput == "" then
			warn("[Trade] Usage: !remove <item name>")
			return
		end

		removeItem(targetInput)
		return
	end

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
			if message.TextSource then
				local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
				if sender and IsAuthorized(sender.Name) then
					handleChatCommand(message.Text)
				end
			end
		end)
	)
else
	for _, plr in ipairs(Players:GetPlayers()) do
		if IsAuthorized(plr.Name) then
			table.insert(
				_G.TradeAddConnections,
				plr.Chatted:Connect(handleChatCommand)
			)
		end
	end
	table.insert(
		_G.TradeAddConnections,
		Players.PlayerAdded:Connect(function(plr)
			if IsAuthorized(plr.Name) then
				table.insert(
					_G.TradeAddConnections,
					plr.Chatted:Connect(handleChatCommand)
				)
			end
		end)
	)
end

-- =========================================================
-- 8B. STRICT WHITELIST AUTO-SIT & TABLE SWITCHING
-- =========================================================

local function TweenToSeat(hrp, targetCFrame)
	local distance = (hrp.Position - targetCFrame.Position).Magnitude
	local speed = 150
	local duration = math.clamp(distance / speed, 0.2, 1.5)

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
	tween:Play()
	tween.Completed:Wait()
end

local function IsTradeTableSeat(seat)
	local parent = seat.Parent
	return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
end

local function GetUnauthorizedPlayerInSeat(seat)
	-- 1. Primary check: actual seat occupant
	local occupant = seat.Occupant

	if occupant then
		local character = occupant.Parent
		local player = character and Players:GetPlayerFromCharacter(character)

		if player and player ~= LocalPlayer then
			if not IsAuthorized(player.Name) then
				return player.Name
			end
		end

		-- A real occupant exists; don't run spatial fallback.
		return nil
	end

	-- 2. Fallback: check only when Occupant is empty
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	if LocalPlayer.Character then
		overlapParams.FilterDescendantsInstances = { LocalPlayer.Character }
	end

	local parts = Workspace:GetPartsInPart(seat, overlapParams)
	local checkedPlayers = {}

	for _, part in ipairs(parts) do
		local character = part:FindFirstAncestorOfClass("Model")

		if character and not checkedPlayers[character] then
			checkedPlayers[character] = true

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local hrp = character:FindFirstChild("HumanoidRootPart")

			if humanoid and hrp and not humanoid.SeatPart then
				local player = Players:GetPlayerFromCharacter(character)

				if player and player ~= LocalPlayer then
					local distance = (hrp.Position - seat.Position).Magnitude

					-- Require the character to be very close to the seat.
					if distance <= 4 and humanoid.Health > 0 then
						if not IsAuthorized(player.Name) then
							return player.Name
						end
					end
				end
			end
		end
	end

	return nil
end

local function IsTableBlocked(tableModel)
	for _, child in ipairs(tableModel:GetChildren()) do
		if child:IsA("Seat") and IsTradeTableSeat(child) then
			local unauth = GetUnauthorizedPlayerInSeat(child)
			if unauth then
				return true
			end
		end
	end
	return false
end

task.spawn(function()
	local lastTable = nil
	local jumpCooldown = 0

	while true do
		task.wait(0.5)

		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
		local hrp = character.HumanoidRootPart
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then continue end

		if humanoid.SeatPart then
			local currentSeat = humanoid.SeatPart
			if IsTradeTableSeat(currentSeat) then
				lastTable = currentSeat.Parent

				local tableModel = currentSeat.Parent
				local unauthorizedFound = nil

				for _, child in ipairs(tableModel:GetChildren()) do
					if child:IsA("Seat") and IsTradeTableSeat(child) then
						local unauthName = GetUnauthorizedPlayerInSeat(child)
						if unauthName then
							unauthorizedFound = unauthName
							break
						end
					end
				end

				if unauthorizedFound then
					task.wait(2)
					humanoid.Sit = false
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					jumpCooldown = tick() + 2
					task.wait(0.8)
				end
			end
		else
			if tick() < jumpCooldown then continue end

			local bestSeat = nil
			local shortestDist = math.huge

			for _, obj in pairs(Workspace:GetDescendants()) do
				if obj:IsA("Seat") and IsTradeTableSeat(obj) then
					local tableModel = obj.Parent
					if obj.Parent ~= lastTable and not IsTableBlocked(tableModel) then
						local dist = (hrp.Position - obj.Position).Magnitude
						if dist < 800 and dist < shortestDist then
							shortestDist = dist
							bestSeat = obj
						end
					end
				end
			end

			if not bestSeat and lastTable then
				lastTable = nil
			end

			if bestSeat then
				local targetCF = bestSeat.CFrame + Vector3.new(0, 3, 0)
				TweenToSeat(hrp, targetCF)
				task.wait(0.2)
				if bestSeat
					and bestSeat.Parent
					and bestSeat.Occupant == nil
					and not IsTableBlocked(bestSeat.Parent)
					and humanoid.Health > 0
					and humanoid.SeatPart == nil then

					bestSeat:Sit(humanoid)
				end
			end
		end
	end
end)

-- =========================================================
-- 9. READY
-- =========================================================

print("========================================")
print("[Trade] Version 5 (Complete Registry) loaded!")
print("[Trade] Multi-ID + StorageKey Fallback active.")
print("[Trade] All Physical & Perm Fruits active.")
print("[Trade] All Gamepasses, Scrolls & Limited Skins active.")
print("[Trade] Command: !add <item> | !remove <item> | !reset <fruit> | !accept | !cancel")
print("[Trade] Examples: !add dragon | !add perm buddha | !add yellow lightning | !add storage")
print("========================================")
