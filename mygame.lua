-- =========================================================
-- BLOX FRUITS TRADE ADDER V5 + AUTO-SIT + !reset + !equip
-- (Merged: !add / !remove / !accept / !cancel / !reset / !equip)
-- =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local function getTradeFunction()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local tf = remotes and remotes:FindFirstChild("TradeFunction")
	if tf then return tf end

	local ok, res = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes", 10):WaitForChild("TradeFunction", 10)
	end)
	if ok and res then return res end

	-- Recursive fallback
	return ReplicatedStorage:FindFirstChild("TradeFunction", true)
end

local TradeFunction = getTradeFunction()
print("[Init] TradeFunction found:", tostring(TradeFunction ~= nil))

local ItemReplicationService = nil
local KEYS = nil
local ItemConfig = nil

task.spawn(function()
	local repMod = ReplicatedStorage:FindFirstChild("ItemReplicationService")
	if repMod and repMod:IsA("ModuleScript") then
		local ok, mod = pcall(require, repMod)
		if ok then
			ItemReplicationService = mod
			local keysMod = repMod:FindFirstChild("KEYS")
			if keysMod and keysMod:IsA("ModuleScript") then
				local kOk, kMod = pcall(require, keysMod)
				if kOk then
					KEYS = kMod
				end
			end
		end
	end

	local cfgMod = ReplicatedStorage:FindFirstChild("ItemConfig")
	if cfgMod and cfgMod:IsA("ModuleScript") then
		local cOk, cMod = pcall(require, cfgMod)
		if cOk then
			ItemConfig = cMod
		end
	end
end)

local function getCommF()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local cf = remotes:FindFirstChild("CommF_")
		if cf then return cf end
	end
	local ok, cf = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
	end)
	return ok and cf or nil
end

local CommF = getCommF()
print("[Init] CommF_ found:", tostring(CommF ~= nil))

-- =========================================================
-- 1. CONFIGURATION & SESSION CLEANUP
-- =========================================================

local COMMAND_PREFIX = "!add "
local REMOVE_PREFIX = "!remove "
local RESET_CMD = "!reset"
local EQUIP_PREFIX = "!equip "
local DUPLICATE_COOLDOWN = 1.0
local EQUIP_DUPLICATE_COOLDOWN = 0.8

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
local lastText = ""
local lastTime = 0

local autoSitPaused = false
local isEquipping = false
local lastCmdText = ""
local lastCmdTime = 0
local lastTable = nil

