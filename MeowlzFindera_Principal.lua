--!nocheck
-- ==============================================================
-- MEOWLZZ FINDER V6 - Gold Edition (divisória correta, textos em cima)
-- ==============================================================

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")

local LP = Players.LocalPlayer
if not LP then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() LP = Players.LocalPlayer end

-- ===== endpoints =====
local _a = "https://meowlzjoiner.lovable.app/api/public/best?key=mz_7fQ4pR2xLb9VnKt3sYh8WcZ6dJ1uEaMg"
local function API_URL() return _a end
local JOINER_URL   = "https://meowlzz-hub-customizer.lovable.app/api/public/mz9k4x7q/hb"
local JOINER_TOKEN = "mz_9K3xQ7pL2vNbY4fJ8hR6tW1sZaB5dE0uMcX"
local HEARTBEAT    = 4

-- ===== paleta ouro suave =====
local GOLD       = Color3.fromRGB(233, 196, 106)
local GOLD_SOFT  = Color3.fromRGB(255, 230, 170)
local BG         = Color3.fromRGB(18, 16, 12)
local BG2        = Color3.fromRGB(26, 23, 17)
local TXT        = Color3.fromRGB(238, 233, 222)
local DIM        = Color3.fromRGB(180, 172, 156)

-- ===== HTTP helpers =====
local function getRequestFn()
    local env = (getgenv and getgenv()) or _G
    return (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
        or env.http_request or env.request
end

local function httpGet(url)
    local req = getRequestFn()
    if req then
        local ok, res = pcall(req, { Url = url, Method = "GET",
            Headers = { ["Content-Type"] = "application/json", ["Cache-Control"] = "no-cache" } })
        if ok and res then return res.Body or res.body end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok then return res end
    return nil
end

local function httpPostJSON(url, tbl)
    local body = HttpService:JSONEncode(tbl)
    local req = getRequestFn()
    if req then
        local ok, res = pcall(req, { Url = url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = body })
        if ok and res then
            local b = res.Body or res.body
            if type(b) == "string" then
                local ok2, dec = pcall(HttpService.JSONDecode, HttpService, b)
                if ok2 then return dec end
            end
        end
    end
    return nil
end

-- ===== formatação =====
local function fmt(v)
    v = tonumber(v) or 0
    if v >= 1e9 then return string.format("%.2fB/s", v/1e9) end
    if v >= 1e6 then return string.format("%.2fM/s", v/1e6) end
    if v >= 1e3 then return string.format("%.1fK/s", v/1e3) end
    return string.format("%d/s", v)
end

local function ago(iso)
    if not iso then return "now" end
    local y,mo,d,h,mi,s = tostring(iso):match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not y then return "now" end
    local t = os.time({year=tonumber(y),month=tonumber(mo),day=tonumber(d),hour=tonumber(h),min=tonumber(mi),sec=tonumber(s)})
    local diff = os.time() - (t - (os.time() - os.time(os.date("!*t"))))
    if diff < 0 then diff = 0 end
    if diff < 60 then return math.floor(diff) .. "s ago" end
    if diff < 3600 then return math.floor(diff/60) .. "m ago" end
    return math.floor(diff/3600) .. "h ago"
end

-- ===== config =====
local cfg = {
    minVal = 1,
    unit = "M",
    good = true,
    secret = true,
    og = true,
    autoJoin = false,
    autoForce = false,
    forceTime = 10,
}

local UNITS = { K = 1e3, M = 1e6, B = 1e9 }
local function threshold() return (tonumber(cfg.minVal) or 0) * (UNITS[cfg.unit] or 1e6) end

local function rarityOK(r)
    r = string.lower(tostring(r or ""))
    if r:find("og") and cfg.og then return true end
    if r:find("secret") and cfg.secret then return true end
    if (r:find("good") or r:find("brainrot god") or r:find("god")) and cfg.good then return true end
    return false
end

local function passes(b)
    return (tonumber(b.gen_val) or 0) >= threshold() and rarityOK(b.rarity)
end

-- ===== GUI =====
local parentGui = (gethui and gethui()) or CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = "MeowlzzFinder_Gold"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parentGui
if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

local function corner(o, r) 
    local c = Instance.new("UICorner") 
    c.CornerRadius = UDim.new(0, r or 10) 
    c.Parent = o 
    return c 
end

local function stroke(o, col, t)
    local s = Instance.new("UIStroke") 
    s.Color = col or GOLD 
    s.Transparency = t or 0.4 
    s.Parent = o 
    return s
end

-- ===== Main Frame =====
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, 350)
main.Position = UDim2.new(0.5, -220, 0.5, -175)
main.BackgroundColor3 = BG
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 20)
stroke(main, GOLD, 0.35)

