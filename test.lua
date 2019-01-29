package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL,THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
local a
function multi:setName(name)
	self.Name = name
end
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end
master = multi:newMaster{
	name = "Main", -- the name of the master
	--noBroadCast = true, -- if using the node manager, set this to true to avoid double connections
	managerDetails = {"192.168.1.4",12345}, -- the details to connect to the node manager (ip,port)
}
master.OnError(function(name,err)
	print(name.." has encountered an error: "..err)
end)
master.OnNodeConnected(function(name)
	multi:newThread("Main Thread Data Sender",function()
		while true do
			thread.sleep(.5)
			conn = master:execute("TASK_MAN",name, multi:getTasksDetails())
		end
	end,5)
end)
multi.OnError(function(...)
	print(...)
end)
multi:mainloop{
	protect = false
}
