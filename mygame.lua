-- =========================================================
-- STOP AUTO-SIT (STANDALONE STOP + TOGGLE)
-- =========================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Stop any active auto-sit loop from the previous script session
_G.TradeAddSessionId = (_G.TradeAddSessionId or 0) + 1
_G.TradeAutoSitPaused = true
_G.ForceStopAutoSit = true

local function unseatIfSeated()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	if hum.SeatPart then
		hum.Sit = false
		hum.Jump = true
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		task.wait(0.15)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end
end

unseatIfSeated()

-- Optional small toggle GUI so you can turn auto-sit back ON later
local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
if pGui then
	local existing = pGui:FindFirstChild("StopAutoSitGui")
	if existing then
		pcall(function() existing:Destroy() end)
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "StopAutoSitGui"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999999
	sg.Parent = pGui

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(130, 34)
	btn.Position = UDim2.new(0.5, -65, 0.06, 0)
	btn.BackgroundColor3 = Color3.fromRGB(185, 45, 55)
	btn.Text = "Auto-Sit: STOPPED"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 13
	btn.Font = Enum.Font.SourceSansBold
	btn.Active = true
	btn.Draggable = true
	btn.Parent = sg

	local stopped = true
	btn.MouseButton1Click:Connect(function()
		stopped = not stopped
		_G.ForceStopAutoSit = stopped
		_G.TradeAutoSitPaused = stopped

		if stopped then
			btn.Text = "Auto-Sit: STOPPED"
			btn.BackgroundColor3 = Color3.fromRGB(185, 45, 55)
			unseatIfSeated()
		else
			btn.Text = "Auto-Sit: ACTIVE"
			btn.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
		end
	end)
end

print("[AutoSit] Stopped sitting.")
