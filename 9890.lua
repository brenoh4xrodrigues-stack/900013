--!nocheck
-- ==========================================================
-- MEOWLZZ FINDER V5 - soft gold glass UI, side rail, rounded
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
local _a = "https://x.test/api/public/best?key=tok"
local function API_URL() return _a end
local JOINER_URL   = "https://meowlzz-hub-customizer.lovable.app/api/public/mz9k4x7q/hb"
local JOINER_TOKEN = "mz_9K3xQ7pL2vNbY4fJ8hR6tW1sZaB5dE0uMcX"
local HEARTBEAT    = 4

-- ==========================================================
-- CONSOLE LOCK + FLOOD (anti-spy / anti-log-stealer)
-- ==========================================================
do
    local StarterGui  = game:GetService("StarterGui")
    local CAS         = game:GetService("ContextActionService")
    local LogService  = game:GetService("LogService")
    local UIS2        = game:GetService("UserInputService")

    -- 1) trava a abertura do dev console (F9 / atalhos)
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

    -- 2) apenas limpa o console periodicamente (leve, sem travar o executor)
    local function wipe()
        pcall(function() if rconsoleclear then rconsoleclear() end end)
        pcall(function() if clearconsole then clearconsole() end end)
        pcall(function() LogService:ClearOutput() end)
    end

    task.spawn(function()
        while true do
            task.wait(2)
            wipe()
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
        local status = res and tonumber(res.StatusCode or res.Status or res.status)
        if ok and res and (not status or (status >= 200 and status < 300)) then return res.Body or res.body end
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
main.Size = UDim2.new(0, 430, 0, 292)
main.Position = UDim2.new(0, 20, 0.5, -146)
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

-- ===== 3D preview (viewport dos brainrots) =====
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
hint.Text = "Notifications stack up to 3 (3s each) with sound + join.\nCLEAR LOGS wipes the list and the on-screen alerts."
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
local OPEN_SIZE = UDim2.new(0, 430, 0, 292)
local minimized = false
headBtn("-", -62, function()
    minimized = not minimized
    body.Visible = not minimized
    TweenService:Create(main, TweenInfo.new(0.18), {
        Size = minimized and UDim2.new(0, 430, 0, 40) or OPEN_SIZE
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

print("[Meowlzz Finder] V5 loaded")
