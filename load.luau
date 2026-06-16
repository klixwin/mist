-- mist boot · use this file if mist.lua is cached
local EXPECTED_VERSION = "1.0.7"
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
            return src
        end
    end

    error(
        "[mist] could not fetch hood.luau v"
            .. EXPECTED_VERSION
            .. " — try loadstring(readfile('hood.luau'))()"
    )
end

loadstring(fetchHood(), "hood.luau")()