-- Disconnect old listeners when re-executed
if _G.TradeAddConnections then
	for _, connection in ipairs(_G.TradeAddConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
end

_G.TradeAddConnections = {}
_G.TradeAddSessionId = (_G.TradeAddSessionId or 0) + 1
local CURRENT_SESSION_ID = _G.TradeAddSessionId

local function isAutoSitBlocked()
	return autoSitPaused or isEquipping or isAdding or isRemoving
end

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
-- 4. GET OWNED INVENTORY (NIL-SAFE)
-- =========================================================

local function getItemMetadata(itemId)
	if not ItemConfig or type(ItemConfig.tryGet) ~= "function" then
		return "", ""
	end

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

	if not ItemReplicationService or not KEYS then
		return ownedIds, ownedStorageKeys
	end

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

	-- Server returns false or nil when the item cannot be added
	if result == false or result == nil then
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

	if not entry or status ~= "found" then
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

	-- A. Try owned numeric IDs first
	for _, itemId in ipairs(numericCandidates) do
		if ownedIds[itemId] and not attempted[itemId] then
			attempted[itemId] = true
			local result = tryAddIdentifier(itemId)
			if result == "success" then
				print("[Trade] [+] Successfully added:", itemName, "| ItemId:", itemId)
				added = true
				break
			elseif result == "error" then
				uncertain = true
				break
			end
		end
	end

	-- B. Try owned string StorageKeys
	if not added and not uncertain then
		for _, storageKey in ipairs(stringCandidates) do
			local normalizedKey = storageKey:lower()
			if ownedStorageKeys[normalizedKey] and not attempted[storageKey] then
				attempted[storageKey] = true
				local result = tryAddIdentifier(storageKey)
				if result == "success" then
					print("[Trade] [+] Successfully added:", itemName, "| StorageKey:", storageKey)
					added = true
					break
				elseif result == "error" then
					uncertain = true
					break
				end
			end
		end
	end

	-- C. Fallback across all remaining candidates
	if not added and not uncertain then
		for _, candidate in ipairs(entry) do
			if not attempted[candidate] then
				attempted[candidate] = true
				local result = tryAddIdentifier(candidate)
				if result == "success" then
					print("[Trade] [+] Successfully added via fallback:", itemName, "| Identifier:", candidate)
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

	-- D. Final status
	if added then
		print("[Trade] Finished adding:", itemName)
	elseif uncertain then
		warn("[Trade] Result uncertain for:", itemName, "| Stopped to prevent possible duplicate.")
	else
		warn("[Trade] Could not add item (not in inventory or table full):", itemName)
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
			TradeFunction:InvokeServer((table.unpack or unpack)(args))
			print("[TRADE] !accept command executed")
		elseif action == "cancel" or action == "!cancel" then
			local args = { "cancel" }
			TradeFunction:InvokeServer((table.unpack or unpack)(args))
			print("[TRADE] !cancel command executed")
		else
			warn("[TRADE] Unknown command:", action)
		end
	end)
end

-- =========================================================
-- 7. FRUIT & SKIN STORAGE KEY MAPPING (for !equip)
-- =========================================================

local EquipAliases = {
	["leo"]         = "tiger",
	["leopard"]     = "tiger",
	["t rex"]       = "trex",
	["t-rex"]       = "trex",
	["lighting"]    = "lightning",
	["chop"]        = "blade",
	["falcon"]      = "eagle",
	["revive"]      = "ghost",
	["barrier"]     = "creation",
	["door"]        = "portal",
	["rumble"]      = "lightning",
	["paw"]         = "pain",
	["soul"]        = "spirit",
	["west dragon"] = "dragon west",
	["east dragon"] = "dragon east",
}

local FruitStorageKeys = {
	["rocket"]      = "Rocket-Rocket",
	["spin"]        = "Spin-Spin",
	["blade"]       = "Blade-Blade",
	["spring"]      = "Spring-Spring",
	["bomb"]        = "Bomb-Bomb",
	["smoke"]       = "Smoke-Smoke",
	["spike"]       = "Spike-Spike",
	["flame"]       = "Flame-Flame",
	["ice"]         = "Ice-Ice",
	["sand"]        = "Sand-Sand",
	["dark"]        = "Dark-Dark",
	["eagle"]       = "Eagle-Eagle",
	["diamond"]     = "Diamond-Diamond",
	["light"]       = "Light-Light",
	["rubber"]      = "Rubber-Rubber",
	["ghost"]       = "Ghost-Ghost",
	["magma"]       = "Magma-Magma",
	["quake"]       = "Quake-Quake",
	["buddha"]      = "Buddha-Buddha",
	["love"]        = "Love-Love",
	["creation"]    = "Creation-Creation",
	["spider"]      = "Spider-Spider",
	["sound"]       = "Sound-Sound",
	["phoenix"]     = "Phoenix-Phoenix",
	["portal"]      = "Portal-Portal",
	["lightning"]   = "Lightning-Lightning",
	["pain"]        = "Pain-Pain",
	["blizzard"]    = "Blizzard-Blizzard",
	["gravity"]     = "Gravity-Gravity",
	["mammoth"]     = "Mammoth-Mammoth",
	["trex"]        = "T-Rex-T-Rex",
	["dough"]       = "Dough-Dough",
	["shadow"]      = "Shadow-Shadow",
	["venom"]       = "Venom-Venom",
	["gas"]         = "Gas-Gas",
	["spirit"]      = "Spirit-Spirit",
	["tiger"]       = "Tiger-Tiger",
	["yeti"]        = "Yeti-Yeti",
	["magnet"]      = "Magnet-Magnet",
	["kitsune"]     = "Kitsune-Kitsune",
	["control"]     = "Control-Control",
	["dragon west"] = "Dragon (West)-Dragon (West)",
	["dragon east"] = "Dragon (East)-Dragon (East)",
	["dragon"]      = "Dragon-Dragon",
}