-- ===== Header =====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = BG2
header.BackgroundTransparency = 0.3
header.BorderSizePixel = 0
header.Parent = main
corner(header, 20)

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 34, 0, 34)
logo.Position = UDim2.new(0, 12, 0.5, -17)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://105194511752844"
logo.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 52, 0, 0)
title.Size = UDim2.new(1, -130, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "MEOWLZZ FINDER"
title.TextSize = 15
title.TextColor3 = GOLD_SOFT
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextStrokeTransparency = 1
title.Parent = header

local function headBtn(txt, x, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 24)
    b.Position = UDim2.new(1, x, 0.5, -12)
    b.BackgroundColor3 = BG
    b.BackgroundTransparency = 0.5
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.Text = txt
    b.TextSize = 13
    b.TextColor3 = GOLD
    b.TextStrokeTransparency = 1
    b.Parent = header
    corner(b, 8)
    stroke(b, GOLD, 0.6)
    b.MouseButton1Click:Connect(fn)
    return b
end

-- ===== Corpo =====
local body = Instance.new("Frame")
body.Position = UDim2.new(0, 0, 0, 52)
body.Size = UDim2.new(1, 0, 1, -52)
body.BackgroundTransparency = 1
body.Parent = main

-- ===== Abas =====
local rail = Instance.new("Frame")
rail.Size = UDim2.new(0, 90, 1, 0)
rail.BackgroundColor3 = BG2
rail.BackgroundTransparency = 0.2
rail.BorderSizePixel = 0
rail.Parent = body
corner(rail, 0)

local railList = Instance.new("UIListLayout")
railList.Padding = UDim.new(0, 8)
railList.HorizontalAlignment = Enum.HorizontalAlignment.Center
railList.Parent = rail

local railPad = Instance.new("UIPadding")
railPad.PaddingTop = UDim.new(0, 14)
railPad.PaddingBottom = UDim.new(0, 14)
railPad.Parent = rail

local pages, tabBtns = {}, {}

local function makePage()
    local p = Instance.new("Frame")
    p.Position = UDim2.new(0, 98, 0, 6)
    p.Size = UDim2.new(1, -106, 1, -12)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = body
    return p
end

local currentTab
local function setTab(id)
    currentTab = id
    for k, p in pairs(pages) do p.Visible = (k == id) end
    for k, b in pairs(tabBtns) do
        local active = (k == id)
        b.BackgroundColor3 = active and GOLD or BG
        b.BackgroundTransparency = active and 0 or 0.7
        b.TextColor3 = active and Color3.fromRGB(25, 20, 10) or GOLD
        b.TextSize = active and 12 or 11
    end
end

local function makeTab(id, label)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 80, 0, 36)
    b.BackgroundColor3 = BG
    b.BackgroundTransparency = 0.7
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.Text = label
    b.TextSize = 11
    b.TextColor3 = GOLD
    b.TextStrokeTransparency = 1
    b.Parent = rail
    corner(b, 10)
    stroke(b, GOLD, 0.5)
    b.MouseButton1Click:Connect(function() setTab(id) end)
    tabBtns[id] = b
    pages[id] = makePage()
    return pages[id]
end

local pFinder = makeTab("finder", "FINDER")
local pUsers  = makeTab("users",  "USERS")
local pConfig = makeTab("config", "CONFIG")

-- ================================================================
-- ===== FINDER PAGE (CORRIGIDO: textos em cima dos toggles) =====
-- ================================================================

-- Barra de ferramentas com altura maior
local quickBar = Instance.new("Frame")
quickBar.Size = UDim2.new(1, 0, 0, 44)  -- altura suficiente para texto + toggle
quickBar.BackgroundTransparency = 1
quickBar.Parent = pFinder

local qLayout = Instance.new("UIListLayout")
qLayout.FillDirection = Enum.FillDirection.Horizontal
qLayout.Padding = UDim.new(0, 4)
qLayout.VerticalAlignment = Enum.VerticalAlignment.Center
qLayout.Parent = quickBar

