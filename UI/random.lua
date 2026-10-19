repeat task.wait() until game:IsLoaded()
if not game:GetService("Players").LocalPlayer then
    repeat task.wait() until game:GetService("Players").LocalPlayer
end

local Player = game:GetService("Players").LocalPlayer
repeat task.wait() until Player.Character or Player.CharacterAdded:Wait()

local Env = (getgenv and getgenv()) or _G
if Env.CustomUtilityUnload then
    pcall(Env.CustomUtilityUnload)
    Env.CustomUtilityUnload = nil
end

local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Lighting = game:GetService("Lighting"),
    Workspace = game:GetService("Workspace"),
    Teams = game:GetService("Teams")
}

local DrawingAvailable = pcall(function()
    local probe = Drawing.new("Text")
    probe:Remove()
end)

local RESPAWN_WAIT_TIME = 2

local Theme = {
    Accent = Color3.fromRGB(242, 169, 59),
    OnAccent = Color3.fromRGB(26, 19, 6),
    Dock = Color3.fromRGB(13, 13, 15),
    Panel = Color3.fromRGB(17, 17, 19),
    Row = Color3.fromRGB(24, 24, 27),
    RowHover = Color3.fromRGB(31, 31, 35),
    Track = Color3.fromRGB(46, 46, 52),
    Border = Color3.fromRGB(40, 40, 46),
    Text = Color3.fromRGB(236, 236, 240),
    Sub = Color3.fromRGB(128, 128, 140),
    Danger = Color3.fromRGB(240, 84, 84),
    DangerBg = Color3.fromRGB(42, 18, 20),
    DangerHover = Color3.fromRGB(60, 24, 27)
}

local function pickFont(name, fallback)
    local ok, font = pcall(function() return Enum.Font[name] end)
    if ok and font then return font end
    return fallback
end

local Fonts = {
    Regular = pickFont("BuilderSans", Enum.Font.Gotham),
    Medium = pickFont("BuilderSansMedium", Enum.Font.GothamMedium),
    Bold = pickFont("BuilderSansBold", Enum.Font.GothamBold)
}

local State = {
    Initialized = false,
    Unloaded = false,
    CharacterLoaded = false,
    Combat = {
        killAura = {
            enabled = false, spareTeam = true, targetAll = false, range = 20, cooldown = 0.3, lastAttack = -10, hits = 0,
            key = "T", getKey = nil,
            hud = {enabled = false, side = "Right"}
        }
    },
    Visuals = {
        esp = {
            enabled = false, distance = 500, xOffset = 0, yOffset = 0, showAll = false,
            fontSize = 16, font = "Plex", showName = true, showHealth = true, rev = 0
        }
    },
    Time = {enabled = false, value = 12, original = nil, connection = nil},
    Groups = {aura = {}, esp = {}},
    Picks = {aura = {}, esp = {}}
}

local Cleanup = {tasks = {}, running = false}

function Cleanup.Add(item)
    table.insert(Cleanup.tasks, item)
    return item
end

function Cleanup.Run()
    if Cleanup.running or State.Unloaded then return end
    Cleanup.running = true
    State.Unloaded = true
    for i = #Cleanup.tasks, 1, -1 do
        local item = Cleanup.tasks[i]
        Cleanup.tasks[i] = nil
        pcall(function()
            if type(item) == "function" then
                item()
            else
                item:Disconnect()
            end
        end)
    end
    if Env.CustomUtilityUnload == Cleanup.Run then
        Env.CustomUtilityUnload = nil
    end
    Cleanup.running = false
end

local Utils = {Cache = {data = {}, timestamps = {}}}

function Utils.SafeDisconnect(connection)
    if connection then
        pcall(function() connection:Disconnect() end)
    end
    return nil
end

function Utils.GetCharacterComponents(player)
    player = player or Player
    local char = player.Character
    if not char or not char.Parent then return nil end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if humanoid and rootPart and rootPart.Parent then
        return {character = char, humanoid = humanoid, rootPart = rootPart}
    end
    return nil
end

function Utils.WaitForCharacterComponents(player, timeout)
    player = player or Player
    timeout = timeout or 10
    local startTime = tick()
    while tick() - startTime < timeout do
        local components = Utils.GetCharacterComponents(player)
        if components then return components end
        task.wait(0.1)
    end
    return nil
end

function Utils.CachedFind(parent, childName, duration)
    duration = duration or 60
    local key = tostring(parent) .. "_" .. childName
    local now = tick()
    if Utils.Cache.data[key] and (now - (Utils.Cache.timestamps[key] or 0)) < duration then
        local cached = Utils.Cache.data[key]
        if cached and cached.Parent then return cached end
    end
    local child = parent:FindFirstChild(childName)
    if child then
        Utils.Cache.data[key] = child
        Utils.Cache.timestamps[key] = now
    end
    return child
end

function Utils.InputMatches(key, input)
    if type(key) ~= "string" or key == "" or key == "None" then return false end
    if key == "MouseLeft" then return input.UserInputType == Enum.UserInputType.MouseButton1 end
    if key == "MouseRight" then return input.UserInputType == Enum.UserInputType.MouseButton2 end
    return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key
end

local GuiFactory = {}

function GuiFactory.New(name, order)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = order
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    local placed = false
    if gethui then
        placed = pcall(function() gui.Parent = gethui() end) and gui.Parent ~= nil
    end
    if not placed then
        placed = pcall(function() gui.Parent = game:GetService("CoreGui") end) and gui.Parent ~= nil
    end
    if not placed then gui.Parent = Player:WaitForChild("PlayerGui") end
    return gui
end

local Groups = {NONE = "~none"}

function Groups.Key(player)
    local team = player.Team
    return team and team.Name or Groups.NONE
end

function Groups.Changed()
    State.Visuals.esp.rev = State.Visuals.esp.rev + 1
end

function Groups.Tag(player)
    local team = player.Team
    return team and team.Name or nil
end

function Groups.Selected(kind, player)
    local pick = State.Picks[kind][player.Name]
    if pick ~= nil then return pick end
    return State.Groups[kind][Groups.Key(player)] == true
end

function Groups.AuraAllowed(player)
    local ka = State.Combat.killAura
    if ka.spareTeam and Player.Team and player.Team == Player.Team then return false end
    if ka.targetAll then return true end
    return Groups.Selected("aura", player)
end

function Groups.EspAllowed(player)
    if State.Visuals.esp.showAll then return true end
    return Groups.Selected("esp", player)
end

function Groups.Leader(group)
    local team = group.team
    if not team then return nil end
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p.Team == team then return p end
    end
    return nil
end

