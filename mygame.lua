local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
local pGui = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5))

if _G._BFSkinProbeGui then
	pcall(function() _G._BFSkinProbeGui:Destroy() end)
	_G._BFSkinProbeGui = nil
end

local logs = {}

local sg = Instance.new("ScreenGui")
sg.Name = "BFSkinProbeGui"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999999

local mounted = false
for _, container in ipairs({ pGui, game:GetService("CoreGui") }) do
	if container then
		local ok = pcall(function()
			sg.Parent = container
		end)
		if ok and sg.Parent == container then
			mounted = true
			break
		end
	end
end

if not mounted then
	warn("[SkinProbe] Failed to parent ScreenGui to PlayerGui or CoreGui.")
end

_G._BFSkinProbeGui = sg

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(480, 290)
frame.Position = UDim2.new(0.5, -240, 0.5, -145)
frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 32)
top.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
top.BorderSizePixel = 0
top.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -140, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "Skin Inventory & Equip Probe"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.fromOffset(60, 24)
copyBtn.Position = UDim2.new(1, -128, 0.5, -12)
copyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
copyBtn.Text = "Copy"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.TextSize = 13
copyBtn.Font = Enum.Font.SourceSansBold
copyBtn.Parent = top

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(60, 24)
closeBtn.Position = UDim2.new(1, -64, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 55)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = top

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -46)
scroll.Position = UDim2.fromOffset(10, 38)
scroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = frame

local outBox = Instance.new("TextBox")
outBox.Size = UDim2.new(1, -12, 0, 220)
outBox.Position = UDim2.fromOffset(6, 4)
outBox.BackgroundTransparency = 1
outBox.Text = ""
outBox.TextColor3 = Color3.fromRGB(220, 240, 255)
outBox.TextSize = 12
outBox.Font = Enum.Font.Code
outBox.TextXAlignment = Enum.TextXAlignment.Left
outBox.TextYAlignment = Enum.TextYAlignment.Top
outBox.TextWrapped = true
outBox.MultiLine = true
outBox.ClearTextOnFocus = false
outBox.TextEditable = false
outBox.Parent = scroll

local function logLine(msg)
	local s = tostring(msg)
	table.insert(logs, s)
	pcall(function() print(s) end)

	local full = table.concat(logs, "\n")
	outBox.Text = full
	local lines = select(2, full:gsub("\n", "\n")) + 1
	local h = math.max(220, lines * 16 + 16)
	outBox.Size = UDim2.new(1, -12, 0, h)
	scroll.CanvasSize = UDim2.fromOffset(0, h + 8)
end

copyBtn.MouseButton1Click:Connect(function()
	local txt = table.concat(logs, "\n")
	local ok = false
	if typeof(setclipboard) == "function" then
		ok = pcall(function() setclipboard(txt) end)
	end
	if not ok and typeof(toclipboard) == "function" then
		ok = pcall(function() toclipboard(txt) end)
	end
	copyBtn.Text = ok and "Copied!" or "Done"
	task.delay(1.2, function()
		if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy" end
	end)
end)

closeBtn.MouseButton1Click:Connect(function()
	pcall(function() sg:Destroy() end)
	_G._BFSkinProbeGui = nil
end)

logLine("[SkinProbe] GUI initialized. Mounted to: " .. tostring(sg.Parent and sg.Parent:GetFullName() or "NONE"))

task.spawn(function()
	local okMod, ItemReplicationService, KEYS, ItemConfig = pcall(function()
		local repMod = ReplicatedStorage:FindFirstChild("ItemReplicationService")
		local cfgMod = ReplicatedStorage:FindFirstChild("ItemConfig")
		if not repMod or not cfgMod then
			error("Missing ItemReplicationService or ItemConfig in ReplicatedStorage")
		end
		local rep = require(repMod)
		local keysMod = repMod:FindFirstChild("KEYS")
		local k = keysMod and require(keysMod) or nil
		local cfg = require(cfgMod)
		return rep, k, cfg
	end)

	if not okMod or not ItemReplicationService then
		logLine("[Error] Module load failed: " .. tostring(ItemReplicationService))
		return
	end

	logLine("[SkinCheck] Scanning owned skins/items...")
	local ownedCelebration = {}

	local buckets = {}
	if KEYS then
		if KEYS.IS_OWNED then table.insert(buckets, { name = "IS_OWNED", key = KEYS.IS_OWNED }) end
		if KEYS.COUNT then table.insert(buckets, { name = "COUNT", key = KEYS.COUNT }) end
	end

	for _, b in ipairs(buckets) do
		local ok, items = pcall(function()
			return ItemReplicationService:GetItems(b.key)
		end)
		if ok and type(items) == "table" then
			for _, item in pairs(items) do
				if type(item) == "table" and item.ItemId then
					local hasVal = item.Value == true
						or (type(item.Value) == "number" and item.Value > 0)
						or (type(item.Count) == "number" and item.Count > 0)

					if hasVal then
						local cOk, cfg = pcall(function() return ItemConfig.tryGet(item.ItemId) end)
						local disp = (cOk and cfg and cfg.Display and cfg.Display.Name) or ""
						local skey = (cOk and cfg and cfg.Index and cfg.Index.StorageKey) or ""
						local blob = (tostring(disp) .. " " .. tostring(skey)):lower()

						if blob:find("bomb", 1, true) or blob:find("celebration", 1, true) or blob:find("skin", 1, true) then
							logLine(string.format("[%s] ItemId=%s | StorageKey=%s | Display=%s | Val=%s | Cnt=%s",
								b.name, tostring(item.ItemId), tostring(skey), tostring(disp), tostring(item.Value), tostring(item.Count)))
							if blob:find("celebration", 1, true) then
								table.insert(ownedCelebration, { id = item.ItemId, storageKey = skey, display = disp })
							end
						end
					end
				end
			end
		end
	end

	logLine("[SkinCheck] ItemReplicationService methods:")
	for k, v in pairs(ItemReplicationService) do
		if type(v) == "function" then
			logLine("  fn: " .. tostring(k))
		end
	end

	local modFunc = ReplicatedStorage:FindFirstChild("Modules")
		and ReplicatedStorage.Modules:FindFirstChild("Net")
		and ReplicatedStorage.Modules.Net:FindFirstChild("RF/ModificationFunction")

	if modFunc and #ownedCelebration > 0 then
		local entry = ownedCelebration[1]
		local modTests = {
			{ "Equip", entry.id },
			{ "Equip", entry.storageKey },
			{ "SetEquipped", entry.id, true },
			{ "SetEquipped", entry.storageKey, true },
			{ "Toggle", entry.id },
			{ "Toggle", entry.storageKey },
			{ entry.id },
			{ entry.storageKey },
		}
		logLine("[SkinCheck] Probing RF/ModificationFunction...")
		for i, args in ipairs(modTests) do
			local ok, r1, r2 = pcall(function()
				return modFunc:InvokeServer(table.unpack(args))
			end)
			local s = {}
			for idx = 1, #args do s[idx] = tostring(args[idx]) end
			logLine(string.format("[ModRF #%d] (%s) -> ok=%s | ret1=%s, ret2=%s",
				i, table.concat(s, ", "), tostring(ok), tostring(r1), tostring(r2)))
			task.wait(0.25)
		end
	elseif #ownedCelebration == 0 then
		logLine("[SkinCheck] No Celebration Bomb entry found in IS_OWNED/COUNT buckets.")
	end

	logLine("[SkinCheck] Done. Click Copy to grab output.")
end)
