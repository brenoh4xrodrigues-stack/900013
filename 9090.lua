--[[
    Meowlzz Hub Semi Invisble
    ]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- CONFIG (persistência)
-- ============================================================
local CONFIG_FILE = "MeowlzzHub_SemiInvis.json"
local Config = {
    InvisStealAngle = 225,
    SinkSliderValue = 7,
    AutoRecoverLagback = true,
    AutoInvisDuringSteal = false,
    WalkSpeedEnabled = false,
    WalkSpeedValue = 16,
    AntiDieEnabled = false,
}
pcall(function()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and typeof(data) == "table" then
            for k, v in pairs(data) do Config[k] = v end
        end
    end
end)
local function saveConfig()
    pcall(function()
        if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end
    end)
end

-- ============================================================
-- BYPASS ANTI-KICK (do script original)
-- Bloqueia o remote de deteccao ("StopTrying") que causa o kick
-- ============================================================
pcall(function()
    if hookfunction then
        local old; old = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
            local args = {...}
            local arg1 = args[1]
            if #self.Name == 67 and arg1 and typeof(arg1) == "string" then
                if string.find(arg1, "StopTrying") then
                    return -- bloqueado: bypass anti-kick
                end
            end
            return old(self, ...)
        end)
    elseif hookmetamethod and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                local arg1 = select(1, ...)
                if #self.Name == 67 and arg1 and typeof(arg1) == "string" and string.find(arg1, "StopTrying") then
                    return
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- ============================================================
-- ANTI-DIE / ANTI-RESET (do script original) — com toggle
-- ============================================================
local AntiDieConn = nil
local function setupAntiDie()
    if AntiDieConn then pcall(function() AntiDieConn:Disconnect() end); AntiDieConn = nil end
    if not Config.AntiDieEnabled then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    AntiDieConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if not Config.AntiDieEnabled then return end
        if humanoid.Health <= 0 then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end
local function setAntiDieEnabled(on)
    Config.AntiDieEnabled = on and true or false
    saveConfig()
    setupAntiDie()
end
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    setupAntiDie()
end)
task.defer(setupAntiDie)

-- ============================================================
-- TOGGLE REGISTRY
-- ============================================================
local ToggleState = {}
local function regToggle(name, default)
    if not ToggleState[name] then ToggleState[name] = {value = default and true or false, listeners = {}} end
end
local function getToggle(name) regToggle(name); return ToggleState[name].value end
local function setToggle(name, v)
    regToggle(name)
    ToggleState[name].value = v and true or false
    for _, fn in ipairs(ToggleState[name].listeners) do pcall(fn, ToggleState[name].value) end
end
local function onToggleChanged(name, fn)
    regToggle(name); table.insert(ToggleState[name].listeners, fn)
end

-- ============================================================
-- TEMA GOLD (dourado)
-- ============================================================
local Theme = {
    Background   = Color3.fromRGB(24, 18, 6),    -- fundo escuro amadeirado
    Panel        = Color3.fromRGB(48, 38, 12),   -- linhas/painéis internos
    TitleBar     = Color3.fromRGB(38, 29, 8),
    Gold         = Color3.fromRGB(255, 200, 60), -- dourado principal
    GoldDark     = Color3.fromRGB(184, 138, 26),
    GoldLight    = Color3.fromRGB(255, 226, 130),
    Text         = Color3.fromRGB(255, 236, 190),
    Dim          = Color3.fromRGB(200, 170, 110),
    ToggleOff    = Color3.fromRGB(70, 58, 28),
    SliderBg     = Color3.fromRGB(58, 46, 16),
    InputBg      = Color3.fromRGB(40, 32, 10),
}

-- ============================================================
-- GUI BASE
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "MeowlzzHub_SemiInvis"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999999
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o; return c end
local function stroke(o, col, th, tr)
    local s = Instance.new("UIStroke"); s.Color = col or Theme.GoldDark; s.Thickness = th or 1
    s.Transparency = tr or 0; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s
end
local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
end

