-- set up the package
package.path="?/init.lua;?.lua;"..package.path
-- Import the libraries
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
-- Act as a master node
master = multi:newMaster{
	name = "Main", -- the name of the master
	noBroadCast = true, -- if using the node manager, set this to true to avoid double connections
	managerDetails = {"localhost",12345}, -- the details to connect to the node manager (ip,port)
}
-- Send to all the nodes that are connected to the master
master.OnNodeConnected(function(node)
	print("Lets Go!")
	master:execute("RemoteTest",node,1,2,3)
	multi:newThread("waiter",function()
		print("Hello!",node)
		while true do
			thread.sleep(2)
			print("sending")
			master:pushTo(node,"This is a test 2")
			if master.connections["NODE_"..node]==nil then
				thread.kill()
			end
		end
	end)
end)
multi:newThread("some-test",function()
	local dat = master:pop()
	while true do
		thread.skip(10)
		if dat then
			print(dat)
		end
		dat = master:pop()
	end
end,"NODE_TESTNODE")
-- Starting the multitasker
settings = {
	priority = 0, -- 0, 1 or 2
	protect = false,
}
multi:mainloop(settings)
