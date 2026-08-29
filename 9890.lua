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

-- ===== Finder API pública do Railway + chave do Scanner =====
-- O valor precisa corresponder ao SCANNER_API_KEY configurado no servidor.
-- A chave é enviada na URL porque game:HttpGet não envia headers customizados.
local API_BASE = "https://meowlzz-soft-notify-production.up.railway.app/api/public/best"
local DEX_RECEIVE_URL = "https://meowlzz-soft-notify-production.up.railway.app/api/public/dex-receive"
local local_KeyScanner = "Mz_71f7f603ce017f6d642234d86fe78c2b9e7f4d6626e51f1bfa265be7c9b5a4b4"
local function API_URL(minGen)
    return API_BASE .. "?key=" .. HttpService:UrlEncode(local_KeyScanner) ..
        "&minGen=" .. HttpService:UrlEncode(tostring(tonumber(minGen) or 0))
end
local JOINER_URL   = "https://meowlzz-hub-customizer.lovable.app/api/public/mz9k4x7q/hb"
local JOINER_TOKEN = "mz_9K3xQ7pL2vNbY4fJ8hR6tW1sZaB5dE0uMcX"
local HEARTBEAT    = 4

-- ===== Dex Finder: fonte adicional via WebSocket =====
local DEX_WS_URL = "wss://dexapi2.up.railway.app/ws"
local DEX_LOGS_URL = "https://dexapi2.up.railway.app/logs"
local DEX_RECONNECT_DELAY = 3

-- ==========================================================
-- CONSOLE LOCK + WIPE (anti-spy / anti-log-stealer) - OTIMIZADO
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

    -- 2) FUNÇÃO DE LIMPEZA DO CONSOLE
    local function wipe()
        pcall(function() if rconsoleclear then rconsoleclear() end end)
        pcall(function() if clearconsole then clearconsole() end end)
        pcall(function() if consoleclear then consoleclear() end end)
        pcall(function() LogService:ClearOutput() end)
    end


    -- Exposto pro botão CLEAR LOGS da UI
    local env = (getgenv and getgenv()) or _G
    env.__mz_wipe_console = wipe

    -- 3) LOOP OTIMIZADO: Limpa console a cada 0.2s (zero lag)
    task.spawn(function()
        while true do
            wipe()
            task.wait(0.2)
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
        if ok and res and (not status or (status >= 200 and status < 300)) then
            return res.Body or res.body, status
        end
        if res and status then return nil, status end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok then return res, 200 end
    return nil, nil
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

local function cleanText(v)
    if v == nil then return "" end
    if type(v) == "table" then
        local parts = {}
        for _, item in ipairs(v) do
            if item ~= nil then table.insert(parts, tostring(item)) end
        end
        if #parts == 0 then
            for _, item in pairs(v) do
                if item ~= nil then table.insert(parts, tostring(item)) end
            end
        end
        return table.concat(parts, ", ")
    end
    return tostring(v)
end

local function compactKey(v)
    return string.lower(tostring(v)):gsub("[^%w]", "")
end

local function rowField(row, ...)
    if type(row) ~= "table" then return nil end
    local aliases = {}
    for i = 1, select("#", ...) do
        local wanted = select(i, ...)
        if row[wanted] ~= nil then return row[wanted] end
        aliases[compactKey(wanted)] = true
    end
    for key, value in pairs(row) do
        if aliases[compactKey(key)] then return value end
    end
    return nil
end

local function normalizeTimestamp(value)
    if value == nil then return nil end
    if type(value) == "number" then
        if value > 100000000000 then value = value / 1000 end
        return os.date("!%Y-%m-%dT%H:%M:%S", math.floor(value))
    end
    local text = cleanText(value)
    local numeric = tonumber(text)
    if numeric then
        if numeric > 100000000000 then numeric = numeric / 1000 end
        return os.date("!%Y-%m-%dT%H:%M:%S", math.floor(numeric))
    end
    if text:match("^%d%d%d%d%-%d%d%-%d%d[T ]%d%d:%d%d:%d%d") then
        return text:gsub(" ", "T", 1)
    end
    return nil
end

local function clipText(v, maxLen)
    local text = cleanText(v)
    if text == "" then return "-" end
    maxLen = maxLen or 42
    if #text <= maxLen then return text end
    return text:sub(1, math.max(1, maxLen - 3)) .. "..."
end

local function displayMutation(b)
    return clipText(b.mutation or b.mutations or "None", 22)
end

local function displayTraits(b)
    return clipText(b.traits or b.trait or "No traits", 58)
end

local function looksLikeRobloxInstanceId(value)
    local text = cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
    return text:match("^[%x]+%-%x+%-%x+%-%x+%-%x+$") ~= nil
end

local function looksLikeDexJobToken(value)
    local text = cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
    if looksLikeRobloxInstanceId(text) then return true end
    -- O DEX pode entregar o alvo como Base64 padrão, incluindo `/`, `+` e `=`.
    return #text >= 16 and #text <= 128 and text:match("^[%w_+/=%%-]+$") ~= nil
end

local function looksLikeDexPlayerToken(value)
    local text = cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
    return text:match("^%d+%s*/%s*%d+$") ~= nil or text:match("^%d+%s+of%s+%d+$") ~= nil
end

local function parseDexPlayerToken(value)
    local text = cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
    local count, max = text:match("^(%d+)%s*/%s*(%d+)$")
    if not count then count, max = text:match("^(%d+)%s+of%s+(%d+)$") end
    if count then return tonumber(count), tonumber(max) end
    return tonumber(text), nil
end

local function isFusing(b)
    local value = b.fusing or b.fuse or b.isFusing
    if type(value) == "boolean" then return value end
    local normalized = string.lower(cleanText(value))
    return normalized == "true" or normalized == "1" or normalized:find("fuse") ~= nil
end

local function receivedTimestamp(iso)
    if not iso then return nil end
    local y, mo, d, h, mi, s = tostring(iso):match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not y then return nil end
    local stamp = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d),
        hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
    return stamp - (os.time() - os.time(os.date("!*t")))
