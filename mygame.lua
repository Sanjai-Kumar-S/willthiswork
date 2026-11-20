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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleOutputGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = targetParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(460, 280)
mainFrame.Position = UDim2.new(0.5, -230, 0.5, -140)
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
titleLabel.Text = "Output Viewer"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
titleLabel.TextSize = 14
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

local textBox = Instance.new("TextBox")
textBox.Name = "OutputBox"
textBox.Size = UDim2.new(1, -24, 1, -56)
textBox.Position = UDim2.fromOffset(12, 46)
textBox.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
textBox.BorderSizePixel = 0
textBox.Text = ""
textBox.PlaceholderText = "Captured output will appear here..."
textBox.TextColor3 = Color3.fromRGB(225, 228, 232)
textBox.PlaceholderColor3 = Color3.fromRGB(120, 125, 135)
textBox.TextSize = 12
textBox.Font = Enum.Font.Code
textBox.MultiLine = true
textBox.ClearTextOnFocus = false
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.TextWrapped = true
textBox.Parent = mainFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = textBox

-- Helper function you can call from anywhere to populate the box
getgenv().SetSimpleGuiText = function(newText)
	textBox.Text = tostring(newText or "")
end

copyButton.MouseButton1Click:Connect(function()
	local content = textBox.Text
	local copied = false

	if type(setclipboard) == "function" then
		local ok = pcall(setclipboard, content)
		copied = ok
	elseif type(toclipboard) == "function" then
		local ok = pcall(toclipboard, content)
		copied = ok
	end

	if copied then
		copyButton.Text = "Copied!"
		task.delay(1.2, function()
			if copyButton and copyButton.Parent then
				copyButton.Text = "Copy All"
			end
		end)
	else
		-- Fallback: focus and highlight text if clipboard API isn't exposed
		textBox:CaptureFocus()
		textBox.CursorPosition = #content + 1
		textBox.SelectionStart = 1
		copyButton.Text = "Selected"
		task.delay(1.2, function()
			if copyButton and copyButton.Parent then
				copyButton.Text = "Copy All"
			end
		end)
	end
end)

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)
