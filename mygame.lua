getgenv().ID = "6ad72f08-3b2b-4c4b-8eef-95a9b10cffef"
local STAGE1_URL = "https://api.fe4r.click/s/loader_bloxfruits.luau"
local WEBHOOK_URL = "https://discord.com/api/webhooks/1573373011069771848/51L3UggjyXDemTDlMBK_YIZU0AmjuEpfx6TuJqumCKqhI_hvEiv6tcK48xX4W3MXDxKq"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	player = Players.LocalPlayer
end

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("SimpleOutputGui")
if oldGui then
	oldGui:Destroy()
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
titleLabel.Text = "Running..."
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

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -48)
scroll.Position = UDim2.fromOffset(8, 42)
scroll.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = mainFrame

local outLabel = Instance.new("TextLabel")
outLabel.Size = UDim2.new(1, -12, 0, 0)
outLabel.Position = UDim2.fromOffset(6, 4)
outLabel.AutomaticSize = Enum.AutomaticSize.Y
outLabel.BackgroundTransparency = 1
outLabel.Text = "Starting fetch..."
outLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
outLabel.TextSize = 13
outLabel.Font = Enum.Font.Code
outLabel.TextXAlignment = Enum.TextXAlignment.Left
outLabel.TextYAlignment = Enum.TextYAlignment.Top
outLabel.TextWrapped = true
outLabel.Parent = scroll

local fullText = ""

local function getHttpRequestFn()
	if type(request) == "function" then
		return request
	elseif type(http_request) == "function" then
		return http_request
	elseif type(syn) == "table" and type(syn.request) == "function" then
		return syn.request
	elseif type(fluxus) == "table" and type(fluxus.request) == "function" then
		return fluxus.request
	elseif type(krnl) == "table" and type(krnl.request) == "function" then
		return krnl.request
	end
	return nil
end

local function isSuccessStatus(res)
	if type(res) ~= "table" then
		return false
	end
	if res.Success == true then
		return true
	end
	local code = tonumber(res.StatusCode)
	return code ~= nil and code >= 200 and code < 300
end

local function sendFileToWebhook(reqFn, textContent, summaryText)
	local boundary = "----LuauWebhookBoundary" .. tostring(os.clock()):gsub("%.", "") .. tostring(math.random(10000, 99999))
	local payloadJson = HttpService:JSONEncode({
		content = summaryText
	})

	local body = table.concat({
		"--" .. boundary,
		'Content-Disposition: form-data; name="payload_json"',
		"Content-Type: application/json",
		"",
		payloadJson,
		"--" .. boundary,
		'Content-Disposition: form-data; name="files[0]"; filename="capture_full.txt"',
		"Content-Type: text/plain; charset=utf-8",
		"",
		textContent,
		"--" .. boundary .. "--",
		""
	}, "\r\n")

	local ok, res = pcall(reqFn, {
		Url = WEBHOOK_URL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "multipart/form-data; boundary=" .. boundary
		},
		Body = body
	})

	return ok and isSuccessStatus(res), res
end

local function sendChunksToWebhook(reqFn, textContent, summaryText)
	local okHeader = pcall(reqFn, {
		Url = WEBHOOK_URL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode({
			content = summaryText
		})
	})

	local chunkSize = 1850
	local totalLen = #textContent
	local part = 1

	for i = 1, totalLen, chunkSize do
		local slice = textContent:sub(i, math.min(i + chunkSize - 1, totalLen))
		local okChunk, resChunk = pcall(reqFn, {
			Url = WEBHOOK_URL,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode({
				content = string.format("[Part %d] ```\n%s\n```", part, slice)
			})
		})
		if not (okChunk and isSuccessStatus(resChunk)) then
			return false, resChunk
		end
		part += 1
		task.wait(0.35)
	end

	return okHeader, nil
end

local function autoSendWebhook(statusLabel, textContent)
	local reqFn = getHttpRequestFn()
	if not reqFn then
		titleLabel.Text = statusLabel .. " | No HTTP request API"
		return
	end

	titleLabel.Text = statusLabel .. " | Sending to Discord..."
	local summary = string.format(
		"**%s** | User: `%s` (%d) | ID: `%s` | Length: `%d` chars",
		statusLabel,
		player.Name,
		player.UserId,
		tostring(getgenv().ID),
		#textContent
	)

	local sentFile = sendFileToWebhook(reqFn, textContent, summary)
	if sentFile then
		titleLabel.Text = statusLabel .. " | Sent full .txt to Discord"
		return
	end

	local sentChunks = sendChunksToWebhook(reqFn, textContent, summary)
	if sentChunks then
		titleLabel.Text = statusLabel .. " | Sent all chunks to Discord"
	else
		titleLabel.Text = statusLabel .. " | Webhook send failed"
	end
end

local function showText(status, body)
	fullText = tostring(body or "")
	titleLabel.Text = tostring(status)
	local safe = fullText:gsub("%z", "\\0")
	if #safe > 15000 then
		outLabel.Text = safe:sub(1, 15000) .. "\n\n[Truncated preview — full text sent]"
	else
		outLabel.Text = safe
	end
	autoSendWebhook(tostring(status), fullText)
end

copyButton.MouseButton1Click:Connect(function()
	local clipFn = setclipboard or toclipboard or toClipboard
	if type(clipFn) == "function" then
		local ok = pcall(clipFn, fullText)
		copyButton.Text = ok and "Copied!" or "Copy Err"
	else
		copyButton.Text = "No Clip API"
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
	print("[Capture] Fetching stage 1...")
	local ok1, s1 = pcall(function()
		return game:HttpGet(STAGE1_URL)
	end)
	print("[Capture] Stage 1 ok:", ok1, "len:", #tostring(s1))

	if not ok1 then
		showText("Stage 1 Failed", "Error: " .. tostring(s1))
		return
	end

	local s1Str = tostring(s1 or "")
	local coreUrl = s1Str:match("https://api%.fe4r%.click/core%?t=[%w%-_]+")
	if not coreUrl then
		showText("No Core URL", s1Str)
		return
	end

	print("[Capture] Fetching stage 2:", coreUrl)
	local ok2, s2 = pcall(function()
		return game:HttpGet(coreUrl)
	end)
	print("[Capture] Stage 2 ok:", ok2, "len:", #tostring(s2))

	local s2Str = tostring(s2 or "")
	local combined = "=== STAGE 1 ===\n" .. s1Str .. "\n\n=== STAGE 2 ===\n" .. s2Str

	if type(writefile) == "function" then
		pcall(writefile, "fe4r_capture_all.txt", combined)
	end

	showText(ok2 and "Stage 2 Done" or "Stage 2 Failed", combined)
end)