end

local RECENT_WINDOW_SECONDS = 4 * 60
local function isRecentLog(b)
    local stamp = receivedTimestamp(b.received_at)
    return stamp ~= nil and os.time() - stamp <= RECENT_WINDOW_SECONDS
end

local function isFreshForNotification(b)
    return isRecentLog(b)
end

local function parseValue(v)
    if type(v) == "number" then return v end
    local text = string.upper(cleanText(v)):gsub("%s+", ""):gsub(",", "")
    if text == "" then return 0 end
    local direct = tonumber(text)
    if direct then return direct end
    local number, suffix = text:match("([%d%.]+)([KMBT]?)")
    number = tonumber(number)
    if not number then return 0 end
    local multiplier = ({ K = 1e3, M = 1e6, B = 1e9, T = 1e12 })[suffix or ""] or 1
    return number * multiplier
end

local function usableJobText(value)
    local text = cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
    local lowered = string.lower(text)
    if text == "" or lowered == "none" or lowered == "nil" or lowered == "n/a" or
        lowered == "unavailable" or lowered == "not received" then
        return ""
    end
    return text
end

local function findDexJobId(node, depth)
    if type(node) ~= "table" or (depth or 0) > 6 then return "" end
    for key, value in pairs(node) do
        local keyName = compactKey(key)
        local isJobKey = keyName == "jobid" or keyName == "job" or keyName == "serverid" or
            keyName == "gamejobid" or keyName == "gameinstanceid" or keyName == "gameinstance" or
            keyName == "rawjobid" or keyName == "targetjobid" or keyName == "serverjobid" or
            keyName == "rawserverid" or keyName == "instanceid" or keyName == "serverinstanceid" or
            keyName == "serverinstance"
        if isJobKey then
            if type(value) == "table" then
                local nested = findDexJobId(value, (depth or 0) + 1)
                if nested ~= "" then return nested end
            else
                local candidate = usableJobText(value)
                if looksLikeDexJobToken(candidate) then return candidate end
            end
        elseif type(value) == "table" then
            local nested = findDexJobId(value, (depth or 0) + 1)
            if nested ~= "" then return nested end
        elseif type(value) == "string" then
            -- Também cobre arrays como {"N/A", "<job-id>"} e payloads
            -- que guardam o alias dentro de uma lista sem nome de campo.
            local candidate = usableJobText(value)
            if looksLikeDexJobToken(candidate) then return candidate end
        end
    end
    return ""
end

local function normalizeRow(row, source)
    if type(row) ~= "table" then return nil end
    local misplacedMutation = cleanText(rowField(row, "mutation", "mut"))
    local misplacedTraits = cleanText(rowField(row, "traits", "trait", "attributes", "abilities"))
    if not row.player_count or row.player_count == "" then
        local count, max = parseDexPlayerToken(misplacedMutation)
        if count and count >= 0 and count <= 1000 then
            row.player_count = count
            row.max_players = row.max_players or max
            row.mutation = "None"
        end
    end
    if (not row.server_id or cleanText(row.server_id) == "") and looksLikeDexJobToken(misplacedTraits) then
        row.server_id = misplacedTraits
        row.traits = "No traits"
    end
    local name = cleanText(rowField(row, "name", "brainrot", "animal", "pet", "itemName", "item",
        "displayName", "brainrotName", "petName", "title"))
    local value = parseValue(rowField(row, "gen_val", "genVal", "generationValue", "generation",
        "generationPerSecond", "generationPerSec", "genPerSec", "income", "value", "money",
        "moneyPerSecond", "valuePerSecond", "amount", "cash", "gen", "genText"))
    if name == "" or value <= 0 then return nil end

    local rawServer = rowField(row, "server_id", "serverId", "server", "jobId", "job_id", "job",
        "gameJobId", "gameInstanceId", "game_instance_id", "rawJobId", "raw_job_id",
        "targetJobId", "target_job_id", "serverJobId", "server_job_id", "rawServerId", "raw_server_id",
        "serverInstanceId", "server_instance_id", "instanceId", "instance_id", "instance")
    if type(rawServer) == "table" then
        rawServer = rowField(rawServer, "id", "value", "server_id", "serverId", "jobId", "job_id", "job",
            "gameInstanceId", "game_instance_id", "rawJobId", "raw_job_id", "targetJobId", "target_job_id",
            "serverJobId", "server_job_id", "instanceId", "instance_id")
    end
    local rawPlace = rowField(row, "place_id", "placeId", "place", "gameId", "game_id", "experienceId")
    if type(rawPlace) == "table" then
        rawPlace = rowField(rawPlace, "id", "value", "place_id", "placeId", "gameId")
    end
    local detectedSource = cleanText(rowField(row, "source", "sourceType"))
    if detectedSource == "" then detectedSource = source or "SCANNER" end

    local serverText = usableJobText(rawServer)
    local instanceText = usableJobText(rowField(row, "gameInstanceId", "game_instance_id", "instanceId", "instance_id",
        "rawJobId", "raw_job_id", "targetJobId", "target_job_id", "serverJobId", "server_job_id"))
    local nestedJobId = findDexJobId(row, 0)
    if looksLikeRobloxInstanceId(instanceText) then
        -- O UUID bruto é o instanceId aceito pelo Roblox; não o substitua
        -- por um token codificado encontrado em outro alias.
        serverText = instanceText
    elseif nestedJobId ~= "" then
        -- `server_id` pode chegar como N/A enquanto jobId/gameInstanceId
        -- válido está em outro alias ou dentro de um objeto aninhado.
        serverText = nestedJobId
    elseif serverText == "" then
        serverText = instanceText
    end
    if serverText == "" and looksLikeDexJobToken(cleanText(row.external_id)) then
        serverText = cleanText(row.external_id)
    end
    local normalized = {
        name = name,
        gen_val = value,
        gen = cleanText(rowField(row, "gen", "genText")) ~= "" and
            cleanText(rowField(row, "gen", "genText")) or fmt(value),
        mutation = cleanText(rowField(row, "mutation", "mutations", "mut", "mutationName")) or "None",
        rarity = cleanText(rowField(row, "rarity", "rarityName", "tier", "category")) or "Unknown",
        traits = cleanText(rowField(row, "traits", "trait", "attributes", "abilities")) or "No traits",
        owner = cleanText(rowField(row, "owner", "ownerName", "player", "username", "user")),
        server_id = serverText,
        job_id = serverText,
        game_instance_id = instanceText,
        place_id = cleanText(rawPlace),
        player_count = row.player_count or rowField(row, "player_count", "playerCount", "players"),
        max_players = row.max_players or rowField(row, "max_players", "maxPlayers"),
        image_url = rowField(row, "image_url", "imageUrl", "image"),
        received_at = normalizeTimestamp(rowField(row, "received_at", "receivedAt", "timestamp", "time", "createdAt")),
        source = detectedSource,
        external_id = cleanText(rowField(row, "id", "uid", "uuid", "uniqueId")),
        uid = cleanText(rowField(row, "uid", "uuid", "uniqueId", "id")),
        index = cleanText(rowField(row, "index", "animalIndex", "itemIndex")),
        plot = cleanText(rowField(row, "plot", "plot_name", "plotName")),
        slot = cleanText(rowField(row, "slot", "slot_index", "slotIndex")),
        fusing = cleanText(rowField(row, "fusing", "fuse", "isFusing")),
    }
    if normalized.mutation == "" then normalized.mutation = "None" end
    if normalized.rarity == "" then normalized.rarity = "Unknown" end
    if normalized.traits == "" then normalized.traits = "No traits" end
    normalized._key = table.concat({
        normalized.source, normalized.external_id, normalized.name, normalized.job_id,
        tostring(normalized.gen_val), normalized.mutation, normalized.traits, normalized.owner,
    }, "|")
    return normalized
