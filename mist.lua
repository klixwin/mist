-- Redirect: use rivals.lua (mist.lua URL is often cached by executors)
local url = "https://raw.githubusercontent.com/klixwin/mist/main/rivals.lua?t=" .. os.time()
loadstring(game:HttpGet(url))()
