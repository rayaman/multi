-- set up the package
package.path="?/init.lua;?.lua;"..package.path
-- Import the libraries
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
-- Run the code
master = multi:newMaster("Main")
-- Starting the multitasker
settings = {
	priority = 0, -- 1 or 2
	protect = false,
}
master.OnFirstNodeConnected(function()
	print("Node connected lets go!")
	master:newNetworkThread("Test_Thread",nil,function()
		RemoteTest()
		multi:newThread("test",function()
			nGLOBAL["test"]="Did it work?"
		end)
	end)
	multi:newThread("Checker",function()
		while true do
			thread.sleep(.5)
			if nGLOBAL["test"] then
				print(nGLOBAL["test"])
				thread.kill()
			end
		end
	end)
end)
os.execute("start lua node.lua")
multi:mainloop(settings)

