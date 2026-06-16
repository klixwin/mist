local EXPECTED_VERSION = "1.0.3"
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

local function compile(src, chunkname)
    if not src or #src < 50 then
        error("[mist] empty response for " .. chunkname)
    end
    local fn, err
    if load then
        fn, err = load(src, chunkname)
    end
    if not fn and loadstring then
        fn, err = loadstring(src, chunkname)
    end
    if not fn then
        error("[mist] compile failed (" .. chunkname .. "): " .. tostring(err))
    end
    return fn
end

local function fetchHood()
    local bust = tostring(tick())
    local urls = {
        REPO .. "hood.luau?b=" .. bust,
        "https://cdn.jsdelivr.net/gh/klixwin/mist@main/hood.luau?b=" .. bust,
    }

    for _, url in ipairs(urls) do
        local src = httpGet(url)
        if src
            and #src >= 100
            and not src:find("function getgenv().", 1, true)
            and not src:find("sneeky-s-fov-lib", 1, true)
            and src:find('VERSION = "' .. EXPECTED_VERSION .. '"', 1, true)
        then
            return src, url
        end
    end

    error(
        "[mist] could not fetch hood.luau v"
            .. EXPECTED_VERSION
            .. " — clear cache, wait 1 min, retry"
    )
end

local remoteVer = httpGet(REPO .. "version.txt?b=" .. tostring(tick()))
remoteVer = remoteVer:gsub("%s+", ""):match("v?([%d%.]+)")
if remoteVer ~= EXPECTED_VERSION then
    error("[mist] version.txt is v" .. tostring(remoteVer) .. " expected v" .. EXPECTED_VERSION)
end

local src, url = fetchHood()
compile(src, url)()
