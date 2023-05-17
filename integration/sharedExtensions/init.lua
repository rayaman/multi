--[[
MIT License

Copyright (c) 2023 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local multi, thread = require("multi"):init()

-- Returns a handler that allows a user to interact with an object on another thread!
-- Create on the thread that you want to interact with, send over the handle
function multi:newProxy(obj)
	
	c.name = multi.randomString(12)
	
	function c:init()
		if not multi.isMainThread then
			local multi, thread = require("multi"):init()
			local function check()
				return self.send:pop()
			end
			self.send = multi:newSystemThreadedQueue(self.name.."_S"):init()
			self.recv = multi:newSystemThreadedQueue(self.name.."_R"):init()
			self.ref = obj
			self.funcs = {}
			for i, v in pairs(obj) do
				if type(v) == "function" then
					self.funcs[#self.funcs] = i
				end
			end
			thread:newThread(function()
				while true do
					local data = thread.hold(check)
					local func = table.remove(data, 1)
					local ret = {self.ref[func](multi.unpack(data))}
					table.insert(ret, 1, func)
					self.recv:push(ret)
				end
			end)
		else
			GLOBAL = multi.integration.GLOBAL
			THREAD = multi.integration.THREAD
			self.send = THREAD.waitFor(self.name.."_S")
			self.recv = THREAD.waitFor(self.name.."_R")
			for _,v in pairs(self.funcs) do
				self[v] = thread:newFunction(function(...)
					self.send:push({v, ...})
					return thread.hold(function()
						local data = self.recv:peek()
						if data[1] == v then
							self.recv:pop()
							thread.remove(data, 1)
							return multi.unpack(data)
						end
					end)
				end, true)
			end
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
	
	local spawnThread = c.jobqueue:newFunction(function(name, func, ...)
		local multi, thread = require("multi"):init()
		print("hmm")
		local proxy = multi:newProxy(thread:newThread(name, func, ...))
		multi:newTask(function()
			proxy:init()
		end)
		return proxy
	end, true)

	local spawnTask = c.jobqueue:newFunction(function(name, func, ...)
		local multi, thread = require("multi"):init()
		local proxy = multi:newProxy(multi[obj](multi, func))
		multi:newTask(function()
			proxy:init()
		end)
		return proxy
	end, true)

	c.newLoop = thread:newFunction(function(self, func, notime)
		return spawnTask("newLoop", func, notime):init()
	end, true)

	c.newUpdater = thread:newFunction(function(self, skip, func)
		return spawnTask("newUpdater", func, notime):init()
	end, true)

	c.OnObjectCreated(function(proc, obj)
		if not(obj.Type == multi.UPDATER or obj.Type == multi.LOOP) then
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

	c.newThread = thread:newFunction(function(self, name, func, ...)
		return spawnThread(name, func, ...):init()
	end, true)

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