end

-- ===== config =====
local cfg = { minVal = 1, unit = "M", good = true, secret = true, og = true }
local UNITS = { K = 1e3, M = 1e6, B = 1e9 }
local function threshold() return (tonumber(cfg.minVal) or 0) * (UNITS[cfg.unit] or 1e6) end

local function rarityOK(r)
    r = string.lower(tostring(r or ""))
    if r == "" or r == "unknown" then return true end
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

local pLogs    = makeTab("logs",    "LOGS")
local pConfig  = makeTab("config",  "CONFIG")
local pUsers   = makeTab("users",   "USERS")
local pUpdates = makeTab("updates", "UPDATES")

local railFoot = Instance.new("TextLabel")
railFoot.LayoutOrder = 99
railFoot.Size = UDim2.new(1, 0, 0, 26)
railFoot.BackgroundTransparency = 1
railFoot.Font = Enum.Font.Gotham
railFoot.Text = "MEOWLZZ\nHUB"
railFoot.TextSize = 8
railFoot.TextColor3 = DIM
railFoot.Parent = rail

-- ===== updates page: mensagem pública única, sem detalhes internos =====
local UPDATE_PROGRESS_TARGET = 42
local updateProgressFill
local updateProgressText

local updatesScroll = Instance.new("ScrollingFrame")
updatesScroll.Size = UDim2.new(1, 0, 1, 0)
updatesScroll.BackgroundTransparency = 1
updatesScroll.BorderSizePixel = 0
updatesScroll.ScrollBarThickness = 3
updatesScroll.ScrollBarImageColor3 = GOLD
updatesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
updatesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
updatesScroll.Parent = pUpdates

local updateOverview = Instance.new("Frame")
updateOverview.Size = UDim2.new(1, -6, 0, 74)
updateOverview.BackgroundColor3 = BG2
updateOverview.BackgroundTransparency = 0.18
updateOverview.BorderSizePixel = 0
updateOverview.Parent = updatesScroll
corner(updateOverview, 12) stroke(updateOverview, GOLD, 0.55)

local updateTitle = Instance.new("TextLabel")
updateTitle.BackgroundTransparency = 1
updateTitle.Position = UDim2.new(0, 12, 0, 10)
updateTitle.Size = UDim2.new(1, -24, 0, 18)
updateTitle.Font = Enum.Font.GothamBold
updateTitle.Text = "Add New Bots, And Fixing bugs"
updateTitle.TextSize = 12
updateTitle.TextColor3 = GOLD_SOFT
updateTitle.TextXAlignment = Enum.TextXAlignment.Left
updateTitle.Parent = updateOverview

updateProgressText = Instance.new("TextLabel")
updateProgressText.BackgroundTransparency = 1
updateProgressText.Position = UDim2.new(1, -58, 0, 10)
updateProgressText.Size = UDim2.new(0, 46, 0, 18)
updateProgressText.Font = Enum.Font.GothamBold
updateProgressText.Text = tostring(UPDATE_PROGRESS_TARGET) .. "%"
updateProgressText.TextSize = 12
updateProgressText.TextColor3 = GOLD_SOFT
updateProgressText.TextXAlignment = Enum.TextXAlignment.Right
updateProgressText.Parent = updateOverview