function Groups.List()
    local teams = Services.Teams:GetTeams()
    table.sort(teams, function(a, b) return a.Name < b.Name end)
    local out = {}
    for _, team in ipairs(teams) do
        out[#out + 1] = {key = team.Name, name = team.Name, color = team.TeamColor.Color, team = team}
    end
    out[#out + 1] = {key = Groups.NONE, name = "No Team", color = Theme.Sub}
    return out
end

function Groups.Members(group)
    local names = {}
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p.Team == group.team then names[#names + 1] = p.Name end
    end
    table.sort(names)
    return names
end

local Combat = {}

local combatPartsCache = setmetatable({}, {__mode = "k"})

local function combatGetParts(player)
    local char = player.Character
    if not char or not char.Parent then return nil end
    local cached = combatPartsCache[player]
    if cached and cached.char == char and cached.humanoid.Parent and cached.root.Parent then
        return cached
    end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        combatPartsCache[player] = nil
        return nil
    end
    cached = {char = char, humanoid = humanoid, root = root}
    combatPartsCache[player] = cached
    return cached
end

function Combat.GetKey()
    local ka = State.Combat.killAura
    local key = ka.getKey and ka.getKey() or nil
    if type(key) ~= "string" or key == "" then key = ka.key end
    return key
end

function Combat.MatchesKey(input)
    return Utils.InputMatches(Combat.GetKey(), input)
end

function Combat.FindNearestTarget()
    local ka = State.Combat.killAura
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local myPos = myRoot.Position
    local rangeSq = ka.range * ka.range
    local nearest, shortestSq = nil, rangeSq + 1
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Player and Groups.AuraAllowed(player) then
            local parts = combatGetParts(player)
            if parts and parts.humanoid.Health > 0 then
                local offset = parts.root.Position - myPos
                local distSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z
                if distSq <= rangeSq and distSq < shortestSq then
                    shortestSq = distSq
                    nearest = {
                        player = player, character = parts.char, humanoid = parts.humanoid,
                        rootPart = parts.root, distance = math.sqrt(distSq)
                    }
                end
            end
        end
    end
    return nearest
end

function Combat.GetCooldownRemaining()
    local ka = State.Combat.killAura
    return math.max(0, ka.cooldown - (os.clock() - ka.lastAttack))
end

function Combat.TryAttack()
    local ka = State.Combat.killAura
    if State.Unloaded or not ka.enabled or not State.CharacterLoaded then return false end
    if Combat.GetCooldownRemaining() > 0 then return false end

    local target = Combat.FindNearestTarget()
    if not target then
        if Combat.OnMiss then Combat.OnMiss() end
        return false
    end

    local remote = Utils.CachedFind(Services.ReplicatedStorage, "AttackHandlerRemoteEvent")
    if not remote then return false end

    local sent = pcall(function() remote:FireServer(target.humanoid) end)
    if not sent then pcall(function() remote:FireServer(target.player) end) end

    ka.lastAttack = os.clock()
    ka.hits = ka.hits + 1
    if Combat.OnHit then Combat.OnHit(target) end
    return true
end

local ESP = {}

local ESP_FONTS = {UI = 0, System = 1, Plex = 2, Monospace = 3}
local ESP_FONT_NAMES = {"UI", "System", "Plex", "Monospace"}
local ESP_COLORS = {
    Color3.fromRGB(80, 255, 120),
    Color3.fromRGB(255, 235, 70),
    Color3.fromRGB(255, 150, 45),
    Color3.fromRGB(255, 65, 65)
}
local ESP_OUTLINE = Color3.fromRGB(0, 0, 0)
local ESP_BIND_NAME = "CustomUtilityESP"

local espEntries = {}
local espRunning = false
local espPlayerAddedConn = nil
local espPlayerRemovingConn = nil

local function espDestroyDrawing(text)
    if text then pcall(function() text:Remove() end) end
end

local function espCreateDrawing(color)
    local ok, text = pcall(Drawing.new, "Text")
    if not ok or not text then return nil end
    pcall(function()
        text.Center = true
        text.Outline = true
        text.OutlineColor = ESP_OUTLINE
        text.Transparency = 1
        text.Color = color or ESP_COLORS[1]
        text.Visible = false
    end)
    return text
end

local ESP_NAME_COLOR = Color3.fromRGB(255, 255, 255)

local function espHide(entry)
    if entry.visible then
        entry.visible = false
        pcall(function()
            entry.text.Visible = false
            entry.hpText.Visible = false
        end)
    end
end

local function espBucket(pct)
    if pct > 0.75 then return 1 end
    if pct > 0.5 then return 2 end
    if pct > 0.25 then return 3 end
    return 4
end

local function espResolve(entry)
    local char = entry.player.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if char and hum and root then
        entry.char, entry.humanoid, entry.root = char, hum, root
        entry.hp = -1
        entry.topOffset = nil
        entry.nextMeasure = 0
    else
        entry.char, entry.humanoid, entry.root = nil, nil, nil
    end
end

local ESP_WORLD_PAD = 0.6

local function espMeasure(entry)
    local char, root = entry.char, entry.root
    local rootY = root.Position.Y
    local topY = rootY + root.Size.Y / 2
    local colliders = char:FindFirstChild("RagdollColliderParts")
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 and not (colliders and part:IsDescendantOf(colliders)) then
            local cf = part.CFrame
            local _, _, _, _, _, _, r10, r11, r12 = cf:GetComponents()
            local size = part.Size
            local top = cf.Position.Y + (math.abs(r10) * size.X + math.abs(r11) * size.Y + math.abs(r12) * size.Z) / 2
            if top > topY then topY = top end
        end
    end
    local offset = topY - rootY
    if entry.topOffset then offset = entry.topOffset * 0.6 + offset * 0.4 end
    entry.topOffset = offset
end

local function espUpdateEntry(entry, cam, origin, now, cfg)
    local char, hum, root = entry.char, entry.humanoid, entry.root
    if not char or not hum or not root or char.Parent == nil or entry.player.Character ~= char then
        espHide(entry)
        if now >= entry.nextResolve then
            entry.nextResolve = now + 0.25
            espResolve(entry)
        end
        return
    end

    if not Groups.EspAllowed(entry.player) then espHide(entry) return end

    local hp = hum.Health
    if hp <= 0 then espHide(entry) return end

    local pos = root.Position
    local dist = (pos - origin).Magnitude
    if dist > cfg.distance then espHide(entry) return end

    if not entry.topOffset or now >= entry.nextMeasure then
        entry.nextMeasure = now + 1 + math.random() * 0.4
        espMeasure(entry)
    end

    local anchor = Vector3.new(pos.X, pos.Y + entry.topOffset + ESP_WORLD_PAD, pos.Z)
    local screen, onScreen = cam:WorldToViewportPoint(anchor)
    if not onScreen then espHide(entry) return end

    local nameText, hpText = entry.text, entry.hpText

    if entry.font ~= cfg.font then
        entry.font = cfg.font
        local f = ESP_FONTS[cfg.font] or 0
        nameText.Font = f
        hpText.Font = f
    end
    if entry.size ~= cfg.fontSize then
        entry.size = cfg.fontSize
        nameText.Size = cfg.fontSize
        hpText.Size = cfg.fontSize
    end

    local maxHp = hum.MaxHealth
    local hpInt = math.floor(hp + 0.5)
    local maxInt = math.floor(maxHp + 0.5)
    if entry.hp ~= hpInt or entry.maxHp ~= maxInt then
        entry.hp, entry.maxHp = hpInt, maxInt
        hpText.Text = string.format("%d / %d HP", hpInt, maxInt)
    end

    local bucket = espBucket(maxHp > 0 and hp / maxHp or 0)
    if entry.bucket ~= bucket then
        entry.bucket = bucket
        hpText.Color = ESP_COLORS[bucket]
    end

    local nameOn, hpOn = cfg.showName, cfg.showHealth
    local lineH = cfg.fontSize + 3
    local rows = (nameOn and 1 or 0) + (hpOn and 1 or 0)
    local x = screen.X + cfg.xOffset
    local y = screen.Y + cfg.yOffset - rows * lineH
    if nameOn then
        nameText.Position = Vector2.new(x, y)
        y = y + lineH
    end
    if hpOn then
        hpText.Position = Vector2.new(x, y)
    end
    nameText.Visible = nameOn
    hpText.Visible = hpOn
    entry.visible = true
end

local function espReplaceDrawing(entry)
    local newName = espCreateDrawing(ESP_NAME_COLOR)
    local newHp = espCreateDrawing()
    if not newName or not newHp then
        espDestroyDrawing(newName)
        espDestroyDrawing(newHp)
        return
    end
    espDestroyDrawing(entry.text)
    espDestroyDrawing(entry.hpText)
    pcall(function() newName.Text = entry.name end)
    entry.text, entry.hpText = newName, newHp
    entry.visible, entry.font, entry.size, entry.bucket, entry.hp = false, nil, nil, 0, -1
end

local function espStep()
    local cfg = State.Visuals.esp
    local cam = Services.Workspace.CurrentCamera
    if not cam then return end

    local origin = cam.CFrame.Position
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myRoot then origin = myRoot.Position end

    local now = os.clock()
    for _, entry in pairs(espEntries) do
        local ok = pcall(espUpdateEntry, entry, cam, origin, now, cfg)
        if ok then
            entry.errors = 0
        else
            entry.errors = entry.errors + 1
            if entry.errors >= 3 then
                entry.errors = 0
                espReplaceDrawing(entry)
            end
        end
    end
end

function ESP.AddPlayer(player)
    if player == Player or espEntries[player] then return end
    local text = espCreateDrawing(ESP_NAME_COLOR)
    if not text then return end
    local hpText = espCreateDrawing()
    if not hpText then
        espDestroyDrawing(text)
        return
    end
    pcall(function() text.Text = player.Name end)
    local entry = {
        player = player, text = text, hpText = hpText, name = player.Name,
        visible = false, bucket = 0, errors = 0, nextResolve = 0, nextMeasure = 0, height = 0,
        hp = -1, maxHp = -1, dist = -1, rev = -1
    }
    entry.conns = {
        player.CharacterAdded:Connect(function()
            entry.char, entry.humanoid, entry.root = nil, nil, nil
            entry.nextResolve = 0
        end),
        player.CharacterRemoving:Connect(function()
            entry.char, entry.humanoid, entry.root = nil, nil, nil
            espHide(entry)
        end)
    }
    espEntries[player] = entry
    espResolve(entry)
end

function ESP.RemovePlayer(player)
    local entry = espEntries[player]
    if not entry then return end
    espEntries[player] = nil
    for _, conn in ipairs(entry.conns) do Utils.SafeDisconnect(conn) end
    espDestroyDrawing(entry.text)
    espDestroyDrawing(entry.hpText)
end

function ESP.Start()
    if espRunning or State.Unloaded or not DrawingAvailable then return end
    espRunning = true
    for _, p in ipairs(Services.Players:GetPlayers()) do ESP.AddPlayer(p) end
    espPlayerAddedConn = Services.Players.PlayerAdded:Connect(ESP.AddPlayer)
    espPlayerRemovingConn = Services.Players.PlayerRemoving:Connect(ESP.RemovePlayer)
    Services.RunService:BindToRenderStep(ESP_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, espStep)
end

function ESP.Stop()
    if not espRunning then return end
    espRunning = false
    pcall(function() Services.RunService:UnbindFromRenderStep(ESP_BIND_NAME) end)
    espPlayerAddedConn = Utils.SafeDisconnect(espPlayerAddedConn)
    espPlayerRemovingConn = Utils.SafeDisconnect(espPlayerRemovingConn)
    for player in pairs(espEntries) do ESP.RemovePlayer(player) end
end

local TweenService = game:GetService("TweenService")

local HUD = {
    gui = nil, box = nil, stroke = nil, conn = nil,
    dot = nil, title = nil, status = nil, name = nil, info = nil, hpFill = nil, cdFill = nil,
    side = "Right", nextScan = 0, lastStep = 0, target = nil
}

local HUD_ACCENT = Theme.Border
local HUD_BG = Theme.Dock
local HUD_TRACK = Theme.Track
local HUD_TEXT = Theme.Text
local HUD_SUB = Theme.Sub
local HUD_OFF = Color3.fromRGB(255, 65, 65)
local HUD_HIT_FLASH = Color3.fromRGB(255, 255, 255)
local HUD_MISS_FLASH = Color3.fromRGB(255, 65, 65)
local HUD_COOLDOWN = Color3.fromRGB(255, 150, 45)

local function hudNew(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function hudSet(inst, prop, value)
    if inst[prop] ~= value then inst[prop] = value end
end

local function hudLabel(parent, props)
    props.BackgroundTransparency = 1
    props.BorderSizePixel = 0
    props.TextTruncate = Enum.TextTruncate.AtEnd
    return hudNew("TextLabel", props, parent)
end

function HUD.ApplySide()
    local box = HUD.box
    if not box then return end
    if HUD.side == "Left" then
        box.AnchorPoint = Vector2.new(0, 0.5)
        box.Position = UDim2.new(0, 16, 0.5, 0)
    else
        box.AnchorPoint = Vector2.new(1, 0.5)
        box.Position = UDim2.new(1, -16, 0.5, 0)
    end
end

function HUD.SetSide(side)
    HUD.side = (side == "Left") and "Left" or "Right"
    HUD.ApplySide()
end

function HUD.Create()
    if HUD.gui then return end

    local gui = GuiFactory.New("CustomUtilityHUD", 50)

    local box = hudNew("Frame", {
        Name = "Box", Size = UDim2.fromOffset(204, 92),
        BackgroundColor3 = HUD_BG, BackgroundTransparency = 0.12, BorderSizePixel = 0
    }, gui)
    hudNew("UICorner", {CornerRadius = UDim.new(0, 10)}, box)
    local stroke = hudNew("UIStroke", {
        Color = HUD_ACCENT, Thickness = 1, Transparency = 0.45,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, box)
    hudNew("UIPadding", {
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 10)
    }, box)

    local dot = hudNew("Frame", {
        Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(0, 4),
        BackgroundColor3 = HUD_SUB, BorderSizePixel = 0
    }, box)
    hudNew("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)

    local title = hudLabel(box, {
        Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(110, 16),
        Font = Fonts.Bold, TextSize = 11, TextColor3 = HUD_SUB,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "KILL AURA"
    })
    local status = hudLabel(box, {
        Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 16),
        Font = Fonts.Bold, TextSize = 11, TextColor3 = HUD_SUB,
        TextXAlignment = Enum.TextXAlignment.Right, Text = ""
    })
    local name = hudLabel(box, {
        Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 18),
        Font = Fonts.Bold, TextSize = 15, TextColor3 = HUD_TEXT,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "No target"
    })
    local info = hudLabel(box, {
        Position = UDim2.fromOffset(0, 41), Size = UDim2.new(1, 0, 0, 13),
        Font = Fonts.Regular, TextSize = 11, TextColor3 = HUD_SUB,
        TextXAlignment = Enum.TextXAlignment.Left, Text = ""
    })

    local function makeBar(y)
        local track = hudNew("Frame", {
            Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 4),
            BackgroundColor3 = HUD_TRACK, BorderSizePixel = 0
        }, box)
        hudNew("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
        local fill = hudNew("Frame", {
            Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = HUD_SUB, BorderSizePixel = 0
        }, track)
        hudNew("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
        return fill
    end

    HUD.gui, HUD.box, HUD.stroke = gui, box, stroke
    HUD.dot, HUD.title, HUD.status, HUD.name, HUD.info = dot, title, status, name, info
    HUD.hpFill = makeBar(60)
    HUD.cdFill = makeBar(68)
    HUD.nextScan = 0
    HUD.ApplySide()
end

function HUD.Destroy()
    if HUD.gui then pcall(function() HUD.gui:Destroy() end) end
    HUD.gui, HUD.box, HUD.stroke = nil, nil, nil
    HUD.dot, HUD.title, HUD.status, HUD.name, HUD.info, HUD.hpFill, HUD.cdFill = nil, nil, nil, nil, nil, nil, nil
    HUD.target = nil
end

function HUD.Flash(color)
    local stroke = HUD.stroke
    if not stroke then return end
    stroke.Color = color
    stroke.Transparency = 0
    TweenService:Create(stroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Color = HUD_ACCENT, Transparency = 0.45
    }):Play()
end

local function hudStep()
    if not HUD.gui then return end
    local now = os.clock()
    if now - HUD.lastStep < 0.033 then return end
    HUD.lastStep = now
    local ka = State.Combat.killAura

    if now >= HUD.nextScan then
        HUD.nextScan = now + 0.15
        if ka.enabled and State.CharacterLoaded then
            HUD.target = Combat.FindNearestTarget()
        else
            HUD.target = nil
        end
    end

    local target = HUD.target
    if target and (target.character.Parent == nil or target.humanoid.Health <= 0) then
        target = nil
        HUD.target = nil
    end

    local remaining = Combat.GetCooldownRemaining()

    local statusText, statusColor
    if not ka.enabled then
        statusText, statusColor = "OFF", HUD_OFF
    elseif remaining > 0 then
        statusText, statusColor = string.format("%.2fs", remaining), HUD_COOLDOWN
    elseif target then
        statusText, statusColor = "READY", ESP_COLORS[1]
    else
        statusText, statusColor = "IDLE", HUD_SUB
    end

    local nameText, nameColor, infoText, hpPct
    if not ka.enabled then
        nameText, nameColor, infoText, hpPct = "Disabled", HUD_SUB, "Kill Aura is turned off", 0
    elseif target then
        local hum = target.humanoid
        nameText, nameColor = target.player.Name, HUD_TEXT
        infoText = string.format("%d / %d HP | %d studs",
            math.floor(hum.Health + 0.5), math.floor(hum.MaxHealth + 0.5), math.floor(target.distance + 0.5))
        hpPct = hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0
    else
        nameText, nameColor = "No target", HUD_SUB
        infoText, hpPct = string.format("Nothing within %d studs", math.floor(ka.range)), 0
    end

    local progress = ka.cooldown > 0 and (1 - remaining / ka.cooldown) or 1

    hudSet(HUD.title, "Text", "KILL AURA | " .. tostring(Combat.GetKey()))
    hudSet(HUD.dot, "BackgroundColor3", statusColor)
    hudSet(HUD.status, "Text", statusText)
    hudSet(HUD.status, "TextColor3", statusColor)
    hudSet(HUD.name, "Text", nameText)
    hudSet(HUD.name, "TextColor3", nameColor)
    hudSet(HUD.info, "Text", infoText)
    hudSet(HUD.hpFill, "Size", UDim2.new(hpPct, 0, 1, 0))
    hudSet(HUD.hpFill, "BackgroundColor3", ESP_COLORS[espBucket(hpPct)])
    hudSet(HUD.cdFill, "Size", UDim2.new(ka.enabled and progress or 0, 0, 1, 0))
    hudSet(HUD.cdFill, "BackgroundColor3", remaining > 0 and HUD_COOLDOWN or ESP_COLORS[1])
end

function HUD.SetEnabled(on)
    if on then
        HUD.Create()
        if not HUD.conn then
            HUD.conn = Services.RunService.Heartbeat:Connect(function() pcall(hudStep) end)
        end
    else
        HUD.conn = Utils.SafeDisconnect(HUD.conn)
        HUD.Destroy()
    end
end

Combat.OnHit = function() HUD.Flash(HUD_HIT_FLASH) end
Combat.OnMiss = function() HUD.Flash(HUD_MISS_FLASH) end

local TimeOfDay = {}

function TimeOfDay.Apply()
    local t = State.Time
    if not t.enabled then return end
    local lighting = Services.Lighting
    if math.abs(lighting.ClockTime - t.value) > 0.001 then
        lighting.ClockTime = t.value
    end
end

function TimeOfDay.Enable()
    local t = State.Time
    if t.enabled then return end
    t.original = Services.Lighting.ClockTime
    t.enabled = true
    TimeOfDay.Apply()
    t.connection = Services.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(TimeOfDay.Apply)
end

function TimeOfDay.Disable()
    local t = State.Time
    t.enabled = false
    t.connection = Utils.SafeDisconnect(t.connection)
    if t.original then
        pcall(function() Services.Lighting.ClockTime = t.original end)
        t.original = nil
    end
end

function TimeOfDay.SetValue(value)
    State.Time.value = value
    TimeOfDay.Apply()
end

local Stamina = {conn = nil, enabled = false}

function Stamina.Step()
    if State.Unloaded or not State.CharacterLoaded then return end
    local char = Player.Character
    if not char then return end
    local max = char:GetAttribute("StaminaMax") or char:GetAttribute("MaxStamina") or 100
    if char:GetAttribute("Stamina") ~= max then
        pcall(function() char:SetAttribute("Stamina", max) end)
    end
end

function Stamina.SetEnabled(on)
    Stamina.enabled = on
    Stamina.conn = Utils.SafeDisconnect(Stamina.conn)
    if on then
        Stamina.conn = Services.RunService.Heartbeat:Connect(function() pcall(Stamina.Step) end)
    end
end

local RespawnHandler = {generation = 0}

function RespawnHandler.OnCharacterAdded()
    RespawnHandler.generation = RespawnHandler.generation + 1
    local generation = RespawnHandler.generation
    State.CharacterLoaded = false
    Utils.Cache.data = {}
    Utils.Cache.timestamps = {}
    local components = Utils.WaitForCharacterComponents(Player, 10)
    if not components or State.Unloaded then return end
    task.wait(RESPAWN_WAIT_TIME)
    if State.Unloaded or generation ~= RespawnHandler.generation then return end
    State.CharacterLoaded = true
end

function RespawnHandler.Setup()
    Cleanup.Add(Player.CharacterAdded:Connect(RespawnHandler.OnCharacterAdded))
    if Player.Character then
        task.spawn(RespawnHandler.OnCharacterAdded)
    end
end

local Library = {
    Flags = {}, Categories = {}, Current = nil, Visible = true,
    Gui = nil, Shell = nil, ShellScale = nil, Dock = nil, Panel = nil, PanelScale = nil,
    Title = nil, Subtitle = nil, Hint = nil, Toasts = nil,
    Drag = nil, Listening = nil, LastBind = -10, MenuKey = nil, PanicKey = nil
}

local DOCK_W = 70
local PANEL_W = 348
local SHELL_H = 500
local SHELL_GAP = 10

local Config = {
    folder = "CustomUtility", file = "CustomUtility/Settings.json",
    ready = false, pending = false, disabled = false
}

function Config.CanUse()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

function Config.Collect()
    local data = {}
    for flag, entry in pairs(Library.Flags) do
        local ok, value = pcall(entry.get)
        if ok and value ~= nil then data[flag] = value end
    end
    return data
end

function Config.Save(force)
    if not Config.ready or Config.disabled or not Config.CanUse() then return false end
    if State.Unloaded and not force then return false end
    return pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(Config.folder) then
            makefolder(Config.folder)
        end
        writefile(Config.file, game:GetService("HttpService"):JSONEncode(Config.Collect()))
    end)
end

function Config.MarkDirty()
    if not Config.ready or Config.pending or Config.disabled or State.Unloaded then return end
    Config.pending = true
    task.delay(1, function()
        Config.pending = false
        Config.Save()
    end)
end

function Config.Load()
    if not Config.CanUse() then return false end
    local ok, data = pcall(function()
        if not isfile(Config.file) then return nil end
        return game:GetService("HttpService"):JSONDecode(readfile(Config.file))
    end)
    if not ok or type(data) ~= "table" then return false end
    for flag, value in pairs(data) do
        local entry = Library.Flags[flag]
        if entry then pcall(entry.set, value) end
    end
    return true
end

function Config.Reset()
    Config.disabled = true
    pcall(function()
        if type(isfile) == "function" and type(delfile) == "function" and isfile(Config.file) then
            delfile(Config.file)
        end
    end)
end

function Library.Register(flag, getter, setter)
    Library.Flags[flag] = {get = getter, set = setter}
end

function Library.Changed()
    Config.MarkDirty()
end

local function uiNew(class, props, parent)
    local inst = Instance.new(class)
    for key, value in pairs(props) do inst[key] = value end
    if parent then inst.Parent = parent end
    return inst
end

local function uiCorner(parent, radius)
    return uiNew("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function uiStroke(parent, color, transparency, thickness)
    return uiNew("UIStroke", {
        Color = color, Transparency = transparency or 0, Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function uiPadding(parent, top, right, bottom, left)
    return uiNew("UIPadding", {
        PaddingTop = UDim.new(0, top), PaddingRight = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom), PaddingLeft = UDim.new(0, left)
    }, parent)
end

local function uiList(parent, padding, extra)
    local props = {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, padding or 0)}
    if extra then
        for key, value in pairs(extra) do props[key] = value end
    end
    return uiNew("UIListLayout", props, parent)
end

local function tween(inst, duration, props)
    if State.Unloaded then return end
    local ok, built = pcall(function()
        return TweenService:Create(inst, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    end)
    if ok and built then built:Play() end
end

local function paint(inst, props, animate)
    if animate then
        tween(inst, 0.12, props)
    else
        for key, value in pairs(props) do inst[key] = value end
    end
end

local function iconBuilder(root)
    local parts = {}
    local api = {}

    function api.fill(x, y, w, h, round, rotation, color)
        local frame = uiNew("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, x, 0.5, y),
            Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or Theme.Sub, BorderSizePixel = 0,
            Rotation = rotation or 0
        }, root)
        uiCorner(frame, round or 0)
        if not color then parts[#parts + 1] = {inst = frame, kind = "fill"} end
        return frame
    end

    function api.ring(x, y, w, h, thickness, round)
        local frame = uiNew("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, x, 0.5, y),
            Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, BorderSizePixel = 0
        }, root)
        uiCorner(frame, round or math.floor(math.min(w, h) / 2))
        parts[#parts + 1] = {inst = uiStroke(frame, Theme.Sub, 0, thickness), kind = "stroke"}
        return frame
    end

    function api.color(value)
        for _, part in ipairs(parts) do
            if part.kind == "fill" then
                part.inst.BackgroundColor3 = value
            else
                part.inst.Color = value
            end
        end
    end

    return api
end

local Icons = {}

function Icons.Combat(b)
    b.ring(0, 0, 13, 13, 2)
    b.fill(0, 0, 4, 4, 2)
    b.fill(0, -11, 2, 7, 1)
    b.fill(0, 11, 2, 7, 1)
    b.fill(-11, 0, 7, 2, 1)
    b.fill(11, 0, 7, 2, 1)
end

function Icons.Visuals(b)
    b.ring(0, 0, 19, 10, 2, 5)
    b.fill(0, 0, 7, 7, 4)
end

function Icons.Misc(b)
    b.fill(0, 0, 10, 10, 5)
    for i = 0, 7 do
        local angle = i * 45
        local rad = math.rad(angle)
        b.fill(math.cos(rad) * 11.5, math.sin(rad) * 11.5, 2, 5, 1, angle + 90)
    end
end

function Icons.Settings(b)
    b.ring(0, 0, 11, 11, 3)
    for i = 0, 7 do
        local angle = i * 45
        local rad = math.rad(angle)
        b.fill(math.cos(rad) * 10.5, math.sin(rad) * 10.5, 4, 5, 1, angle + 90)
    end
end

function Icons.Groups(b)
    b.fill(-5, -6, 8, 8, 4)
    b.fill(-5, 5, 14, 7, 3)
    b.fill(7, -4, 6, 6, 3)
    b.fill(7, 5, 10, 6, 3)
end

function Icons.Kill(b)
    for k = 0, 13 do
        local angle = -50 + (280 * k / 13)
        local rad = math.rad(angle)
        b.fill(math.cos(rad) * 9, math.sin(rad) * 9, 3, 5, 1, angle)
    end
    b.fill(0, -7, 2, 11, 1)
end

local function textBlock(parent, title, description, widthOffset)
    local block = uiNew("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, widthOffset, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 0
    }, parent)
    uiList(block, 2)
    uiNew("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = Fonts.Medium, TextSize = 14, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = title or "", LayoutOrder = 1
    }, block)
    if description and description ~= "" then
        uiNew("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Font = Fonts.Regular, TextSize = 12, TextColor3 = Theme.Sub,
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = description, LayoutOrder = 2
        }, block)
    end
    return block
end

local Category = {}
Category.__index = Category

function Category:NextOrder()
    self.Order = self.Order + 1
    return self.Order
end

local function newRow(cat)
    local row = uiNew("Frame", {
        BackgroundColor3 = Theme.Row, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = cat:NextOrder()
    }, cat.Scroll)
    uiCorner(row, 8)
    uiStroke(row, Theme.Border, 0, 1)
    uiPadding(row, 11, 12, 11, 12)
    row.MouseEnter:Connect(function() tween(row, 0.12, {BackgroundColor3 = Theme.RowHover}) end)
    row.MouseLeave:Connect(function() tween(row, 0.12, {BackgroundColor3 = Theme.Row}) end)
    return row
end

function Category:AddSection(title)
    return uiNew("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Fonts.Bold, TextSize = 11,
        TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom,
        Text = string.upper(title), LayoutOrder = self:NextOrder()
    }, self.Scroll)
