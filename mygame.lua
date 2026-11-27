-- =========================================================
-- BLOX FRUITS AUTO-SIT + !reset <fruitname> (2-RESET FLOW)
-- Stop Sit -> Reset #1 -> Menu/Items/Treasure/Search/Equip -> Reset #2 -> Resume Sit
-- =========================================================

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- 1. CONFIGURATION & SESSION CLEANUP
-- =========================================================

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

local isResetting = false
local autoSitEnabled = true
local lastText = ""
local lastTime = 0

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
_G.TradeAutoSitPaused = false
_G.TradeResetLockUntil = 0

local function isAutoSitBlocked()
	return (not autoSitEnabled)
		or _G.TradeAutoSitPaused
		or isResetting
		or (os.clock() < (_G.TradeResetLockUntil or 0))
end

-- =========================================================
-- 2. FRUIT NAME MAPPING
-- =========================================================

local Aliases = {
	["leo"]      = "tiger",
	["leopard"]  = "tiger",
	["t rex"]    = "trex",
	["t-rex"]    = "trex",
	["lighting"] = "lightning",
	["chop"]     = "blade",
	["falcon"]   = "eagle",
	["revive"]   = "ghost",
	["barrier"]  = "creation",
	["door"]     = "portal",
	["rumble"]   = "lightning",
	["paw"]      = "pain",
	["soul"]     = "spirit",
}

local ResetDisplayNames = {
	["rocket"] = "Rocket",
	["spin"] = "Spin",
	["blade"] = "Blade",
	["spring"] = "Spring",
	["bomb"] = "Bomb",
	["smoke"] = "Smoke",
	["spike"] = "Spike",
	["flame"] = "Flame",
	["ice"] = "Ice",
	["sand"] = "Sand",
	["dark"] = "Dark",
	["eagle"] = "Eagle",
	["diamond"] = "Diamond",
	["light"] = "Light",
	["rubber"] = "Rubber",
	["ghost"] = "Ghost",
	["magma"] = "Magma",
	["quake"] = "Quake",
	["buddha"] = "Buddha",
	["love"] = "Love",
	["creation"] = "Creation",
	["spider"] = "Spider",
	["sound"] = "Sound",
	["phoenix"] = "Phoenix",
	["portal"] = "Portal",
	["lightning"] = "Lightning",
	["pain"] = "Pain",
	["blizzard"] = "Blizzard",
	["gravity"] = "Gravity",
	["mammoth"] = "Mammoth",
	["trex"] = "T-Rex",
	["dough"] = "Dough",
	["shadow"] = "Shadow",
	["venom"] = "Venom",
	["gas"] = "Gas",
	["spirit"] = "Spirit",
	["tiger"] = "Tiger",
	["yeti"] = "Yeti",
	["magnet"] = "Magnet",
	["kitsune"] = "Kitsune",
	["control"] = "Control",
	["dragon west"] = "Dragon (West)",
	["west dragon"] = "Dragon (West)",
	["dragon east"] = "Dragon (East)",
	["east dragon"] = "Dragon (East)",
	["dragon"] = "Dragon",
}

local function normalizeName(name)
	name = tostring(name or ""):lower():match("^%s*(.-)%s*$") or ""
	name = name:gsub("^<(.-)>$", "%1"):match("^%s*(.-)%s*$") or ""
	return Aliases[name] or name
end

local function resetNormalize(text)
	return tostring(text or "")
		:lower()
		:gsub("%s+", " ")
		:match("^%s*(.-)%s*$")
end

local function resolveDisplayName(rawInput)
	local key = normalizeName(rawInput)
	if key == "" then return nil end
	if ResetDisplayNames[key] then
		return ResetDisplayNames[key]
	end
	return key:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest
	end)
end

-- =========================================================
-- 3. UI & RESET HELPERS
-- =========================================================

local function isResetGuiVisible(gui)
	if not gui then return false end
	local cur = gui
	while cur and cur ~= PlayerGui do
		if cur:IsA("ScreenGui") and not cur.Enabled then return false end
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		cur = cur.Parent
	end
	if gui:IsA("GuiObject") then
		return gui.AbsoluteSize.X > 1 and gui.AbsoluteSize.Y > 1
	end
	return true
end

