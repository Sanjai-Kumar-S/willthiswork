local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
local pGui = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5))

if _G._BFSetEquipGui then
	pcall(function() _G._BFSetEquipGui:Destroy() end)
	_G._BFSetEquipGui = nil
end

local logs = {}

local sg = Instance.new("ScreenGui")
sg.Name = "BFSetEquipGui"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999999
sg.Parent = pGui or game:GetService("CoreGui")
_G._BFSetEquipGui = sg

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(540, 310)
frame.Position = UDim2.new(0.5, -270, 0.5, -155)
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
title.Text = "SetEquip Schema Probe (ItemId=539)"
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
outBox.Size = UDim2.new(1, -12, 0, 240)
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
	local h = math.max(240, lines * 16 + 16)
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
	_G._BFSetEquipGui = nil
end)

local function describeTable(t)
	if type(t) ~= "table" then return tostring(t) end
	local parts = {}
	for k, v in pairs(t) do
		table.insert(parts, tostring(k) .. "=" .. tostring(v))
	end
	return "{" .. table.concat(parts, ", ") .. "}"
end

task.spawn(function()
	local modFunc = ReplicatedStorage:FindFirstChild("Modules")
		and ReplicatedStorage.Modules:FindFirstChild("Net")
		and ReplicatedStorage.Modules.Net:FindFirstChild("RF/ModificationFunction")

	if not modFunc then
		logLine("[Error] RF/ModificationFunction not found.")
		return
	end

	local payloads = {
		{ Type = "SetEquip", ItemId = 539, Equipped = true },
		{ Type = "SetEquip", ItemId = 539, Equip = true },
		{ Type = "SetEquip", ItemId = 539, Value = true },
		{ Type = "SetEquip", ItemId = 539, State = true },
		{ Type = "SetEquip", StorageKey = "Celebration Bomb", Equipped = true },
		{ Type = "SetEquip", StorageKey = "Celebration Bomb", Equip = true },
		{ Type = "SetEquip", ItemId = 539, StorageKey = "Celebration Bomb", Equipped = true },
		{ Type = "SetEquip", ItemId = 539, Target = "Bomb", Equipped = true },
		{ Type = "SetEquip", ItemId = 539, Category = "Bomb", Equipped = true },
		{ Type = "SetEquip", ItemId = 539, Fruit = "Bomb", Equipped = true },
		{ Type = "SetEquip", SkinId = 539, Equipped = true },
		{ Type = "SetEquip", Skin = "Celebration Bomb", Equipped = true },
	}

	logLine("[SetEquipProbe] Testing Type='SetEquip' payloads...")
	for i, tbl in ipairs(payloads) do
		local ok, r1, r2 = pcall(function()
			return modFunc:InvokeServer(table.unpack({ tbl }))
		end)
		logLine(string.format("[#%d] %s -> ok=%s | ret1=%s | ret2=%s",
			i, describeTable(tbl), tostring(ok), tostring(r1), tostring(r2)))
		task.wait(0.25)
	end

	logLine("[SetEquipProbe] Done. Click Copy to grab output.")
end)