local SkinStorageCandidates = {
	["celebration bomb"]         = { "BOMBSKINcelebration", "Celebration Bomb" },
	["celebration"]              = { "BOMBSKINcelebration", "Celebration Bomb" },
	["nuclear bomb"]             = { "BOMBSKINnuclear", "Nuclear Bomb" },
	["nuclear"]                  = { "BOMBSKINnuclear", "Nuclear Bomb" },
	["thermite bomb"]            = { "BOMBSKINthermite", "Thermite Bomb" },
	["thermite"]                 = { "BOMBSKINthermite", "Thermite Bomb" },
	["azura bomb"]               = { "BOMBSKINazura", "Azura Bomb" },
	["azura"]                    = { "BOMBSKINazura", "Azura Bomb" },

	["purple lightning"]         = { "LIGHTNINGSKINpurple", "Purple Lightning" },
	["yellow lightning"]         = { "LIGHTNINGSKINyellow", "Yellow Lightning" },
	["green lightning"]          = { "LIGHTNINGSKINgreen", "Green Lightning" },
	["red lightning"]            = { "LIGHTNINGSKINred", "Red Lightning" },
	["blue lightning"]           = { "LIGHTNINGSKINblue" },

	["celestial pain"]           = { "PAINSKINcelestial", "Celestial Pain" },
	["super spirit pain"]        = { "PAINSKINsuperspirit", "Super Spirit Pain" },
	["super spirit"]             = { "PAINSKINsuperspirit", "Super Spirit Pain" },
	["sadness pain"]             = { "Sadness Pain" },
	["torment pain"]             = { "Torment Pain" },
	["frustration pain"]         = { "Frustration Pain" },

	["divine portal"]            = { "PORTALSKINdivine", "Divine Portal" },
	["pink portal"]              = { "PORTALSKINpink" },
	["orange portal"]            = { "PORTALSKINorange" },
	["blue portal"]              = { "PORTALSKINblue" },

	["emerald diamond"]          = { "DIAMONDSKINgreen", "Emerald Diamond" },
	["rose quartz diamond"]      = { "DIAMONDSKINpoudretteite", "Rose Quartz Diamond" },
	["rose quartz"]              = { "DIAMONDSKINpoudretteite", "Rose Quartz Diamond" },
	["topaz diamond"]            = { "DIAMONDSKINtopaz", "Topaz Diamond" },
	["ruby diamond"]             = { "DIAMONDSKINred", "Ruby Diamond" },

	["glacier eagle"]            = { "FALCSKINglacier", "Glacier Eagle" },
	["requiem eagle"]            = { "FALCSKINrequiem", "Requiem Eagle" },
	["matrix eagle"]             = { "FALCSKINmatrix", "Matrix Eagle" },
	["parrot eagle"]             = { "FALCSKINparrot" },
	["parrot"]                   = { "FALCSKINparrot" },

	["crimson kitsune"]          = { "KYUKONSKINcrimson" },
	["crimson"]                  = { "KYUKONSKINcrimson" },
	["galaxy kitsune"]           = { "KYUKONSKINgalaxy", "Galaxy Empyrean Kitsune" },
	["galaxy"]                   = { "KYUKONSKINgalaxy", "Galaxy Empyrean Kitsune" },
	["empyrean kitsune"]         = { "Empyrean (Kitsune)-Empyrean (Kitsune)" },
	["empyrean"]                 = { "Empyrean (Kitsune)-Empyrean (Kitsune)" },

	["werewolf tiger"]           = { "TIGERSKINwerewolf", "TIGERMUTWerewolf", "Werewolf (Tiger)-Werewolf (Tiger)" },
	["werewolf"]                 = { "TIGERSKINwerewolf", "TIGERMUTWerewolf", "Werewolf (Tiger)-Werewolf (Tiger)" },

	["runic yeti"]               = { "FIENDSKINsealed", "Sealed Fiend" },
	["runic"]                    = { "FIENDSKINsealed", "Sealed Fiend" },
	["fiend yeti"]               = { "YETISKINfiend", "YETIMUTFiend", "Fiend (Yeti)-Fiend (Yeti)" },
	["fiend"]                    = { "YETISKINfiend", "YETIMUTFiend", "Fiend (Yeti)-Fiend (Yeti)" },

	["hellfire gas"]             = { "HELLFIRESKINdefault", "GASMUTHellfire", "Hellfire (Gas)-Hellfire (Gas)" },
	["hellfire"]                 = { "HELLFIRESKINdefault", "GASMUTHellfire", "Hellfire (Gas)-Hellfire (Gas)" },
	["arcsteel magnet"]          = { "MAGNETSKINarksteel", "Arcsteel Magnet" },
	["arcsteel"]                 = { "MAGNETSKINarksteel", "Arcsteel Magnet" },
	["starlight gravity"]        = { "GRAVITYSKINheavenly", "Heavenly Gravity" },
	["starlight"]                = { "GRAVITYSKINheavenly", "Heavenly Gravity" },
	["lime blade"]               = { "BLADESKINlime", "Lime Blade" },

	["west ember dragon"]        = { "WSTDSKINember", "EmberChromaticDragon" },
	["east ember dragon"]        = { "ESTDSKINember", "EmberChromaticDragon" },
	["ember dragon"]             = { "EmberChromaticDragon", "WSTDSKINember", "ESTDSKINember" },
	["ember"]                    = { "EmberChromaticDragon", "WSTDSKINember", "ESTDSKINember" },
	["west eclipse dragon"]      = { "WSTDSKINeclipse", "EclipseChromaticDragon" },
	["east eclipse dragon"]      = { "ESTDSKINeclipse", "EclipseChromaticDragon" },
	["eclipse dragon"]           = { "EclipseChromaticDragon", "WSTDSKINeclipse", "ESTDSKINeclipse" },
	["eclipse"]                  = { "EclipseChromaticDragon", "WSTDSKINeclipse", "ESTDSKINeclipse" },
	["west blood moon dragon"]   = { "WSTDSKINbloodmoon", "BloodmoonChromaticDragon" },
	["east blood moon dragon"]   = { "ESTDSKINbloodmoon", "BloodmoonChromaticDragon" },
	["blood moon dragon"]        = { "BloodmoonChromaticDragon", "WSTDSKINbloodmoon", "ESTDSKINbloodmoon" },
	["blood moon"]               = { "BloodmoonChromaticDragon", "WSTDSKINbloodmoon", "ESTDSKINbloodmoon" },
	["west phoenix sky dragon"]  = { "WSTDSKINphoenixsky", "PhoenixSkyChromaticDragon" },
	["east phoenix sky dragon"]  = { "ESTDSKINphoenixsky", "PhoenixSkyChromaticDragon" },
	["phoenix sky dragon"]       = { "PhoenixSkyChromaticDragon", "WSTDSKINphoenixsky", "ESTDSKINphoenixsky" },
	["phoenix sky"]              = { "PhoenixSkyChromaticDragon", "WSTDSKINphoenixsky", "ESTDSKINphoenixsky" },
	["west violet night dragon"] = { "WSTDSKINvioletnight", "VioletNightChromaticDragon" },
	["east violet night dragon"] = { "ESTDSKINvioletnight", "VioletNightChromaticDragon" },
	["violet night dragon"]      = { "VioletNightChromaticDragon", "WSTDSKINvioletnight", "ESTDSKINvioletnight" },
	["violet night"]             = { "VioletNightChromaticDragon", "WSTDSKINvioletnight", "ESTDSKINvioletnight" },

	["dog blade"]                = { "BRATSKINdefault", "The Sword Of The Brat" },
	["rabid dog blade"]          = { "BRATSKINslayer", "The Sword Of The Brat" },
	["rabid"]                    = { "BRATSKINslayer", "The Sword Of The Brat" },
}

