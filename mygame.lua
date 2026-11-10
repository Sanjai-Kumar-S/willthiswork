-- Blox Fruits Auto-Sit Script (Physical Proximity & Opponent Detection Fix)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local lastTable = nil

local function IsTradeTableSeat(seat)
    local parent = seat.Parent
    return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
end

-- Smooth tween movement to prevent anti-cheat kicks
local function TweenToSeat(hrp, targetCFrame)
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = 150 
    local duration = math.clamp(distance / speed, 0.2, 1.5)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
end

-- Checks if any other player's character parts are physically located at the target opposite seat position
local function IsOppositeSeatOccupied(oppositeSeat)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.RespectCanCollide = false

    -- Create a small virtual bounding box right above the opposite chair to detect any player model
    local regionCenter = oppositeSeat.Position + Vector3.new(0, 2, 0)
    local regionSize = Vector3.new(3, 4, 3)
    
    local partsInRegion = Workspace:GetPartsInPart(oppositeSeat, overlapParams)
    for _, part in ipairs(partsInRegion) do
        local character = part.Parent
        if character and character:FindFirstChildOfClass("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player ~= LocalPlayer then
                return true
            end
        end
    end
    
    return false
end

task.spawn(function()
    while true do
        task.wait(0.5)
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
        local hrp = character.HumanoidRootPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then continue end

        -- If currently sitting in a trade chair
        if humanoid.SeatPart then
            local currentSeat = humanoid.SeatPart
            if IsTradeTableSeat(currentSeat) then
                lastTable = currentSeat.Parent
                
                -- 1. Check if someone else took our seat
                if currentSeat.Occupant and currentSeat.Occupant ~= humanoid then
                    humanoid.Jump = true
                    task.wait(0.5)
                    continue
                end

                -- 2. Check the opposite chair using physical proximity detection
                local tableModel = currentSeat.Parent
                for _, child in ipairs(tableModel:GetChildren()) do
                    if child:IsA("Seat") and child ~= currentSeat then
                        if IsOppositeSeatOccupied(child) then
                            print("[DEBUG] Opponent detected at opposite seat! Jumping out...")
                            humanoid.Jump = true
                            task.wait(0.5)
                            break
                        end
                    end
                end
            end
        else
            -- If not sitting, find an empty trade chair from a different table
            local bestSeat = nil
            local shortestDist = math.huge

            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Seat") and IsTradeTableSeat(obj) then
                    if obj.Parent ~= lastTable and not IsOppositeSeatOccupied(obj) then
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
