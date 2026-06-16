-- mist · realistic hood testing v1.0.0
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local VERSION = "1.0.0"
local REPO = "https://raw.githubusercontent.com/klixwin/mist/refs/heads/main/"

local cloneref = cloneref or function(i)
    return i
end

local executor = (identifyexecutor and select(2, pcall(identifyexecutor))) and identifyexecutor() or "executor"

if not (hookfunction and run_on_actor and getsenv and debug.getupvalue and debug.setupvalue) then
    local missing = (not hookfunction and "hookfunction " or "")
        .. (not run_on_actor and "run_on_actor " or "")
        .. (not getsenv and "getsenv " or "")
        .. (not debug.getupvalue and "debug.getupvalue " or "")
        .. (not debug.setupvalue and "debug.setupvalue" or "")
    error(executor .. " missing: " .. missing)
end

local SG = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/sneekygoober/sneeky-s-notifications/refs/heads/main/main.luau"
))()

local Players = cloneref(game:GetService("Players"))
local plr = Players.LocalPlayer

local acs = workspace:FindFirstChild("ACS_WorkSpace")
if not acs then
    SG["error"]("acs workspace not found — wrong game?")
    return
end

local client, server = acs:FindFirstChild("Client"), acs:FindFirstChild("Server")
if not client or not server then
    SG["error"]("acs client/server missing — script needs update")
    return
end

getgenv().wallcheck = true
getgenv().fov = 300
getgenv().noRecoil = false
getgenv().silentAim = true

if getgenv().Library and getgenv().Library.Unload then
    pcall(getgenv().Library.Unload, getgenv().Library)
end

local function fetchUrl(path)
    local url = REPO .. path .. "?v=" .. VERSION .. "&b=" .. tostring(tick())
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

local Library = loadstring(fetchUrl("Example.lua"), "Example.lua")()
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
Library:UpdateColorsUsingRegistry()

local SaveManager = loadstring(fetchUrl("Library.lua"), "Library.lua")()
local ThemeManager = loadstring(fetchUrl("addons/ThemeManager.lua"), "ThemeManager.lua")()

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

local payload = [[
local cloneref = cloneref or function(i) return i end
local clonefunction = clonefunction or function(f) return f end
local newcclosure = newcclosure or clonefunction

local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.IgnoreWater = true

local a, s, wallcheck, fov, SG, cli, ser, noRecoil, silentAim = ...
getgenv().wallcheck = wallcheck
getgenv().fov = fov
getgenv().noRecoil = noRecoil
getgenv().silentAim = silentAim

local isVisible = function(part, origin)
    local char = plr.Character
    if not char or not part then return false, nil end

    rp.FilterDescendantsInstances = { char, cli, ser }
    origin = origin or cam.CFrame.Position

    local dir = part.Position - origin
    local result = workspace:Raycast(origin, dir, rp)
    if not result then return true, nil end
    if result.Instance:IsDescendantOf(part.Parent) then
        return true, result.Instance
    end
    return false, result.Instance
end

local getTarget = function(origin)
    local cPart, cDistance = nil, getgenv().fov

    for _, player in Players:GetPlayers() do
        if player == plr then continue end

        local char = player.Character
        if not char or char:FindFirstChildOfClass("ForceField")
            or (char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0) then
            continue
        end

        local tPart = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char.PrimaryPart
        if not tPart then continue end

        local pos, onScreen = cam:WorldToViewportPoint(tPart.Position)
        if not onScreen then continue end

        if getgenv().wallcheck then
            local v, nTPart = isVisible(tPart, origin)
            if not v then
                v, nTPart = isVisible(char:FindFirstChild("UpperTorso") or char.PrimaryPart, origin)
                if not v then continue end
            end
            if nTPart then tPart = nTPart end
        end

        local distance = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
        if distance < cDistance then
            cPart = tPart
            cDistance = distance
        end
    end

    return cPart
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-fov-lib/refs/heads/main/main.luau"))()(getgenv().fov, getTarget, true)

local inject = function()
    clonefunction(hookfunction(rawget(getsenv(s), "resetMods"), function() end))
    clonefunction(hookfunction(rawget(getsenv(s), "setMods"), function() end))

    if getgenv().noRecoil and rawget(getsenv(s), "Recoil") then
        clonefunction(hookfunction(rawget(getsenv(s), "Recoil"), function() return true end))
    end

    local trc = rawget(getsenv(s), "ThrowRayCast")
    if not trc then return end

    local ids = debug.getupvalue(trc, 1)

    if getgenv().noRecoil then
        debug.setupvalue(trc, 17, {
            ZoomValue = 70,
            Zoom2Value = 70,
            AimRM = 1,
            SpreadRM = 0,
            DamageMod = 1,
            minDamageMod = 1,
            MinRecoilPower = 0,
            MaxRecoilPower = 0,
            RecoilPowerStepAmount = 1,
            MinSpread = 0,
            MaxSpread = 0,
            AimInaccuracyStepAmount = 1,
            AimInaccuracyDecrease = 1,
            WalkMult = 2,
            adsTime = 1,
            MuzzleVelocity = 1,
            camRecoilMod = {
                RecoilTilt = 0,
                RecoilUp = 0,
                RecoilLeft = 0,
                RecoilRight = 0,
            },
            gunRecoilMod = {
                RecoilUp = 0,
                RecoilTilt = 0,
                RecoilLeft = 0,
                RecoilRight = 0,
            },
        })
    end

    local cache = {}
    local old
    old = clonefunction(hookfunction(trc, newcclosure(function(_, bullet, origin)
        if cache[bullet] then
            task.cancel(cache[bullet])
            cache[bullet] = nil
        end

        if getgenv().silentAim then
            local c = getTarget(origin)
            if c then
                cache[bullet] = task.defer(function()
                    while c and bullet and c.Parent and bullet.Parent do
                        bullet.Position = c.Position
                        task.wait()
                    end
                    cache[bullet] = nil
                end)
            end
        end

        return old(_, bullet, origin)
    end)))

    if setstackhidden then setstackhidden(trc, true) end
    setfenv(trc, rawset(getfenv(trc), "getfenv", newcclosure(function()
        return {
            [rawget(ids, "Var")] = rawget(ids, "Value"),
        }
    end)))
end

task.delay(1, inject)
plr.CharacterAdded:Connect(function()
    task.delay(1, inject)
end)
]]

