--~ package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
--~ local GLOBAL,THREAD = require("multi.integration.lanesManager").init()
--~ nGLOBAL = require("multi.integration.networkManager").init()
--~ local a
--~ local clock = os.clock
--~ function sleep(n)  -- seconds
--~ 	local t0 = clock()
--~ 	while clock() - t0 <= n do end
--~ end
--~ master = multi:newMaster{
--~ 	name = "Main", -- the name of the master
--~ 	noBroadCast = true, -- if using the node manager, set this to true to avoid double connections
--~ 	managerDetails = {"localhost",12345}, -- the details to connect to the node manager (ip,port)
--~ }
--~ master.OnError(function(name,err)
--~ 	print(name.." has encountered an error: "..err)
--~ end)
--~ local connlist = {}
--~ multi:newThread("NodeUpdater",function()
--~ 	while true do
--~ 		thread.sleep(1)
--~ 		for i=1,#connlist do
--~ 			master:execute("TASK_MAN",connlist[i], multi:getTasksDetails())
--~ 		end
--~ 	end
--~ end)
--~ master.OnNodeConnected(function(name)
--~ 	print("Connected to the node")
--~ 	table.insert(connlist,name)
--~ end)
--~ multi.OnError(function(...)
--~ 	print(...)
--~ end)
print("HI!")
multi:mainloop{
	protect = false,
	print = true
}
