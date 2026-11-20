getgenv().ID = "6ad72f08-3b2b-4c4b-8eef-95a9b10cffef"
local TARGET_URL = "https://api.fe4r.click/s/loader_bloxfruits.luau"

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local targetParent = player:WaitForChild("PlayerGui")

pcall(function()
	if gethui then
		targetParent = gethui()
	elseif CoreGui and pcall(function() return CoreGui:GetChildren() end) then
		targetParent = CoreGui
	end
end)

-- Remove existing instance if re-executed
local existing = targetParent:FindFirstChild("SimpleOutputGui")
if existing then
	existing:Destroy()
end

-- Build GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleOutputGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = targetParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(500, 320)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -180, 1, 0)
titleLabel.Position = UDim2.fromOffset(12, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Payload Viewer - Fetching..."
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local copyButton = Instance.new("TextButton")
copyButton.Name = "CopyAllButton"
copyButton.Size = UDim2.fromOffset(82, 24)
copyButton.Position = UDim2.new(1, -152, 0.5, -12)
copyButton.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
copyButton.BorderSizePixel = 0
copyButton.Text = "Copy All"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 12
copyButton.Font = Enum.Font.GothamSemibold
copyButton.Parent = topBar

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 5)
copyCorner.Parent = copyButton

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(58, 24)
closeButton.Position = UDim2.new(1, -64, 0.5, -12)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
closeButton.BorderSizePixel = 0
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 12
closeButton.Font = Enum.Font.GothamSemibold
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeButton

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -24, 1, -56)
scrollFrame.Position = UDim2.fromOffset(12, 46)
scrollFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollFrame

local textBox = Instance.new("TextBox")
textBox.Name = "OutputBox"
textBox.Size = UDim2.new(1, -12, 1, 0)
textBox.Position = UDim2.fromOffset(6, 4)
textBox.AutomaticSize = Enum.AutomaticSize.Y
textBox.BackgroundTransparency = 1
textBox.Text = "Fetching payload..."
textBox.TextColor3 = Color3.fromRGB(225, 228, 232)
textBox.TextSize = 12
textBox.Font = Enum.Font.Code
textBox.MultiLine = true
textBox.ClearTextOnFocus = false
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.TextWrapped = true
textBox.Parent = scrollFrame

local rawPayload = ""

-- Button handlers
copyButton.MouseButton1Click:Connect(function()
	local content = rawPayload ~= "" and rawPayload or textBox.Text
	local copied = false

	if type(setclipboard) == "function" then
		copied = pcall(setclipboard, content)
	elseif type(toclipboard) == "function" then
		copied = pcall(toclipboard, content)
	end

	if copied then
		copyButton.Text = "Copied!"
	else
		textBox:CaptureFocus()
		textBox.CursorPosition = #textBox.Text + 1
		textBox.SelectionStart = 1
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

-- Fetch raw response automatically inside this script
task.spawn(function()
	local ok, response = pcall(function()
		return game:HttpGet(TARGET_URL)
	end)

	if ok and response then
		rawPayload = tostring(response)
		titleLabel.Text = string.format("Payload Viewer (%d chars)", #rawPayload)
		-- TextBox has a display limit around 16k chars, so truncate preview if huge while Copy All copies full rawPayload
		if #rawPayload > 15000 then
			textBox.Text = rawPayload:sub(1, 15000) .. "\n\n... [Preview truncated — Copy All copies full " .. #rawPayload .. " chars]"
		else
			textBox.Text = rawPayload
		end
	else
		rawPayload = "HttpGet Error:\n" .. tostring(response)
		titleLabel.Text = "Payload Viewer - Failed"
		textBox.Text = rawPayload
	end
end)
