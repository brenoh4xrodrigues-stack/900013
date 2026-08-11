--!nocheck
-- ==========================================================
-- MEOWLZZ FINDER V5.1 - soft gold glass UI, side rail, rounded
-- same features as V4: auto joiner, refresh, clear logs, notifs
-- ==========================================================
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local Debris           = game:GetService("Debris")

local LP = Players.LocalPlayer
if not LP then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() LP = Players.LocalPlayer end

-- ===== anti-spy: keep endpoints out of tables / gc-scannable objects =====
local _a = "https://zxlove.lovable.app/api/public/best?key=mz_7fQ4pR2xLb9VnKt3sYh8WcZ6dJ1uEaMg"
local function API_URL() return _a end
local JOINER_URL   = "https://meowlzz-hub-customizer.lovable.app/api/public/mz9k4x7q/hb"
local JOINER_TOKEN = "mz_9K3xQ7pL2vNbY4fJ8hR6tW1sZaB5dE0uMcX"
local HEARTBEAT    = 4

-- ==========================================================
-- CONSOLE LOCK + WIPE (anti-spy / anti-log-stealer) - ULTRA OTIMIZADO
-- ==========================================================
do
    local StarterGui  = game:GetService("StarterGui")
    local CAS         = game:GetService("ContextActionService")
    local LogService  = game:GetService("LogService")
    local UIS2        = game:GetService("UserInputService")

    -- 1) BLOQUEIA A ABERTURA DO DEV CONSOLE (F9 / F8)
    local function sinkKey()
        return Enum.ContextActionResult.Sink
    end
    pcall(function()
        CAS:BindActionAtPriority("_mz_lock_f9", sinkKey, false, 2147483647,
            Enum.KeyCode.F9, Enum.KeyCode.F8)
    end)
    pcall(function()
        UIS2.InputBegan:Connect(function(input, gp)
            if input.KeyCode == Enum.KeyCode.F9 then
                pcall(function() StarterGui:SetCore("DevConsoleVisible", false) end)
            end
        end)
    end)
    task.spawn(function()
        while true do
            pcall(function() StarterGui:SetCore("DevConsoleVisible", false) end)
            task.wait(0.1)
        end
    end)

    -- 2) FUNÇÃO DE LIMPEZA DO CONSOLE (instantânea)
    local function wipe()
        pcall(function() if rconsoleclear then rconsoleclear() end end)
        pcall(function() if clearconsole then clearconsole() end end)
        pcall(function() if consoleclear then consoleclear() end end)
        pcall(function() LogService:ClearOutput() end)
    end
    
    -- Exposto pro botão CLEAR LOGS da UI
    local env = (getgenv and getgenv()) or _G
    env.__mz_wipe_console = wipe

    -- 3) SISTEMA ULTRA RÁPIDO: Limpa logo que detecta novo log
    pcall(function()
        LogService.MessageOut:Connect(function()
            wipe()
        end)
    end)

    -- 4) BACKUP: Loop ultra rápido (0.05s) caso o evento não funcione
    task.spawn(function()
        while true do
            wipe()
            task.wait(0.05)
        end
    end)

    wipe()
end

local LOGO         = "rbxassetid://105194511752844"

-- ===== palette (soft gold / warm glass) =====
local GOLD      = Color3.fromRGB(240, 208, 130)
local GOLD_SOFT = Color3.fromRGB(255, 238, 195)
local GOLD_DEEP = Color3.fromRGB(196, 158, 84)
local INK       = Color3.fromRGB(34, 27, 12)
local BG        = Color3.fromRGB(20, 17, 12)
local BG2       = Color3.fromRGB(32, 27, 19)
local BG3       = Color3.fromRGB(44, 37, 25)
local TXT       = Color3.fromRGB(242, 236, 224)
local DIM       = Color3.fromRGB(160, 150, 132)

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
local cfg = { minVal = 1, unit = "M", good = true, secret = true, og = true }
local UNITS = { K = 1e3, M = 1e6, B = 1e9 }
local function threshold() return (tonumber(cfg.minVal) or 0) * (UNITS[cfg.unit] or 1e6) end

