-- mist loader v1.0.9
local EXPECTED_VERSION = "1.0.9"
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
    error("[mist] no http method available")
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

local function isValidHood(src)
    if not src or #src < 100 then
        return false
    end
    if not src:find('VERSION = "' .. EXPECTED_VERSION .. '"', 1, true) then
        return false
    end
    if not src:find("getRealEnv", 1, true) then
        return false
    end
    return true
end

local function fetchHood()
    local bust = tostring(tick())
    local urls = {
        REPO .. "hood.luau?nocache=" .. bust,
        "https://cdn.jsdelivr.net/gh/klixwin/mist@main/hood.luau?nocache=" .. bust,
    }

    for _, url in ipairs(urls) do
        local ok, src = pcall(httpGet, url)
        if ok and isValidHood(src) then
            return src
        end
    end

    error("[mist] could not fetch hood.luau v" .. EXPECTED_VERSION)
end

local fn, err = loadstring(fetchHood(), "hood.luau")
if not fn then
    error("[mist] compile hood: " .. tostring(err))
end
if setfenv then
    setfenv(fn, getRealEnv())
end
fn()
