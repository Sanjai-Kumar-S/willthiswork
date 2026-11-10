-- Blox Fruits Auto-Sit Testing Script (Jump on Opponent Occupancy)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local lastTable = nil

local function IsTradeTableSeat(seat)
    local parent = seat.Parent
    return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
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

                -- 2. Testing mode: Jump immediately if ANYONE sits in the opposite seat
                local tableModel = currentSeat.Parent
                for _, child in ipairs(tableModel:GetChildren()) do
                    if child:IsA("Seat") and child ~= currentSeat then
                        if child.Occupant then
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
                    if obj.Parent ~= lastTable and not obj.Occupant then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < 600 and dist < shortestDist then
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
                hrp.CFrame = bestSeat.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.2)
                bestSeat:Sit(humanoid)
            end
        end
    end
end)