-- ============================================================
-- PAINEL PRINCIPAL (altura reduzida: 390)
-- ============================================================
local PANEL_W, PANEL_H, TITLE_H = 300, 390, 36   -- ALTURA REDUZIDA

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position = UDim2.new(0, 80, 0.5, -PANEL_H / 2)
panel.BackgroundColor3 = Theme.Background
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = gui
corner(panel, 14)
stroke(panel, Theme.Gold, 1.5, 0.05)

-- ---------- BARRA DE TÍTULO ----------
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = Theme.TitleBar
titleBar.BackgroundTransparency = 0.05
titleBar.BorderSizePixel = 0
titleBar.Parent = panel
corner(titleBar, 14)

-- círculo com a foto
local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 28, 0, 28)   -- ligeiramente menor
avatar.Position = UDim2.new(0, 6, 0.5, -14)
avatar.BackgroundColor3 = Theme.GoldDark
avatar.Image = "rbxassetid://127524836439200"
avatar.Parent = titleBar
corner(avatar, 999)
stroke(avatar, Theme.Gold, 1.5, 0)

-- título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 40, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Meowlzz Semi Invisble || https://discord.gg/cq7GCFPYVb "
title.TextColor3 = Theme.Gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 7
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = titleBar

-- botão minimizar
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -34, 0.5, -13)
minBtn.BackgroundColor3 = Theme.Panel
minBtn.Text = "—"
minBtn.TextColor3 = Theme.Gold
minBtn.Font = Enum.Font.GothamBlack
minBtn.TextSize = 14
minBtn.AutoButtonColor = false
minBtn.Parent = titleBar
corner(minBtn, 8)
stroke(minBtn, Theme.GoldDark, 1, 0.2)

-- divisória dourada
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.new(0, 12, 0, TITLE_H)
divider.BackgroundColor3 = Theme.Gold
divider.BackgroundTransparency = 0.15
divider.BorderSizePixel = 0
divider.Parent = panel

-- ---------- CORPO ----------
local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, -16, 1, -(TITLE_H + 12))
body.Position = UDim2.new(0, 8, 0, TITLE_H + 6)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 3
body.ScrollBarImageColor3 = Theme.Gold
body.CanvasSize = UDim2.new(0, 0, 0, 0)
body.Active = true
body.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 5); lay.Parent = body  -- Padding reduzido
lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    body.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8)
end)

-- ---------- MINIMIZAR / RESTAURAR ----------
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        minBtn.Text = "+"
        body.Visible = false
        divider.Visible = false
        tw(panel, {Size = UDim2.new(0, PANEL_W, 0, TITLE_H)}, 0.2)
    else
        minBtn.Text = "—"
        divider.Visible = true
        tw(panel, {Size = UDim2.new(0, PANEL_W, 0, PANEL_H)}, 0.2)
        task.delay(0.12, function() body.Visible = true end)
    end
end)

-- ---------- ARRASTÁVEL (pela barra de título) ----------
do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = panel.Position
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ============================================================
-- WIDGETS (estilo gold) — com alturas reduzidas
-- ============================================================
local function makeSyncStateRow(parent, text, toggleName, callback)
    regToggle(toggleName, getToggle(toggleName))
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 32); row.BackgroundColor3 = Theme.Panel
    row.BackgroundTransparency = 0.15; row.Parent = parent; corner(row, 8)
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -84, 1, 0); label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamSemibold; label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd; label.Parent = row
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 68, 0, 26); btn.Position = UDim2.new(1, -74, 0.5, -13)
    btn.Font = Enum.Font.GothamBlack; btn.TextSize = 11; btn.AutoButtonColor = false; btn.Parent = row; corner(btn, 7)
    local function refresh(val)
        btn.BackgroundColor3 = val and Theme.Gold or Theme.ToggleOff
        btn.TextColor3 = val and Theme.Background or Theme.Dim
        btn.Text = val and "ON" or "OFF"
    end
    refresh(getToggle(toggleName)); onToggleChanged(toggleName, function(val) refresh(val) end)
    btn.MouseButton1Click:Connect(function()
        local nv = not getToggle(toggleName); setToggle(toggleName, nv)
        if callback then callback(nv) end
    end)
    return function(ns, fire)
        if typeof(ns) == "boolean" then setToggle(toggleName, ns); if fire ~= false and callback then callback(ns) end end
    end
end

