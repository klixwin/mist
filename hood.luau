-- mist · realistic hood testing v1.0.9
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local VERSION = "1.0.9"
local REPO = "https://raw.githubusercontent.com/klixwin/mist/refs/heads/main/"

local function httpGet(url)
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
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and body then
        return body
    end
    error("[mist hood] no http method available")
end

local function normalizeVersion(text)
    text = (text or ""):gsub("%s+", "")
    return text:match("^v?([%d%.]+)$") or text:match("([%d%.]+)") or text
end

local localVersion = normalizeVersion(VERSION)

local function getExpectedVersion()
    if readfile and isfile and isfile("version.txt") then
        return normalizeVersion(readfile("version.txt"))
    end

    local bust = tostring(tick())
    local urls = {
        REPO .. "version.txt?b=" .. bust,
        "https://cdn.jsdelivr.net/gh/klixwin/mist@main/version.txt?b=" .. bust,
    }

    for _, url in ipairs(urls) do
        local ok, body = pcall(httpGet, url)
        if ok and body then
            local remote = normalizeVersion(body)
            if remote == localVersion then
                return remote
            end
        end
    end

    return localVersion
end

local remoteVersion = getExpectedVersion()

if localVersion ~= remoteVersion then
    error(
        "[mist hood] version mismatch — script v"
            .. localVersion
            .. " but github v"
            .. remoteVersion
    )
end

local cloneref = cloneref or function(i)
    return i
end

local SNEEKY_GGKEY =
    "-eiu4ty-juehje-4jhy-w4-0yh304y0bjpoekr;gjpeuj50-y9u54-iy-043i5-hje[prthmjpiejur09huw-eir=-qiw3t=jm35-jhe-0urh0jdrp[ohme;mhpjue-50uy-ejbmer[kh[eir-hie-u[erktj[mrtpohj-"

local function sneekyEnvKeys()
    local keys = { SNEEKY_GGKEY }
    if crypt and crypt.base64encode then
        table.insert(keys, crypt.base64encode(SNEEKY_GGKEY))
    end
    return keys
end

local function destroySneekyState(state)
    if type(state) ~= "table" then
        return
    end

    pcall(function()
        local draw = state.draw_instance
        if draw and type(draw.terminate) == "function" then
            draw:terminate()
        end
        if draw and type(draw.stop) == "function" then
            draw:stop()
        end
    end)

    if state.connections then
        for _, conn in ipairs(state.connections) do
            pcall(conn.Disconnect, conn)
        end
    end

    pcall(function()
        if state.p_instance then
            state.p_instance:Destroy()
        end
    end)

    if cleardrawcache then
        pcall(cleardrawcache)
    end
end

local function isSneekyGui(gui)
    if not gui:IsA("ScreenGui") then
        return false
    end

    for _, desc in gui:GetDescendants() do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            local text = desc.Text
            if text == "HOLD TO DRAG" or text == "FOV Enabled" or text == "FOV Disabled" then
                return true
            end
            if text and string.find(text, "FOV Size", 1, true) then
                return true
            end
        end
    end

    return false
end

local function getGuiRoots()
    local roots = {}
    local seen = {}

    local function add(inst)
        if inst and not seen[inst] then
            seen[inst] = true
            table.insert(roots, inst)
        end
    end

    add(cloneref(game:GetService("CoreGui")))
    local core = game:GetService("CoreGui")
    add(core:FindFirstChild("RobloxGui"))

    local plr = game:GetService("Players").LocalPlayer
    if plr then
        add(plr:FindFirstChildOfClass("PlayerGui"))
    end

    if gethui then
        local ok, custom = pcall(gethui)
        if ok and custom then
            add(cloneref(custom))
        end
    end

    return roots
end

getgenv().MistCleanupSneekyFOV = function()
    for _, key in sneekyEnvKeys() do
        destroySneekyState(getgenv()[key])
        getgenv()[key] = nil
    end

    for key, state in pairs(getgenv()) do
        if type(state) == "table" and state.draw_instance and state.p_instance then
            destroySneekyState(state)
            getgenv()[key] = nil
        end
    end

    getgenv().fov = nil

    for _, root in getGuiRoots() do
        for _, desc in root:GetDescendants() do
            if desc:IsA("ScreenGui") and isSneekyGui(desc) then
                pcall(desc.Destroy, desc)
            end
        end
    end

    if cleardrawcache then
        pcall(cleardrawcache)
    end
end

local cleanupSneekyFOV = getgenv().MistCleanupSneekyFOV
cleanupSneekyFOV()

local executor = (identifyexecutor and select(2, pcall(identifyexecutor))) and identifyexecutor() or "executor"