-- Função para criar um container com texto em cima e toggle embaixo
local function createToggleContainer(label, key, width)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, width, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = quickBar
    
    -- Texto em cima
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, 0, 0, 14)
    labelText.Position = UDim2.new(0, 0, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = GOLD
    labelText.TextSize = 8
    labelText.Font = Enum.Font.GothamBold
    labelText.TextStrokeTransparency = 1
    labelText.TextXAlignment = Enum.TextXAlignment.Center
    labelText.Parent = container
    
    -- Toggle (embaixo)
    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 40, 0, 18)
    toggleBg.Position = UDim2.new(0.5, -20, 0, 16)
    toggleBg.BackgroundColor3 = cfg[key] and GOLD or Color3.fromRGB(40, 40, 50)
    toggleBg.BorderSizePixel = 0
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.Parent = container
    corner(toggleBg, 9)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = cfg[key] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    corner(knob, 7)
    
    local function updateToggle()
        local state = cfg[key]
        toggleBg.BackgroundColor3 = state and GOLD or Color3.fromRGB(40, 40, 50)
        knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    end
    
    toggleBg.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        updateToggle()
    end)
    
    return container
end

-- Botões normais (REFRESH e CLEAR LOGS)
local function quickBtn(txt, w, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 1, 0)
    b.BackgroundColor3 = BG2
    b.BackgroundTransparency = 0.4
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.Text = txt
    b.TextSize = 10
    b.TextColor3 = GOLD
    b.TextStrokeTransparency = 1
    b.Parent = quickBar
    corner(b, 8)
    stroke(b, GOLD, 0.5)
    b.MouseButton1Click:Connect(fn)
    return b
end

-- Criar toggles com texto em cima
createToggleContainer("AUTO-JOIN", "autoJoin", 52)
createToggleContainer("AUTO-FORCE", "autoForce", 52)

quickBtn("REFRESH", 58, function() task.spawn(refresh) end)
quickBtn("CLEAR LOGS", 72, function()
    for _, b in ipairs(lastRows) do cleared[b._key] = true end
    for _, e in ipairs({ table.unpack(activeNotifs) }) do removeNotif(e) end
    for _, c in ipairs(list:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
end)

-- ===== DIVISÓRIA (logo abaixo da quickBar) =====
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -12, 0, 1)
divider.Position = UDim2.new(0, 6, 0, 46) -- 44 (altura da quickBar) + 2 margem
divider.BackgroundColor3 = GOLD
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Parent = pFinder

-- ===== Lista de logs =====
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 0, 0, 50) -- 46 (divisória) + 4 margem
list.Size = UDim2.new(1, 0, 1, -50)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = GOLD
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = pFinder

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = list

local cleared = {}
local lastRows = {}

local function safeTeleport(placeId, jobId)
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(tonumber(placeId) or game.PlaceId, jobId, LP)
    end)
    if not ok then
        pcall(function()
            TeleportService:Teleport(tonumber(placeId) or game.PlaceId, LP)
        end)
        warn("[Meowlzz] join fallback:", err)
    end
end

local autoJoinCooldown = false

local function handleAutoJoin(jobId)
    if cfg.autoJoin and jobId and jobId ~= "" then
        if not autoJoinCooldown then
            autoJoinCooldown = true
            task.spawn(safeTeleport, game.PlaceId, jobId)
            task.delay(3, function() autoJoinCooldown = false end)
        end
    end
    if cfg.autoForce and jobId and jobId ~= "" then
        task.spawn(function()
            for i = 1, cfg.forceTime or 10 do
                if not cfg.autoForce then break end
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP) end)
                task.wait(2.5)
            end
        end)
    end
end