end

function Category:AddParagraph(title, content)
    local row = newRow(self)
    textBlock(row, title, content, 0)
    return row
end

function Category:AddToggle(flag, opts)
    local control = {Value = opts.Default == true}
    local row = newRow(self)
    uiList(row, 8, {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center})
    textBlock(row, opts.Title, opts.Description, -48)
    local switch = uiNew("TextButton", {
        LayoutOrder = 1, Size = UDim2.fromOffset(36, 20), BackgroundColor3 = Theme.Track,
        BorderSizePixel = 0, AutoButtonColor = false, Text = ""
    }, row)
    uiCorner(switch, 10)
    local knob = uiNew("Frame", {
        Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Theme.Text, BorderSizePixel = 0
    }, switch)
    uiCorner(knob, 7)

    local function render(animate)
        local on = control.Value
        paint(knob, {
            Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = on and Theme.OnAccent or Theme.Sub
        }, animate)
        paint(switch, {BackgroundColor3 = on and self.Color or Theme.Track}, animate)
    end

    local function set(value)
        value = value == true
        if value == control.Value then return end
        control.Value = value
        render(true)
        if opts.Callback then pcall(opts.Callback, value) end
        Library.Changed()
    end

    control.Set = set
    switch.MouseButton1Click:Connect(function() set(not control.Value) end)
    render(false)
    if opts.Callback then pcall(opts.Callback, control.Value) end
    if flag then Library.Register(flag, function() return control.Value end, set) end
    return control
