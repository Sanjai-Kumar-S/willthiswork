-- =========================================================
-- BLOX FRUITS AUTO-SIT + !reset + !equip <fruitname>
-- =========================================================

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- =========================================================
-- 1. CONFIGURATION & SESSION CLEANUP
-- =========================================================

local RESET_CMD = "!reset"
local EQUIP_PREFIX = "!equip "
local DUPLICATE_COOLDOWN = 0.8
local AuthorizedUsers = { "BLACKGOKU_0707", "Aid3no" }

local function IsAuthorized(username)
	for _, name in ipairs(AuthorizedUsers) do
		if name == username then
			return true
		end
	end
	return false
end

local autoSitPaused = false
local isEquipping = false
local lastCmdText = ""
local lastCmdTime = 0
local lastTable = nil

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
	return autoSitPaused or isEquipping
end

-- =========================================================
-- 2. FRUIT NAME & STORAGE KEY MAPPING
-- =========================================================

local Aliases = {
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

local function normalizeName(name)
	name = tostring(name or ""):lower():gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
	name = name:gsub("^<(.-)>$", "%1"):match("^%s*(.-)%s*$") or ""
	return Aliases[name] or name
end

local function resolveStorageCandidates(rawInput)
	local key = normalizeName(rawInput)
	if key == "" then return nil end

	if key == "dragon" then
		return { "Dragon (West)-Dragon (West)", "Dragon (East)-Dragon (East)", "Dragon-Dragon" }
	end

	if FruitStorageKeys[key] then
		return { FruitStorageKeys[key] }
	end

	local title = key:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest
	end)
	return { title .. "-" .. title }
end

-- =========================================================
-- 3. !reset AND !equip ACTIONS
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

local function findFruitTool(storageKey)
	local baseName = storageKey:match("^(.-)%-") or storageKey
	local target = baseName:lower()

	for _, container in ipairs({ LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character }) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") and item.Name:lower():find(target, 1, true) then
					return item
				end
			end
		end
	end
	return nil
end

local function equipFruitAction(rawInput)
	if isEquipping then
		warn("[Equip] Already equipping a fruit.")
		return
	end

	local candidates = resolveStorageCandidates(rawInput)
	if not candidates then
		warn("[Equip] Usage: !equip <fruit name>")
		return
	end

	isEquipping = true
	autoSitPaused = true

	local ok, err = pcall(function()
		print("[Equip] Jumping off trade table & stopping auto-sit...")
		jumpOffTableAndStand()
		task.wait(0.3)

		local equippedTool = nil
		for _, storageKey in ipairs(candidates) do
			equippedTool = findFruitTool(storageKey)
			if equippedTool then
				break
			end

			local okCall, res = pcall(function()
				return CommF:InvokeServer("LoadFruit", storageKey)
			end)

			if okCall and res == true then
				local deadline = os.clock() + 1.5
				while os.clock() < deadline do
					equippedTool = findFruitTool(storageKey)
					if equippedTool then
						break
					end
					task.wait(0.05)
				end
				if equippedTool then
					break
				end
			end
		end

		if equippedTool then
			local character = LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and equippedTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
				pcall(function()
					humanoid:EquipTool(equippedTool)
				end)
			end
			print("[Equip] Fruit ready & equipped:", equippedTool.Name)
		else
			warn("[Equip] Could not load/equip:", table.concat(candidates, " / "))
		end
	end)

	if not ok then
		warn("[Equip] Error:", err)
	end

	-- Re-enable auto-sit and standing state only after equip finishes
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
-- 4. CHAT COMMAND LISTENER (!reset & !equip <fruitname>)
-- =========================================================

local function handleChatCommand(rawText)
	if type(rawText) ~= "string" then return end

	local cleanText = rawText:match("^%s*(.-)%s*$")
	local lowerText = cleanText:lower()

	local now = os.clock()
	if lowerText == lastCmdText and (now - lastCmdTime) < DUPLICATE_COOLDOWN then
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
			warn("[Equip] Usage: !equip <fruit name>")
			return
		end
		task.spawn(function()
			equipFruitAction(targetInput)
		end)
	end
end

if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
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
			table.insert(_G.TradeAddConnections, plr.Chatted:Connect(handleChatCommand))
		end
	end
	table.insert(
		_G.TradeAddConnections,
		Players.PlayerAdded:Connect(function(plr)
			if IsAuthorized(plr.Name) then
				table.insert(_G.TradeAddConnections, plr.Chatted:Connect(handleChatCommand))
			end
		end)
	)
end

-- =========================================================
-- 5. AUTO-SIT LOOP
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

print("[Ready] Auto-Sit + !reset + !equip <fruit> loaded!")
