-- Mist Rivals v1.7.4
local VERSION = "1.7.4"
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
    range = math.huge,
    visibleOnly = true,
    teamCheck = true,
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
        local winner, record = nil, X.range
        for i = 1, #pool do
            local v = pool[i]
            if sameTeam(v) then continue end
            local bone = v:FindFirstChild(X.bone)
            if not bone then continue end
            local p, vis = X.cam:WorldToViewportPoint(bone.Position)
            if not vis then continue end
            if X.visibleOnly and not isVisible(v, bone.Position) then continue end
            local d = (Vector2.new(cx, cy) - Vector2.new(p.X, p.Y)).Magnitude
            if d < record then
                winner, record = v, d
            end
        end
        if winner then
            local bone = winner:FindFirstChild(X.bone)
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
local Main = CombatTab:AddLeftGroupbox("silent aim")

local boneMap = {
    head = "Head",
    humanoidrootpart = "HumanoidRootPart",
    uppertorso = "UpperTorso",
}

Main:AddToggle("SilentAim", {
    Text = "enabled",
    Default = true,
    Callback = function(v) X.enabled = v end,
})

Main:AddToggle("VisibleOnly", {
    Text = "visible only",
    Default = true,
    Callback = function(v) X.visibleOnly = v end,
})

Main:AddToggle("TeamCheck", {
    Text = "team check",
    Default = true,
    Callback = function(v) X.teamCheck = v end,
})

Main:AddDropdown("TargetBone", {
    Text = "target bone",
    Values = { "head", "humanoidrootpart", "uppertorso" },
    Default = 1,
    Callback = function(v) X.bone = boneMap[v] or v end,
})

Main:AddSlider("FOV", {
    Text = "fov radius",
    Default = 500,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Callback = function(v) X.range = v end,
})

Main:AddDivider()
Main:AddButton("unload ui", unloadMist)

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

Library:Notify("mist v" .. VERSION .. " loaded")