local function makeQuickSlider(parent, text, min, max, default, callback, suffix)
    local holder = Instance.new("Frame"); holder.Size = UDim2.new(1, -4, 0, 46); holder.BackgroundTransparency = 1; holder.Parent = parent
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, 0, 0, 16); label.Position = UDim2.new(0, 4, 0, 0)
    label.BackgroundTransparency = 1; label.Text = text .. ": " .. tostring(default) .. (suffix or "")
    label.TextColor3 = Theme.Text; label.Font = Enum.Font.GothamMedium; label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = holder
    local bar = Instance.new("Frame"); bar.Size = UDim2.new(1, -10, 0, 6); bar.Position = UDim2.new(0, 4, 0, 26)
    bar.BackgroundColor3 = Theme.SliderBg; bar.BorderSizePixel = 0; bar.Parent = holder; corner(bar, 10)
    local fill = Instance.new("Frame"); fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Gold; fill.BorderSizePixel = 0; fill.Parent = bar; corner(fill, 10)
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 0.5, 0)
    knob.BackgroundColor3 = Theme.GoldLight; knob.BorderSizePixel = 0; knob.Parent = bar; corner(knob, 20)
    stroke(knob, Theme.GoldDark, 1, 0)
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor((min + (max - min) * rel) * 10 + 0.5) / 10
        fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, 0, 0.5, 0)
        label.Text = text .. ": " .. tostring(v) .. (suffix or "")
        if callback then callback(v) end
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    local function setVal(v, silent)
        v = math.clamp(v, min, max)
        local rel = (v - min) / (max - min)
        local displayVal = math.floor(v * 10 + 0.5) / 10
        fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, 0, 0.5, 0)
        label.Text = text .. ": " .. tostring(displayVal) .. (suffix or "")
        if callback and not silent then callback(displayVal) end
    end
    return {Set = setVal}
end

local function makeMainSliderWithInput(parent, text, min, max, default, callback, suffix)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, -4, 0, 48); row.BackgroundColor3 = Theme.Panel
    row.BackgroundTransparency = 0.15; row.Parent = parent; corner(row, 8)
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.6, 0, 0, 16); label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1; label.Text = text; label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium; label.TextSize = 11; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    local box = Instance.new("TextBox"); box.Size = UDim2.new(0.28, 0, 0, 16); box.Position = UDim2.new(0.72, -8, 0, 4)
    box.BackgroundColor3 = Theme.InputBg; box.BorderSizePixel = 0
    box.Text = tostring(default) .. (suffix or ""); box.TextColor3 = Theme.Gold
    box.Font = Enum.Font.GothamBold; box.TextSize = 10; box.ClearTextOnFocus = false; box.Parent = row
    corner(box, 5); stroke(box, Theme.GoldDark, 1, 0.3)
    local bar = Instance.new("Frame"); bar.Size = UDim2.new(1, -20, 0, 6); bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Theme.SliderBg; bar.BorderSizePixel = 0; bar.Parent = row; corner(bar, 10)
    local fill = Instance.new("Frame"); fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Gold; fill.BorderSizePixel = 0; fill.Parent = bar; corner(fill, 10)
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 14, 0, 14); knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 0.5, 0)
    knob.BackgroundColor3 = Theme.GoldLight; knob.BorderSizePixel = 0; knob.Parent = bar; corner(knob, 20)
    stroke(knob, Theme.GoldDark, 1, 0)
    local current = default
    local function apply(v, silent)
        v = math.clamp(v, min, max)
        current = v
        local rel = (v - min) / (max - min)
        fill.Size = UDim2.new(rel, 0, 1, 0); knob.Position = UDim2.new(rel, 0, 0.5, 0)
        box.Text = tostring(math.floor(v * 100 + 0.5) / 100) .. (suffix or "")
        if callback and not silent then callback(v) end
    end
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        apply(min + (max - min) * rel)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    box.FocusLost:Connect(function()
        local n = tonumber((box.Text:gsub("[^%d%.%-]", "")))
        if n then apply(n) else apply(current, true) end
    end)
    return {Set = function(v, silent) apply(v, silent) end}
end