local function clickResetButton(target)
	if not target or not target:IsA("GuiObject") then return false end

	local button = target
	if not button:IsA("GuiButton") then
		button = target:FindFirstAncestorWhichIsA("GuiButton") or target:FindFirstChildWhichIsA("GuiButton", true) or target
	end

	local fired = false
	if typeof(getconnections) == "function" then
		for _, sigName in ipairs({ "Activated", "MouseButton1Click" }) do
			local ok, conns = pcall(function()
				return getconnections(button[sigName])
			end)
			if ok and conns and #conns > 0 then
				for _, conn in ipairs(conns) do
					pcall(function()
						conn:Fire()
						fired = true
					end)
				end
				if fired then return true end
			end
		end
	end

	if typeof(firesignal) == "function" then
		local ok = pcall(function()
			firesignal(button.Activated)
		end)
		if ok then return true end
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

local function findInventoryRoots()
	local invGui = PlayerGui:FindFirstChild("Inventory")
	local invInner = invGui and invGui:FindFirstChild("Inventory")
	local main = invInner and invInner:FindFirstChild("Main")

	if main then
		return invGui, invInner, main
	end

	for _, gui in ipairs(PlayerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name:lower():find("inv", 1, true) then
			local inner = gui:FindFirstChild("Inventory") or gui
			local m = inner:FindFirstChild("Main") or gui:FindFirstChild("Main", true)
			if m then
				return gui, m.Parent, m
			end
		end
	end

	return invGui, invInner, main
end

local function findTreasureTab(main)
	local nav = main:FindFirstChild("NavigationRail")
	if nav then
		local cat2 = nav:FindFirstChild("Category2")
		if cat2 then return cat2 end
	end

	local searchRoot = nav or main
	for _, obj in ipairs(searchRoot:GetDescendants()) do
		if obj:IsA("GuiObject") then
			local n = obj.Name:lower()
			if n:find("category2", 1, true) or n:find("treas", 1, true) then
				return obj
			end
			if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text:lower():find("treas", 1, true) then
				return obj:FindFirstAncestorWhichIsA("GuiButton") or obj
			end
		end
	end

	return nil
end

local function findTileGrid(main)
	local pageContent = main:FindFirstChild("PageContent")
	if pageContent then
		local nestedGrid = pageContent:FindFirstChild("Grid")
			and pageContent.Grid:FindFirstChild("Content")
			and pageContent.Grid.Content:FindFirstChild("Grid")
		if nestedGrid then return pageContent, nestedGrid end

		local tileGrid = pageContent:FindFirstChild("TileGrid")
		if tileGrid then return pageContent, tileGrid end

		for _, obj in ipairs(pageContent:GetDescendants()) do
			if obj.Name == "Grid" and obj:FindFirstChild("Tile") then
				return pageContent, obj
			end
		end
	end

	for _, obj in ipairs(main:GetDescendants()) do
		if obj.Name == "Grid" and obj:FindFirstChild("Tile") then
			return pageContent or main, obj
		end
	end

	return pageContent, nil
end

local function findResetTextBox(parent)
	if not parent then return nil end
	if parent:IsA("TextBox") then return parent end
	for _, obj in ipairs(parent:GetDescendants()) do
		if obj:IsA("TextBox") then return obj end
	end
	return nil
end

local function openResetTreasure()
	local _, invInner, main = findInventoryRoots()

	if not isResetGuiVisible(main) then
		local hud = PlayerGui:FindFirstChild("HUDRoot")
		if hud then
			local m = hud:FindFirstChild("Menu", true)
			local it = hud:FindFirstChild("Items", true)

			if m and not isResetGuiVisible(it) then
				clickResetButton(m)
				local w0 = os.clock()
				while os.clock() - w0 < 1.2 do
					it = hud:FindFirstChild("Items", true)
					if it and isResetGuiVisible(it) then break end
					task.wait(0.05)
				end
			end

			it = hud:FindFirstChild("Items", true)
			if it then
				clickResetButton(it)
			end
		end

		local waitStart = os.clock()
		while os.clock() - waitStart < 2.5 do
			_, invInner, main = findInventoryRoots()
			if isResetGuiVisible(main) then break end
			task.wait(0.1)
		end
	end

	if not main or not isResetGuiVisible(main) then
		warn("[Reset] Inventory Main panel not visible.")
		return nil, nil, nil
	end

	local treasureButton = findTreasureTab(main)
	if not treasureButton then
		warn("[Reset] Treasure tab (Category2) not found.")
		return nil, nil, nil
	end

	clickResetButton(treasureButton)
	task.wait(0.5)

	local _, grid = findTileGrid(main)
	if not grid then
		warn("[Reset] Treasure Grid not found.")
		return nil, nil, nil
	end

	return invInner, main, grid
end

local function searchResetTreasure(invInner, main, query)
	local pageContent = main:FindFirstChild("PageContent")
	local toolbar = pageContent and pageContent:FindFirstChild("ToolBar")
	local searchField = toolbar and toolbar:FindFirstChild("SearchTextField")

	if searchField then
		clickResetButton(searchField)
		task.wait(0.2)
	end

	local searchBox = findResetTextBox(searchField) or findResetTextBox(toolbar)
	if not searchBox then
		for _, obj in ipairs((main or invInner):GetDescendants()) do
			if obj:IsA("TextBox") and isResetGuiVisible(obj) then
				searchBox = obj
				break
			end
		end
	end

	if not searchBox then
		warn("[Reset] Search TextBox not found.")
		return false
	end

	pcall(function()
		searchBox:CaptureFocus()
	end)
	searchBox.Text = ""
	task.wait(0.05)
	searchBox.Text = query

	if typeof(getconnections) == "function" then
		pcall(function()
			for _, conn in ipairs(getconnections(searchBox:GetPropertyChangedSignal("Text"))) do
				conn:Fire()
			end
		end)
		pcall(function()
			for _, conn in ipairs(getconnections(searchBox.FocusLost)) do
				conn:Fire(true)
			end
		end)
	end

	pcall(function()
		searchBox:ReleaseFocus(true)
	end)

	task.wait(0.35)
	return true
end

local function getResetTileName(tile)
	local details = tile:FindFirstChild("Details")
	if not details then return "" end

	local line1 = details:FindFirstChild("Line-1")
	local line2 = details:FindFirstChild("Line-2")

	local first = (line1 and line1:IsA("TextLabel") and line1.Text) or ""
	local second = (line2 and line2:IsA("TextLabel") and line2.Text) or ""

	if first ~= "" and second ~= "" then
		return resetNormalize(first .. " " .. second)
	end

	return resetNormalize(first ~= "" and first or second)
end

local function waitForResetTile(grid, displayName, timeout)
	local wanted = resetNormalize(displayName)
	local deadline = os.clock() + (timeout or 1.5)

	while os.clock() < deadline do
		local fallbackMatch = nil

		for _, tile in ipairs(grid:GetChildren()) do
			if tile:IsA("GuiObject") and tile.Visible then
				local details = tile:FindFirstChild("Details")
				local category = details and details:FindFirstChild("Category")
				local catNorm = (category and category:IsA("TextLabel") and resetNormalize(category.Text)) or ""
				local tileName = getResetTileName(tile)

				local matched = (tileName == wanted)
				if not matched then
					for _, lbl in ipairs(tile:GetDescendants()) do
						if (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) and lbl.Visible then
							if resetNormalize(lbl.Text) == wanted then
								matched = true
								break
							end
						end
					end
				end

				if matched then
					if catNorm == "" or catNorm:find("fruit", 1, true) then
						return tile
					elseif not fallbackMatch then
						fallbackMatch = tile
					end
				end
			end
		end

		if fallbackMatch then
			return fallbackMatch
		end

		task.wait(0.1)
	end

	return nil
end

local function findEquipButton(rightCard)
	local itemCard = rightCard:FindFirstChild("ItemCard")
	local buttons = itemCard and itemCard:FindFirstChild("Buttons")
	local direct = buttons and buttons:FindFirstChild("Action-EquipFruit")
	if direct and isResetGuiVisible(direct) then
		return direct
	end

	for _, obj in ipairs(rightCard:GetDescendants()) do
		if obj:IsA("GuiObject") and isResetGuiVisible(obj) then
			local n = obj.Name:lower()
			if n == "action-equipfruit" or n == "equipfruit" or n == "equipbutton" or n == "equip" then
				return obj
			end
			if obj:IsA("TextButton") or obj:IsA("TextLabel") then
				local txt = resetNormalize(obj.Text)
				if txt == "equip" or txt == "equip fruit" then
					return obj:FindFirstAncestorWhichIsA("GuiButton") or obj
				end
			end
		end
	end

	return nil
end

local function equipResetTile(invInner, main, tile, displayName)
	if not tile then return false end

	clickResetButton(tile)
	task.wait(0.5)

	local rightCard = (main and main:FindFirstChild("RightCard"))
		or (invInner and invInner:FindFirstChild("RightCard"))
		or (main and main:FindFirstChild("RightCard", true))

	if not rightCard or not isResetGuiVisible(rightCard) then
		warn("[Reset] RightCard not visible.")
		return false
	end

	local wanted = resetNormalize(displayName)
	local titleMatched = false
	for _, lbl in ipairs(rightCard:GetDescendants()) do
		if lbl:IsA("TextLabel") and isResetGuiVisible(lbl) and resetNormalize(lbl.Text) == wanted then
			titleMatched = true
			break
		end
	end
	if not titleMatched then
		warn("[Reset] RightCard title did not match:", displayName)
		return false
	end

	local equipButton = findEquipButton(rightCard)
	if not equipButton then
		warn("[Reset] Action-EquipFruit button unavailable.")
		return false
	end

	return clickResetButton(equipButton)
end

local function resetCharacterAndWait(stepLabel)
	local oldCharacter = LocalPlayer.Character
	if not oldCharacter then
		warn("[Reset] Character not found for:", stepLabel)
		return false
	end

	local humanoid = oldCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		warn("[Reset] Character cannot be reset for:", stepLabel)
		return false
	end

	if humanoid.Sit then
		humanoid.Sit = false
	end

	local newCharacter = nil
	local connection = LocalPlayer.CharacterAdded:Connect(function(character)
		if character ~= oldCharacter then
			newCharacter = character
		end
	end)

	pcall(function()
		humanoid.Health = 0
	end)
	task.wait(0.3)
	if humanoid.Health > 0 then
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		end)
	end

	local startTime = os.clock()
	while not newCharacter and os.clock() - startTime < 20 do
		task.wait(0.1)
	end

	connection:Disconnect()

	if not newCharacter then
		warn("[Reset] Respawn timed out on:", stepLabel)
		return false
	end

	local wsWait = os.clock()
	while newCharacter.Parent ~= Workspace and os.clock() - wsWait < 10 do
		task.wait(0.1)
	end

	local newHum = newCharacter:WaitForChild("Humanoid", 10)
	local newHrp = newCharacter:WaitForChild("HumanoidRootPart", 10)
	if not newHum or not newHrp then
		warn("[Reset] New character parts missing on:", stepLabel)
		return false
	end

	task.wait(1.5)
	print("[Reset] Respawned & settled:", stepLabel)
	return true
