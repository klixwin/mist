-- Mist Rivals v1.8.0
local VERSION = "1.8.0"
local REPO = "https://raw.githubusercontent.com/klixwin/mist/refs/heads/main/"

getgenv().MistVersion = VERSION

if getgenv().Library and getgenv().Library.Unload then
    pcall(getgenv().Library.Unload, getgenv().Library)
end

local function fetchUrl(path)
    local url = REPO .. path .. "?v=" .. VERSION
    if syn and syn.request then
        local res = syn.request({ Url = url, Method = "GET" })
        if res and res.Body then
            return res.Body
        end
    end
    if http and http.request then
        local res = http.request({ Url = url, Method = "GET" })
        if res and res.Body then
            return res.Body
        end
    end
    return game:HttpGet(url)
end

local function loadModule(path)
    return loadstring(fetchUrl(path), path)()
end

local function unloadMist()
    Library:Unload()
end

local Library = loadModule("Example.lua")
local SaveManager = loadModule("Library.lua")
local ThemeManager = loadModule("addons/ThemeManager.lua")

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

local X = {
    enabled = true,
    bone = "Head",
    range = 310,
    hitChance = 100,
    visibleOnly = true,
    teamCheck = true,
    closestPart = false,
    showFov = false,
    visualize = false,
    fovColor = Color3.fromRGB(255, 255, 255),
    services = {
        rep = game:GetService("ReplicatedStorage"),
        plr = game:GetService("Players"),
        run = game:GetService("RunService"),
    },
}

local pool = {}
local cx, cy = 0, 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local rayFilter = {}
local heartbeatConn = nil
local fovConn = nil
local fovCircle = Drawing and Drawing.new("Circle")