local updateTrack = Instance.new("Frame")
updateTrack.Position = UDim2.new(0, 12, 0, 43)
updateTrack.Size = UDim2.new(1, -24, 0, 10)
updateTrack.BackgroundColor3 = BG3
updateTrack.BorderSizePixel = 0
updateTrack.ClipsDescendants = true
updateTrack.Parent = updateOverview
corner(updateTrack, 5)

updateProgressFill = Instance.new("Frame")
updateProgressFill.Size = UDim2.new(UPDATE_PROGRESS_TARGET / 100, 0, 1, 0)
updateProgressFill.BackgroundColor3 = GOLD
updateProgressFill.BorderSizePixel = 0
updateProgressFill.Parent = updateTrack
corner(updateProgressFill, 5)
goldGradient(updateProgressFill, 0)

local updateShine = Instance.new("Frame")
updateShine.Size = UDim2.new(0, 42, 1, 0)
updateShine.Position = UDim2.new(-0.18, 0, 0, 0)
updateShine.BackgroundColor3 = GOLD_SOFT
updateShine.BackgroundTransparency = 0.7
updateShine.BorderSizePixel = 0
updateShine.Parent = updateProgressFill

local shineGradient = Instance.new("UIGradient")
shineGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0.15),
    NumberSequenceKeypoint.new(1, 1),
})
shineGradient.Parent = updateShine

task.spawn(function()
    while gui.Parent do
        local tween = TweenService:Create(updateShine, TweenInfo.new(1.4, Enum.EasingStyle.Linear), {
            Position = UDim2.new(1.05, 0, 0, 0),
        })
        updateShine.Position = UDim2.new(-0.18, 0, 0, 0)
        tween:Play()
        task.wait(1.8)
    end
end)

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
local teleportBusy = false
local teleportNextAt = 0
local teleportTarget = nil
local teleportAttempt = 0

local function cleanId(value)
    return cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
        :gsub("^[\"']", ""):gsub("[\"']$", "")
end

local function rowJobId(b)
    if type(b) ~= "table" then return nil end
    local candidates = {
        b.job_id, b.server_id, b.serverId, b.jobId,
        b.gameInstanceId, b.game_instance_id, b.instanceId, b.instance_id,
        b.gameJobId, b.game_job_id, b.rawJobId, b.raw_job_id, b.targetJobId, b.target_job_id,
        b.serverJobId, b.server_job_id, b.serverInstanceId, b.server_instance_id,
    }
    local fallback
    for _, candidate in ipairs(candidates) do
        local id = cleanId(candidate)
        local lowered = string.lower(id)
        if id ~= "" and id ~= tostring(game.JobId) and lowered ~= "none" and lowered ~= "nil" and
            lowered ~= "n/a" and lowered ~= "na" and lowered ~= "unavailable" and lowered ~= "not received" and
            looksLikeDexJobToken(id) then
            -- Se os dois aliases vierem juntos, o UUID bruto tem precedência
            -- sobre um token codificado ou código alternativo.
            if looksLikeRobloxInstanceId(id) then return id end
            fallback = fallback or id
        end
    end
    if fallback then return fallback end
    -- A resposta DEX pode manter o valor acima como N/A e colocar o ID real
    -- em outro alias ou dentro de server/job/instance.
    local nested = findDexJobId(b, 0)
    if nested ~= "" and nested ~= tostring(game.JobId) then return nested end
    return nil
end

local function isRobloxInstanceId(value)
    return looksLikeRobloxInstanceId(cleanId(value))
end

local function rowPlaceId(b)
    local raw = b and (b.place_id or b.placeId or b.gameId or b.game_id or
        b.experienceId or b.experience_id or b.universeId or b.universe_id)
    local id = tonumber(cleanId(raw))
    return (id and id > 0) and id or game.PlaceId
end

local function requestTeleport(b, reason, preferredMode)
    local jobId = rowJobId(b)
    if not jobId then return false, "missing-server" end
    if teleportBusy or os.clock() < teleportNextAt then return false, "cooldown" end

    local placeId = rowPlaceId(b)
    -- O valor do log é o alvo oficial do DEX. Não o converter em access code
    -- nem alternar o método, porque isso muda o destino e quebra o Join.
    local mode = "instance"
    teleportBusy = true
    teleportNextAt = os.clock() + 7
    teleportTarget = {
        place_id = placeId,
        server_id = jobId,
        row = b,
        mode = mode,
        reason = reason or "manual",
    }
    teleportAttempt = teleportAttempt + 1

    local attempt = teleportAttempt
    warn("[Meowlzz] teleport target=" .. tostring(jobId) .. " mode=" .. tostring(mode) ..
        " reason=" .. tostring(reason or "manual"))
    local ok, err = pcall(function()
        -- Join manual, notificações, Auto Joiner e Auto Force usam exatamente
        -- o mesmo job ID publicado pelo log DEX.
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LP)
    end)
    if not ok then
        teleportBusy = false
        teleportNextAt = os.clock() + 1.5
        warn("[Meowlzz] teleport method=" .. tostring(mode) .. " failed:", tostring(err),
            "target=", tostring(jobId))
        return false, tostring(err)
    end
    task.delay(8, function()
        if teleportBusy and teleportAttempt == attempt and gui.Parent then
            teleportBusy = false
            teleportNextAt = os.clock() + 0.2
            if autoForce or autoJoin then
                local retryTarget = teleportTarget
                local retryRow = retryTarget and retryTarget.row
                if retryRow then requestTeleport(retryRow, "watchdog-retry", retryTarget.mode) end
            end
        end
    end)
    return true
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
        local started, why = requestTeleport(b, "button")
        j.Text = started and "..." or (why == "missing-server" and "N/A" or "WAIT")
        task.delay(started and 6 or 1.2, function()
            if j.Parent then j.Text = "JOIN" end
        end)
    end)
    return j