-- ============================================================
-- WALKSPEED (CFrame Bypass) — igual ao original
-- ============================================================
local WalkSpeedState = {enabled = false, conn = nil, speed = Config.WalkSpeedValue or 16}
local function setWalkSpeedEnabled(en, isAuto)
    WalkSpeedState.enabled = en
    if not isAuto then
        -- so salva na config quando for acao do usuario (nao do auto do steal)
        Config.WalkSpeedEnabled = en
        saveConfig()
    end
    setToggle("WalkSpeed", en)
    if WalkSpeedState.conn then WalkSpeedState.conn:Disconnect(); WalkSpeedState.conn = nil end
    if not en then return end
    WalkSpeedState.conn = RunService.Heartbeat:Connect(function(dt)
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then return end
        if humanoid.MoveDirection.Magnitude > 0 and WalkSpeedState.speed > humanoid.WalkSpeed then
            local extraSpeed = WalkSpeedState.speed - humanoid.WalkSpeed
            rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * extraSpeed * dt)
        end
    end)
end
local function setWalkSpeedValue(v)
    v = math.clamp(math.floor(v + 0.5), 15, 29)
    WalkSpeedState.speed = v
    Config.WalkSpeedValue = v
    saveConfig()
    return v
end
_G.setWalkSpeedEnabled = setWalkSpeedEnabled
_G.setWalkSpeedValue = setWalkSpeedValue