end

function Category:AddSlider(flag, opts)
    local min, max = opts.Min, opts.Max
    local rounding = opts.Rounding or 0
    local suffix = opts.Suffix or ""
    local control = {Value = math.clamp(opts.Default or min, min, max)}
    local row = newRow(self)
    uiList(row, 9)
    local top = uiNew("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1
    }, row)
    uiList(top, 8, {FillDirection = Enum.FillDirection.Horizontal})
    textBlock(top, opts.Title, opts.Description, -70)
    local valueLabel = uiNew("TextLabel", {
        LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.fromOffset(62, 18),
        Font = Fonts.Bold, TextSize = 13, TextColor3 = self.Color,
        TextXAlignment = Enum.TextXAlignment.Right, Text = ""
    }, top)
    local hit = uiNew("TextButton", {
        LayoutOrder = 2, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 18)
    }, row)
    local track = uiNew("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Track, BorderSizePixel = 0
    }, hit)
    uiCorner(track, 2)
    local fill = uiNew("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self.Color, BorderSizePixel = 0
    }, track)
    uiCorner(fill, 2)
    local knob = uiNew("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 2
    }, track)
    uiCorner(knob, 6)

    local function render()
        local pct = max > min and (control.Value - min) / (max - min) or 0
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        if opts.Format then
            valueLabel.Text = opts.Format(control.Value)
        else
            valueLabel.Text = string.format("%." .. rounding .. "f%s", control.Value, suffix)
        end
    end

    local function set(value)
        value = tonumber(value)
        if not value then return end
        local mult = 10 ^ rounding
        value = math.floor(value * mult + 0.5) / mult
        value = math.clamp(value, min, max)
        if value == control.Value then return end
        control.Value = value
        render()
        if opts.Callback then pcall(opts.Callback, value) end
        Library.Changed()
    end

    control.Set = set
    hit.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local function fromX(x)
            local width = track.AbsoluteSize.X
            if width <= 0 then return end
            set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / width, 0, 1))
        end
        fromX(input.Position.X)
        Library.Drag = function(pos) fromX(pos.X) end
    end)
    render()
    if opts.Callback then pcall(opts.Callback, control.Value) end
    if flag then Library.Register(flag, function() return control.Value end, set) end
    return control