if not (hookfunction and run_on_actor and getsenv and debug.getupvalue and debug.setupvalue) then
    local missing = (not hookfunction and "hookfunction " or "")
        .. (not run_on_actor and "run_on_actor " or "")
        .. (not getsenv and "getsenv " or "")
        .. (not debug.getupvalue and "debug.getupvalue " or "")
        .. (not debug.setupvalue and "debug.setupvalue" or "")
    error(executor .. " missing: " .. missing)
end

local Players = cloneref(game:GetService("Players"))
local plr = Players.LocalPlayer

local acs = workspace:FindFirstChild("ACS_WorkSpace")
if not acs then
    error("acs workspace not found — wrong game?")
end

local client, server = acs:FindFirstChild("Client"), acs:FindFirstChild("Server")
if not client or not server then
    error("acs client/server missing — script needs update")
end

getgenv().noRecoil = getgenv().noRecoil or false

if getgenv().Library and getgenv().Library.Unload then
    pcall(getgenv().Library.Unload, getgenv().Library)
end

local function fetchUrl(path)
    if readfile and isfile and isfile(path) then
        return readfile(path)
    end
    local url = REPO .. path .. "?v=" .. VERSION .. "&b=" .. tostring(tick())
    return httpGet(url)
end

local function getRealEnv()
    if getrenv then
        return getrenv()
    end
    if getfenv then
        return getfenv(0)
    end
    return _G
end

local function loadModule(path)
    local fn, err = loadstring(fetchUrl(path), path)
    if not fn then
        error("[mist hood] compile " .. path .. ": " .. tostring(err))
    end
    if setfenv then
        setfenv(fn, getRealEnv())
    end
    return fn()
end

local Library = loadModule("Example.lua")
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
Library:UpdateColorsUsingRegistry()

local SaveManager = loadModule("Library.lua")
local ThemeManager = loadModule("addons/ThemeManager.lua")

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

local payload = [[
local a, s, noRecoil = ...
getgenv().noRecoil = noRecoil

if getgenv().MistCleanupSneekyFOV then
    getgenv().MistCleanupSneekyFOV()
end

local cloneref = cloneref or function(i) return i end
local clonefunction = clonefunction or function(f) return f end

local Players = cloneref(game:GetService("Players"))
local plr = Players.LocalPlayer

local inject = function()
    if not getgenv().noRecoil then return end

    local env = getsenv(s)
    if rawget(env, "resetMods") then
        clonefunction(hookfunction(rawget(env, "resetMods"), function() end))
    end
    if rawget(env, "setMods") then
        clonefunction(hookfunction(rawget(env, "setMods"), function() end))
    end
    if rawget(env, "Recoil") then
        clonefunction(hookfunction(rawget(env, "Recoil"), function() return true end))
    end

    local trc = rawget(env, "ThrowRayCast")
    if not trc then return end

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

if getgenv().MistCleanupSneekyFOV then
    getgenv().MistCleanupSneekyFOV()
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
        local ok = pcall(run_on_actor, a, payload, a, s, getgenv().noRecoil)
        if ok then
            return true
        end
        task.wait(0.05)
    end

    return false, "inject failed"
end

local function runInject(silent)
    task.delay(0.5, function()
        cleanupSneekyFOV()
        local ok, err = injectActor()
        cleanupSneekyFOV()
        if ok then
            if getgenv().noRecoil and not silent then
                Library:Notify("no recoil active")
            end
        elseif not silent then
            Library:Notify(err or "inject failed", 4)
        end
    end)
end

task.spawn(function()
    for _ = 1, 12 do
        cleanupSneekyFOV()
        task.wait(0.5)
    end
end)

Library:OnUnload(function()
    cleanupSneekyFOV()
    getgenv().MistHoodVersion = nil
    getgenv().noRecoil = false
end)

local Window = Library:CreateWindow({
    Title = "mist · hood testing",
    Center = true,
    AutoShow = true,
})

local CombatTab = Window:AddTab("combat")
local Main = CombatTab:AddLeftGroupbox("weapon")

Main:AddToggle("NoRecoil", {
    Text = "no recoil",
    Default = getgenv().noRecoil,
    Callback = function(v)
        getgenv().noRecoil = v
        runInject()
    end,
})

Main:AddButton("re-inject", function()
    runInject()
end)

local Misc = CombatTab:AddRightGroupbox("misc")
Misc:AddLabel("re-inject after spawn", true)
Misc:AddButton("remove sneeky ui", function()
    cleanupSneekyFOV()
    runInject(true)
    Library:Notify("sneeky ui removed")
end)
Misc:AddLabel("v" .. VERSION, true)

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

runInject(true)
cleanupSneekyFOV()

Library:Notify("v" .. VERSION)
