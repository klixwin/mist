local sources = {
    "https://cdn.jsdelivr.net/gh/klixwin/mist@main/core.lua",
    "https://raw.githubusercontent.com/klixwin/mist/refs/heads/main/core.lua",
}

local function fetch(url)
    local busted = url .. "?b=" .. tostring(tick())
    if syn and syn.request then
        local res = syn.request({ Url = busted, Method = "GET" })
        if res and res.Body then
            return res.Body
        end
    end
    if http and http.request then
        local res = http.request({ Url = busted, Method = "GET" })
        if res and res.Body then
            return res.Body
        end
    end
    return game:HttpGet(busted)
end

for _, url in ipairs(sources) do
    local src = fetch(url)
    if src and #src > 100 then
        loadstring(src)()
        return
    end
end