-- ===== SAVE/LOAD SYSTEM (gen data + rarities) =====
local SAVE_FILE = "meowlzz_finder_cfg.json"
local function saveConfig()
    local data = {
        minVal = cfg.minVal,
        unit = cfg.unit,
        good = cfg.good,
        secret = cfg.secret,
        og = cfg.og,
        timestamp = os.time()
    }
    local json = HttpService:JSONEncode(data)
    pcall(function()
        if syn and syn.write_file then
            syn.write_file(SAVE_FILE, json)
        elseif writefile then
            writefile(SAVE_FILE, json)
        end
    end)
end

local function loadConfig()
    local json = nil
    pcall(function()
        if syn and syn.read_file then
            json = syn.read_file(SAVE_FILE)
        elseif readfile then
            json = readfile(SAVE_FILE)
        end
    end)
    if json then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
        if ok and data then
            cfg.minVal = data.minVal or cfg.minVal
            cfg.unit = data.unit or cfg.unit
            cfg.good = data.good ~= false
            cfg.secret = data.secret ~= false
            cfg.og = data.og ~= false
        end
    end
end

-- Carregar ao iniciar
loadConfig()

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

-- ===== gui helpers =====
local parentGui = (gethui and gethui()) or CoreGui
local gui = Instance.new("ScreenGui")
gui.Name = HttpService:GenerateGUID(false)
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parentGui
if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

local function corner(o, r)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = o return c
end
local function stroke(o, col, t, th)
    local s = Instance.new("UIStroke")
    s.Color = col or GOLD
    s.Transparency = t or 0.55
    s.Thickness = th or 1
    s.Parent = o
    return s
end
local function pad(o, all)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, all) p.PaddingBottom = UDim.new(0, all)
    p.PaddingLeft = UDim.new(0, all) p.PaddingRight = UDim.new(0, all)
    p.Parent = o
    return p
end
local function goldGradient(o, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GOLD_SOFT),
        ColorSequenceKeypoint.new(1, GOLD_DEEP),
    })
    g.Rotation = rot or 90
    g.Parent = o
    return g
end

-- ===== window =====
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 512, 0, 344)
main.Position = UDim2.new(0, 20, 0.5, -172)
main.BackgroundColor3 = BG
main.BackgroundTransparency = 0.18   -- semi transparente
main.BorderSizePixel = 0
main.Parent = gui
corner(main, 16) stroke(main, GOLD, 0.35, 1.4)

do -- soft inner glow gradient over the glass
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 40, 26)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 13, 9)),
    })
    g.Rotation = 115
    g.Parent = main
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = BG2
header.BackgroundTransparency = 0.35
header.BorderSizePixel = 0
header.Parent = main
corner(header, 16)

local headerFix = Instance.new("Frame") -- squares off the bottom corners of header
headerFix.Size = UDim2.new(1, 0, 0, 16)
headerFix.Position = UDim2.new(0, 0, 1, -16)
headerFix.BackgroundColor3 = BG2
headerFix.BackgroundTransparency = 0.35
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 26, 0, 26)
logo.Position = UDim2.new(0, 10, 0, 7)
logo.BackgroundColor3 = BG3
logo.BackgroundTransparency = 0.2
logo.BorderSizePixel = 0
logo.Image = LOGO
logo.ScaleType = Enum.ScaleType.Fit
logo.ZIndex = 3
logo.Parent = header
corner(logo, 9) stroke(logo, GOLD, 0.45)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 44, 0, 5)
title.Size = UDim2.new(1, -120, 0, 16)
title.Font = Enum.Font.GothamBold
title.Text = "MEOWLZZ FINDER"
title.TextSize = 13
title.TextColor3 = GOLD_SOFT
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 44, 0, 21)
subtitle.Size = UDim2.new(1, -120, 0, 13)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "v5  -  by @Zx_Meowl on tiktok"
subtitle.TextSize = 10
subtitle.TextColor3 = DIM
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 3
subtitle.Parent = header