end

function Category:AddSegmented(flag, opts)
    local values = opts.Values
    local control = {Value = opts.Default or values[1]}
    local row = newRow(self)
    uiList(row, 9)
    local block = textBlock(row, opts.Title, opts.Description, 0)
    block.LayoutOrder = 1
    local bar = uiNew("Frame", {
        LayoutOrder = 2, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28)
    }, row)
    local buttons = {}
    local count = #values
    for i, value in ipairs(values) do
        local button = uiNew("TextButton", {
            Position = UDim2.new((i - 1) / count, 0, 0, 0), Size = UDim2.new(1 / count, -4, 1, 0),
            BackgroundColor3 = Theme.Track, BorderSizePixel = 0, AutoButtonColor = false,
            Font = Fonts.Medium, TextSize = 13, TextColor3 = Theme.Sub, Text = value
        }, bar)
        uiCorner(button, 6)
        buttons[value] = button
        button.MouseButton1Click:Connect(function() control.Set(value) end)
    end

    local function render(animate)
        for value, button in pairs(buttons) do
            local active = value == control.Value
            paint(button, {
                BackgroundColor3 = active and self.Color or Theme.Track,
                TextColor3 = active and Theme.OnAccent or Theme.Sub
            }, animate)
        end
    end

    function control.Set(value)
        if not buttons[value] or value == control.Value then return end
        control.Value = value
        render(true)
        if opts.Callback then pcall(opts.Callback, value) end
        Library.Changed()
    end

    render(false)
    if opts.Callback then pcall(opts.Callback, control.Value) end
    if flag then Library.Register(flag, function() return control.Value end, control.Set) end
    return control
end

function Category:AddKeybind(flag, opts)
    local control = {Value = opts.Default or "None"}
    local row = newRow(self)
    uiList(row, 8, {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center})
    textBlock(row, opts.Title, opts.Description, -96)
    local button = uiNew("TextButton", {
        LayoutOrder = 1, Size = UDim2.fromOffset(88, 26), BackgroundColor3 = Theme.Track, BorderSizePixel = 0,
        AutoButtonColor = false, Font = Fonts.Bold, TextSize = 12, TextColor3 = Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = control.Value
    }, row)
    uiCorner(button, 6)
    local stroke = uiStroke(button, self.Color, 1)

    local function render()
        button.Text = control.Value
    end

    function control.Set(value)
        if type(value) ~= "string" or value == "" then value = "None" end
        if value == control.Value then
            render()
            return
        end
        control.Value = value
        render()
        if opts.Callback then pcall(opts.Callback, value) end
        Library.Changed()
    end

    button.MouseButton1Click:Connect(function()
        if Library.Listening then Library.Listening.cancel() end
        button.Text = "..."
        stroke.Transparency = 0
        Library.Listening = {
            finish = function(name)
                stroke.Transparency = 1
                control.Set(name)
                render()
            end,
            cancel = function()
                Library.Listening = nil
                stroke.Transparency = 1
                render()
            end
        }
    end)

    render()
    if flag then Library.Register(flag, function() return control.Value end, control.Set) end
    return control
end

function Category:AddInput(opts)
    local row = newRow(self)
    uiList(row, 9)
    local block = textBlock(row, opts.Title, opts.Description, 0)
    block.LayoutOrder = 1
    local line = uiNew("Frame", {
        LayoutOrder = 2, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)
    }, row)
    local box = uiNew("TextBox", {
        Size = UDim2.new(1, -72, 1, 0), BackgroundColor3 = Theme.Track, BorderSizePixel = 0,
        Font = Fonts.Medium, TextSize = 13, TextColor3 = Theme.Text, PlaceholderText = opts.Placeholder or "",
        PlaceholderColor3 = Theme.Sub, Text = "", ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    }, line)
    uiCorner(box, 6)
    uiPadding(box, 0, 8, 0, 10)
    local button = uiNew("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(64, 30),
        BackgroundColor3 = self.Color, BorderSizePixel = 0, AutoButtonColor = false, Font = Fonts.Bold,
        TextSize = 13, TextColor3 = Theme.OnAccent, Text = opts.ButtonText or "Add"
    }, line)
    uiCorner(button, 6)
    local function submit()
        local text = string.match(box.Text, "^%s*(.-)%s*$")
        if not text or text == "" then return end
        local accepted = opts.OnSubmit and opts.OnSubmit(text)
        if accepted ~= false then box.Text = "" end
    end
    button.MouseButton1Click:Connect(submit)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then submit() end
    end)
    return {Box = box, Submit = submit}
end

function Category:AddButton(opts)
    local danger = opts.Danger == true
    local base = danger and Theme.DangerBg or Theme.Row
    local hover = danger and Theme.DangerHover or Theme.RowHover
    local button = uiNew("TextButton", {
        Size = UDim2.new(1, 0, 0, opts.Height or 36), BackgroundColor3 = base, BorderSizePixel = 0,
        AutoButtonColor = false, Font = Fonts.Bold, TextSize = opts.TextSize or 14,
        TextColor3 = danger and Theme.Danger or Theme.Text, Text = opts.Title, LayoutOrder = self:NextOrder()
    }, self.Scroll)
    uiCorner(button, 8)
    uiStroke(button, danger and Theme.Danger or Theme.Border, danger and 0.35 or 0, 1)
    button.MouseEnter:Connect(function() tween(button, 0.12, {BackgroundColor3 = hover}) end)
    button.MouseLeave:Connect(function() tween(button, 0.12, {BackgroundColor3 = base}) end)
    button.MouseButton1Click:Connect(function()
        if opts.Callback then pcall(opts.Callback) end
    end)
    return button
end

