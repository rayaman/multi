package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.threading"):init()

function multi:newSystemThreadedConnection(name,...)
	local master_conn = multi:newConnection(...)
	local c = {}
	local name = name or multi.randomString(16)
	local connections = {} -- All triggers sent from main connection. When a connection is triggered on another thread, they speak to the main then send stuff out.
	setmetatable(c,master_conn) -- A different approach will be taken for the non main connection objects
	c.subscribe = multi:newSystemThreadedQueue("Subscribe_"..name)
	multi:newThread("STC_"..name,function()
		while true do
			thread.yield()
			local item = c.subscribe:pop()
			if item ~= nil then
				connections[#connections+1] = item
				thread.skip(multi.Priority_Normal) -- Usually a bunch of threads subscribe close to the same time. Process those by ensuring that they come alive around the same time
			else -- I'm using these "Constant" values since they may change with other releases and this should allow these functions to adjust with them.
				thread.skip(multi.Priority_Idle)
			end
		end
	end)
	function c:init()
		return self
	end
	GLOBAL[name or "_"] = c
	return c
end

multi:mainloop()