local function headBtn(txt, x, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 22)
    b.Position = UDim2.new(1, x, 0, 9)
    b.BackgroundColor3 = BG3
    b.BackgroundTransparency = 0.2
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.Text = txt
    b.TextSize = 12
    b.TextColor3 = GOLD
    b.ZIndex = 3
    b.Parent = header
    corner(b, 8) stroke(b, GOLD, 0.6)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = GOLD_DEEP b.TextColor3 = INK end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = BG3 b.TextColor3 = GOLD end)
    b.MouseButton1Click:Connect(fn)
    return b
end

local body = Instance.new("Frame")
body.Position = UDim2.new(0, 0, 0, 40)
body.Size = UDim2.new(1, 0, 1, -40)
body.BackgroundTransparency = 1
body.Parent = main

-- ===== side rail =====
local RAIL_W = 96
local rail = Instance.new("Frame")
rail.Size = UDim2.new(0, RAIL_W, 1, 0)
rail.BackgroundColor3 = BG2
rail.BackgroundTransparency = 0.4
rail.BorderSizePixel = 0
rail.Parent = body

local railDiv = Instance.new("Frame")
railDiv.Size = UDim2.new(0, 1, 1, -16)
railDiv.Position = UDim2.new(0, RAIL_W, 0, 8)
railDiv.BackgroundColor3 = GOLD
railDiv.BackgroundTransparency = 0.65
railDiv.BorderSizePixel = 0
railDiv.Parent = body

local railList = Instance.new("UIListLayout")
railList.Padding = UDim.new(0, 6)
railList.HorizontalAlignment = Enum.HorizontalAlignment.Center
railList.SortOrder = Enum.SortOrder.LayoutOrder
railList.Parent = rail
local railPad = Instance.new("UIPadding")
railPad.PaddingTop = UDim.new(0, 10)
railPad.PaddingLeft = UDim.new(0, 8)
railPad.PaddingRight = UDim.new(0, 8)
railPad.Parent = rail

local pages, tabBtns, tabPills = {}, {}, {}
local function makePage()
    local p = Instance.new("Frame")
    p.Position = UDim2.new(0, RAIL_W + 12, 0, 10)
    p.Size = UDim2.new(1, -(RAIL_W + 24), 1, -20)
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
        local on = (k == id)
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = on and GOLD or BG3,
            BackgroundTransparency = on and 0 or 0.25,
            TextColor3 = on and INK or GOLD,
        }):Play()
        tabPills[k].BackgroundTransparency = on and 0 or 1
    end
end

local order = 0
local function makeTab(id, label)
    order = order + 1
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34)
    b.LayoutOrder = order
    b.BackgroundColor3 = BG3
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.Text = label
    b.TextSize = 10
    b.TextColor3 = GOLD
    b.Parent = rail
    corner(b, 10) stroke(b, GOLD, 0.7)

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 3, 0, 16)
    pill.Position = UDim2.new(0, 4, 0.5, -8)
    pill.BackgroundColor3 = INK
    pill.BackgroundTransparency = 1
    pill.BorderSizePixel = 0
    pill.Parent = b
    corner(pill, 2)
    tabPills[id] = pill

    b.MouseButton1Click:Connect(function() setTab(id) end)
    tabBtns[id] = b
    pages[id] = makePage()
    return pages[id]
end

local pLogs   = makeTab("logs",   "LOGS")
local pConfig = makeTab("config", "CONFIG")
local pUsers  = makeTab("users",  "USERS")

local railFoot = Instance.new("TextLabel")
railFoot.LayoutOrder = 99
railFoot.Size = UDim2.new(1, 0, 0, 26)
railFoot.BackgroundTransparency = 1
railFoot.Font = Enum.Font.Gotham
railFoot.Text = "MEOWLZZ\nHUB"
railFoot.TextSize = 8
railFoot.TextColor3 = DIM
railFoot.Parent = rail

