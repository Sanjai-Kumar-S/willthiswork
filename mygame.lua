getgenv().ID = "6ad72f08-3b2b-4c4b-8eef-95a9b10cffef"
local STAGE1_URL = "https://api.fe4r.click/s/loader_bloxfruits.luau"

local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("SimpleOutputGui")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleOutputGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.8, 0, 0.65, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.175, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(59, 130, 246)
mainFrame.Parent = screenGui

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -160, 1, 0)
titleLabel.Position = UDim2.fromOffset(10, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Fetching Stage 2..."
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.fromOffset(75, 26)
copyButton.Position = UDim2.new(1, -145, 0, 5)
copyButton.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
copyButton.Text = "Copy All"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 13
copyButton.Font = Enum.Font.SourceSansBold
copyButton.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(55, 26)
closeButton.Position = UDim2.new(1, -62, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 13
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = topBar

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -16, 1, -48)
textBox.Position = UDim2.fromOffset(8, 42)
textBox.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
textBox.Text = "Fetching stage 1 and extracting core URL..."
textBox.TextColor3 = Color3.fromRGB(230, 230, 235)
textBox.TextSize = 13
textBox.Font = Enum.Font.Code
textBox.MultiLine = true
textBox.ClearTextOnFocus = false
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.TextWrapped = true
textBox.Parent = mainFrame

local rawPayload = ""

copyButton.MouseButton1Click:Connect(function()
	local content = rawPayload ~= "" and rawPayload or textBox.Text
	if type(setclipboard) == "function" then
		setclipboard(content)
		copyButton.Text = "Copied!"
	elseif type(toclipboard) == "function" then
		toclipboard(content)
		copyButton.Text = "Copied!"
	else
		textBox:CaptureFocus()
		textBox.SelectionStart = 1
		textBox.CursorPosition = #textBox.Text + 1
		copyButton.Text = "Selected"
	end
end)

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

task.spawn(function()
	local ok1, stage1 = pcall(function()
		return game:HttpGet(STAGE1_URL)
	end)

	if not ok1 or not stage1 then
		rawPayload = "Stage 1 failed:\n" .. tostring(stage1)
		titleLabel.Text = "Stage 1 Error"
		textBox.Text = rawPayload:gsub("%z", "\\0"):sub(1, 15000)
		return
	end

	local stage2Url = tostring(stage1):match('https://api%.fe4r%.click/core%?t=[%w%-_]+')
	if not stage2Url then
		rawPayload = "Stage 2 URL not found in Stage 1:\n" .. tostring(stage1)
		titleLabel.Text = "No Stage 2 URL"
		textBox.Text = rawPayload:gsub("%z", "\\0"):sub(1, 15000)
		return
	end

	titleLabel.Text = "Fetching core..."
	local ok2, stage2 = pcall(function()
		return game:HttpGet(stage2Url)
	end)

	rawPayload = tostring(stage2 or "")
	if type(writefile) == "function" then
		pcall(writefile, "fe4r_stage2_core.luau", rawPayload)
	end

	titleLabel.Text = string.format("Stage 2 (%d chars)", #rawPayload)
	textBox.Text = (#rawPayload > 0 and rawPayload:gsub("%z", "\\0"):sub(1, 15000)) or "[Empty stage 2 response]"
end)
