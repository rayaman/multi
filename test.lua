package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
require("multi.integration.networkManager")
master = multi:newMaster("Main")
settings = {
	priority = 0, -- 1 or 2
	protect = false,
}
multi:mainloop(settings)

