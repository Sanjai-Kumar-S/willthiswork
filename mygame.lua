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
titleLabel.Text = "Running single-pass capture..."
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
textBox.Text = "Fetching stage 1..."
textBox.TextColor3 = Color3.fromRGB(230, 230, 235)
textBox.TextSize = 13
textBox.Font = Enum.Font.Code
textBox.MultiLine = true
textBox.ClearTextOnFocus = false
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.TextWrapped = true
textBox.Parent = mainFrame

local allOutput = ""

copyButton.MouseButton1Click:Connect(function()
	local content = allOutput ~= "" and allOutput or textBox.Text
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
	task.delay(1.2, function()
		if copyButton and copyButton.Parent then
			copyButton.Text = "Copy All"
		end
	end)
end)

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

task.spawn(function()
	local ok1, s1 = pcall(function()
		return game:HttpGet(STAGE1_URL)
	end)

	local s1Str = tostring(s1 or "")
	if not ok1 or s1Str == "" then
		allOutput = "=== STAGE 1 FAILED ===\n" .. s1Str
		titleLabel.Text = "Stage 1 Error"
		textBox.Text = allOutput:gsub("%z", "\\0"):sub(1, 15000)
		return
	end

	local coreUrl = s1Str:match("https://api%.fe4r%.click/core%?t=[%w%-_]+")
	if not coreUrl then
		allOutput = "=== STAGE 1 (NO CORE URL FOUND) ===\n" .. s1Str
		titleLabel.Text = "Stage 1 Done (No Core URL)"
		textBox.Text = allOutput:gsub("%z", "\\0"):sub(1, 15000)
		if type(writefile) == "function" then
			pcall(writefile, "fe4r_capture_all.txt", allOutput)
		end
		return
	end

	titleLabel.Text = "Fetching fresh core..."
	local ok2, s2 = pcall(function()
		return game:HttpGet(coreUrl)
	end)

	local s2Str = tostring(s2 or "")
	allOutput = string.format(
		"=== STAGE 1 (%d chars) ===\n%s\n\n=== CORE URL ===\n%s\n\n=== STAGE 2 (ok=%s, %d chars) ===\n%s",
		#s1Str, s1Str, coreUrl, tostring(ok2), #s2Str, s2Str
	)

	if type(writefile) == "function" then
		pcall(writefile, "fe4r_capture_all.txt", allOutput)
	end

	titleLabel.Text = string.format("Done | S1:%d S2:%d", #s1Str, #s2Str)
	textBox.Text = allOutput:gsub("%z", "\\0"):sub(1, 15000)
end)
