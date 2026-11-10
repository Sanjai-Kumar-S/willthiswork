-- Minimal Blox Fruits Auto-Sit & Switch Script
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Target only P1 and P2 chairs inside TradeTable models (Sea 2 & Sea 3)
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

        -- If currently sitting, check if another player occupies the seat
        if humanoid.SeatPart then
            local currentSeat = humanoid.SeatPart
            if currentSeat.Occupant and currentSeat.Occupant ~= humanoid then
                -- Someone else sat in it, jump out so we can switch tables
                humanoid.Jump = true
                task.wait(0.5)
            end
        else
            -- If not sitting, search for an empty trade table chair and sit
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Seat") and IsTradeTableSeat(obj) then
                    if not obj.Occupant then
                        if (hrp.Position - obj.Position).Magnitude < 400 then
                            hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.2)
                            obj:Sit(humanoid)
                            break
                        end
                    end
                end
            end
        end
    end
end)