-- ===== logs page =====
local quickBar = Instance.new("Frame")
quickBar.Size = UDim2.new(1, 0, 0, 26)
quickBar.BackgroundTransparency = 1
quickBar.Parent = pLogs
local qLayout = Instance.new("UIListLayout")
qLayout.FillDirection = Enum.FillDirection.Horizontal
qLayout.Padding = UDim.new(0, 6)
qLayout.VerticalAlignment = Enum.VerticalAlignment.Center
qLayout.Parent = quickBar

local function quickBtn(txt, w, fn, filled)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 1, 0)
    b.BackgroundColor3 = filled and GOLD or BG3
    b.BackgroundTransparency = filled and 0 or 0.2
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.Text = txt
    b.TextSize = 9
    b.TextColor3 = filled and INK or GOLD
    b.Parent = quickBar
    corner(b, 9) stroke(b, GOLD, filled and 0.9 or 0.65)
    b.MouseButton1Click:Connect(fn)
    return b
end

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 0, 0, 32)
list.Size = UDim2.new(1, 0, 1, -32)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = GOLD
list.ScrollBarImageTransparency = 0.3
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = pLogs
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
        pcall(function() TeleportService:Teleport(tonumber(placeId) or game.PlaceId, LP) end)
        warn("[Meowlzz] join fallback:", err)
    end
end

local function joinButton(parent, b, w, h)
    local j = Instance.new("TextButton")
    j.Size = UDim2.new(0, w, 0, h)
    j.Position = UDim2.new(1, -(w + 10), 0.5, -(h/2))
    j.BackgroundColor3 = GOLD
    j.BorderSizePixel = 0
    j.AutoButtonColor = false
    j.Font = Enum.Font.GothamBold
    j.Text = "JOIN"
    j.TextSize = 10
    j.TextColor3 = INK
    j.ZIndex = 3
    j.Parent = parent
    corner(j, 9)
    goldGradient(j, 90)
    j.MouseButton1Click:Connect(function()
        if not b.server_id or b.server_id == "" then
            j.Text = "N/A" task.delay(1.2, function() j.Text = "JOIN" end) return
        end
        j.Text = "..."
        task.spawn(safeTeleport, b.place_id or game.PlaceId, b.server_id)
    end)
    return j
end

local function makeCard(b)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 56)
    f.BackgroundColor3 = BG2
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.Parent = list
    corner(f, 12) stroke(f, GOLD, 0.72)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -16)
    accent.Position = UDim2.new(0, 7, 0, 8)
    accent.BackgroundColor3 = GOLD
    accent.BorderSizePixel = 0
    accent.Parent = f
    corner(accent, 2)

    local n = Instance.new("TextLabel")
    n.BackgroundTransparency = 1
    n.Position = UDim2.new(0, 18, 0, 7)
    n.Size = UDim2.new(1, -80, 0, 15)
    n.Font = Enum.Font.GothamBold
    n.Text = tostring(b.name or "?")
    n.TextSize = 12
    n.TextColor3 = GOLD_SOFT
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.TextTruncate = Enum.TextTruncate.AtEnd
    n.Parent = f

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0, 18, 0, 23)
    sub.Size = UDim2.new(1, -80, 0, 14)
    sub.Font = Enum.Font.GothamMedium
    sub.Text = fmt(b.gen_val) .. "  •  " .. tostring(b.rarity or "?")
    sub.TextSize = 10
    sub.TextColor3 = TXT
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.Parent = f

    local meta = Instance.new("TextLabel")
    meta.BackgroundTransparency = 1
    meta.Position = UDim2.new(0, 18, 0, 37)
    meta.Size = UDim2.new(1, -80, 0, 13)
    meta.Font = Enum.Font.Gotham
    meta.Text = (b.traits and b.traits ~= "" and b.traits or "No traits") .. "  •  " .. ago(b.received_at)
    meta.TextSize = 9
    meta.TextColor3 = DIM
    meta.TextXAlignment = Enum.TextXAlignment.Left
    meta.TextTruncate = Enum.TextTruncate.AtEnd
    meta.Parent = f

    joinButton(f, b, 52, 24)
    return f