local function makeCard(b)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -4, 0, 54)
    f.BackgroundColor3 = BG2
    f.BackgroundTransparency = 0.4
    f.BorderSizePixel = 0
    f.Parent = list
    corner(f, 12)
    stroke(f, GOLD, 0.4)

    local n = Instance.new("TextLabel")
    n.BackgroundTransparency = 1
    n.Position = UDim2.new(0, 12, 0, 4)
    n.Size = UDim2.new(1, -76, 0, 16)
    n.Font = Enum.Font.GothamBold
    n.Text = tostring(b.name or "?")
    n.TextSize = 13
    n.TextColor3 = GOLD_SOFT
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.TextTruncate = Enum.TextTruncate.AtEnd
    n.TextStrokeTransparency = 1
    n.Parent = f

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0, 12, 0, 20)
    sub.Size = UDim2.new(1, -76, 0, 15)
    sub.Font = Enum.Font.Gotham
    sub.Text = fmt(b.gen_val) .. "  -  " .. tostring(b.rarity or "?")
    sub.TextSize = 10
    sub.TextColor3 = TXT
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextStrokeTransparency = 1
    sub.Parent = f

    local meta = Instance.new("TextLabel")
    meta.BackgroundTransparency = 1
    meta.Position = UDim2.new(0, 12, 0, 35)
    meta.Size = UDim2.new(1, -76, 0, 14)
    meta.Font = Enum.Font.Gotham
    meta.Text = (b.traits and b.traits ~= "" and b.traits or "No traits") .. "  -  " .. ago(b.received_at)
    meta.TextSize = 9
    meta.TextColor3 = DIM
    meta.TextXAlignment = Enum.TextXAlignment.Left
    meta.TextTruncate = Enum.TextTruncate.AtEnd
    meta.TextStrokeTransparency = 1
    meta.Parent = f

    local join = Instance.new("TextButton")
    join.Size = UDim2.new(0, 54, 0, 26)
    join.Position = UDim2.new(1, -62, 0.5, -13)
    join.BackgroundColor3 = GOLD
    join.BorderSizePixel = 0
    join.Font = Enum.Font.GothamBold
    join.Text = "JOIN"
    join.TextSize = 10
    join.TextColor3 = Color3.fromRGB(25, 20, 10)
    join.TextStrokeTransparency = 1
    join.Parent = f
    corner(join, 8)
    join.MouseButton1Click:Connect(function()
        if not b.server_id or b.server_id == "" then
            join.Text = "N/A" 
            task.delay(1.2, function() join.Text = "JOIN" end) 
            return
        end
        join.Text = "..."
        task.spawn(safeTeleport, b.place_id or game.PlaceId, b.server_id)
    end)
    return f
end

-- ===== Notificações =====
local notifHolder = Instance.new("Frame")
notifHolder.AnchorPoint = Vector2.new(0.5, 0)
notifHolder.Position = UDim2.new(0.5, 0, 0, 8)
notifHolder.Size = UDim2.new(0, 340, 0, 160)
notifHolder.BackgroundTransparency = 1
notifHolder.Parent = gui

local nLayout = Instance.new("UIListLayout")
nLayout.Padding = UDim.new(0, 6)
nLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
nLayout.Parent = notifHolder

local activeNotifs = {}

local function playPing()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://125621644257669"
    s.Volume = 2
    s.Parent = SoundService
    s:Play()
    game:GetService("Debris"):AddItem(s, 5)
end

