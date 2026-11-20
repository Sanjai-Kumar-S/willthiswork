getgenv().ID = "6ad72f08-3b2b-4c4b-8eef-95a9b10cffef"
local TARGET_URL = "https://api.fe4r.click/s/loader_bloxfruits.luau"

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
titleLabel.Text = "Fetching..."
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
textBox.Text = "Requesting..."
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
	local ok, res = pcall(function()
		return game:HttpGet(TARGET_URL)
	end)

	local methodUsed = "HttpGet"
	if not ok or res == nil or tostring(res) == "" then
		local req = request or http_request or (syn and syn.request) or (http and http.request)
		if type(req) == "function" then
			local rOk, rRes = pcall(function()
				return req({ Url = TARGET_URL, Method = "GET" })
			end)
			if rOk and type(rRes) == "table" then
				ok = true
				methodUsed = "request (Status " .. tostring(rRes.StatusCode) .. ")"
				res = rRes.Body
			elseif not ok then
				ok = rOk
				res = rRes
			end
		end
	end

	local str = tostring(res or "")
	-- Strip null bytes so TextBox doesn't choke on \0
	local cleaned = str:gsub("%z", "\\0")
	rawPayload = str

	if type(writefile) == "function" then
		pcall(writefile, "fe4r_raw_dump.txt", str)
	end

	titleLabel.Text = string.format("%s | Len: %d", methodUsed, #str)

	if #cleaned == 0 then
		textBox.Text = "[Response was empty / 0 bytes]"
	else
		textBox.Text = cleaned:sub(1, 15000)
	end

	print("[Viewer] Method:", methodUsed, "| ok:", ok, "| type:", type(res), "| len:", #str)
end)