end

local function resetFruitItem(rawInput)
	if isResetting then
		warn("[Reset] Another reset is already running.")
		return
	end

	local displayName = resolveDisplayName(rawInput)
	if not displayName then
		warn("[Reset] Usage: !reset <fruit name>")
		return
	end

	-- Stop sitting completely until both resets finish
	isResetting = true
	autoSitEnabled = false
	_G.TradeAutoSitPaused = true
	_G.TradeResetLockUntil = os.clock() + 60

	local success, result = pcall(function()
		-- 1. Reset character first
		print("[Reset] Starting Reset #1...")
		if not resetCharacterAndWait("Reset #1") then
			return false
		end

		-- 2. Open Menu -> Items -> Treasure, search, and equip first matching fruit once
		print("[Reset] Opening Treasure for:", displayName)
		local invInner, main, grid = openResetTreasure()
		if not main or not grid then return false end

		if not searchResetTreasure(invInner, main, displayName) then return false end

		local tile = waitForResetTile(grid, displayName, 1.5)
		if not tile then
			warn("[Reset] Exact Treasure item not found:", displayName)
			return false
		end

		print("[Reset] Equipping first matching fruit:", displayName)
		if not equipResetTile(invInner, main, tile, displayName) then
			return false
		end

		task.wait(0.8)

		-- 3. Reset character again after equipping fruit
		print("[Reset] Equipped. Starting Reset #2...")
		return resetCharacterAndWait("Reset #2")
	end)

	-- Resume sitting only after Reset #2 completes
	if success and result then
		_G.TradeResetLockUntil = os.clock() + 1.0
	else
		_G.TradeResetLockUntil = os.clock() + 3.0
	end

	_G.TradeAutoSitPaused = false
	autoSitEnabled = true
	isResetting = false

	if not success then
		warn("[Reset] Error:", result)
	elseif result then
		print("[Reset] Completed 2-reset flow:", displayName)
	else
		warn("[Reset] Failed:", displayName)
	end
end

-- =========================================================
-- 4. CHAT COMMAND LISTENER
-- =========================================================

local function handleChatCommand(rawText)
	if type(rawText) ~= "string" then return end

	local cleanText = rawText:match("^%s*(.-)%s*$")
	local lowerText = cleanText:lower()

	if lowerText:sub(1, #RESET_PREFIX) == RESET_PREFIX then
		local now = os.clock()
		if lowerText == lastText and (now - lastTime) < DUPLICATE_COOLDOWN then
			return
		end
		lastText = lowerText
		lastTime = now

		local targetInput = cleanText:sub(#RESET_PREFIX + 1):match("^%s*(.-)%s*$")
		if targetInput == "" then
			warn("[Reset] Usage: !reset <fruit name>")
			return
		end

		task.spawn(function()
			resetFruitItem(targetInput)
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
	local lastTable = nil
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

print("[Reset] Auto-Sit + !reset <fruit> (2-Reset Flow) loaded!")
