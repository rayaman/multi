-- set up the package
package.path="?/init.lua;?.lua;"..package.path
-- Import the libraries
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
-- Act as a master node
master = multi:newMaster{
	pollManagerRate = 15,
	name = "Main",
	noBroadCast = true,
	managerDetails = {"localhost",12345},
}
-- Starting the multitasker
settings = {
	priority = 0, -- 0, 1 or 2
	protect = false,
}
--~ master.OnFirstNodeConnected(function(node_name)
multi:newAlarm(3):OnRing(function(alarm)
	master:doToAll(function(node_name)
		master:register("TestFunc",node_name,function(msg)
			print("It works: "..msg)
		end)
		multi:newAlarm(2):OnRing(function(alarm)
			master:execute("TestFunc",node_name,"Hello!")
			alarm:Destroy()
		end)
		multi:newThread("Checker",function()
			while true do
				thread.sleep(1)
				if nGLOBAL["test"] then
					print(nGLOBAL["test"])
					thread.kill()
				end
			end
		end)
		nGLOBAL["test2"]={age=22}
	end)
	alarm:Destroy()
end)
--~ os.execute("start lua node.lua")
multi:mainloop(settings)