-- ============================================================
-- INVISIBLE STEAL — igual ao original
-- ============================================================
do
    local animPlaying = false
    local tracks = {}
    local clone, oldRoot, hip, connection
    local folderConnections = {}
    local serverGhosts = {}
    local ghostEnabled = true
    local lagbackCallCount = 0
    local lagbackWindowStart = 0
    local lastLagbackTime = 0
    local errorOrbActive = false
    local errorOrb = nil
    local errorOrbConnection = nil

    _G.invisibleStealEnabled = false
    _G.InvisStealAngle = Config.InvisStealAngle or 225
    _G.SinkSliderValue = Config.SinkSliderValue or 7
    _G.AutoRecoverLagback = Config.AutoRecoverLagback ~= nil and Config.AutoRecoverLagback or true
    _G.AutoInvisDuringSteal = Config.AutoInvisDuringSteal or false

    local function clearErrorOrb()
        if errorOrb and errorOrb.Parent then errorOrb:Destroy() end
        errorOrb = nil; errorOrbActive = false
        if errorOrbConnection then errorOrbConnection:Disconnect(); errorOrbConnection = nil end
    end

    local function createErrorOrb()
        if errorOrbActive then return end
        errorOrbActive = true
        for _, ghost in pairs(serverGhosts) do if ghost and ghost.Parent then ghost:Destroy() end end
        serverGhosts = {}
    end

    local function createServerGhost(position)
        if not ghostEnabled or errorOrbActive then return end
        local now = tick()
        if now - lastLagbackTime < 0.05 then return end
        lastLagbackTime = now
        if now - lagbackWindowStart > 1 then lagbackCallCount = 0; lagbackWindowStart = now end
        lagbackCallCount = lagbackCallCount + 1
        if lagbackCallCount >= 7 then createErrorOrb(); return end
        for _, g in pairs(serverGhosts) do if g and g.Parent then g:Destroy() end end
        serverGhosts = {}
        local ghost = Instance.new("Part")
        ghost.Name = "LagbackGhost"; ghost.Shape = Enum.PartType.Ball
        ghost.Size = Vector3.new(3, 3, 3); ghost.Color = Color3.fromRGB(255, 0, 0)
        ghost.Material = Enum.Material.Glass; ghost.Transparency = 0.3
        ghost.CanCollide = false; ghost.Anchored = true; ghost.CastShadow = false
        ghost.Position = position + Vector3.new(0, 5, 0); ghost.Parent = Workspace.CurrentCamera
        table.insert(serverGhosts, ghost)
    end

    local function clearAllGhosts()
        for _, ghost in pairs(serverGhosts) do pcall(function() if ghost and ghost.Parent then ghost:Destroy() end end) end
        serverGhosts = {}; clearErrorOrb(); lagbackCallCount = 0; lastLagbackTime = 0
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            if pg then for _, g in pairs(pg:GetChildren()) do if g.Name == "LagbackNotification" then g:Destroy() end end end
        end)
        pcall(function() if Workspace.CurrentCamera then for _, c in pairs(Workspace.CurrentCamera:GetChildren()) do if c.Name == "LagbackGhost" then c:Destroy() end end end end)
        pcall(function() for _, c in pairs(Workspace:GetDescendants()) do if c.Name == "LagbackGhost" then c:Destroy() end end end)
    end

    local function removeFolders()
        local pf = Workspace:FindFirstChild(player.Name)
        if not pf then return end
        local dr = pf:FindFirstChild("DoubleRig")
        if dr then
            local rr = dr:FindFirstChild("HumanoidRootPart") or dr:FindFirstChildWhichIsA("BasePart")
            if rr and ghostEnabled then createServerGhost(rr.Position) end
            dr:Destroy()
        end
        local cs = pf:FindFirstChild("Constraints")
        if cs then cs:Destroy() end
        local conn = pf.ChildAdded:Connect(function(child)
            if child.Name == "DoubleRig" then
                task.defer(function()
                    local rr = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
                    if rr and ghostEnabled then createServerGhost(rr.Position) end
                    child:Destroy()
                end)
            elseif child.Name == "Constraints" then child:Destroy() end
        end)
        table.insert(folderConnections, conn)
    end

    local function doClone()
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            hip = character.Humanoid.HipHeight
            oldRoot = character:FindFirstChild("HumanoidRootPart")
            if not oldRoot or not oldRoot.Parent then return false end
            for _, c in pairs(oldRoot:GetChildren()) do
                if c:IsA("Attachment") and (c.Name:find("Beam") or c.Name:find("Attach")) then c:Destroy() end
            end
            for _, c in pairs(oldRoot:GetChildren()) do if c:IsA("Beam") then c:Destroy() end end
            local tmp = Instance.new("Model"); tmp.Parent = game
            character.Parent = tmp
            clone = oldRoot:Clone(); clone.Parent = character
            oldRoot.Parent = Workspace.CurrentCamera
            clone.CFrame = oldRoot.CFrame; character.PrimaryPart = clone
            character.Parent = Workspace
            for _, v in pairs(character:GetDescendants()) do
                if v:IsA("Weld") or v:IsA("Motor6D") then
                    if v.Part0 == oldRoot then v.Part0 = clone end
                    if v.Part1 == oldRoot then v.Part1 = clone end
                end
            end
            tmp:Destroy(); return true
        end
        return false
    end

    local function revertClone()
        local character = player.Character
        if not oldRoot or not oldRoot:IsDescendantOf(Workspace) or not character or character.Humanoid.Health <= 0 then return end
        local tmp = Instance.new("Model"); tmp.Parent = game
        character.Parent = tmp
        oldRoot.Parent = character; character.PrimaryPart = oldRoot
        character.Parent = Workspace; oldRoot.CanCollide = true
        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("Weld") or v:IsA("Motor6D") then
                if v.Part0 == clone then v.Part0 = oldRoot end
                if v.Part1 == clone then v.Part1 = oldRoot end
            end
        end
        if clone then local p = clone.CFrame; clone:Destroy(); clone = nil; oldRoot.CFrame = p end
        oldRoot = nil
        if character and character.Humanoid then character.Humanoid.HipHeight = hip end
        clearAllGhosts()
    end

    local function animationTrickery()
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            local anim = Instance.new("Animation")
            anim.AnimationId = "http://www.roblox.com/asset/?id=18537363391"
            local humanoid = character.Humanoid
            local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
            local animTrack = animator:LoadAnimation(anim)
            animTrack.Priority = Enum.AnimationPriority.Action4
            animTrack:Play(0, 1, 0); anim:Destroy()
            table.insert(tracks, animTrack)
            animTrack.Stopped:Connect(function() if animPlaying then animationTrickery() end end)
            task.delay(0, function()
                animTrack.TimePosition = 0.7
                task.delay(0.3, function() if animTrack then animTrack:AdjustSpeed(math.huge) end end)
            end)
        end
    end

    local _invisToggleCooldown = 0

    local function invisTurnOff()
        clearAllGhosts()
        if not animPlaying then return end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        animPlaying = false; _G.invisibleStealEnabled = false
        setToggle("Invisible Steal", false)
        for _, t in pairs(tracks) do pcall(function() t:Stop(0) end) end
        tracks = {}
        if connection then connection:Disconnect(); connection = nil end
        for _, c in ipairs(folderConnections) do if c then c:Disconnect() end end
        folderConnections = {}
        revertClone(); clearAllGhosts()
        if humanoid then
            pcall(function()
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.Priority == Enum.AnimationPriority.Action4 or track.Priority == Enum.AnimationPriority.Action3 then
                            track:Stop(0)
                        end
                    end
                end
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.defer(function()
                    if humanoid and humanoid.Parent then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end)
            end)
        end
        if WalkSpeedState and WalkSpeedState.enabled ~= (Config.WalkSpeedEnabled and true or false) then
            -- restaura exatamente o que o usuario deixou salvo (nao força off)
            setWalkSpeedEnabled(Config.WalkSpeedEnabled and true or false, true)
        end
        _invisToggleCooldown = tick()
    end

    local function invisTurnOn()
        if animPlaying then return end
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        animPlaying = true; _G.invisibleStealEnabled = true
        setToggle("Invisible Steal", true)
        tracks = {}; removeFolders()
        local success = doClone()
        if success then
            task.wait(0.05); animationTrickery()
            task.delay(1, function()
                if _G.invisibleStealEnabled and not WalkSpeedState.enabled then
                    setWalkSpeedEnabled(true, true) -- auto: temporario, nao salva na config
                end
            end)
            local lastSetPosition = nil; local skipFrames = 5
            connection = RunService.PreSimulation:Connect(function()
                if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 and oldRoot then
                    local root = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
                    if root then
                        if skipFrames > 0 then skipFrames = skipFrames - 1; lastSetPosition = nil
                        elseif lastSetPosition and ghostEnabled then
                            local currentPos = oldRoot.Position
                            local jumpDist = (currentPos - lastSetPosition).Magnitude
                            if jumpDist > 6 and not _G.RecoveryInProgress and player:GetAttribute("Stealing") then
                                lastSetPosition = nil; createServerGhost(currentPos)
                                if _G.AutoRecoverLagback and _G._forceInvisToggle then
                                    _G.RecoveryInProgress = true
                                    task.spawn(function()
                                        pcall(_G._forceInvisToggle); task.wait(0.6)
                                        if player:GetAttribute("Stealing") then
                                            pcall(_G._forceInvisToggle)
                                        end
                                        _G.RecoveryInProgress = false
                                    end)
                                end
                            end
                        end
                        if clone then clone.CanCollide = true end
                        if oldRoot and oldRoot.Parent then
                            for _, c in pairs(oldRoot:GetChildren()) do
                                if c:IsA("Attachment") or c:IsA("Beam") then c:Destroy() end
                            end
                            local sa = (_G.SinkSliderValue or 7) * 0.5
                            local cf = root.CFrame - Vector3.new(0, sa, 0)
                            oldRoot.CFrame = cf * CFrame.Angles(math.rad(_G.InvisStealAngle or 225), 0, 0)
                            oldRoot.AssemblyLinearVelocity = root.AssemblyLinearVelocity; oldRoot.CanCollide = false
                            lastSetPosition = oldRoot.Position
                        end
                    end
                end
            end)
        end
    end

    _G.toggleInvisibleSteal = function()
        if (tick() - _invisToggleCooldown) < 0.3 then return end
        if animPlaying then invisTurnOff() else invisTurnOn() end
    end

    _G._forceInvisToggle = function()
        if animPlaying then invisTurnOff() else invisTurnOn() end
    end

    player.CharacterAdded:Connect(function(newChar)
        task.wait(0.1)
        clearErrorOrb(); clearAllGhosts(); lagbackCallCount = 0
        pcall(function() for _, c in pairs(Workspace.CurrentCamera:GetChildren()) do if c:IsA("BasePart") and c.Name == "HumanoidRootPart" then c:Destroy() end end end)
        if oldRoot then pcall(function() oldRoot:Destroy() end); oldRoot = nil end
        if clone then pcall(function() clone:Destroy() end); clone = nil end
        animPlaying = false; _G.invisibleStealEnabled = false
        setToggle("Invisible Steal", false)
        task.wait(0.2)
        local camera = Workspace.CurrentCamera
        if camera and newChar then
            local h = newChar:FindFirstChildOfClass("Humanoid")
            if h then camera.CameraSubject = h; camera.CameraType = Enum.CameraType.Custom end
        end
        -- reaplica a config salva apos o reset (respeita o que o usuario deixou)
        setWalkSpeedEnabled(Config.WalkSpeedEnabled and true or false, true)
        _G.InvisStealAngle = Config.InvisStealAngle or 225
        _G.SinkSliderValue = Config.SinkSliderValue or 7
        _G.AutoRecoverLagback = Config.AutoRecoverLagback and true or false
        _G.AutoInvisDuringSteal = Config.AutoInvisDuringSteal and true or false
    end)

    local function setupDeathListener()
        local ch = player.Character
        if ch then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then h.Died:Connect(function() clearErrorOrb(); clearAllGhosts(); lagbackCallCount = 0 end) end
        end
    end
    setupDeathListener()
    player.CharacterAdded:Connect(function() task.wait(0.1); setupDeathListener() end)

    -- Automatic Invis During Steal Loop
    task.spawn(function()
        local wasStealingForInvis = false
        local autoEnabledInvis = false
        task.wait(1)
        while task.wait(0.15) do
            if Config.AutoInvisDuringSteal == false then
                wasStealingForInvis = false
                autoEnabledInvis = false
            else
                local isStealing = player:GetAttribute("Stealing")
                if isStealing and not wasStealingForInvis then
                    if not _G.invisibleStealEnabled and _G._forceInvisToggle then
                        task.defer(function()
                            if player:GetAttribute("Stealing") and not _G.invisibleStealEnabled then
                                pcall(_G._forceInvisToggle)
                                autoEnabledInvis = true
                            end
                        end)
                    end
                end
                if not isStealing and autoEnabledInvis and _G.invisibleStealEnabled and _G._forceInvisToggle then
                    task.wait(0.3)
                    if not player:GetAttribute("Stealing") then
                        pcall(_G._forceInvisToggle)
                        autoEnabledInvis = false
                    end
                end
                wasStealingForInvis = isStealing
            end
        end
    end)
