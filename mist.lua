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
    if loadstring then
        fn, err = loadstring(src, chunkname)
    end
    if not fn and load then
        fn, err = load(src, chunkname)
    end
    if not fn then
        error("[mist] compile failed (" .. chunkname .. "): " .. tostring(err))
    end
    return fn
end

local url = REPO .. "hood.luau?b=" .. tostring(tick())
compile(httpGet(url), "hood.luau")()