function Category:AddPlayerList(flag, opts)
    local selected = {}
    local rows = {}
    local destroyed = false
    if type(opts.Initial) == "table" then
        for name, on in pairs(opts.Initial) do
            if on == true then selected[name] = true end
        end
    end
    local onText, offText = opts.OnText or "ON", opts.OffText or "OFF"
    local holder = newRow(self)
    uiList(holder, 9)
    local block = textBlock(holder, opts.Title, opts.Description, 0)
    block.LayoutOrder = 1
    local list = uiNew("Frame", {
        LayoutOrder = 2, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, holder)
    uiList(list, 4, {SortOrder = Enum.SortOrder.Name})
    local empty = uiNew("TextLabel", {
        Name = "~empty", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Font = Fonts.Regular,
        TextSize = 13, TextColor3 = Theme.Sub, Text = "No other players in the server", Visible = false
    }, list)

    local render

    local function commit()
        if opts.Callback then pcall(opts.Callback, selected) end
        Library.Changed()
    end

    local function makeRow(name)
        local button = uiNew("TextButton", {
            Name = string.lower(name), Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Track,
            BorderSizePixel = 0, AutoButtonColor = false, Text = ""
        }, list)
        uiCorner(button, 6)
        local label = uiNew("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -84, 1, 0),
            Font = Fonts.Medium, TextSize = 13, TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = name
        }, button)
        local pill = uiNew("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(58, 20),
            Font = Fonts.Bold, TextSize = 11, BorderSizePixel = 0, BackgroundColor3 = Theme.Row,
            TextColor3 = Theme.Sub, Text = offText
        }, button)
        uiCorner(pill, 5)
        local entry = {button = button, label = label, pill = pill}
        button.MouseButton1Click:Connect(function()
            if selected[name] then selected[name] = nil else selected[name] = true end
            render()
            commit()
        end)
        rows[name] = entry
        return entry
    end

    render = function()
        local present, names = {}, {}
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= Player then
                present[p.Name] = true
                names[#names + 1] = p.Name
            end
        end
        for name in pairs(selected) do
            if not present[name] then names[#names + 1] = name end
        end
        local keep = {}
        for _, name in ipairs(names) do keep[name] = true end
        for name, entry in pairs(rows) do
            if not keep[name] then
                entry.button:Destroy()
                rows[name] = nil
            end
        end
        for _, name in ipairs(names) do
            local entry = rows[name] or makeRow(name)
            local on = selected[name] == true
            local here = present[name] == true
            entry.pill.Text = on and onText or offText
            entry.pill.BackgroundColor3 = on and self.Color or Theme.Row
            entry.pill.TextColor3 = on and Theme.OnAccent or Theme.Sub
            entry.label.Text = here and name or (name .. " (left)")
            entry.label.TextColor3 = here and Theme.Text or Theme.Sub
        end
        empty.Visible = #names == 0
    end

    local function refreshLater()
        task.delay(0.3, function()
            if not State.Unloaded and not destroyed then render() end
        end)
    end
    local addedConn = Services.Players.PlayerAdded:Connect(refreshLater)
    local removingConn = Services.Players.PlayerRemoving:Connect(refreshLater)
    Cleanup.Add(addedConn)
    Cleanup.Add(removingConn)

    local function set(value)
        if type(value) ~= "table" then return end
        selected = {}
        for name, on in pairs(value) do
            if on == true and type(name) == "string" then selected[name] = true end
        end
        render()
        commit()
    end

    render()
    commit()
    if flag then
        Library.Register(flag, function()
            local copy = {}
            for name in pairs(selected) do copy[name] = true end
            return copy
        end, set)
    end
    return {
        Set = set,
        Destroy = function()
            destroyed = true
            Utils.SafeDisconnect(addedConn)
            Utils.SafeDisconnect(removingConn)
        end
    }
end

function Library.Notify(title, text, duration)
    if State.Unloaded or not Library.Toasts then return end
    local toast = uiNew("Frame", {
        Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0,
        BorderSizePixel = 0, LayoutOrder = math.floor(os.clock() * 100)
    }, Library.Toasts)
    uiCorner(toast, 10)
    local stroke = uiStroke(toast, Theme.Border, 0)
    local accent = uiNew("Frame", {
        Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(3, 28),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0
    }, toast)
    uiCorner(accent, 2)
    local titleLabel = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 7), Size = UDim2.new(1, -26, 0, 17),
        Font = Fonts.Bold, TextSize = 13, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = title
    }, toast)
    local textLabel = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 25), Size = UDim2.new(1, -26, 0, 16),
        Font = Fonts.Regular, TextSize = 12, TextColor3 = Theme.Sub,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = text or ""
    }, toast)
    task.delay(duration or 2.5, function()
        if State.Unloaded then return end
        tween(toast, 0.25, {BackgroundTransparency = 1})
        tween(stroke, 0.25, {Transparency = 1})
        tween(accent, 0.25, {BackgroundTransparency = 1})
        tween(titleLabel, 0.25, {TextTransparency = 1})
        tween(textLabel, 0.25, {TextTransparency = 1})
        task.delay(0.3, function()
            pcall(function() toast:Destroy() end)
        end)
    end)
end

function Library.SetScale(value)
    if Library.ShellScale then Library.ShellScale.Scale = value end
end

function Library.SetHint(keyName)
    if Library.Hint then Library.Hint.Text = tostring(keyName) .. " hides the menu" end
end

function Library.SetVisible(visible)
    Library.Visible = visible
    Library.Drag = nil
    if not visible and Library.Listening then Library.Listening.cancel() end
    if Library.Gui then Library.Gui.Enabled = visible end
end

function Library.GroupsChanged() end

function Library.Select(cat)
    if Library.Picker then Library.Picker.Close() end
    if Library.Current == cat then cat = nil end
    Library.Current = cat
    for _, other in ipairs(Library.Categories) do
        if not other.Action then
            local active = other == cat
            other.Scroll.Visible = active
            other.SetActive(active)
        end
    end
    if not cat then
        Library.Panel.Visible = false
        return
    end
    Library.Title.Text = cat.Name
    Library.Subtitle.Text = cat.Subtitle
    Library.Panel.Visible = true
    Library.PanelScale.Scale = 0.97
    tween(Library.PanelScale, 0.16, {Scale = 1})
end