local function findActor()
    if get_actors then
        for _, v in get_actors() do
            if v.Parent == plr.PlayerScripts then
                return v
            end
        end
    end
    return plr.PlayerScripts:FindFirstChildOfClass("Actor")
end

local function injectActor()
    local a = findActor()
    if not a then
        return false, "couldn't find actor"
    end

    local s = a:FindFirstChildOfClass("LocalScript")
    if not s then
        return false, "couldn't get localscript"
    end

    for _ = 1, 100 do
        local ok = pcall(
            run_on_actor,
            a,
            payload,
            a,
            s,
            getgenv().wallcheck,
            getgenv().fov,
            SG,
            client,
            server,
            getgenv().noRecoil,
            getgenv().silentAim
        )
        if ok then
            return true
        end
        task.wait(0.05)
    end

    return false, "inject failed"
end

local function runInject()
    SG["info"]("injecting...")
    task.delay(0.5, function()
        local ok, err = injectActor()
        if ok then
            SG["success"]("injected — mist hood v" .. VERSION)
            Library:Notify("injected")
        else
            SG["error"](err or "inject failed")
            Library:Notify(err or "inject failed", 4)
        end
    end)
end

Library:OnUnload(function()
    getgenv().MistHoodVersion = nil
end)

local Window = Library:CreateWindow({
    Title = "mist · hood testing",
    Center = true,
    AutoShow = true,
})

local CombatTab = Window:AddTab("combat")
local Main = CombatTab:AddLeftGroupbox("silent aim")

Main:AddToggle("SilentAim", {
    Text = "enabled",
    Default = true,
    Callback = function(v)
        getgenv().silentAim = v
        runInject()
    end,
})

Main:AddToggle("Wallcheck", {
    Text = "wallcheck",
    Default = true,
    Callback = function(v)
        getgenv().wallcheck = v
    end,
})

Main:AddToggle("NoRecoil", {
    Text = "no recoil",
    Default = false,
    Callback = function(v)
        getgenv().noRecoil = v
        runInject()
    end,
})

Main:AddSlider("FOV", {
    Text = "radius",
    Suffix = "px",
    Compact = true,
    Default = 300,
    Min = 50,
    Max = 600,
    Rounding = 0,
    Callback = function(v)
        getgenv().fov = v
    end,
})

local Misc = CombatTab:AddRightGroupbox("misc")
Misc:AddLabel("re-inject after spawn", true)
Misc:AddLabel("v" .. VERSION, true)

Misc:AddButton("re-inject", function()
    runInject()
end)

local SettingsTab = Window:AddTab("settings")
local MenuGroup = SettingsTab:AddLeftGroupbox("menu")

MenuGroup:AddButton("unload ui", function()
    Library:Unload()
end)
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

getgenv().MistHoodVersion = VERSION
runInject()

Library:Notify("v" .. VERSION)
