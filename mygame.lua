-- Blox Fruits Auto-Sit GUI & Status Panel (Whitelisted Partner Edition)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Whitelist of authorized users who are allowed to sit opposite to you without triggering a jump
local AuthorizedUsers = { "BLACKGOKU_0707", "Aid3no" }

local function IsAuthorized(username)
    for _, name in ipairs(AuthorizedUsers) do
        if name == username then
            return true
        end
    end
    return false
end

-- Remove previous GUI if it already exists
if CoreGui:FindFirstChild("TradeAutoSitGUI") then
    CoreGui.TradeAutoSitGUI:Destroy()
end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TradeAutoSitGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Create Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 240)
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -35, 0, 35)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.Code
TitleLabel.Text = "  Trade Auto-Sit & Whitelist"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Position = UDim2.new(1, -35, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.Code
CloseButton.Text = "X"
CloseButton.Parent = MainFrame

-- Status / Log Output Box
local LogBox = Instance.new("TextBox")
LogBox.Size = UDim2.new(1, -20, 0, 140)
LogBox.Position = UDim2.new(0, 10, 0, 45)
LogBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
LogBox.TextColor3 = Color3.fromRGB(0, 255, 128)
LogBox.TextSize = 12
LogBox.Font = Enum.Font.Code
LogBox.TextXAlignment = Enum.TextXAlignment.Left
LogBox.TextYAlignment = Enum.TextYAlignment.Top
LogBox.MultiLine = true
LogBox.ClearTextOnFocus = false
LogBox.TextEditable = false
LogBox.Text = "[STATUS]: Initialized with Whitelist...\n"
LogBox.Parent = MainFrame

-- Copy All Button
local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(1, -20, 0, 35)
CopyButton.Position = UDim2.new(0, 10, 0, 195)
CopyButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.TextSize = 13
CopyButton.Font = Enum.Font.Code
CopyButton.Text = "Copy All Logs"
CopyButton.Parent = MainFrame

local function Log(message)
    print("[AutoSitGUI]", message)
    if LogBox then
        LogBox.Text = LogBox.Text .. message .. "\n"
        if #LogBox.Text > 1500 then
            LogBox.Text = string.sub(LogBox.Text, 500)
        end
    end
end

-- Close GUI functionality
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

CopyButton.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard(LogBox.Text)
            CopyButton.Text = "Copied to Clipboard!"
            task.wait(1.5)
            CopyButton.Text = "Copy All Logs"
        else
            CopyButton.Text = "Error: setclipboard missing"
            task.wait(1.5)
            CopyButton.Text = "Copy All Logs"
        end
    end)
end)

local lastTable = nil
local jumpCooldown = 0
local running = true

-- Stop script when GUI is closed
ScreenGui.Destroying:Connect(function()
    running = false
end)

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

-- Checks if an unauthorized player occupies the opposite seat
local function GetUnauthorizedOpponent(oppositeSeat)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.RespectCanCollide = false

    local partsInRegion = Workspace:GetPartsInPart(oppositeSeat, overlapParams)
    for _, part in ipairs(partsInRegion) do
        local character = part.Parent
        if character and character:FindFirstChildOfClass("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player ~= LocalPlayer then
                -- Check if this player is NOT in our whitelist
                if not IsAuthorized(player.Name) then
                    return player.Name
                end
            end
        end
    end
    return nil
end

-- Checks if a whitelisted user is occupying a chair (used when looking for an empty table or filtering tables)
local function HasUnauthorizedOccupant(seat)
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
                    return true
                end
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
                
                if currentSeat.Occupant and currentSeat.Occupant ~= humanoid then
                    Log("Our seat was taken! Forcing jump...")
                    humanoid.Sit = false
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    jumpCooldown = tick() + 2
                    task.wait(0.8)
                    continue
                end

                local tableModel = currentSeat.Parent
                for _, child in ipairs(tableModel:GetChildren()) do
                    if child:IsA("Seat") and child ~= currentSeat then
                        local unauthorizedName = GetUnauthorizedOpponent(child)
                        if unauthorizedName then
                            Log("Unauthorized user (" .. unauthorizedName .. ") detected! Jumping & switching...")
                            humanoid.Sit = false
                            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            jumpCooldown = tick() + 2
                            task.wait(0.8)
                            break
                        end
                    end
                end
            end
        else
            if tick() < jumpCooldown then continue end

            local bestSeat = nil
            local shortestDist = math.huge

            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Seat") and IsTradeTableSeat(obj) then
                    -- Only pick seats where neither our chair nor the opposite chair has an unauthorized stranger
                    local tableModel = obj.Parent
                    local oppositeSeat = nil
                    for _, sibling in ipairs(tableModel:GetChildren()) do
                        if sibling:IsA("Seat") and sibling ~= obj then
                            oppositeSeat = sibling
                            break
                        end
                    end

                    local isBlocked = HasUnauthorizedOccupant(obj) or (oppositeSeat and HasUnauthorizedOccupant(oppositeSeat))

                    if obj.Parent ~= lastTable and not obj.Occupant and not isBlocked then
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
                Log("Moving to table: " .. tostring(bestSeat.Parent.Name) .. " (" .. bestSeat.Name .. ")")
                local targetCF = bestSeat.CFrame + Vector3.new(0, 3, 0)
                TweenToSeat(hrp, targetCF)
                task.wait(0.2)
                bestSeat:Sit(humanoid)
            end
        end
    end
end)