function Library.BeginShellDrag(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    local startMouse = Vector2.new(input.Position.X, input.Position.Y)
    local startPos = Library.Shell.Position
    Library.Drag = function(pos)
        local delta = Vector2.new(pos.X, pos.Y) - startMouse
        Library.Shell.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end

function Library.HandleListen(input)
    local listening = Library.Listening
    local name
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode.Name == "Escape" then
            listening.cancel()
            return
        end
        name = input.KeyCode.Name == "Backspace" and "None" or input.KeyCode.Name
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        name = "MouseRight"
    else
        return
    end
    Library.Listening = nil
    Library.LastBind = os.clock()
    listening.finish(name)
end

function Library.BuildPicker(panel)
    local picker = {kind = "aura"}
    local overlay = uiNew("Frame", {
        Name = "Picker", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
        Active = true, Visible = false, ZIndex = 50
    }, panel)
    local title = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 20),
        Font = Fonts.Bold, TextSize = 17, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = ""
    }, overlay)
    local sub = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 31), Size = UDim2.new(1, -32, 0, 16),
        Font = Fonts.Regular, TextSize = 12, TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left, Text = ""
    }, overlay)
    uiNew("Frame", {
        Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0
    }, overlay)
    local list = uiNew("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 57), Size = UDim2.new(1, 0, 1, -113), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Track, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y
    }, overlay)
    uiPadding(list, 6, 12, 6, 12)
    uiList(list, 6)
    local done = uiNew("TextButton", {
        Position = UDim2.new(0, 12, 1, -48), Size = UDim2.new(1, -24, 0, 36), BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0, AutoButtonColor = false, Font = Fonts.Bold, TextSize = 14, TextColor3 = Theme.OnAccent,
        Text = "Done"
    }, overlay)
    uiCorner(done, 8)

    local function paintSwitch(switch, knob, on)
        switch.BackgroundColor3 = on and Theme.Accent or Theme.Track
        knob.Position = on and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3)
        knob.BackgroundColor3 = on and Theme.OnAccent or Theme.Sub
    end

    local function makeSection(order, text)
        uiNew("TextLabel", {
            LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Fonts.Bold,
            TextSize = 11, TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom, Text = string.upper(text)
        }, list)
    end

    local function makeRow(order, name, subtext, color, isOn, onClick, count)
        local row = uiNew("TextButton", {
            LayoutOrder = order, Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
            AutoButtonColor = false, Text = ""
        }, list)
        uiCorner(row, 8)
        uiStroke(row, Theme.Border, 0, 1)
        local textWidth = -96
        if count then
            textWidth = -136
            uiNew("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0), Size = UDim2.fromOffset(26, 18),
                BackgroundTransparency = 1, Font = Fonts.Bold, TextSize = 13, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(count)
            }, row)
            local iconRoot = uiNew("Frame", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1
            }, row)
            local icon = iconBuilder(iconRoot)
            icon.fill(0, -4, 6, 6, 3)
            icon.fill(0, 4, 12, 6, 3)
            icon.color(Theme.Sub)
        end
        local swatch = uiNew("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(10, 10),
            BackgroundColor3 = color, BorderSizePixel = 0
        }, row)
        uiCorner(swatch, 3)
        uiNew("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(32, 7), Size = UDim2.new(1, textWidth, 0, 18),
            Font = Fonts.Bold, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = name
        }, row)
        uiNew("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(32, 26), Size = UDim2.new(1, textWidth, 0, 14),
            Font = Fonts.Regular, TextSize = 11, TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = subtext
        }, row)
        local switch = uiNew("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(36, 20),
            BackgroundColor3 = Theme.Track, BorderSizePixel = 0
        }, row)
        uiCorner(switch, 10)
        local knob = uiNew("Frame", {
            Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Theme.Sub,
            BorderSizePixel = 0
        }, switch)
        uiCorner(knob, 7)
        paintSwitch(switch, knob, isOn())
        row.MouseButton1Click:Connect(function()
            onClick()
            Groups.Changed()
            Library.GroupsChanged()
            Library.Changed()
            picker.Render()
        end)
    end

    function picker.Render()
        local canvas = list.CanvasPosition
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local kind = picker.kind
        local order = 1
        makeSection(order, "Teams")
        for _, group in ipairs(Groups.List()) do
            order = order + 1
            local count = #Groups.Members(group)
            local sub = "Players without a team"
            if group.team then
                local leader = Groups.Leader(group)
                sub = leader and ("\u{1F451} " .. leader.Name) or "Empty"
            end
            makeRow(order, group.name, sub, group.color,
                function() return State.Groups[kind][group.key] == true end,
                function()
                    local set = State.Groups[kind]
                    if set[group.key] then set[group.key] = nil else set[group.key] = true end
                end, count)
        end
        order = order + 1
        makeSection(order, "Players")
        local players = {}
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= Player then players[#players + 1] = p end
        end
        table.sort(players, function(a, b) return a.Name < b.Name end)
        if #players == 0 then
            order = order + 1
            uiNew("TextLabel", {
                LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Font = Fonts.Regular,
                TextSize = 13, TextColor3 = Theme.Sub, Text = "No other players in the server"
            }, list)
        end
        for _, p in ipairs(players) do
            order = order + 1
            local team = p.Team
            makeRow(order, p.Name, team and team.Name or "No Team", team and team.TeamColor.Color or Theme.Sub,
                function() return Groups.Selected(kind, p) end,
                function()
                    local teamOn = State.Groups[kind][Groups.Key(p)] == true
                    local new = not Groups.Selected(kind, p)
                    if new == teamOn then State.Picks[kind][p.Name] = nil else State.Picks[kind][p.Name] = new end
                end)
        end
        list.CanvasPosition = canvas
    end

    function picker.Open(kind)
        picker.kind = kind
        title.Text = kind == "aura" and "Who to hit" or "Who to show"
        sub.Text = "Tap a team or a player to turn them on or off"
        picker.Render()
        overlay.Visible = true
    end

    function picker.Close()
        overlay.Visible = false
    end

    done.MouseButton1Click:Connect(picker.Close)

    local queued = false
    local function refresh()
        if queued then return end
        queued = true
        task.defer(function()
            queued = false
            if State.Unloaded then return end
            if overlay.Visible then picker.Render() end
            Library.GroupsChanged()
            Groups.Changed()
        end)
    end

    local watched = {}
    local function watch(p)
        if watched[p] then return end
        watched[p] = p:GetPropertyChangedSignal("Team"):Connect(refresh)
        Cleanup.Add(watched[p])
    end
    for _, p in ipairs(Services.Players:GetPlayers()) do watch(p) end
    Cleanup.Add(Services.Players.PlayerAdded:Connect(function(p)
        watch(p)
        refresh()
    end))
    Cleanup.Add(Services.Players.PlayerRemoving:Connect(function(p)
        watched[p] = Utils.SafeDisconnect(watched[p])
    end))
    Cleanup.Add(Services.Players.ChildRemoved:Connect(refresh))
    Cleanup.Add(Services.Teams.ChildAdded:Connect(function() task.delay(0.15, refresh) end))
    Cleanup.Add(Services.Teams.ChildRemoved:Connect(refresh))

    Library.Picker = picker
end

function Library.Create()
    local gui = GuiFactory.New("CustomUtilityMenu", 100)
    Library.Gui = gui
    Cleanup.Add(function()
        Library.Drag, Library.Listening = nil, nil
        pcall(function() gui:Destroy() end)
        Library.Gui = nil
    end)
    Cleanup.Add(gui.AncestryChanged:Connect(function()
        if not gui:IsDescendantOf(game) then Cleanup.Run() end
    end))

    local shell = uiNew("Frame", {
        Name = "Shell", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(DOCK_W + SHELL_GAP + PANEL_W, SHELL_H), BackgroundTransparency = 1
    }, gui)
    Library.Shell = shell
    Library.ShellScale = uiNew("UIScale", {Scale = 1}, shell)

    local dock = uiNew("Frame", {
        Name = "Dock", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, DOCK_W, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Dock, BorderSizePixel = 0
    }, shell)
    Library.Dock = dock
    uiCorner(dock, 14)
    uiStroke(dock, Theme.Border, 0)
    uiPadding(dock, 7, 7, 7, 7)
    uiList(dock, 6, {HorizontalAlignment = Enum.HorizontalAlignment.Center})

    local logo = uiNew("TextButton", {
        Name = "Logo", Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "", LayoutOrder = 0
    }, dock)
    uiCorner(logo, 10)
    uiStroke(logo, Theme.Border, 0)
    local mark = iconBuilder(logo)
    mark.fill(8, -11, 4, 8, 1, 0, Theme.Accent)
    mark.fill(-6.5, -8, 17, 4, 2, -35, Theme.Accent)
    mark.fill(6.5, -8, 17, 4, 2, 35, Theme.Accent)
    mark.fill(0, 3, 18, 14, 2, 0, Theme.Accent)
    mark.fill(0, 6, 6, 8, 2, 0, Theme.Row)
    logo.InputBegan:Connect(Library.BeginShellDrag)

    local function divider(order)
        uiNew("Frame", {
            Size = UDim2.new(0.5, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, LayoutOrder = order
        }, dock)
    end
    divider(1)
    divider(99)

    local panel = uiNew("Frame", {
        Name = "Panel", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, DOCK_W + SHELL_GAP, 0.5, 0),
        Size = UDim2.fromOffset(PANEL_W, SHELL_H), BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0, Visible = false, ClipsDescendants = true
    }, shell)
    Library.Panel = panel
    uiCorner(panel, 14)
    uiStroke(panel, Theme.Border, 0)
    Library.PanelScale = uiNew("UIScale", {Scale = 1}, panel)

    local header = uiNew("TextButton", {
        Name = "Header", Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Text = "", AutoButtonColor = false
    }, panel)
    header.InputBegan:Connect(Library.BeginShellDrag)
    Library.Title = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -64, 0, 20),
        Font = Fonts.Bold, TextSize = 17, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = ""
    }, header)
    Library.Subtitle = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 31), Size = UDim2.new(1, -64, 0, 16),
        Font = Fonts.Regular, TextSize = 12, TextColor3 = Theme.Sub,
        TextXAlignment = Enum.TextXAlignment.Left, Text = ""
    }, header)
    local close = uiNew("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 14), Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = Theme.Row, BorderSizePixel = 0, AutoButtonColor = false, Font = Fonts.Bold,
        TextSize = 14, TextColor3 = Theme.Sub, Text = "X"
    }, header)
    uiCorner(close, 8)
    close.MouseEnter:Connect(function() tween(close, 0.12, {BackgroundColor3 = Theme.DangerBg, TextColor3 = Theme.Danger}) end)
    close.MouseLeave:Connect(function() tween(close, 0.12, {BackgroundColor3 = Theme.Row, TextColor3 = Theme.Sub}) end)
    close.MouseButton1Click:Connect(function() Library.Select(Library.Current) end)
    uiNew("Frame", {
        Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0
    }, panel)

    uiNew("Frame", {
        Position = UDim2.new(0, 0, 1, -30), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0
    }, panel)
    uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 16, 1, -29), Size = UDim2.new(0.5, -16, 0, 28),
        Font = Fonts.Bold, TextSize = 11, TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "CUSTOM UTILITY"
    }, panel)
    Library.Hint = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 1, -29), Size = UDim2.new(0.5, -16, 0, 28),
        Font = Fonts.Regular, TextSize = 11, TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Right,
        Text = ""
    }, panel)

    Library.BuildPicker(panel)

    Library.Toasts = uiNew("Frame", {
        Name = "Toasts", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24),
        Size = UDim2.new(0, 290, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1
    }, gui)
    uiList(Library.Toasts, 6, {VerticalAlignment = Enum.VerticalAlignment.Bottom})

    Cleanup.Add(Services.UserInputService.InputChanged:Connect(function(input)
        if Library.Drag and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            Library.Drag(input.Position)
        end
    end))
    Cleanup.Add(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Library.Drag = nil
        end
    end))
    Cleanup.Add(Services.UserInputService.InputBegan:Connect(function(input)
        if Library.Listening then
            Library.HandleListen(input)
            return
        end
        if Services.UserInputService:GetFocusedTextBox() then return end
        if Library.MenuKey and Utils.InputMatches(Library.MenuKey.Value, input) then
            Library.SetVisible(not Library.Visible)
        elseif Library.PanicKey and Utils.InputMatches(Library.PanicKey.Value, input) then
            Cleanup.Run()
        end
    end))
end

function Library.AddCategory(info)
    local color = info.Danger and Theme.Danger or Theme.Accent
    local cat = setmetatable({
        Name = info.Name, Subtitle = info.Subtitle or "", Color = color, Order = 0
    }, Category)

    local tile = uiNew("TextButton", {
        Name = info.Name, Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = info.Danger and Theme.DangerBg or Theme.Row,
        BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
        LayoutOrder = info.Danger and 100 or (10 + #Library.Categories)
    }, Library.Dock)
    uiCorner(tile, 10)
    local bar = uiNew("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -7, 0.5, 0), Size = UDim2.fromOffset(3, 22),
        BackgroundColor3 = color, BorderSizePixel = 0, Visible = false
    }, tile)
    uiCorner(bar, 2)
    local iconRoot = uiNew("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1
    }, tile)
    local icon = iconBuilder(iconRoot)
    if Icons[info.Icon] then Icons[info.Icon](icon) end
    local label = uiNew("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 14),
        Font = Fonts.Medium, TextSize = 11, TextColor3 = Theme.Sub, Text = info.Name
    }, tile)

    local active = false
    local restColor = info.Danger and Theme.Danger or Theme.Sub
    icon.color(restColor)
    label.TextColor3 = restColor
    cat.SetActive = function(value)
        active = value
        bar.Visible = value
        icon.color(value and color or restColor)
        tween(tile, 0.14, {BackgroundTransparency = value and 0 or 1})
        tween(label, 0.14, {TextColor3 = value and color or restColor})
    end
    tile.MouseEnter:Connect(function()
        if not active then tween(tile, 0.12, {BackgroundTransparency = 0.5}) end
    end)
    tile.MouseLeave:Connect(function()
        if not active then tween(tile, 0.12, {BackgroundTransparency = 1}) end
    end)
    cat.Action = info.OnClick ~= nil
    tile.MouseButton1Click:Connect(function()
        if info.OnClick then info.OnClick(cat) else Library.Select(cat) end
    end)

    local scroll = uiNew("ScrollingFrame", {
        Name = info.Name, Position = UDim2.new(0, 0, 0, 57), Size = UDim2.new(1, 0, 1, -88),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Track,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false
    }, Library.Panel)
    uiPadding(scroll, 6, 12, 12, 12)
    uiList(scroll, 8)
    cat.Scroll = scroll

    table.insert(Library.Categories, cat)
    return cat