end

local function makeCard(b)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 72)
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
    sub.Position = UDim2.new(0, 18, 0, 21)
    sub.Size = UDim2.new(1, -80, 0, 14)
    sub.Font = Enum.Font.GothamMedium
    sub.Text = "Value: " .. fmt(b.gen_val)
    sub.TextSize = 10
    sub.TextColor3 = TXT
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.Parent = f

    local mutation = Instance.new("TextLabel")
    mutation.BackgroundTransparency = 1
    mutation.Position = UDim2.new(0, 18, 0, 37)
    mutation.Size = UDim2.new(1, -80, 0, 14)
    mutation.Font = Enum.Font.Gotham
    mutation.Text = "Mutation: " .. displayMutation(b)
    mutation.TextSize = 8
    mutation.TextColor3 = TXT
    mutation.TextXAlignment = Enum.TextXAlignment.Left
    mutation.TextTruncate = Enum.TextTruncate.AtEnd
    mutation.Parent = f

    local meta = Instance.new("TextLabel")
    meta.BackgroundTransparency = 1
    meta.Position = UDim2.new(0, 18, 0, 53)
    meta.Size = UDim2.new(1, -80, 0, 14)
    meta.Font = Enum.Font.Gotham
    meta.Text = "Traits: " .. displayTraits(b)
    meta.TextSize = 8
    meta.TextColor3 = DIM
    meta.TextXAlignment = Enum.TextXAlignment.Left
    meta.TextTruncate = Enum.TextTruncate.AtEnd
    meta.Parent = f

    joinButton(f, b, 52, 24)
    return f
end

-- ===== notifications (max 3 visible, queued, 3s, sound) =====
local notifHolder = Instance.new("Frame")
notifHolder.AnchorPoint = Vector2.new(0.5, 0)
notifHolder.Position = UDim2.new(0.5, 0, 0, 10)
notifHolder.Size = UDim2.new(0, 340, 0, 220)
notifHolder.BackgroundTransparency = 1
notifHolder.Parent = gui
local nLayout = Instance.new("UIListLayout")
nLayout.Padding = UDim.new(0, 6)
nLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
nLayout.Parent = notifHolder

local activeNotifs = {}
local notificationQueue = {}
local notificationPumpRunning = false

local function notificationKey(b)
    return b._key or (tostring(b.name) .. "|" .. tostring(b.server_id) .. "|" ..
        tostring(b.gen_val) .. "|" .. tostring(b.mutation) .. "|" .. tostring(b.traits))
end

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
    local key = notificationKey(b)
    for _, e in ipairs(activeNotifs) do
        if e.key == key then return end
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
    local fuse = isFusing(b)
    local alertRed = Color3.fromRGB(185, 52, 52)
    local alertRedSoft = Color3.fromRGB(255, 150, 150)
    f.Size = UDim2.new(1, 0, 0, 64)
    f.BackgroundColor3 = fuse and Color3.fromRGB(68, 24, 24) or BG2
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = notifHolder
    corner(f, 12) stroke(f, fuse and alertRed or GOLD, 0.35)
    TweenService:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 0.12 }):Play()

    local accentN = Instance.new("Frame")
    accentN.Size = UDim2.new(0, 3, 1, -16)
    accentN.Position = UDim2.new(0, 4, 0, 8)
    accentN.BackgroundColor3 = fuse and alertRed or GOLD
    accentN.BorderSizePixel = 0
    accentN.Parent = f
    corner(accentN, 2)

    local n = Instance.new("TextLabel")
    n.BackgroundTransparency = 1
    n.Position = UDim2.new(0, 12, 0, 7)
    n.Size = UDim2.new(1, -80, 0, 15)
    n.Font = Enum.Font.GothamBold
    n.Text = tostring(b.name or "?")
    n.TextSize = 12
    n.TextColor3 = fuse and alertRedSoft or GOLD_SOFT
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.TextTruncate = Enum.TextTruncate.AtEnd
    n.Parent = f

    local d = Instance.new("TextLabel")
    d.BackgroundTransparency = 1
    d.Position = UDim2.new(0, 12, 0, 25)
    d.Size = UDim2.new(1, -80, 0, 34)
    d.Font = Enum.Font.Gotham
    d.Text = fmt(b.gen_val) .. "\n" ..
             "Mutation: " .. displayMutation(b) .. "\n" ..
             "Traits: " .. displayTraits(b)
    d.TextSize = 9
    d.TextColor3 = fuse and alertRedSoft or TXT
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextYAlignment = Enum.TextYAlignment.Top
    d.Parent = f

    joinButton(f, b, 52, 24)

    local entry = { frame = f, val = tonumber(b.gen_val) or 0, key = key }
    table.insert(activeNotifs, entry)
    pcall(playPing)
    task.delay(3, function() removeNotif(entry) end)
end

local function pumpNotificationQueue()
    if notificationPumpRunning then return end
    notificationPumpRunning = true
    task.spawn(function()
        while gui.Parent do
            while #notificationQueue > 0 and #activeNotifs < 3 do
                local b = table.remove(notificationQueue, 1)
                showNotif(b)
            end
            if #notificationQueue == 0 then break end
            task.wait(0.15)
        end
        notificationPumpRunning = false
    end)