end

-- ===== notifications (max 3, 3s, sound) =====
local notifHolder = Instance.new("Frame")
notifHolder.AnchorPoint = Vector2.new(0.5, 0)
notifHolder.Position = UDim2.new(0.5, 0, 0, 10)
notifHolder.Size = UDim2.new(0, 340, 0, 200)
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
    Debris:AddItem(s, 5)
end

local function removeNotif(entry)
    for i, e in ipairs(activeNotifs) do
        if e == entry then table.remove(activeNotifs, i) break end
    end
    if entry.frame then
        TweenService:Create(entry.frame, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        task.delay(0.28, function() pcall(function() entry.frame:Destroy() end) end)
    end
end

local function showNotif(b)
    for _, e in ipairs(activeNotifs) do
        if e.key == (tostring(b.name) .. tostring(b.server_id)) then return end
    end
    if #activeNotifs >= 3 then
        local worst, _idx = nil, nil
        for i, e in ipairs(activeNotifs) do
            if not worst or e.val < worst.val then worst, _idx = e, i end
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
    corner(f, 12) stroke(f, GOLD, 0.35)
    TweenService:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 0.12 }):Play()

    local accentN = Instance.new("Frame")
    accentN.Size = UDim2.new(0, 3, 1, -16)
    accentN.Position = UDim2.new(0, 8, 0, 8)
    accentN.BackgroundColor3 = GOLD
    accentN.BorderSizePixel = 0
    accentN.Parent = f
    corner(accentN, 2)

    local n = Instance.new("TextLabel")
    n.BackgroundTransparency = 1
    n.Position = UDim2.new(0, 18, 0, 7)
    n.Size = UDim2.new(1, -82, 0, 15)
    n.Font = Enum.Font.GothamBold
    n.Text = tostring(b.name or "?")
    n.TextSize = 12
    n.TextColor3 = GOLD_SOFT
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.TextTruncate = Enum.TextTruncate.AtEnd
    n.Parent = f

    local d = Instance.new("TextLabel")
    d.BackgroundTransparency = 1
    d.Position = UDim2.new(0, 18, 0, 23)
    d.Size = UDim2.new(1, -82, 0, 26)
    d.Font = Enum.Font.Gotham
    d.Text = fmt(b.gen_val) .. "  •  " .. tostring(b.mutation or "None") .. "\n" ..
             (b.traits and b.traits ~= "" and b.traits or "No traits")
    d.TextSize = 9
    d.TextColor3 = TXT
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextYAlignment = Enum.TextYAlignment.Top
    d.Parent = f

    joinButton(f, b, 52, 24)

    local entry = { frame = f, val = tonumber(b.gen_val) or 0, key = tostring(b.name) .. tostring(b.server_id) }
    table.insert(activeNotifs, entry)
    pcall(playPing)
    task.delay(3, function() removeNotif(entry) end)
end

