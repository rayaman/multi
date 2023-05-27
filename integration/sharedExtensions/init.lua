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
			v.getThreadID = function() -- Special function we are adding
				return THREAD_ID
			end

			v.getUniqueName = function(self)
				return self.__link_name
			end
	
			local l = multi:chop(v)
			v.__link_name = l[0]
			v.__name = i
	
			table.insert(list, {i, multi:newProxy(l):init()})
		end
	end
	table.insert(list, "isConnection")
	if obj.Type == multi.CONNECTOR then
		obj.isConnection = function() return true end
	else
		obj.isConnection = function() return false end
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
			self.Type = multi.PROXY
			for _,v in pairs(self.funcs) do
				if type(v) == "table" then
					v[2]:init()
					self[v[1]] = v[2]
					v[2].Parent = self
				else
					lastObj = self
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

multi.PROXY = "proxy"

local targets = {}

local nFunc = 0
function multi:newTargetedFunction(ID, proc, name, func, holup) -- This registers with the queue
	if type(name)=="function" then
		holup = func
		func = name
		name = "JQ_TFunc_"..nFunc
	end
	nFunc = nFunc + 1
	proc.jobqueue:registerFunction(name, func)
	return thread:newFunction(function(...)
		local id = proc:pushJob(ID, name, ...)
		local link
		local rets
		link = proc.jobqueue.OnJobCompleted(function(jid,...)
			if id==jid then
				rets = {...}
			end
		end)
		return thread.hold(function()
			if rets then
				return multi.unpack(rets) or multi.NIL
			end
		end)
	end, holup), name
end

local jid = -1
function multi:newSystemThreadedProcessor(cores)

	local name = "STP_"..multi.randomString(4) -- set a random name if none was given.

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
	c.targetedQueue = multi:newSystemThreadedQueue(name.."_target"):init()

	c.jobqueue:registerFunction("enable_targets",function(name)
		local multi, thread = require("multi"):init()
		local qname = THREAD_NAME .. "_t_queue"
		local targetedQueue = THREAD.waitFor(name):init()
		local tjq = multi:newSystemThreadedQueue(qname):init()
		targetedQueue:push({tonumber(THREAD_ID), qname})
		multi:newThread("TargetedJobHandler", function()
			local queueReturn = _G["__QR"]
			while true do
				local dat = thread.hold(function()
					return tjq:pop()
				end)
				if dat then
					thread:newThread("test",function()
						local name = table.remove(dat, 1)
						local jid = table.remove(dat, 1)
						local args = table.remove(dat, 1)
						queueReturn:push{jid, _G[name](multi.unpack(args)), queue}
					end).OnError(multi.error)
				end
			end
		end).OnError(multi.error)
	end)

	function c:pushJob(ID, name, ...)
        targets[ID]:push{name, jid, {...}}
        jid = jid - 1
        return jid + 1
    end

	c.jobqueue:doToAll(function(name)
		enable_targets(name)
	end, name.."_target")

	local count = 0
	while count < c.cores do
		local dat = c.targetedQueue:pop()
		if dat then
			targets[dat[1]] = multi.integration.THREAD.waitFor(dat[2]):init()
			count = count + 1
		end
	end

	c.jobqueue:registerFunction("packObj",function(obj)
		local multi, thread = require("multi"):init()
		obj.getThreadID = function() -- Special function we are adding
			return THREAD_ID
		end

		obj.getUniqueName = function(self)
			return self.__link_name
		end

		local list = multi:chop(obj)
		obj.__link_name = list[0]

		local proxy = multi:newProxy(list):init()

		return proxy
	end)

	c.spawnThread = c.jobqueue:newFunction("__spawnThread__", function(name, func, ...)
		local multi, thread = require("multi"):init()
		local obj = thread:newThread(name, func, ...)
		return packObj(obj)
	end, true)

	c.spawnTask = c.jobqueue:newFunction("__spawnTask__", function(obj, func, ...)
		local multi, thread = require("multi"):init()
		local obj = multi[obj](multi, func, ...)
		return packObj(obj)
	end, true)

	function c:newLoop(func, notime)
		proxy = self.spawnTask("newLoop", func, notime):init()
		proxy.__proc = self
		return proxy
	end

	function c:newTLoop(func, time)
		proxy = self.spawnTask("newTLoop", func, time):init()
		proxy.__proc = self
		return proxy
	end

	function c:newUpdater(skip, func)
		proxy = self.spawnTask("newUpdater", func, notime):init()
		proxy.__proc = self
		return proxy
	end

	function c:newEvent(task, func)
		proxy = self.spawnTask("newEvent", task, func):init()
		proxy.__proc = self
		return proxy
	end

	function c:newAlarm(set, func)
		proxy = self.spawnTask("newAlarm", set, func):init()
		proxy.__proc = self
		return proxy
	end

	function c:newStep(start, reset, count, skip)
		proxy = self.spawnTask("newStep", start, reset, count, skip):init()
		proxy.__proc = self
		return proxy
	end

	function c:newTStep(start ,reset, count, set)
		proxy = self.spawnTask("newTStep", start, reset, count, set):init()
		proxy.__proc = self
		return proxy
	end

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
		proxy = self.spawnThread(name, func, ...):init()
		proxy.__proc = self
		return proxy
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

-- Modify thread.hold to handle proxies
local thread_ref = thread.hold
function thread.hold(n, opt)
	if type(n) == "table" and n.Type == multi.PROXY and n.isConnection() then
		local ready = false
		local args
		local id = n.getThreadID()
		local name = n:getUniqueName()
		local func = multi:newTargetedFunction(id, n.Parent.__proc, "conn_"..multi.randomString(8), function(_name)
			local multi, thread = require("multi"):init()
			local obj = _G[_name]
			local rets = {thread.hold(obj)}
			for i,v in pairs(rets) do
				if v.Type then
					rets[i] = {_self_ref_ = "parent"}
				end
			end
			return unpack(rets)
		end)
		func(name).OnReturn(function(...)
			ready = true
			args = {...}
		end)
		local ret = {thread_ref(function()
			if ready then
				return multi.unpack(args) or multi.NIL
			end
		end, opt)}
		for i,v in pairs(ret) do
			if type(v) == "table" and v._self_ref_ == "parent" then
				ret[i] = n.Parent
			end
		end
		return unpack(ret)
	else
		return thread_ref(n, opt)
	end
end

