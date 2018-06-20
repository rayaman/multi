package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
master = multi:newNode()
function RemoteTest()
	print("Yes I work!")
end
settings = {
	priority = 0, -- 1 or 2
	protect = false,
}
multi:mainloop(settings)