end

local queuedNotificationKeys = {}

local function enqueueNotification(b)
    local key = notificationKey(b)
    if queuedNotificationKeys[key] then return end
    queuedNotificationKeys[key] = true
    table.insert(notificationQueue, b)
end

-- ===== Scanner + Dex: cada brainrot individual, sem melhor por servidor =====
local notified = {}
local statusLbl
local scannerRows = {}
local dexRows = {}
local dexIndex = {}
local scannerStatus = "IDLE"
local dexStatus = "OFFLINE"
local dexConnecting = false

local function parseDexPlayers(value)
    local text = cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
    local count, max = text:match("^(%d+)%s*/%s*(%d+)$")
    if not count then count, max = text:match("^(%d+)%s+of%s+(%d+)$") end
    if count then return tonumber(count), tonumber(max) end
    local only = tonumber(text)
    return only, nil
end

local function looksLikeDexJobId(value)
    local text = cleanText(value):gsub("^%s+", ""):gsub("%s+$", "")
    if looksLikeRobloxInstanceId(text) then return true end
    -- Aceita Base64 padrão e URL-safe; sem isso tokens com `/` ou `+` viravam
    -- mutation/traits e o botão recebia `N/A`.
    return #text >= 16 and #text <= 128 and text:match("^[%w_+/=%%-]+$") ~= nil
end

local function looksLikeDexPlayers(value)
    local text = cleanText(value)
    return text:match("^%s*%d+%s*/%s*%d+%s*$") ~= nil or
        text:match("^%s*%d+%s+of%s+%d+%s*$") ~= nil
end

local function setDexField(row, key, value)
    local normalizedKey = compactKey(key)
    value = cleanText(value)
    if normalizedKey == "name" or normalizedKey == "brainrot" or normalizedKey == "animal" or
        normalizedKey == "pet" or normalizedKey == "item" or normalizedKey == "itemname" or
        normalizedKey == "displayname" or normalizedKey == "brainrotname" or normalizedKey == "petname" or
        normalizedKey == "title" then
        row.name = value
    elseif normalizedKey == "value" or normalizedKey == "gen" or normalizedKey == "genval" or
        normalizedKey == "genvalue" or normalizedKey == "generation" or normalizedKey == "generationvalue" or
        normalizedKey == "generationpersecond" or normalizedKey == "generationpersec" or
        normalizedKey == "genpersec" or normalizedKey == "income" or normalizedKey == "money" or
        normalizedKey == "moneypersecond" or normalizedKey == "valuepersecond" or
        normalizedKey == "amount" or normalizedKey == "cash" then
        row.gen = value
    elseif normalizedKey:find("mutation", 1, true) or normalizedKey == "mut" then
        row.mutation = value
    elseif normalizedKey:find("rarity", 1, true) or normalizedKey == "tier" or normalizedKey == "category" then
        row.rarity = value
    elseif normalizedKey:find("trait", 1, true) or normalizedKey:find("attribute", 1, true) or
        normalizedKey == "ability" or normalizedKey == "abilities" then
        row.traits = value
    elseif normalizedKey == "players" or normalizedKey == "playercount" or
        normalizedKey == "serverplayers" or normalizedKey == "onlineplayers" or
        normalizedKey == "currentplayers" then
        local count, max = parseDexPlayers(value)
        row.player_count = count
        row.max_players = max
    elseif normalizedKey:find("owner", 1, true) or normalizedKey == "player" or
        normalizedKey == "user" or normalizedKey == "username" then
        row.owner = value
    elseif normalizedKey:find("server", 1, true) or normalizedKey:find("job", 1, true) or
        normalizedKey == "instance" or normalizedKey == "instanceid" or
        normalizedKey == "gameinstanceid" or normalizedKey == "serverinstanceid" then
        row.server_id = value
    elseif normalizedKey:find("place", 1, true) or normalizedKey == "gameid" or
        normalizedKey == "experienceid" then
        row.place_id = value
    elseif normalizedKey == "timestamp" or normalizedKey == "time" or normalizedKey == "receivedat" or
        normalizedKey == "createdat" then
        row.received_at = value
    elseif normalizedKey == "fuse" or normalizedKey == "fusing" or normalizedKey == "isfusing" or
        normalizedKey == "fusion" or normalizedKey == "fusestatus" then
        row.fusing = value
    end
end

local function looksLikeDexValue(value)
    local text = string.upper(cleanText(value)):gsub("%s+", "")
    if text == "" then return false end
    if not text:match("[%d]") then return false end
    return text:match("^[$%d%.]+[KMBT]?/?S?%+?$") ~= nil or
        text:match("[%d%.]+[KMBT]/?S") ~= nil
end

