--[[ todo finish the targeted job!
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

function copy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do res[copy(k)] = copy(v) end
    return res
end

function tprint (tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
	  formatting = string.rep("  ", indent) .. k .. ": "
	  if type(v) == "table" then
		print(formatting)
		tprint(v, indent+1)
	  else
		print(formatting .. tostring(v))      
	  end
	end
  end

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
	c.is_init = false
	
	function c:init(proc_name)
		local multi, thread = nil, nil
		if not(c.is_init) then
			c.is_init = true
			local multi, thread = require("multi"):init()
			local function check()
				return self.send:pop()
			end
			self.send = multi:newSystemThreadedQueue(self.name.."_S"):init()
			self.recv = multi:newSystemThreadedQueue(self.name.."_R"):init()
			self.funcs = list
			self._funcs = copy(list)
			self.Type = multi.PROXY
			self.TID = THREAD_ID
			thread:newThread(function()
				while true do
					local data = thread.hold(check)
					if data then
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
				end
			end).OnError(print)
			return self
		else
			local multi, thread = require("multi"):init()
			local me = self
			self.proc_name = proc_name
			if multi.integration then
				GLOBAL = multi.integration.GLOBAL
				THREAD = multi.integration.THREAD
			end
			self.send = THREAD.waitFor(self.name.."_S"):init()
			self.recv = THREAD.waitFor(self.name.."_R"):init()
			self.Type = multi.PROXY
			for _,v in pairs(self.funcs) do
				if type(v) == "table" then
					-- We have a connection
					v[2]:init(proc_name)
					self["_"..v[1]] = v[2]
					v[2].Parent = self
					setmetatable(v[2],getmetatable(multi:newConnection()))
					self[v[1]] = multi:newConnection()
					
					thread:newThread(function()
						while true do
							local data = thread.hold(self["_"..v[1]])
							self[v[1]]:Fire(data)
						end
					end).OnError(multi.error)
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
	function c:getTransferable()
		local multi, thread = require("multi"):init()
		local cp = {}
		cp.name = self.name
		cp.funcs = copy(self._funcs)
		cp._funcs = copy(self._funcs)
		cp.Type = self.Type
		cp.init = self.init
		return cp
	end
	return c
end

local targets = {}
local references = {}

local nFunc = 0
function multi:newTargetedFunction(ID, proxy, name, func, holup) -- This registers with the queue
	if type(name)=="function" then
		holup = func
		func = name
		name = "JQ_TFunc_"..nFunc
	end
	nFunc = nFunc + 1

	multi:executeOnProcess(proxy.proc_name, function(proc, name, func)
		proc.jobqueue:registerFunction(name, func)
	end, name, func)
	
	return thread:newFunction(function(...)
		return multi:executeOnProcess(proxy.proc_name, function(proc, name, ID, ...)
			local multi, thread = require("multi"):init()
			local id = proc:pushJob(ID, name, ...)
			local rets
			local tjq = THREAD.get(proc.Name .. "_target_rtq_" .. ID):init()
			return thread.hold(function()
				local data = tjq:peek()
				if data then
					print(data)
				end
				if data and data[1] == id then
					print("Got it sigh")
					tjq:pop()
					table.remove(data, 1)
					return multi.unpack(data) or multi.NIL
				end
			end)
			-- proc.jobqueue.OnJobCompleted(function(jid, ...)
			-- 	if id==jid then
			-- 		rets = {...}
			-- 		print("Got!")
			-- 	end
			-- end)
			-- return thread.hold(function()
			-- 	if rets then
			-- 		return multi.unpack(rets) or multi.NIL
			-- 	end
			-- end)
		end, name, ID, ...)
	end, holup), name
end

multi.executeOnProcess = thread:newFunction(function(self, name, func, ...)
	local queue = THREAD.get(name .. "_local_proc")
	local queueR = THREAD.get(name .. "_local_return")
	if queue and queueR then
		local multi, thread = require("multi"):init()
		local id = multi.randomString(8)
		queue = queue:init()
		queueR = queueR:init()
		queue:push({func, id, ...})
		return thread.hold(function()
			local data = queueR:peek()
			if data and data[1] == id then
				queueR:pop()
				table.remove(data, 1)
				return multi.unpack(data) or multi.NIL
			end
		end)
	else
		return nil, "Unable to find a process queue with name: '" .. name .. "'"
	end
end, true)

local jid = -1
function multi:newSystemThreadedProcessor(cores)

	local name = "STP_"..multi.randomString(4) -- set a random name if none was given.

	local autoscale = autoscale or false -- Will scale up the number of cores that the process uses.
	local c = {}
	
	setmetatable(c,{__index = multi})
	
	c.threads = {}
	c.cores = cores or 8
	c.Name = name
	c.Mainloop = {}
	c.__count = 0
	c.processors = {}
	c.proc_list = {}
	c.OnObjectCreated = multi:newConnection()
	c.parent = self
	c.jobqueue = multi:newSystemThreadedJobQueue(c.cores)
	c.local_cmd = multi:newSystemThreadedQueue(name .. "_local_proc"):init()
	c.local_cmd_return = multi:newSystemThreadedQueue(name .. "_local_return"):init()

	c.jobqueue:registerFunction("STP_enable_targets",function(name)
		local multi, thread = require("multi"):init()
		local qname = name .. "_tq_" .. THREAD_ID
		local rqname = name .. "_rtq_" .. THREAD_ID
		
		local tjq = multi:newSystemThreadedQueue(qname):init()
		local trq = multi:newSystemThreadedQueue(rqname):init()
		multi:newThread("TargetedJobHandler", function()
			local th
			while true do
				local dat = thread.hold(function()
					return tjq:pop()
				end)
				if dat then
					th = thread:newThread("JQ-TargetThread",function()
						local name = table.remove(dat, 1)
						local jid = table.remove(dat, 1)
						local func = table.remove(dat, 1)
						local args = table.remove(dat, 1)
						th.OnError(function(self,err)
							-- We want to pass this to the other calling thread incase
							trq:push{jid, err}
						end)
						trq:push{jid, func(multi.unpack(args))}
					end)
				end
			end
		end).OnError(print)
	end)

	c.jobqueue:registerFunction("STP_GetThreadCount",function()
		return _G["__THREADS"]
	end)

	c.jobqueue:registerFunction("STP_GetTaskCount",function()
		return _G["__TASKS"]
	end)

	function c:pushJob(ID, name, ...)
		print("pushing")
		local tq = THREAD.waitFor(self.Name .. "_target_tq_" .. ID):init()
        --targets[ID]:push{name, jid, {...}}
		tq:push{name, jid, {...}}
        jid = jid - 1
        return jid + 1
    end

	c.jobqueue:doToAll(function(name)
		STP_enable_targets(name)
		_G["__THREADS"] = 0
		_G["__TASKS"] = 0
	end, name.."_target")

	c.jobqueue:registerFunction("packObj",function(obj)
		local multi, thread = require("multi"):init()
		obj.getThreadID = function() -- Special functions we are adding
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
		_G["__THREADS"] = _G["__THREADS"] + 1
		return packObj(obj)
	end, true)

	c.spawnTask = c.jobqueue:newFunction("__spawnTask__", function(obj, func, ...)
		local multi, thread = require("multi"):init()
		local obj = multi[obj](multi, func, ...)
		_G["__TASKS"] = _G["__TASKS"] + 1
		return packObj(obj)
	end, true)

	local implement = {
		"newLoop",
		"newTLoop",
		"newUpdater",
		"newEvent",
		"newAlarm",
		"newStep",
		"newTStep"
	}

	for _, method in pairs(implement) do
		c[method] = function(self, ...)
			proxy = self.spawnTask(method, ...):init(self.Name)
			references[proxy] = self
			return proxy
		end
	end

	function c:newThread(name, func, ...)
		proxy = self.spawnThread(name, func, ...):init(self.Name)
		references[proxy] = self
		table.insert(self.threads, proxy)
		return proxy
	end

	function c:newFunction(func, holdme)
		return c.jobqueue:newFunction(func, holdme)
	end

	function c:newSharedTable(name)
		if not name then multi.error("You must provide a name when creating a table!") end
		local tbl_name = "TABLE_"..multi.randomString(8)
		c.jobqueue:doToAll(function(tbl_name, interaction)
			_G[interaction] = THREAD.waitFor(tbl_name):init()
		end, tbl_name, name)
		return multi:newSystemThreadedTable(tbl_name):init()
	end

	function c:getHandler()
		return function() end -- return empty function
	end

	function c:getThreads()
		return self.threads
	end

	function c:getFullName()
		return self.parent:getFullName() .. "." .. c.Name
	end

	function c:getName()
		return self.Name
	end

	function c.run()
		return self
	end

	function c.isActive()
		return true
	end
	
	function c.Start()
		return self
	end

	function c.Stop()
		return self
	end

	function c:Destroy()
		return false
	end

	c.getLoad = thread:newFunction(function(self, tp)
		local loads = {}
		local func

		if tp then
			func = "STP_GetThreadCount"
		else
			func = "STP_GetTaskCount"
		end

		for i,v in pairs(self.proc_list) do
			local conn
			local jid = self:pushJob(v, func)
			
			conn = self.jobqueue.OnJobCompleted(function(id, data)
				if id == jid then
					table.insert(loads, {v, data})
					multi:newTask(function()
						self.jobqueue.OnJobCompleted:Unconnect(conn)
					end)
				end
			end)
		end

		thread.hold(function() return #loads == c.cores end)
		return loads
	end, true)

	local check = function()
		return c.local_cmd:pop()
	end
	thread:newThread(function()
		while true do
			local data = thread.hold(check)
			if data then
				thread:newThread(function()
					local func = table.remove(data, 1)
					local id = table.remove(data, 1)
					local ret = {id, func(c, multi.unpack(data))}
					c.local_cmd_return:push(ret)
				end).OnError(multi.error)
			end
		end
	end).OnError(multi.error)

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
		print(id, name)
		local func = multi:newTargetedFunction(id, n, "conn_"..multi.randomString(8), function(_name)
			local multi, thread = require("multi"):init()
			local obj = _G[_name]
			print("Start")
			local rets = {thread.hold(obj)}
			print("Ring ;)")
			for i,v in pairs(rets) do
				if v.Type then
					rets[i] = {_self_ref_ = "parent"}
				end
			end
			return multi.unpack(rets)
		end, true)

		local conn
		local args = {func(name)}
		-- conn = handle.OnReturn(function(...)
		-- 	ready = true
		-- 	args = {...}
		-- 	for i,v in pairs(args) do
		-- 		print("DATA",i,v)
		-- 	end
		-- 	handle.OnReturn:Unconnect(conn)
		-- end)

		local ret = {thread_ref(function()
			if ready then
				return multi.unpack(args) or multi.NIL
			end
		end, opt)}

		for i,v in pairs(ret) do
			print("OBJECT",v.Type)
			if type(v) == "table" and v._self_ref_ == "parent" then
				print("assign")
				ret[i] = n.Parent
			end
		end

		return multi.unpack(ret)
	else
		return thread_ref(n, opt)
	end
end