local function rebuildPool()
    table.clear(pool)
    local me = X.me
    if not me then return end
    local myChar = me.Character
    for _, plr in X.services.plr:GetPlayers() do
        local char = plr.Character
        if char and char ~= myChar then
            pool[#pool + 1] = char
        end
    end
    local hurt = workspace:FindFirstChild("HurtEffect")
    if hurt then
        for _, c in hurt:GetChildren() do
            if c.ClassName ~= "Highlight" then
                pool[#pool + 1] = c
            end
        end
    end
end

local function sameTeam(char)
    if not X.teamCheck then return false end
    local plr = X.services.plr:GetPlayerFromCharacter(char)
    return plr and plr.Team and X.me.Team and plr.Team == X.me.Team
end

local function isVisible(char, bonePos)
    local myChar = X.me.Character
    if not myChar then return false end
    rayFilter[1] = myChar
    rayFilter[2] = char
    rayParams.FilterDescendantsInstances = rayFilter
    local cam = X.cam
    if not cam then return false end
    local origin = cam.CFrame.Position
    local hit = workspace:Raycast(origin, bonePos - origin, rayParams)
    return not hit or hit.Instance:IsDescendantOf(char)
end

local function getAimPart(char)
    if X.closestPart then
        local best, bestD = nil, math.huge
        for _, p in char:GetDescendants() do
            if p:IsA("BasePart") then
                local pos, vis = X.cam:WorldToViewportPoint(p.Position)
                if vis then
                    local d = (Vector2.new(cx, cy) - Vector2.new(pos.X, pos.Y)).Magnitude
                    if d < bestD then
                        best, bestD = p, d
                    end
                end
            end
        end
        return best
    end
    return char:FindFirstChild(X.bone)
end

local function setupFovCircle()
    if not fovCircle then return end
    fovCircle.Thickness = 1
    fovCircle.Filled = false
    fovCircle.NumSides = 64
    fovCircle.Transparency = 1
    fovCircle.Visible = false
    fovCircle.Color = X.fovColor

    fovConn = X.services.run.RenderStepped:Connect(function()
        local show = X.showFov or X.visualize
        if not show or not X.cam then
            fovCircle.Visible = false
            return
        end
        fovCircle.Visible = true
        fovCircle.Position = Vector2.new(cx, cy)
        fovCircle.Radius = X.range
        fovCircle.Color = X.fovColor
        fovCircle.Filled = X.visualize
        fovCircle.Transparency = X.visualize and 0.55 or 1
    end)
end

local function setupSilentAim()
    local modules = X.services.rep:WaitForChild("Modules", 15)
    if not modules then
        Library:Notify("rivals not detected — silent aim disabled", 5)
        return
    end
    local utility = modules:WaitForChild("Utility", 10)
    if not utility then
        Library:Notify("utility module missing — silent aim disabled", 5)
        return
    end

    X.mod = require(utility)
    X.original = X.mod.Raycast
    X.cam = workspace.CurrentCamera
    X.me = X.services.plr.LocalPlayer

    heartbeatConn = X.services.run.Heartbeat:Connect(function()
        if X.cam then
            cx = X.cam.ViewportSize.X / 2
            cy = X.cam.ViewportSize.Y / 2
        end
        rebuildPool()
    end)

    X.mod.Raycast = function(...)
        local args = { ... }
        if not X.enabled or args[4] ~= 999 then
            return X.original(...)
        end
        local dir = args[3] - args[2]
        if dir.Magnitude > 0 and dir.Unit.Y < -0.7 then
            return X.original(...)
        end
        if X.hitChance < 100 and math.random(1, 100) > X.hitChance then
            return X.original(...)
        end
        local winner, record = nil, X.range
        for i = 1, #pool do
            local v = pool[i]
            if sameTeam(v) then continue end
            local bone = getAimPart(v)
            if not bone then continue end
            local p, vis = X.cam:WorldToViewportPoint(bone.Position)
            if not vis then continue end
            if X.visibleOnly and not isVisible(v, bone.Position) then continue end
            local d = (Vector2.new(cx, cy) - Vector2.new(p.X, p.Y)).Magnitude
            if d <= X.range and d < record then
                winner, record = v, d
            end
        end
        if winner then
            local bone = getAimPart(winner)
            if bone then args[3] = bone.Position end
        end
        return X.original(table.unpack(args))
    end

    Library:Notify("silent aim active")
end

Library:OnUnload(function()
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    if fovConn then
        fovConn:Disconnect()
        fovConn = nil
    end
    if fovCircle then
        fovCircle:Remove()
    end
    if X.mod and X.original then
        X.mod.Raycast = X.original
    end
    getgenv().MistVersion = nil
end)

local Window = Library:CreateWindow({
    Title = "Mist — Rivals v" .. VERSION,
    Center = true,
    AutoShow = true,
})

local CombatTab = Window:AddTab("combat")
local CombatBox = CombatTab:AddLeftTabbox()
local SilentTab = CombatBox:AddTab("silent aim")
local AimbotTab = CombatBox:AddTab("aimbot")

SilentTab:AddToggle("SilentAim", {
    Text = "enabled",
    Default = true,
    Callback = function(v) X.enabled = v end,
}):AddKeyPicker("SilentAimKey", {
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "silent aim",
    NoUI = true,
})

SilentTab:AddToggle("VisibleOnly", {
    Text = "visible only",
    Default = true,
    Callback = function(v) X.visibleOnly = v end,
})

SilentTab:AddToggle("TeamCheck", {
    Text = "team check",
    Default = true,
    Callback = function(v) X.teamCheck = v end,
})

SilentTab:AddToggle("ClosestPart", {
    Text = "closest part",
    Default = false,
    Callback = function(v) X.closestPart = v end,
})

SilentTab:AddToggle("Visualize", {
    Text = "visualize",
    Default = false,
    Callback = function(v) X.visualize = v end,
})

SilentTab:AddToggle("ShowFov", {
    Text = "show fov",
    Default = false,
    Callback = function(v) X.showFov = v end,
}):AddColorPicker("FovColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) X.fovColor = c end,
})

SilentTab:AddSlider("Radius", {
    Text = "radius",
    Suffix = "px",
    Compact = true,
    Default = 310,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(v) X.range = v end,
})

SilentTab:AddSlider("HitChance", {
    Text = "hit chance",
    Suffix = "%",
    Compact = true,
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(v) X.hitChance = v end,
})

AimbotTab:AddLabel("coming soon", true)

local SettingsTab = Window:AddTab("settings")
local MenuGroup = SettingsTab:AddLeftGroupbox("menu")

MenuGroup:AddButton("unload ui", unloadMist)
MenuGroup:AddDivider()

MenuGroup:AddLabel("menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "Insert",
    NoUI = false,
    Text = "toggle ui",
    Mode = "Toggle",
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

if writefile then
    pcall(SaveManager.LoadAutoloadConfig, SaveManager)
end

task.spawn(setupSilentAim)
setupFovCircle()

Library:Notify("mist v" .. VERSION .. " loaded")