local function removeNotif(entry)
    for i, e in ipairs(activeNotifs) do
        if e == entry then table.remove(activeNotifs, i) break end
    end
    if entry.frame then
        local t = TweenService:Create(entry.frame, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
        t:Play()
        task.delay(0.28, function() pcall(function() entry.frame:Destroy() end) end)
    end
end

local function showNotif(b)
    for _, e in ipairs(activeNotifs) do
        if e.key == (tostring(b.name) .. tostring(b.server_id)) then return end
    end
    if #activeNotifs >= 3 then
        local worst, idx = nil, nil
        for i, e in ipairs(activeNotifs) do
            if not worst or e.val < worst.val then worst, idx = e, i end
        end
        if worst and worst.val >= (tonumber(b.gen_val) or 0) then return end
        if worst then removeNotif(worst) end
    end

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 56)
    f.BackgroundColor3 = BG2
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = notifHolder
    corner(f, 12)
    stroke(f, GOLD, 0.3)
    TweenService:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 0.05 }):Play()

    local n = Instance.new("TextLabel")
    n.BackgroundTransparency = 1
    n.Position = UDim2.new(0, 12, 0, 4)
    n.Size = UDim2.new(1, -76, 0, 16)
    n.Font = Enum.Font.GothamBold
    n.Text = tostring(b.name or "?")
    n.TextSize = 13
    n.TextColor3 = GOLD_SOFT
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.TextTruncate = Enum.TextTruncate.AtEnd
    n.TextStrokeTransparency = 1
    n.Parent = f

    local d = Instance.new("TextLabel")
    d.BackgroundTransparency = 1
    d.Position = UDim2.new(0, 12, 0, 20)
    d.Size = UDim2.new(1, -76, 0, 28)
    d.Font = Enum.Font.Gotham
    d.Text = fmt(b.gen_val) .. "  -  " .. tostring(b.mutation or "None") .. "\n" ..
             (b.traits and b.traits ~= "" and b.traits or "No traits")
    d.TextSize = 9
    d.TextColor3 = TXT
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextYAlignment = Enum.TextYAlignment.Top
    d.TextStrokeTransparency = 1
    d.Parent = f

    local j = Instance.new("TextButton")
    j.Size = UDim2.new(0, 54, 0, 26)
    j.Position = UDim2.new(1, -62, 0.5, -13)
    j.BackgroundColor3 = GOLD
    j.BorderSizePixel = 0
    j.Font = Enum.Font.GothamBold
    j.Text = "JOIN"
    j.TextSize = 10
    j.TextColor3 = Color3.fromRGB(25, 20, 10)
    j.TextStrokeTransparency = 1
    j.Parent = f
    corner(j, 8)
    j.MouseButton1Click:Connect(function()
        if b.server_id and b.server_id ~= "" then
            task.spawn(safeTeleport, b.place_id or game.PlaceId, b.server_id)
        end
    end)

    local entry = { frame = f, val = tonumber(b.gen_val) or 0, key = tostring(b.name) .. tostring(b.server_id) }
    table.insert(activeNotifs, entry)
    pcall(playPing)
    task.delay(3.5, function() removeNotif(entry) end)
end

-- ===== Refresh =====
local notified = {}
local function refresh()
    local raw = httpGet(API_URL())
    if not raw then return end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(data) ~= "table" then return end
    local rows = data.data or data.servers or data.results or {}
    if type(rows) ~= "table" then return end

    local kept = {}
    for _, b in ipairs(rows) do
        local key = tostring(b.name) .. "|" .. tostring(b.server_id) .. "|" .. tostring(b.gen_val)
        if passes(b) and not cleared[key] then
            b._key = key
            table.insert(kept, b)
        end
    end
    table.sort(kept, function(x, y) return (tonumber(x.gen_val) or 0) > (tonumber(y.gen_val) or 0) end)

    lastRows = kept
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    if #kept == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, -4, 0, 40)
        e.BackgroundTransparency = 1
        e.Font = Enum.Font.Gotham
        e.Text = "No logs yet"
        e.TextSize = 10
        e.TextColor3 = DIM
        e.TextStrokeTransparency = 1
        e.Parent = list
    end
    for i, b in ipairs(kept) do
        if i > 35 then break end
        makeCard(b)
        if not notified[b._key] then
            notified[b._key] = true
            showNotif(b)
            handleAutoJoin(b.server_id)
        end
    end
end

-- ===== USERS PAGE =====
local usersList = Instance.new("ScrollingFrame")
usersList.Size = UDim2.new(1, 0, 1, 0)
usersList.BackgroundTransparency = 1
usersList.BorderSizePixel = 0
usersList.ScrollBarThickness = 3
usersList.ScrollBarImageColor3 = GOLD
usersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
usersList.CanvasSize = UDim2.new(0, 0, 0, 0)
usersList.Parent = pUsers

local uLayout = Instance.new("UIListLayout")
uLayout.Padding = UDim.new(0, 6)
uLayout.Parent = usersList

