-- =========================================================
-- FORCE STOP AUTO-SIT (KILLS LOOPS + BLOCKS SEAT WELDING)
-- =========================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 1. Kill session IDs & disconnect stored connections
_G.TradeAddSessionId = (_G.TradeAddSessionId or 0) + 999
_G.TradeAutoSitPaused = true
_G.ForceStopAutoSit = true
_G.AutoSitEnabled = false

if _G.TradeAddConnections then
	for _, conn in ipairs(_G.TradeAddConnections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(_G.TradeAddConnections)
end

if _G._AntiSitConn then
	pcall(function() _G._AntiSitConn:Disconnect() end)
	_G._AntiSitConn = nil
end

-- 2. Unseat immediately and block any loop from re-seating you
local function forceStand(char)
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum then return end

	if hum.SeatPart then
		local seat = hum.SeatPart
		hum.Sit = false
		hum.Jump = true
		hum:ChangeState(Enum.HumanoidStateType.Jumping)

		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("Weld") or d:IsA("WeldConstraint") then
				if d.Name == "SeatWeld" or d.Part0 == seat or d.Part1 == seat then
					pcall(function() d:Destroy() end)
				end
			end
		end

		if hrp and seat:IsA("BasePart") then
			local away = (hrp.Position - seat.Position) * Vector3.new(1, 0, 1)
			away = (away.Magnitude > 0.1) and away.Unit or Vector3.new(0, 0, 1)
			hrp.AssemblyLinearVelocity = Vector3.zero
			char:PivotTo(CFrame.new(seat.Position + away * 8 + Vector3.new(0, 2, 0)))
		end
	end

	-- Guard: if any stray loop calls seat:Sit(hum), stand right back up
	if _G._AntiSitConn then
		pcall(function() _G._AntiSitConn:Disconnect() end)
	end
	_G._AntiSitConn = hum.Seated:Connect(function(active, seat)
		if active and _G.ForceStopAutoSit then
			task.defer(function()
				if hum and hum.Parent then
					hum.Sit = false
					hum.Jump = true
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end)
		end
	end)
end

forceStand(LocalPlayer.Character)

LocalPlayer.CharacterAdded:Connect(function(newChar)
	if _G.ForceStopAutoSit then
		newChar:WaitForChild("Humanoid", 10)
		forceStand(newChar)
	end
end)

print("[AutoSit] Force-stopped and anti-sit guard active.")
