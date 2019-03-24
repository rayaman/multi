package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL,THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
multi:newThread(function()
	error("Did it work?")
end)
multi.OnError(function(...)
	print(...)
end)
multi:mainloop{
	protect = false,
	print = true
}
