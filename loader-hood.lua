local REPO = "https://raw.githubusercontent.com/klixwin/mist/refs/heads/main/"
local bust = tostring(tick())

local function httpGet(url)
    return game:HttpGet(url)
end

local function normalizeVersion(text)
    text = (text or ""):gsub("%s+", "")
    return text:match("^v?([%d%.]+)$") or text:match("([%d%.]+)") or text
end

local remoteVersion = normalizeVersion(httpGet(REPO .. "version.txt?b=" .. bust))
local hoodSrc = httpGet(REPO .. "hood.lua?b=" .. bust)
local hoodVersion = normalizeVersion(hoodSrc:match("VERSION%s*=%s*[\"']([^\"']+)[\"']"))

if hoodVersion ~= remoteVersion then
    error(
        "[mist hood] blocked — hood.lua v"
            .. (hoodVersion or "?")
            .. " != version.txt v"
            .. remoteVersion
            .. " (old cache — rejoin and run again)"
    )
end

if hoodSrc:find("sneeky-s-fov-lib", 1, true) then
    error("[mist hood] blocked — cached hood.lua still contains sneeky fov (rejoin)")
end

loadstring(hoodSrc, REPO .. "hood.lua")()