local function parseDexDelimitedMessage(message)
    local row, plain = {}, {}
    for part in tostring(message):gmatch("([^|\n]+)") do
        local clean = cleanText(part):gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then
            local key, value = clean:match("^([^:=]+)%s*[:=]%s*(.-)$")
            if key and value and cleanText(value) ~= "" then
                setDexField(row, key, value)
            else
                table.insert(plain, clean)
            end
        end
    end

    if not row.name or row.name == "" then
        for i, value in ipairs(plain) do
            if not looksLikeDexValue(value) then
                row.name = value
                table.remove(plain, i)
                break
            end
        end
    end
    if not row.gen or row.gen == "" then
        for i, value in ipairs(plain) do
            if looksLikeDexValue(value) then
                row.gen = value
                table.remove(plain, i)
                break
            end
        end
    end

    for i = #plain, 1, -1 do
        local value = plain[i]
        local currentJobId = usableJobText(row.server_id)
        if looksLikeDexJobId(value) and (currentJobId == "" or
            (looksLikeRobloxInstanceId(value) and not looksLikeRobloxInstanceId(currentJobId))) then
            row.server_id = value
            table.remove(plain, i)
        elseif looksLikeDexPlayers(value) and row.player_count == nil then
            local count, max = parseDexPlayers(value)
            row.player_count = count
            row.max_players = max
            table.remove(plain, i)
        end
    end

    if (not row.mutation or row.mutation == "") and plain[1] and
        not looksLikeDexJobId(plain[1]) and not looksLikeDexPlayers(plain[1]) then
        row.mutation = table.remove(plain, 1)
    end
    if (not row.traits or row.traits == "") and plain[1] and
        not looksLikeDexJobId(plain[1]) and not looksLikeDexPlayers(plain[1]) then
        row.traits = table.remove(plain, 1)
    end
    return normalizeRow(row, "DEX")
end

local function collectDexRows(node, output, seen, depth)
    if type(node) ~= "table" or depth > 7 then return end
    local row = normalizeRow(node, "DEX")
    if row and not seen[row._key] then
        seen[row._key] = true
        table.insert(output, row)
    end
    for _, child in pairs(node) do
        if type(child) == "table" then
            collectDexRows(child, output, seen, depth + 1)
        elseif type(child) == "string" then
            local childRow = parseDexDelimitedMessage(child)
            if childRow and not seen[childRow._key] then
                seen[childRow._key] = true
                table.insert(output, childRow)
            end
        end
    end
end

local function decodeDexMessage(message)
    local rows, seen = {}, {}
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, tostring(message))
    if ok and type(decoded) == "table" then
        collectDexRows(decoded, rows, seen, 0)
    elseif ok and type(decoded) == "string" then
        local row = parseDexDelimitedMessage(decoded)
        if row then table.insert(rows, row) end
    else
        -- `/logs` do DEX entrega uma linha por pet. Não juntar todas as linhas
        -- em um único registro, pois isso fazia o job ID ficar associado ao
        -- pet errado ou desaparecer no parsing.
        for line in tostring(message):gmatch("[^\r\n]+") do
            local row = parseDexDelimitedMessage(line)
            if row then table.insert(rows, row) end
        end
        if #rows == 0 then
            local row = parseDexDelimitedMessage(message)
            if row then table.insert(rows, row) end
        end
    end
    return rows
end