end

-- ============================================================
-- POPULAÇÃO DO PAINEL (mesmas funções do painel original)
-- ============================================================
regToggle("Invisible Steal", false)
regToggle("Auto Recover Lagback", Config.AutoRecoverLagback)
regToggle("Auto Invis During Steal", Config.AutoInvisDuringSteal)
regToggle("WalkSpeed", Config.WalkSpeedEnabled)
regToggle("Anti Die", Config.AntiDieEnabled)

makeSyncStateRow(body, "Enabled:", "Invisible Steal", function(on)
    if _G.toggleInvisibleSteal then pcall(_G.toggleInvisibleSteal) end
end)

makeQuickSlider(body, "Rotation", 0, 360, Config.InvisStealAngle or 225, function(v)
    _G.InvisStealAngle = v; Config.InvisStealAngle = v; saveConfig()
end)

makeQuickSlider(body, "Depth", 0, 18, Config.SinkSliderValue or 7, function(v)
    _G.SinkSliderValue = v; Config.SinkSliderValue = v; saveConfig()
end)

makeSyncStateRow(body, "Auto Recover:", "Auto Recover Lagback", function(on)
    _G.AutoRecoverLagback = on; Config.AutoRecoverLagback = on; saveConfig()
end)

makeSyncStateRow(body, "Auto Invis:", "Auto Invis During Steal", function(on)
    _G.AutoInvisDuringSteal = on; Config.AutoInvisDuringSteal = on; saveConfig()
end)

makeSyncStateRow(body, "WalkSpeed:", "WalkSpeed", function(on)
    setWalkSpeedEnabled(on)
end)

makeSyncStateRow(body, "Anti Die:", "Anti Die", function(on)
    setAntiDieEnabled(on)
end)

makeMainSliderWithInput(body, "Walk Speed", 15, 29, Config.WalkSpeedValue or 16, function(v)
    setWalkSpeedValue(v)
end)

if Config.WalkSpeedEnabled then
    task.defer(function() setWalkSpeedEnabled(true) end)
end