local function normalizeEquipName(name)
	name = tostring(name or ""):lower():gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
	name = name:gsub("^<(.-)>$", "%1"):match("^%s*(.-)%s*$") or ""
	return EquipAliases[name] or name
end

local function resolveUnstoreCandidates(rawInput)
	local key = normalizeEquipName(rawInput)
	if key == "" then return nil end

	if SkinStorageCandidates[key] then
		return SkinStorageCandidates[key]
	end

	for k, list in pairs(SkinStorageCandidates) do
		if k == key or k:find(key, 1, true) then
			return list
		end
	end

	if key == "dragon" then
		return { "Dragon (West)-Dragon (West)", "Dragon (East)-Dragon (East)", "Dragon-Dragon" }
	end

	if FruitStorageKeys[key] then
		return { FruitStorageKeys[key] }
	end

	local title = key:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest
	end)
	return { title .. "-" .. title, title }
end

-- =========================================================
-- 8. !reset AND !equip ACTIONS
-- =========================================================

local function resetCharacterAlone()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		warn("[Reset] Character not alive.")
		return false
	end

	pcall(function()
		humanoid.Health = 0
	end)
	task.wait(0.2)
	if humanoid.Health > 0 then
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		end)
	end
	return true
end

local function jumpOffTableAndStand()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end

	local seatPart = humanoid.SeatPart
	local awayDir = nil
	local originPos = hrp.Position

	if seatPart and seatPart:IsA("BasePart") then
		originPos = seatPart.Position
		lastTable = seatPart.Parent

		local tableModel = seatPart.Parent
		if tableModel and tableModel:IsA("Model") then
			local pivotPos = tableModel:GetPivot().Position
			local flatDir = Vector3.new(seatPart.Position.X - pivotPos.X, 0, seatPart.Position.Z - pivotPos.Z)
			if flatDir.Magnitude > 0.05 then
				awayDir = flatDir.Unit
			end
		end
		if not awayDir then
			local look = seatPart.CFrame.LookVector
			awayDir = Vector3.new(look.X, 0, look.Z)
			awayDir = (awayDir.Magnitude > 0.05) and awayDir.Unit or Vector3.new(0, 0, 1)
		end
	end

	humanoid.Sit = false
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("Weld") or d:IsA("WeldConstraint") then
			if d.Name == "SeatWeld" or (seatPart and (d.Part0 == seatPart or d.Part1 == seatPart)) then
				pcall(function()
					d:Destroy()
				end)
			end
		end
	end

	local t0 = os.clock()
	while humanoid.SeatPart ~= nil and os.clock() - t0 < 0.8 do
		humanoid.Sit = false
		task.wait(0.05)
	end

	if awayDir then
		local standPos = originPos + (awayDir * 8) + Vector3.new(0, 2, 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		character:PivotTo(CFrame.new(standPos, standPos + awayDir))
		task.wait(0.25)
	end

	humanoid.Sit = false
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
	return true
end

local function findMatchingTool(candidateKey, rawQuery)
	local base = candidateKey:match("^(.-)%-") or candidateKey
	local t1 = base:lower()
	local t2 = tostring(rawQuery or ""):lower()

	for _, container in ipairs({ LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") then
					local n = item.Name:lower()
					if (t1 ~= "" and n:find(t1, 1, true)) or (t2 ~= "" and n:find(t2, 1, true)) then
						return item
					end
				end
			end
		end
	end
	return nil
end

local function equipUnstoreAction(rawInput)
	if isEquipping then
		warn("[Equip] Already unstoring/equipping an item.")
		return
	end

	local candidates = resolveUnstoreCandidates(rawInput)
	if not candidates then
		warn("[Equip] Usage: !equip <fruitname/skinname>")
		return
	end

	isEquipping = true
	autoSitPaused = true

	local ok, err = pcall(function()
		print("[Equip] Jumping off trade table & stopping auto-sit...")
		jumpOffTableAndStand()
		task.wait(0.3)

		local cf = CommF or getCommF()
		if not cf then
			warn("[Equip] CommF_ not found.")
			return
		end

		local loadedTool = nil
		for _, storageKey in ipairs(candidates) do
			loadedTool = findMatchingTool(storageKey, rawInput)
			if loadedTool then
				break
			end

			local okCall, res = pcall(function()
				return cf:InvokeServer("LoadFruit", storageKey)
			end)
			print(string.format("[Equip] LoadFruit('%s') -> ok=%s | res=%s",
				storageKey, tostring(okCall), tostring(res)))

			if okCall and res ~= false then
				local deadline = os.clock() + 1.5
				while os.clock() < deadline do
					loadedTool = findMatchingTool(storageKey, rawInput)
					if loadedTool then
						break
					end
					task.wait(0.05)
				end
				if loadedTool then
					break
				end
			end
		end

		if loadedTool then
			local character = LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and loadedTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
				pcall(function()
					humanoid:EquipTool(loadedTool)
				end)
			end
			print("[Equip] Unstored & equipped:", loadedTool.Name)
		else
			warn("[Equip] Could not unstore:", table.concat(candidates, " / "))
		end
	end)

	if not ok then
		warn("[Equip] Error:", err)
	end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end

	isEquipping = false
	autoSitPaused = false
	print("[Equip] Auto-sit re-enabled.")
end

-- =========================================================
-- 9. CHAT COMMAND HANDLERS
-- =========================================================

-- !add / !remove / !accept / !cancel
local function handleTradeCommand(rawText)
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

-- !reset / !equip <fruitname/skinname>
local function handleEquipCommand(rawText)
	if type(rawText) ~= "string" then return end

	local cleanText = rawText:match("^%s*(.-)%s*$")
	local lowerText = cleanText:lower()

	local now = os.clock()
	if lowerText == lastCmdText and (now - lastCmdTime) < EQUIP_DUPLICATE_COOLDOWN then
		return
	end

	if lowerText == RESET_CMD then
		lastCmdText = lowerText
		lastCmdTime = now
		task.spawn(resetCharacterAlone)
		return
	end

	if lowerText:sub(1, #EQUIP_PREFIX) == EQUIP_PREFIX then
		lastCmdText = lowerText
		lastCmdTime = now
		local targetInput = cleanText:sub(#EQUIP_PREFIX + 1):match("^%s*(.-)%s*$")
		if targetInput == "" then
			warn("[Equip] Usage: !equip <fruitname/skinname>")
			return
		end
		task.spawn(function()
			equipUnstoreAction(targetInput)
		end)
	end
end

-- Combined entry point used by the chat listeners
local function handleChatCommand(rawText)
	handleTradeCommand(rawText)
	handleEquipCommand(rawText)
end

-- =========================================================
-- 10. CHAT LISTENERS
-- =========================================================

if TextChatService
	and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then

	table.insert(
		_G.TradeAddConnections,
		TextChatService.MessageReceived:Connect(function(message)
			if message.TextSource and message.Status == Enum.TextChatMessageStatus.Success then
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
-- 11. AUTO-SIT LOOP
-- =========================================================

local function TweenToSeat(hrp, targetCFrame, sessionId)
	local distance = (hrp.Position - targetCFrame.Position).Magnitude
	local speed = 150
	local duration = math.clamp(distance / speed, 0.2, 1.5)

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
	tween:Play()

	local completed = false
	local conn = tween.Completed:Connect(function()
		completed = true
	end)

	while not completed do
		if _G.TradeAddSessionId ~= sessionId or isAutoSitBlocked() then
			tween:Cancel()
			conn:Disconnect()
			return false
		end
		task.wait(0.05)
	end

	conn:Disconnect()
	return true
end

local function IsTradeTableSeat(seat)
	local parent = seat.Parent
	return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
end

local cachedTradeSeats = {}
local lastSeatScan = 0

local function getTradeSeats()
	if os.clock() - lastSeatScan < 10 and #cachedTradeSeats > 0 then
		return cachedTradeSeats
	end
	lastSeatScan = os.clock()
	table.clear(cachedTradeSeats)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Seat") and IsTradeTableSeat(obj) then
			table.insert(cachedTradeSeats, obj)
		end
	end
	return cachedTradeSeats
end

local function GetUnauthorizedPlayerInSeat(seat)
	local occupant = seat.Occupant
	if occupant then
		local character = occupant.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and player ~= LocalPlayer and not IsAuthorized(player.Name) then
			return player.Name
		end
		return nil
	end

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
					if distance <= 4 and humanoid.Health > 0 and not IsAuthorized(player.Name) then
						return player.Name
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
			if GetUnauthorizedPlayerInSeat(child) then
				return true
			end
		end
	end
	return false
end

task.spawn(function()
	local jumpCooldown = 0

	while _G.TradeAddSessionId == CURRENT_SESSION_ID do
		task.wait(0.5)
		if _G.TradeAddSessionId ~= CURRENT_SESSION_ID then break end
		if isAutoSitBlocked() then continue end

		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
		local hrp = character.HumanoidRootPart
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then continue end

		if humanoid.SeatPart then
			local currentSeat = humanoid.SeatPart
			if IsTradeTableSeat(currentSeat) then
				lastTable = currentSeat.Parent
				local unauthorizedFound = nil

				for _, child in ipairs(currentSeat.Parent:GetChildren()) do
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
					if _G.TradeAddSessionId ~= CURRENT_SESSION_ID or isAutoSitBlocked() then continue end
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

			for _, obj in ipairs(getTradeSeats()) do
				local tableModel = obj.Parent
				if tableModel and tableModel ~= lastTable and not IsTableBlocked(tableModel) then
					local dist = (hrp.Position - obj.Position).Magnitude
					if dist < 800 and dist < shortestDist then
						shortestDist = dist
						bestSeat = obj
					end
				end
			end

			if not bestSeat and lastTable then
				lastTable = nil
			end

			if bestSeat then
				local targetCF = bestSeat.CFrame + Vector3.new(0, 3, 0)
				local tweenOk = TweenToSeat(hrp, targetCF, CURRENT_SESSION_ID)
				if not tweenOk then continue end
				task.wait(0.2)
				if _G.TradeAddSessionId ~= CURRENT_SESSION_ID or isAutoSitBlocked() then continue end
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
-- 12. READY
-- =========================================================

print("========================================")
print("[Trade] Version 5 (Complete Registry) loaded!")
print("[Trade] Multi-ID + StorageKey Fallback active.")
print("[Trade] All Physical & Perm Fruits active.")
print("[Trade] All Gamepasses, Scrolls & Limited Skins active.")
print("[Trade] Command: !add <item> | !remove <item> | !accept | !cancel")
print("[Trade] Examples: !add dragon | !add perm buddha | !add yellow lightning | !add storage")
print("========================================")
print("[Ready] Auto-Sit + !reset + !equip <fruit/skin> loaded!")
