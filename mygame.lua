-- Blox Fruits Auto-Sit Headless Script (Strict Whitelist Edition)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- STRICT WHITELIST: Only these two usernames are allowed to trade with you.
local AuthorizedUsers = { "BLACKGOKU_0707", "Aid3no" }

local function IsAuthorized(username)
    for _, name in ipairs(AuthorizedUsers) do
        if name == username then
            return true
        end
    end
    return false
end

local lastTable = nil
local jumpCooldown = 0
local running = true

local function IsTradeTableSeat(seat)
    local parent = seat.Parent
    return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
end

local function TweenToSeat(hrp, targetCFrame)
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 150 
    local duration = math.clamp(distance / speed, 0.2, 1.5)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
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

task.spawn(function()
    while running do
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
