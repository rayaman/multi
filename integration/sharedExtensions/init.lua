local multi, thread = require("multi"):init()


-- Returns a handler that allows a user to interact with an object on another thread!
-- Create on the thread that you want to interact with, send over the handle
function multi:newProxy(obj)
	
	local c = {
		__index = function()
			--
		end,
		__newindex = function()
			--
		end,
		__call = function()
			--
		end
	}

	c.name = multi.randomString(12)
	
	function c:init()
		if not multi.isMainThread then
			c.send = multi:newSystemThreadedQueue(self.name.."_S"):init()
			c.recv = multi:newSystemThreadedQueue(self.name.."_R"):init()
			c.ref = obj
		else
			GLOBAL = multi.integration.GLOBAL
			THREAD = multi.integration.THREAD
			c.send = THREAD.waitFor(self.name.."_S")
			c.recv = THREAD.waitFor(self.name.."_R")
		end
	end

	return c
end

function multi:newSystemThreadedProcessor(name, cores)

	local name = name or "STP_"multi.randomString(4) -- set a random name if none was given.

	local autoscale = autoscale or false -- Will scale up the number of cores that the process uses.
	local c = {}
	
	setmetatable(c,{__index = multi})
	
	c.cores = cores or 8
	c.Name = name
	c.Mainloop = {}
	c.__count = 0
	c.processors = {}
	c.proc_list = {}
	c.OnObjectCreated = multi:newConnection()
	c.parent = self
	c.jobqueue = multi:newSystemThreadedJobQueue(c.cores)
	
	c.jobqueue:registerFunction("__spawnThread__", function(name, func, ...)
		local multi, thread = require("multi"):init()
		thread:newThread(name, func, ...)
		return true
	end)

	c.jobqueue:registerFunction("__spawnTask__", function(obj, ...)
		local multi, thread = require("multi"):init()
		multi[obj](multi, func)
		return true
	end)

	c.OnObjectCreated(function(proc, obj)
		if obj.Type == multi.UPDATER then
			local func = obj.OnUpdate:Remove()[1]
			c.jobqueue:pushJob("__spawnTask__", "newUpdater", func)
		elseif obj.Type == multi.LOOP then
			local func = obj.OnLoop:Remove()[1]
			c.jobqueue:pushJob("__spawnTask__", "newLoop", func)
		else
			return multi.error("Invalid type!")
		end
	end)

	function c:getHandler()
		-- Not needed
	end

	function c:getThreads()
		-- We might want to keep track of the number of threads we have
	end

	function c:getFullName()
		return self.parent:getFullName() .. "." .. c.Name
	end

	function c:getName()
		return self.Name
	end

	function c:newThread(name, func, ...)
		c.jobqueue:pushJob("__spawnThread__", name, func, ...)
	end

	function c:newFunction(func, holdme)
		return c.jobqueue:newFunction(func, holdme)
	end

	function c.run()
		-- Not needed
	end

	function c.isActive()
		-- 
	end
	
	function c.Start()
		--
	end

	function c.Stop()
		--
	end

	function c:Destroy()
		--
	end

	return c
end

