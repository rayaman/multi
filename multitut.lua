package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
--~ local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
--~ nGLOBAL = require("multi.integration.networkManager").init()


local a = 0
local clock = os.clock
b = clock()
while clock()-b <1 do
	a = a +1
end
print("a: "..a)
--~ multi:benchMark(1,nil,"Bench:")
--~ multi:mainloop()