local function renderCombinedRows()
    for i = #dexRows, 1, -1 do
        if not isRecentLog(dexRows[i]) then
            table.remove(dexRows, i)
        end
    end
    dexIndex = {}
    for i, row in ipairs(dexRows) do
        dexIndex[row._key] = i
    end
    local kept, seen = {}, {}
    local function appendRows(rows)
        for _, b in ipairs(rows) do
            if passes(b) and isRecentLog(b) and not cleared[b._key] and not seen[b._key] then
                seen[b._key] = true
                table.insert(kept, b)
            end
        end
    end
    appendRows(scannerRows)
    appendRows(dexRows)
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
        if i <= 30 then makeCard(b) end
        if not notified[b._key] then
            notified[b._key] = true
            if isFreshForNotification(b) then
                enqueueNotification(b)
            end
        end
    end
    table.sort(notificationQueue, function(x, y)
        return (tonumber(x.gen_val) or 0) > (tonumber(y.gen_val) or 0)
    end)
    pumpNotificationQueue()
    if statusLbl then
        statusLbl.Text = "TOTAL " .. tostring(#kept) .. "  •  S:" .. scannerStatus .. " D:" .. dexStatus
    end
end

local function forwardDexRows(rows)
    local payloadRows = {}
    for _, row in ipairs(rows) do
        if row and row.name and tonumber(row.gen_val) and tonumber(row.gen_val) > 0 then
            table.insert(payloadRows, {
                name = tostring(row.name),
                gen_val = tonumber(row.gen_val),
                gen = row.gen,
                mutation = row.mutation,
                rarity = row.rarity,
                traits = row.traits,
                owner = row.owner,
                        server_id = rowJobId(row),
                job_id = rowJobId(row),
                place_id = (row.place_id and tostring(row.place_id) ~= "" and row.place_id) or tostring(game.PlaceId),
                player_count = row.player_count,
                max_players = row.max_players,
                image_url = row.image_url,
                external_id = row.external_id,
                fusing = row.fusing,
            })
        end
    end
    if #payloadRows == 0 then return end
    task.spawn(function()
        local url = DEX_RECEIVE_URL .. "?key=" .. HttpService:UrlEncode(local_KeyScanner)
        local response = httpPostJSON(url, { rows = payloadRows })
        if response and response.ok == false then
            warn("[Meowlzz Dex] relay recusado:", tostring(response.error or "unknown"))
        end
    end)
end

local function acceptDexMessage(message, relayToMeowlzz)
    pcall(function()
        print("[Meowlzz Dex][RAW]", tostring(message))
    end)
    local rows = decodeDexMessage(message)
    pcall(function()
        print("[Meowlzz Dex][DECODED] rows=", tostring(#rows))
        for i, row in ipairs(rows) do
            print("[Meowlzz Dex][ROW]", tostring(i), "name=", tostring(row.name),
                "job_id=", tostring(row.job_id), "server_id=", tostring(row.server_id),
                "instance=", tostring(row.game_instance_id), "place_id=", tostring(row.place_id),
                "players=", tostring(row.player_count) .. "/" .. tostring(row.max_players))
        end
    end)
    if #rows == 0 then
        dexStatus = "NO DATA"
        pcall(function() print("[Meowlzz Dex] mensagem recebida sem registro reconhecível") end)
        if statusLbl then renderCombinedRows() end
        return
    end
    local arrivalStamp = os.date("!%Y-%m-%dT%H:%M:%S")
    for _, row in ipairs(rows) do
        if not row.received_at or not receivedTimestamp(row.received_at) then
            row.received_at = arrivalStamp
        end
        local index = dexIndex[row._key]
        if index then
            dexRows[index] = row
        else
            table.insert(dexRows, row)
            dexIndex[row._key] = #dexRows
        end
    end
    if relayToMeowlzz ~= false then
        forwardDexRows(rows)
    end
    dexStatus = "OK"
    renderCombinedRows()
end

local function startDexSocket()
    local hasWebSocket = false
    pcall(function() hasWebSocket = WebSocket and type(WebSocket.connect) == "function" end)
    if dexConnecting or not hasWebSocket then
        dexStatus = "NO WS"
        if statusLbl then renderCombinedRows() end
        return
    end
    dexConnecting = true
    local ok, ws = pcall(function() return WebSocket.connect(DEX_WS_URL) end)
    dexConnecting = false
    if not ok or not ws then
        dexStatus = "CONNECT ERROR"
        if statusLbl then renderCombinedRows() end
        task.delay(DEX_RECONNECT_DELAY, startDexSocket)
        return
    end
    dexStatus = "CONNECTED"
    if statusLbl then renderCombinedRows() end
    pcall(function()
        ws.OnMessage:Connect(function(message)
                    pcall(acceptDexMessage, message)
        end)
    end)
    pcall(function()
        ws.OnClose:Connect(function()
            dexStatus = "CLOSED"
                if gui.Parent then
                task.delay(DEX_RECONNECT_DELAY, startDexSocket)
            end
        end)
    end)
end

local dexHttpBusy = false
local function refreshDexHttpLogs()
    if dexHttpBusy then return end
    dexHttpBusy = true
    local raw, httpStatus = httpGet(DEX_LOGS_URL)
    if raw and raw ~= "" then
        -- O Finder usa exatamente o identificador que o DEX publica nos logs;
        -- não reenvia esses registros ao Meowlzz para não criar duplicatas.
        acceptDexMessage(raw, false)
    elseif httpStatus then
        warn("[Meowlzz Dex] /logs HTTP", tostring(httpStatus))
    end
    dexHttpBusy = false
end

local function refresh()
    task.spawn(refreshDexHttpLogs)
    local raw, httpStatus = httpGet(API_URL(threshold()))
    if not raw then
        scannerStatus = httpStatus and ("HTTP " .. tostring(httpStatus)) or "OFFLINE"
        renderCombinedRows()
        return
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(data) ~= "table" then
        scannerStatus = "INVALID"
        renderCombinedRows()
        return
    end
    if data.error then
        scannerStatus = "ERROR"
        renderCombinedRows()
        return
    end
    local rows = data.data or data.servers or data.results or {}
    if type(rows) ~= "table" then
        scannerStatus = "DATA ERROR"
        renderCombinedRows()
        return
    end

    scannerRows = {}
    for _, row in ipairs(rows) do
        local normalized = normalizeRow(row, "SCANNER")
        if normalized then table.insert(scannerRows, normalized) end
    end
    scannerStatus = "OK"
    renderCombinedRows()
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
    queuedNotificationKeys = {}
    notificationQueue = {}
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
        local sid = rowJobId(b)
        if sid then return b end
    end
    return nil
end

-- Se o Roblox rejeitar o destino, libera o alvo e agenda uma nova tentativa.
local function retryTeleportAfterFailure(message)
    local failedTarget = teleportTarget
    teleportBusy = false
    teleportNextAt = os.clock() + (autoForce and 0.35 or 1.2)
    warn("[Meowlzz] teleport falhou:", tostring(message or "unknown"),
        "target=", tostring(failedTarget and failedTarget.server_id),
        "mode=", tostring(failedTarget and failedTarget.mode))
    if autoJoin or autoForce then
        task.delay(autoForce and 0.4 or 1.3, function()
            if not gui.Parent then return end
            local target = failedTarget or teleportTarget
            local b = (target and target.row) or bestRow()
            if not b then return end
            requestTeleport(b, autoForce and "auto-force-retry" or "auto-join-retry", "instance")
        end)
    end
end

pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(_, result, message)
        retryTeleportAfterFailure(message or result)
    end)
end)

-- Libera o bloqueio quando o Roblox muda o estado do teleporte.
pcall(function()
    LP.OnTeleport:Connect(function(state)
        local stateName = tostring(state)
        if stateName:find("Failed") or stateName:find("Cancelled") then
            retryTeleportAfterFailure(stateName)
        elseif stateName:find("Started") or stateName:find("InProgress") then
            teleportBusy = true
        end
    end)
end)

-- AUTO JOINER: tenta entrar no melhor servidor recente, sem disparar chamadas simultâneas.
task.spawn(function()
    while gui.Parent do
        if autoJoin and not autoForce and not teleportBusy then
            local b = bestRow()
            if b then requestTeleport(b, "auto-join") end
            task.wait(2)
        else
            task.wait(0.35)
        end
    end
end)

-- AUTO FORCE: repete o melhor destino até o Roblox aceitar o teleporte.
task.spawn(function()
    while gui.Parent do
        if autoForce and not teleportBusy then
            local b = bestRow()
            if b then requestTeleport(b, "auto-force") end
            task.wait(0.8)
        else
            task.wait(0.35)
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
task.spawn(startDexSocket)
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