-- ===== refresh =====
local notified = {}
local statusLbl
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
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    if #kept == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, -6, 0, 46)
        e.BackgroundTransparency = 1
        e.Font = Enum.Font.Gotham
        e.Text = "No logs yet"
        e.TextSize = 10
        e.TextColor3 = DIM
        e.Parent = list
    end
    for i, b in ipairs(kept) do
        if i > 30 then break end
        makeCard(b)
        if not notified[b._key] then
            notified[b._key] = true
            showNotif(b)
        end
    end
    if statusLbl then statusLbl.Text = "TOTAL LOGS " .. tostring(#kept) end
end

quickBtn("REFRESH", 62, function() task.spawn(refresh) end, true)
quickBtn("CLEAR", 54, function()
    pcall(function()
        local env = (getgenv and getgenv()) or _G
        if env.__mz_wipe_console then env.__mz_wipe_console() end
    end)
    for _, b in ipairs(lastRows) do cleared[b._key] = true end
    for _, e in ipairs({ table.unpack(activeNotifs) }) do removeNotif(e) end
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    notified = {}
    if statusLbl then statusLbl.Text = "TOTAL LOGS 0" end
end)
quickBtn("TOP", 32, function() list.CanvasPosition = Vector2.new(0, 0) end)

-- ===== AUTO JOINER / AUTO FORCE =====
local autoJoin, autoForce = false, false

local function toggleBtn(txt, w, getter, setter)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 1, 0)
    b.BackgroundColor3 = BG3
    b.BackgroundTransparency = 0.2
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.Text = txt
    b.TextSize = 8
    b.TextColor3 = DIM
    b.Parent = quickBar
    corner(b, 9)
    local st = stroke(b, GOLD, 0.7)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 5, 0, 5)
    dot.Position = UDim2.new(0, 5, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(120, 110, 95)
    dot.BorderSizePixel = 0
    dot.Parent = b
    corner(dot, 3)
    local function paint()
        local on = getter()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = on and GOLD or BG3,
            BackgroundTransparency = on and 0 or 0.2,
            TextColor3 = on and INK or DIM,
        }):Play()
        dot.BackgroundColor3 = on and Color3.fromRGB(70, 200, 110) or Color3.fromRGB(120, 110, 95)
        st.Transparency = on and 0.9 or 0.7
    end
    b.MouseButton1Click:Connect(function() setter(not getter()) paint() end)
    paint()
    return b
end

toggleBtn("A-JOINER", 66, function() return autoJoin end, function(v) autoJoin = v end)
toggleBtn("A-FORCE", 64, function() return autoForce end, function(v)
    autoForce = v
    if v then autoJoin = true end
end)

local function bestRow()
    for _, b in ipairs(lastRows) do
        local sid = tostring(b.server_id or "")
        if sid ~= "" and sid ~= tostring(game.JobId) then return b end
    end
    return nil
end

-- teleport falhou? tenta de novo na hora
TeleportService.TeleportInitFailed:Connect(function(_, _, msg)
    if autoForce or autoJoin then
        task.wait(autoForce and 0.2 or 1.5)
        local b = bestRow()
        if b then pcall(safeTeleport, b.place_id or game.PlaceId, b.server_id) end
    end
end)

-- AUTO JOINER: fica tentando entrar no servidor da melhor log
task.spawn(function()
    while gui.Parent do
        if autoJoin and not autoForce then
            local b = bestRow()
            if b then pcall(safeTeleport, b.place_id or game.PlaceId, b.server_id) end
            task.wait(5)
        else
            task.wait(0.5)
        end
    end
end)

-- AUTO FORCE: forca entrada instantaneamente ate ir
task.spawn(function()
    while gui.Parent do
        if autoForce then
            local b = bestRow()
            if b then
                pcall(safeTeleport, b.place_id or game.PlaceId, b.server_id)
                task.wait(0.35)
            else
                task.wait(0.35)
            end
        else
            task.wait(0.4)
        end
    end
end)

statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -284, 1, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = Enum.Font.Gotham
statusLbl.Text = "TOTAL LOGS 0"
statusLbl.TextSize = 8
statusLbl.TextColor3 = DIM
statusLbl.TextXAlignment = Enum.TextXAlignment.Right
statusLbl.Parent = quickBar

-- ===== config page =====
local cfgScroll = Instance.new("ScrollingFrame")
cfgScroll.Size = UDim2.new(1, 0, 1, 0)
cfgScroll.BackgroundTransparency = 1
cfgScroll.BorderSizePixel = 0
cfgScroll.ScrollBarThickness = 3
cfgScroll.ScrollBarImageColor3 = GOLD
cfgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
cfgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
cfgScroll.Parent = pConfig
local cfgLayout = Instance.new("UIListLayout")
cfgLayout.Padding = UDim.new(0, 8)
cfgLayout.Parent = cfgScroll