local function renderUsers(users)
    for _, c in ipairs(usersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local count = 0
    for id, info in pairs(users) do
        count = count + 1
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -4, 0, 46)
        f.BackgroundColor3 = BG2
        f.BackgroundTransparency = 0.4
        f.BorderSizePixel = 0
        f.Parent = usersList
        corner(f, 12)
        stroke(f, GOLD, 0.4)

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(0, 34, 0, 34)
        img.Position = UDim2.new(0, 6, 0.5, -17)
        img.BackgroundColor3 = BG
        img.BorderSizePixel = 0
        img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(id) .. "&w=48&h=48"
        img.Parent = f
        corner(img, 17)

        local nm = Instance.new("TextLabel")
        nm.BackgroundTransparency = 1
        nm.Position = UDim2.new(0, 48, 0, 4)
        nm.Size = UDim2.new(1, -56, 0, 18)
        nm.Font = Enum.Font.GothamBold
        nm.Text = tostring(info.display or info.name)
        nm.TextSize = 12
        nm.TextColor3 = GOLD_SOFT
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.TextStrokeTransparency = 1
        nm.Parent = f

        local un = Instance.new("TextLabel")
        un.BackgroundTransparency = 1
        un.Position = UDim2.new(0, 48, 0, 22)
        un.Size = UDim2.new(1, -56, 0, 18)
        un.Font = Enum.Font.Gotham
        un.Text = "@" .. tostring(info.name)
        un.TextSize = 9
        un.TextColor3 = DIM
        un.TextXAlignment = Enum.TextXAlignment.Left
        un.TextStrokeTransparency = 1
        un.Parent = f
    end
    if count == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, -4, 0, 30)
        e.BackgroundTransparency = 1
        e.Font = Enum.Font.Gotham
        e.Text = "No joiner users online"
        e.TextSize = 10
        e.TextColor3 = DIM
        e.TextStrokeTransparency = 1
        e.Parent = usersList
    end
end

local marked, activeUsers = {}, {}
local TAG_TEXT = "Meowlzz Joiner user"

local function clearMark(plr)
    local m = marked[plr]
    if not m then return end
    pcall(function() m.hl:Destroy() end)
    pcall(function() m.bb:Destroy() end)
    marked[plr] = nil
end

local function applyMark(plr, info)
    local char = plr and plr.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    local text = (plr == LP) and TAG_TEXT or (TAG_TEXT .. "\n@" .. tostring(info.name))
    local m = marked[plr]
    if m and m.hl.Parent == char then
        if m.lbl.Text ~= text then m.lbl.Text = text end
        return
    end
    clearMark(plr)

    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillColor = GOLD_SOFT
    hl.FillTransparency = 0.4
    hl.OutlineColor = GOLD
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0, 220, 0, 54)
    bb.StudsOffset = Vector3.new(0, 2.8, 0)
    bb.AlwaysOnTop = true
    bb.Parent = char

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(1, 0, 1, 0)
    lb.Font = Enum.Font.GothamBold
    lb.Text = text
    lb.TextColor3 = GOLD_SOFT
    lb.TextStrokeColor3 = Color3.fromRGB(60, 40, 0)
    lb.TextStrokeTransparency = 0.25
    lb.TextScaled = true
    lb.Parent = bb

    marked[plr] = { hl = hl, bb = bb, lbl = lb }
end

local function joinerSync()
    local res = httpPostJSON(JOINER_URL, {
        token = JOINER_TOKEN,
        robloxUserId = tostring(LP.UserId),
        username = LP.Name,
        displayName = LP.DisplayName,
        placeId = tostring(game.PlaceId),
        jobId = tostring(game.JobId),
    })
    if not res or type(res.users) ~= "table" then return end
    local latest = {}
    for _, u in ipairs(res.users) do
        local id = u.id or u.userId or u.robloxUserId
        if id then
            latest[tostring(id)] = { name = u.name or u.username or "?", display = u.display or u.displayName or u.name or "?" }
        end
    end
    activeUsers = latest
    renderUsers(activeUsers)
    for _, plr in ipairs(Players:GetPlayers()) do
        local info = activeUsers[tostring(plr.UserId)]
        if info then applyMark(plr, info) else clearMark(plr) end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.6)
        local info = activeUsers[tostring(plr.UserId)]
        if info then applyMark(plr, info) end
    end)
end)
Players.PlayerRemoving:Connect(clearMark)
LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    local info = activeUsers[tostring(LP.UserId)]
    if info then applyMark(LP, info) end
end)

-- ===== CONFIG PAGE =====
local cfgLayout = Instance.new("UIListLayout")
cfgLayout.Padding = UDim.new(0, 6)
cfgLayout.Parent = pConfig

