local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local SkinEquipIds = {
	["celebration bomb"] = 536,
	["celebration"] = 536,
}

local FruitStorageKeys = {
	["rocket"] = "Rocket-Rocket",
	["spin"] = "Spin-Spin",
	["blade"] = "Blade-Blade",
	["spring"] = "Spring-Spring",
	["bomb"] = "Bomb-Bomb",
	["smoke"] = "Smoke-Smoke",
	["spike"] = "Spike-Spike",
	["flame"] = "Flame-Flame",
	["ice"] = "Ice-Ice",
	["sand"] = "Sand-Sand",
	["dark"] = "Dark-Dark",
	["eagle"] = "Eagle-Eagle",
	["diamond"] = "Diamond-Diamond",
	["light"] = "Light-Light",
	["rubber"] = "Rubber-Rubber",
	["ghost"] = "Ghost-Ghost",
	["magma"] = "Magma-Magma",
	["quake"] = "Quake-Quake",
	["buddha"] = "Buddha-Buddha",
	["love"] = "Love-Love",
	["creation"] = "Creation-Creation",
	["spider"] = "Spider-Spider",
	["sound"] = "Sound-Sound",
	["phoenix"] = "Phoenix-Phoenix",
	["portal"] = "Portal-Portal",
	["lightning"] = "Lightning-Lightning",
	["pain"] = "Pain-Pain",
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
	["tiger"] = "Tiger-Tiger",
	["leopard"] = "Tiger-Tiger",
	["leo"] = "Tiger-Tiger",
	["yeti"] = "Yeti-Yeti",
	["magnet"] = "Magnet-Magnet",
	["kitsune"] = "Kitsune-Kitsune",
	["control"] = "Control-Control",
	["dragon west"] = "Dragon (West)-Dragon (West)",
	["west dragon"] = "Dragon (West)-Dragon (West)",
	["dragon east"] = "Dragon (East)-Dragon (East)",
	["east dragon"] = "Dragon (East)-Dragon (East)",
	["dragon"] = "Dragon-Dragon",
}

local function getModificationFunction()
	local mods = ReplicatedStorage:FindFirstChild("Modules")
	local net = mods and mods:FindFirstChild("Net")
	return net and net:FindFirstChild("RF/ModificationFunction")
end

local function getCommF()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild("CommF_")
end

local function equipToolByName(fruitKey)
	local char = LocalPlayer and LocalPlayer.Character
	local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return false
	end

	local baseName = fruitKey:match("^[^%-]+") or fruitKey
	local targetNameLower = baseName:lower()

	local function findMatchingTool(container)
		if not container then
			return nil
		end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") then
				local n = item.Name:lower()
				if n == targetNameLower or n:find(targetNameLower, 1, true) then
					return item
				end
			end
		end
		return nil
	end

	local tool = findMatchingTool(char) or findMatchingTool(backpack)
	if not tool then
		local deadline = os.clock() + 2.5
		repeat
			task.wait(0.1)
			char = LocalPlayer.Character
			backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
			hum = char and char:FindFirstChildOfClass("Humanoid")
			tool = findMatchingTool(char) or findMatchingTool(backpack)
		until tool or not hum or os.clock() >= deadline
	end

	if tool and hum then
		local ok = pcall(function()
			hum:EquipTool(tool)
		end)
		return ok
	end

	return false
end

local function handleEquipCommand(rawArg)
	if type(rawArg) ~= "string" then
		return false, "Invalid argument"
	end

	local query = rawArg:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if query == "" then
		return false, "Missing item name"
	end

	local skinId = SkinEquipIds[query]
	if skinId then
		local modFunc = getModificationFunction()
		if not modFunc then
			return false, "RF/ModificationFunction not found"
		end
		local ok, res = pcall(function()
			return modFunc:InvokeServer({
				Type = "SetEquip",
				IsEquipped = true,
				ItemId = skinId,
			})
		end)
		return ok, res
	end

	local storageKey = FruitStorageKeys[query]
	if not storageKey then
		local title = query:gsub("(%a)([%w']*)", function(a, b)
			return a:upper() .. b:lower()
		end)
		storageKey = title .. "-" .. title
	end

	local commF = getCommF()
	if not commF then
		return false, "CommF_ not found"
	end

	local ok, res = pcall(function()
		return commF:InvokeServer("LoadFruit", storageKey)
	end)
	if ok and res ~= false then
		equipToolByName(storageKey)
	end
	return ok, res
end