local function section(titleTxt, h)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -6, 0, h)
    card.BackgroundColor3 = BG2
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = cfgScroll
    corner(card, 12) stroke(card, GOLD, 0.72)

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.new(0, 12, 0, 8)
    t.Size = UDim2.new(1, -20, 0, 13)
    t.Font = Enum.Font.GothamBold
    t.Text = titleTxt
    t.TextSize = 9
    t.TextColor3 = GOLD
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = card
    return card
end

-- min gen
local secGen = section("MINIMUM GENERATION", 66)

local box = Instance.new("TextBox")
box.Position = UDim2.new(0, 12, 0, 28)
box.Size = UDim2.new(0, 92, 0, 28)
box.BackgroundColor3 = BG3
box.BackgroundTransparency = 0.15
box.BorderSizePixel = 0
box.Font = Enum.Font.GothamMedium
box.Text = "1"
box.PlaceholderText = "1"
box.PlaceholderColor3 = DIM
box.TextSize = 11
box.TextColor3 = TXT
box.ClearTextOnFocus = false
box.Parent = secGen
corner(box, 9) stroke(box, GOLD, 0.65)
box.FocusLost:Connect(function()
    cfg.minVal = tonumber(box.Text) or 0
    box.Text = tostring(cfg.minVal)
    task.spawn(refresh)
    saveConfig()
end)

local unitHolder = Instance.new("Frame")
unitHolder.Position = UDim2.new(0, 112, 0, 28)
unitHolder.Size = UDim2.new(1, -124, 0, 28)
unitHolder.BackgroundTransparency = 1
unitHolder.Parent = secGen
local uL = Instance.new("UIListLayout")
uL.FillDirection = Enum.FillDirection.Horizontal
uL.Padding = UDim.new(0, 6)
uL.Parent = unitHolder

local unitBtns = {}
local function paintUnit(b, on)
    b.BackgroundColor3 = on and GOLD or BG3
    b.BackgroundTransparency = on and 0 or 0.15
    b.TextColor3 = on and INK or GOLD
end
for _, u in ipairs({ "K", "M", "B" }) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 38, 1, 0)
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.Text = u
    b.TextSize = 11
    b.Parent = unitHolder
    corner(b, 9) stroke(b, GOLD, 0.65)
    paintUnit(b, u == cfg.unit)
    unitBtns[u] = b
    b.MouseButton1Click:Connect(function()
        cfg.unit = u
        for k, bb in pairs(unitBtns) do paintUnit(bb, k == u) end
        task.spawn(refresh)
        saveConfig()
    end)
end

-- rarities
local secRar = section("RARITY FILTER", 104)
local rarHolder = Instance.new("Frame")
rarHolder.Position = UDim2.new(0, 12, 0, 28)
rarHolder.Size = UDim2.new(1, -24, 0, 66)
rarHolder.BackgroundTransparency = 1
rarHolder.Parent = secRar
local rL = Instance.new("UIListLayout")
rL.Padding = UDim.new(0, 6)
rL.Parent = rarHolder

local function toggle(key, label)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundColor3 = BG3
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Text = ""
    row.Parent = rarHolder
    corner(row, 9) stroke(row, GOLD, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Position = UDim2.new(0, 12, 0, 0)
    lb.Size = UDim2.new(1, -60, 1, 0)
    lb.Font = Enum.Font.GothamBold
    lb.Text = label
    lb.TextSize = 9
    lb.TextColor3 = GOLD_SOFT
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = row

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, -10, 0.5, 0)
    track.Size = UDim2.new(0, 32, 0, 14)
    track.BackgroundColor3 = cfg[key] and GOLD or BG
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 7) stroke(track, GOLD, 0.6)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = cfg[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
    knob.BackgroundColor3 = cfg[key] and INK or GOLD
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 5)

    row.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        TweenService:Create(track, TweenInfo.new(0.15), { BackgroundColor3 = cfg[key] and GOLD or BG }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = cfg[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5),
            BackgroundColor3 = cfg[key] and INK or GOLD,
        }):Play()
        task.spawn(refresh)
        saveConfig()
    end)
end
toggle("good",   "BRAINROT GOOD")
toggle("secret", "SECRET")
toggle("og",     "OG")

