package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
multi:nodeManager(12345)
print("Node Manager Running...")
settings = {
	priority = 0, -- 1 or 2
	protect = false,
}
multi:mainloop(settings)