end

local UI = {}

function UI.Initialize()
    Library.Create()
    local ka = State.Combat.killAura
    local esp = State.Visuals.esp
    local summaries = {}

    local labels = {aura = "Who to hit", esp = "Who to show"}

    local function summarize(kind)
        local list = Groups.List()
        local on = 0
        for _, group in ipairs(list) do
            if State.Groups[kind][group.key] == true then on = on + 1 end
        end
        local text
        if on == 0 then
            text = "No teams"
        elseif on == #list then
            text = "All teams"
        else
            text = on .. " of " .. #list .. " teams"
        end
        local changed = 0
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= Player and State.Picks[kind][p.Name] ~= nil then changed = changed + 1 end
        end
        if changed > 0 then
            text = text .. ", " .. changed .. (changed == 1 and " player" or " players") .. " changed"
        end
        return text
    end

    local function addGroupsButton(cat, kind)
        local button = cat:AddButton({
            Title = "", Callback = function() Library.Picker.Open(kind) end
        })
        button.Visible = false
        button.TextSize = 13
        button.TextTruncate = Enum.TextTruncate.AtEnd
        summaries[kind] = function() button.Text = labels[kind] .. ": " .. summarize(kind) end
        summaries[kind]()
        return button
    end

    Library.GroupsChanged = function()
        for _, update in pairs(summaries) do update() end
    end

    local function toList(set)
        local out = {}
        for key, on in pairs(set) do
            if on == true then out[#out + 1] = key end
        end
        table.sort(out)
        return out
    end

    local function toSet(list)
        local out = {}
        if type(list) == "table" then
            for _, key in ipairs(list) do
                if type(key) == "string" then out[key] = true end
            end
        end
        return out
    end

    local combat = Library.AddCategory({Name = "Combat", Icon = "Combat", Subtitle = "Keybind kill aura"})
    local auraGroups
    combat:AddToggle(nil, {
        Title = "Kill Aura", Description = "Hit the nearest player with the keybind", Default = false,
        Callback = function(v)
            ka.enabled = v
            if auraGroups then auraGroups.Visible = v and not ka.targetAll end
            if v and not ka.targetAll then Library.Picker.Open("aura") end
        end
    })
    auraGroups = addGroupsButton(combat, "aura")
    combat:AddToggle(nil, {
        Title = "Infinite Stamina", Description = "Keeps your stamina full", Default = false,
        Callback = function(v) Stamina.SetEnabled(v) end
    })
    combat:AddToggle("AuraAll", {
        Title = "Target All Players", Description = "Hit anyone in range (your team is still spared)", Default = false,
        Callback = function(v)
            ka.targetAll = v
            if auraGroups then auraGroups.Visible = ka.enabled and not v end
        end
    })
    combat:AddToggle(nil, {
        Title = "Spare Teammates", Description = "Never hit players on your team", Default = true,
        Callback = function(v) ka.spareTeam = v end
    })
    local killKey = combat:AddKeybind("KillAuraKey", {
        Title = "Hit Keybind", Description = "Click, then press a key", Default = "T"
    })
    ka.getKey = function() return killKey.Value end
    combat:AddSlider("AuraRange", {
        Title = "Range", Description = "Max distance in studs", Min = 1, Max = 100, Default = 20, Rounding = 0,
        Suffix = " st", Callback = function(v) ka.range = v end
    })
    combat:AddToggle(nil, {
        Title = "Target HUD", Description = "Shows your current target", Default = false,
        Callback = function(v)
            ka.hud.enabled = v
            HUD.SetEnabled(v)
        end
    })

    local visuals = Library.AddCategory({Name = "Visuals", Icon = "Visuals", Subtitle = "Player ESP"})
    if DrawingAvailable then
        local espGroups
        visuals:AddToggle(nil, {
            Title = "Player ESP", Description = "Team, name, health and distance above players", Default = false,
            Callback = function(v)
                esp.enabled = v
                if v then ESP.Start() else ESP.Stop() end
                if espGroups then espGroups.Visible = v and not esp.showAll end
                if v and not esp.showAll then Library.Picker.Open("esp") end
            end
        })
        espGroups = addGroupsButton(visuals, "esp")
        visuals:AddToggle("ESPAll", {
            Title = "Show All Players", Description = "Show everyone, including your team", Default = false,
            Callback = function(v)
                esp.showAll = v
                if espGroups then espGroups.Visible = esp.enabled and not v end
            end
        })
        visuals:AddToggle("ESPName", {
            Title = "Show Name", Default = true, Callback = function(v) esp.showName = v end
        })
        visuals:AddToggle("ESPHealth", {
            Title = "Show Health", Default = true, Callback = function(v) esp.showHealth = v end
        })
        visuals:AddSegmented("ESPFont", {
            Title = "Font", Description = "Text style for the ESP", Values = ESP_FONT_NAMES, Default = "Plex",
            Callback = function(v) esp.font = v end
        })
        visuals:AddSlider("ESPDist", {
            Title = "Max Distance", Min = 50, Max = 2500, Default = 500, Rounding = 0, Suffix = " st",
            Callback = function(v) esp.distance = v end
        })
        visuals:AddSlider("ESPSize", {
            Title = "Font Size", Min = 8, Max = 32, Default = 16, Rounding = 0, Suffix = "px",
            Callback = function(v) esp.fontSize = v end
        })
    else
        visuals:AddParagraph("ESP unavailable", "Your executor does not support the Drawing API.")
    end

    Library.AddCategory({
        Name = "Day", Icon = "Misc", Subtitle = "Set the time to day",
        OnClick = function(cat)
            if State.Time.enabled then
                TimeOfDay.Disable()
                cat.SetActive(false)
                Library.Notify("Day", "Time restored")
            else
                TimeOfDay.Enable()
                cat.SetActive(true)
                Library.Notify("Day", "Time set to day")
            end
        end
    })

    local settings = Library.AddCategory({Name = "Settings", Icon = "Settings", Subtitle = "Menu"})
    Library.MenuKey = settings:AddKeybind("MenuKey", {
        Title = "Menu Key", Description = "Show or hide the menu", Default = "RightShift",
        Callback = function(v) Library.SetHint(v) end
    })
    Library.SetHint(Library.MenuKey.Value)
    settings:AddSlider("UIScale", {
        Title = "UI Size", Description = "Resize the whole menu", Min = 50, Max = 150, Default = 100, Rounding = 0,
        Suffix = "%", Callback = function(v) Library.SetScale(v / 100) end
    })

    local kill = Library.AddCategory({Name = "Kill", Icon = "Kill", Subtitle = "Emergency shutdown", Danger = true})
    kill:AddButton({
        Title = "KILL SWITCH", Danger = true, Height = 52, TextSize = 16,
        Callback = function() Cleanup.Run() end
    })
    Library.PanicKey = kill:AddKeybind("PanicKey", {
        Title = "Panic Key", Description = "Press anywhere to kill instantly", Default = "End"
    })

    local function copyPicks(set)
        local out = {}
        for name, value in pairs(set) do out[name] = value end
        return out
    end

    local function loadPicks(value)
        local out = {}
        if type(value) == "table" then
            for name, pick in pairs(value) do
                if type(name) == "string" and type(pick) == "boolean" then out[name] = pick end
            end
        end
        return out
    end

    Library.Register("PicksAura", function() return copyPicks(State.Picks.aura) end, function(value)
        State.Picks.aura = loadPicks(value)
        Groups.Changed()
        Library.GroupsChanged()
    end)
    Library.Register("PicksESP", function() return copyPicks(State.Picks.esp) end, function(value)
        State.Picks.esp = loadPicks(value)
        Groups.Changed()
        Library.GroupsChanged()
    end)

    Library.Register("EnabledAura", function() return toList(State.Groups.aura) end, function(value)
        State.Groups.aura = toSet(value)
        Groups.Changed()
        Library.GroupsChanged()
    end)
    Library.Register("EnabledESP", function() return toList(State.Groups.esp) end, function(value)
        State.Groups.esp = toSet(value)
        Groups.Changed()
        Library.GroupsChanged()
    end)

    Library.Select(combat)
    Config.Load()
    Config.ready = true
    Library.Notify("Custom Utility", "Loaded. Press " .. tostring(Library.MenuKey.Value) .. " to hide the menu.", 3.5)
end

local function SetupEventConnections()
    Cleanup.Add(Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local ka = State.Combat.killAura
        if not ka.enabled or Library.Listening then return end
        if os.clock() - Library.LastBind < 0.25 then return end
        if Services.UserInputService:GetFocusedTextBox() then return end
        if gameProcessed and input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if Combat.MatchesKey(input) then
            pcall(Combat.TryAttack)
        end
    end))
end

local function Initialize()
    Env.CustomUtilityUnload = Cleanup.Run
    Cleanup.Add(function() Config.Save(true) end)
    Cleanup.Add(ESP.Stop)
    Cleanup.Add(function() HUD.SetEnabled(false) end)
    Cleanup.Add(TimeOfDay.Disable)
    Cleanup.Add(function() Stamina.SetEnabled(false) end)
    RespawnHandler.Setup()
    local initialComponents = Utils.WaitForCharacterComponents(Player, 15)
    if not initialComponents then
        error("Character failed to load")
    end
    task.wait(RESPAWN_WAIT_TIME)
    State.CharacterLoaded = true
    SetupEventConnections()
    UI.Initialize()
    State.Initialized = true
end

local success, err = pcall(Initialize)
if not success then
    Cleanup.Run()
end