local secInfo = section("INFO", 62)
local hint = Instance.new("TextLabel")
hint.Position = UDim2.new(0, 12, 0, 26)
hint.Size = UDim2.new(1, -24, 0, 30)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.Text = "A-JOINER keeps retrying the best log server. A-FORCE\nspams the join until it lands. CLEAR wipes logs + console."
hint.TextSize = 9
hint.TextWrapped = true
hint.TextColor3 = DIM
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.Parent = secInfo

-- ===== users page (auto joiner) =====
local usersHead = Instance.new("TextLabel")
usersHead.Size = UDim2.new(1, 0, 0, 18)
usersHead.BackgroundTransparency = 1
usersHead.Font = Enum.Font.GothamBold
usersHead.Text = "JOINER USERS ONLINE"
usersHead.TextSize = 9
usersHead.TextColor3 = GOLD
usersHead.TextXAlignment = Enum.TextXAlignment.Left
usersHead.Parent = pUsers

local usersList = Instance.new("ScrollingFrame")
usersList.Position = UDim2.new(0, 0, 0, 24)
usersList.Size = UDim2.new(1, 0, 1, -24)
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
    for _, c in ipairs(usersList:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local count = 0
    for id, info in pairs(users) do
        count = count + 1
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -6, 0, 44)
        f.BackgroundColor3 = BG2
        f.BackgroundTransparency = 0.2
        f.BorderSizePixel = 0
        f.Parent = usersList
        corner(f, 12) stroke(f, GOLD, 0.72)

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(0, 32, 0, 32)
        img.Position = UDim2.new(0, 7, 0, 6)
        img.BackgroundColor3 = BG3
        img.BorderSizePixel = 0
        img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(id) .. "&w=60&h=60"
        img.Parent = f
        corner(img, 16) stroke(img, GOLD, 0.5)

        local nm = Instance.new("TextLabel")
        nm.BackgroundTransparency = 1
        nm.Position = UDim2.new(0, 47, 0, 6)
        nm.Size = UDim2.new(1, -56, 0, 16)
        nm.Font = Enum.Font.GothamBold
        nm.Text = tostring(info.display or info.name)
        nm.TextSize = 11
        nm.TextColor3 = GOLD_SOFT
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.TextTruncate = Enum.TextTruncate.AtEnd
        nm.Parent = f

        local un = Instance.new("TextLabel")
        un.BackgroundTransparency = 1
        un.Position = UDim2.new(0, 47, 0, 22)
        un.Size = UDim2.new(1, -56, 0, 14)
        un.Font = Enum.Font.Gotham
        un.Text = "@" .. tostring(info.name)
        un.TextSize = 9
        un.TextColor3 = DIM
        un.TextXAlignment = Enum.TextXAlignment.Left
        un.TextTruncate = Enum.TextTruncate.AtEnd
        un.Parent = f
    end
    usersHead.Text = "JOINER USERS ONLINE  (" .. tostring(count) .. ")"
    if count == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, -6, 0, 36)
        e.BackgroundTransparency = 1
        e.Font = Enum.Font.Gotham
        e.Text = "No joiner users online"
        e.TextSize = 10
        e.TextColor3 = DIM
        e.Parent = usersList
    end
end

-- tag + highlight
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

-- ===== header buttons + drag =====
local OPEN_SIZE = UDim2.new(0, 512, 0, 344)
local minimized = false
headBtn("-", -62, function()
    minimized = not minimized
    body.Visible = not minimized
    TweenService:Create(main, TweenInfo.new(0.18), {
        Size = minimized and UDim2.new(0, 512, 0, 40) or OPEN_SIZE
    }):Play()
end)
headBtn("X", -32, function() gui:Destroy() end)

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

-- mobile scaling
if UserInputService.TouchEnabled then
    local sc = Instance.new("UIScale")
    sc.Scale = 0.86
    sc.Parent = main
end

setTab("logs")
renderUsers({})
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

print("[Meowlzz Finder] V5.1 loaded")