local function row(h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundTransparency = 1
    f.Parent = pConfig
    return f
end

local r1 = row(30)
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.Size = UDim2.new(0, 78, 1, 0)
lbl.Font = Enum.Font.GothamBold
lbl.Text = "MIN GEN"
lbl.TextSize = 10
lbl.TextColor3 = GOLD
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextStrokeTransparency = 1
lbl.Parent = r1

local box = Instance.new("TextBox")
box.Position = UDim2.new(0, 82, 0, 0)
box.Size = UDim2.new(0, 64, 1, 0)
box.BackgroundColor3 = BG2
box.BackgroundTransparency = 0.4
box.BorderSizePixel = 0
box.Font = Enum.Font.Gotham
box.Text = "1"
box.PlaceholderText = "1"
box.TextSize = 10
box.TextColor3 = TXT
box.TextStrokeTransparency = 1
box.ClearTextOnFocus = false
box.Parent = r1
corner(box, 8)
stroke(box, GOLD, 0.5)
box.FocusLost:Connect(function()
    cfg.minVal = tonumber(box.Text) or 0
    box.Text = tostring(cfg.minVal)
    task.spawn(refresh)
end)

local unitBtns = {}
local ux = 158
for _, u in ipairs({ "K", "M", "B" }) do
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(0, ux, 0, 0)
    b.Size = UDim2.new(0, 32, 1, 0)
    b.BackgroundColor3 = BG2
    b.BackgroundTransparency = 0.4
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.Text = u
    b.TextSize = 10
    b.TextColor3 = GOLD
    b.TextStrokeTransparency = 1
    b.Parent = r1
    corner(b, 8)
    stroke(b, GOLD, 0.5)
    unitBtns[u] = b
    ux = ux + 36
    b.MouseButton1Click:Connect(function()
        cfg.unit = u
        for k, bb in pairs(unitBtns) do
            bb.BackgroundColor3 = (k == u) and GOLD or BG2
            bb.BackgroundTransparency = (k == u) and 0 or 0.4
            bb.TextColor3 = (k == u) and Color3.fromRGB(25, 20, 10) or GOLD
        end
        task.spawn(refresh)
    end)
end
unitBtns.M.BackgroundColor3 = GOLD
unitBtns.M.BackgroundTransparency = 0
unitBtns.M.TextColor3 = Color3.fromRGB(25, 20, 10)

local r2 = row(18)
local rl = Instance.new("TextLabel")
rl.BackgroundTransparency = 1
rl.Size = UDim2.new(1, 0, 1, 0)
rl.Font = Enum.Font.GothamBold
rl.Text = "RARITIES"
rl.TextSize = 10
rl.TextColor3 = GOLD
rl.TextXAlignment = Enum.TextXAlignment.Left
rl.TextStrokeTransparency = 1
rl.Parent = r2

local r3 = row(32)
local rx = 0
local function toggle(key, label)
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(0, rx, 0, 0)
    b.Size = UDim2.new(0, 96, 1, 0)
    b.BackgroundColor3 = cfg[key] and GOLD or BG2
    b.BackgroundTransparency = cfg[key] and 0 or 0.4
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.Text = label
    b.TextSize = 9
    b.TextColor3 = cfg[key] and Color3.fromRGB(25, 20, 10) or GOLD
    b.TextStrokeTransparency = 1
    b.Parent = r3
    corner(b, 8)
    stroke(b, GOLD, 0.5)
    rx = rx + 100
    b.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        b.BackgroundColor3 = cfg[key] and GOLD or BG2
        b.BackgroundTransparency = cfg[key] and 0 or 0.4
        b.TextColor3 = cfg[key] and Color3.fromRGB(25, 20, 10) or GOLD
        task.spawn(refresh)
    end)
end
toggle("good", "BRAINROT GOOD")
toggle("secret", "SECRET")
toggle("og", "OG")

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, 0, 0, 32)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.Text = "Notifications: max 3, 3.5s each. Logs auto-clear with CLEAR LOGS."
hint.TextSize = 9
hint.TextWrapped = true
hint.TextColor3 = DIM
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextStrokeTransparency = 1
hint.Parent = pConfig

-- ===== Header buttons + drag =====
local minimized = false
headBtn("−", -60, function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.new(0, 440, 0, 52) or UDim2.new(0, 440, 0, 350)
end)
headBtn("✕", -30, function() gui:Destroy() end)

local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = i.Position startPos = main.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ===== Inicialização =====
setTab("finder")
task.spawn(refresh)
task.spawn(function()
    while gui.Parent do
        task.wait(1)
        pcall(refresh)
    end
end)
task.spawn(function()
    while gui.Parent do
        pcall(joinerSync)
        task.wait(HEARTBEAT)
    end
end)

print("[MeowlzzFinder] V6 Gold Edition loaded")