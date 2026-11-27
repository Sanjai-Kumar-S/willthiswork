local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local TEST_STORAGE_KEY = "BOMBSKINcelebration"
local TEST_IDS = { 536, 1027, 539 }

local commFProbes = {
	{ "LoadFruit", TEST_STORAGE_KEY },
	{ "EquipSkin", TEST_STORAGE_KEY },
	{ "EquipItem", TEST_STORAGE_KEY },
	{ "EquipMutation", TEST_STORAGE_KEY },
	{ "Inventory", "Equip", TEST_STORAGE_KEY },
}

for _, id in ipairs(TEST_IDS) do
	table.insert(commFProbes, { "EquipSkin", id })
	table.insert(commFProbes, { "EquipItem", id })
	table.insert(commFProbes, { "Inventory", "Equip", id })
end

print("[SkinProbe] Testing CommF_ with Celebration Bomb...")

for i, args in ipairs(commFProbes) do
	local ok, r1, r2 = pcall(function()
		return CommF:InvokeServer(table.unpack(args))
	end)
	local s = {}
	for k = 1, #args do s[k] = tostring(args[k]) end
	print(string.format("[CommF #%d] (%s) -> ok=%s | ret1=%s, ret2=%s", i, table.concat(s, ", "), tostring(ok), tostring(r1), tostring(r2)))
	task.wait(0.25)
end

local modFunc = ReplicatedStorage:FindFirstChild("Modules")
	and ReplicatedStorage.Modules:FindFirstChild("Net")
	and ReplicatedStorage.Modules.Net:FindFirstChild("RF/ModificationFunction")

if modFunc and modFunc:IsA("RemoteFunction") then
	local modProbes = {
		{ "Equip", TEST_STORAGE_KEY },
		{ "EquipSkin", TEST_STORAGE_KEY },
		{ TEST_STORAGE_KEY },
	}
	for _, id in ipairs(TEST_IDS) do
		table.insert(modProbes, { "Equip", id })
		table.insert(modProbes, { id })
	end

	print("[SkinProbe] Testing RF/ModificationFunction with Celebration Bomb...")
	for i, args in ipairs(modProbes) do
		local ok, r1, r2 = pcall(function()
			return modFunc:InvokeServer(table.unpack(args))
		end)
		local s = {}
		for k = 1, #args do s[k] = tostring(args[k]) end
		print(string.format("[ModRF #%d] (%s) -> ok=%s | ret1=%s, ret2=%s", i, table.concat(s, ", "), tostring(ok), tostring(r1), tostring(r2)))
		task.wait(0.25)
	end
end

print("[SkinProbe] Done.")
