-- set up the package
package.path="?/init.lua;?.lua;"..package.path
-- Import the libraries
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
-- Act as a master node
master = multi:newMaster{
	name = "Main", -- the name of the master
	--noBroadCast = true, -- if using the node manager, set this to true to avoid double connections
	--managerDetails = {"localhost",12345}, -- the details to connect to the node manager (ip,port)
}
-- Send to all the nodes that are connected to the master
master.OnError(function(name,err)
	print(name.." has encountered an error: "..err)
end)
master.OnNodeConnected(function(name)
	print("Lets Go!")
	master:newNetworkThread("Thread",function(node)
		local print = node:getConsole().print -- it is important to define things as local... another thing i could do is fenv to make sure all masters work in a protectd isolated enviroment
		multi:newTLoop(function()
			print("Yo whats up man!")
			error("doing a test")
		end,1)
	end)
	master:execute("RemoteTest",name,1,2,3)
	multi:newThread("waiter",function()
		print("Hello!",name)
		while true do
			thread.sleep(2)
			master:pushTo(name,"This is a test 2")
			if master.connections["NODE_"..name]==nil then
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
	protect = true,
}
multi:threadloop(settings)
--multi:mainloop(settings)
