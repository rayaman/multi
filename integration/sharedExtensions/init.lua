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

function multi:chop(obj)
	local multi, thread = require("multi"):init()
	local list = {[0] = multi.randomString(12)}
	_G[list[0]] = obj
	for i,v in pairs(obj) do
		if type(v) == "function" then
			table.insert(list, i)
		elseif type(v) == "table" and v.Type == multi.CONNECTOR then
			table.insert(list, {i, multi:newProxy(multi:chop(v)):init()})
			-- local stc = "stc_"..list[0].."_"..i
			-- list[-1][#list[-1] + 1] = {i, stc}
			-- list[#list+1] = i
			-- obj[stc] = multi:newSystemThreadedConnection(stc):init()
			-- obj["_"..i.."_"] = function(...)
			-- 	return obj[stc](...)
			-- end
		end
	end
	return list
end

function multi:newProxy(list)
	
	local c = {}

	c.name = multi.randomString(12)
	
	function c:init()
		local multi, thread = nil, nil
		if THREAD_NAME then
			local multi, thread = require("multi"):init()
			local function check()
				return self.send:pop()
			end
			self.send = multi:newSystemThreadedQueue(self.name.."_S"):init()
			self.recv = multi:newSystemThreadedQueue(self.name.."_R"):init()
			self.funcs = list
			self.conns = list[-1]
			thread:newThread(function()
				while true do
					local data = thread.hold(check)
					local func = table.remove(data, 1)
					local sref = table.remove(data, 1)
					local ret
					if sref then
						ret = {_G[list[0]][func](_G[list[0]], multi.unpack(data))}
					else
						ret = {_G[list[0]][func](multi.unpack(data))}
					end
					for i = 1,#ret do
						if type(ret[i]) == "table" and getmetatable(ret[i]) then
							setmetatable(ret[i],{}) -- remove that metatable, we do not need it on the other side!
						end
						if ret[i] == _G[list[0]] then
							-- We cannot return itself, that return can contain bad values.
							ret[i] = {_self_ref_ = true}
						end
					end
					table.insert(ret, 1, func)
					self.recv:push(ret)
				end
			end).OnError(print)
			return self
		else
			local multi, thread = require("multi"):init()
			local me = self
			GLOBAL = multi.integration.GLOBAL
			THREAD = multi.integration.THREAD
			self.send = THREAD.waitFor(self.name.."_S")
			self.recv = THREAD.waitFor(self.name.."_R")
			for _,v in pairs(self.funcs) do
				if type(v) == "table" then
					-- We got a connection
					v[2]:init()

					--setmetatable(v[2],getmetatable(multi:newConnection()))
					
					self[v[1]] = v[2]
				else
					self[v] = thread:newFunction(function(self,...)
						if self == me then
							me.send:push({v, true, ...})
						else
							me.send:push({v, false, ...})
						end
						return thread.hold(function()
							local data = me.recv:peek()
							if data and data[1] == v then
								me.recv:pop()
								table.remove(data, 1)
								for i=1,#data do
									if type(data[i]) == "table" and data[i]._self_ref_ then
										-- So if we get a self return as a return, we should return the proxy!
										data[i] = me
									end
								end
								return multi.unpack(data)
							end
						end)
					end, true)
				end
			end
			return self
		end
	end

	return c
end

function multi:newSystemThreadedProcessor(name, cores)

	local name = name or "STP_"..multi.randomString(4) -- set a random name if none was given.

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
	
	c.spawnThread = c.jobqueue:newFunction("__spawnThread__", function(name, func, ...)
		local multi, thread = require("multi"):init()
		local proxy = multi:newProxy(multi:chop(thread:newThread(name, func, ...))):init()
		return proxy
	end, true)

	c.spawnTask = c.jobqueue:newFunction("__spawnTask__", function(obj, func, ...)
		local multi, thread = require("multi"):init()
		local obj = multi[obj](multi, func, ...)
		local proxy = multi:newProxy(multi:chop(obj)):init()
		return proxy
	end, true)

	function c:newLoop(func, notime)
		return self.spawnTask("newLoop", func, notime):init()
	end

	function c:newTLoop(func, time)
		return self.spawnTask("newTLoop", func, time):init()
	end

	function c:newUpdater(skip, func)
		return self.spawnTask("newUpdater", func, notime):init()
	end

	function c:newEvent(task, func)
		return self.spawnTask("newEvent", task, func):init()
	end

	function c:newAlarm(set, func)
		return self.spawnTask("newAlarm", set, func):init()
	end

	function c:newStep(start, reset, count, skip)
		return self.spawnTask("newStep", start, reset, count, skip):init()
	end

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

	function c:newThread(name, func, ...)
		return self.spawnThread(name, func, ...):init()
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

