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

local multi, thread = require("multi"):init()

-- Returns a handler that allows a user to interact with an object on another thread!
-- Create on the thread that you want to interact with, send over the handle

function multi:chop(obj)
	if not _G["UIDS"] then
		_G["UIDS"] = {}
	end
	local multi, thread = require("multi"):init()
	local list = {[0] = multi.randomString(12)}
	_G[list[0]] = obj
	for i,v in pairs(obj) do
		if type(v) == "function" or type(v) == "table" and v.Type == multi.registerType("s_function") then
			table.insert(list, i)
		elseif type(v) == "table" and v.Type == multi.registerType("connector", "connections") then	
			table.insert(list, {i, multi:newProxy(multi:chop(v)):init()})
		end
	end
	return list
end

function multi:newProxy(list)
	
	local c = {}

	c.name = multi.randomString(12)
	c.is_init = false
	local multi, thread = nil, nil
	function c:init()
		local multi, thread = nil, nil
		local function copy(obj)
			if type(obj) ~= 'table' then return obj end
			local res = {}
			for k, v in pairs(obj) do res[copy(k)] = copy(v) end
			return res
		end
		if not(self.is_init) then
			self.is_init = true
			local multi, thread = require("multi"):init()
			self.proxy_link = "PL" .. multi.randomString(12)

			if multi.integration then
				GLOBAL = multi.integration.GLOBAL
				THREAD = multi.integration.THREAD
			end

			GLOBAL[self.proxy_link] = self

			local function check()
				return self.send:pop()
			end

			self.send = multi:newSystemThreadedQueue(self.name.."_S"):init()
			self.recv = multi:newSystemThreadedQueue(self.name.."_R"):init()
			self.funcs = list
			self._funcs = copy(list)
			self.Type = multi.registerType("proxy", "proxies")
			self.TID = THREAD_ID

			thread:newThread("Proxy_Handler_" .. multi.randomString(4), function()
				while true do
					local data = thread.hold(check)
					if data then
						-- Let's not hold the main threadloop
						thread:newThread("Temp_Thread", function()
							local func = table.remove(data, 1)
							local sref = table.remove(data, 1)
							local ret

							if sref then
								ret = {_G[list[0]][func](_G[list[0]], multi.unpack(data))}
							else
								ret = {_G[list[0]][func](multi.unpack(data))}
							end

							for i = 1,#ret do
								if type(ret[i]) == "table" and ret[i].Type ~= nil and ret[i].Type ~= multi.registerType("proxy", "proxies") then
									ret[i] = "\1PARENT_REF"
								end
								if type(ret[i]) == "table" and getmetatable(ret[i]) then
									setmetatable(ret[i],nil) -- remove that metatable, we do not need it on the other side!
								end
								if ret[i] == _G[list[0]] then
									-- We cannot return itself, that return can contain bad values.
									ret[i] = "\1SELF_REF"
								end
							end
							table.insert(ret, 1, func)
							self.recv:push(ret)
						end)
					end
				end
			end).OnError(multi.error)
			return self
		else
			local function copy(obj)
				if type(obj) ~= 'table' then return obj end
				local res = {}
				for k, v in pairs(obj) do res[copy(k)] = copy(v) end
				return res
			end
			local multi, thread = require("multi"):init()
			local me = self
			local funcs = copy(self.funcs)
			if multi.integration then
				GLOBAL = multi.integration.GLOBAL
				THREAD = multi.integration.THREAD
			end
			self.send = THREAD.waitFor(self.name.."_S"):init()
			self.recv = THREAD.waitFor(self.name.."_R"):init()
			self.Type = multi.registerType("proxy", "proxies")
			for _,v in pairs(funcs) do
				if type(v) == "table" then
					-- We have a connection
					v[2]:init(proc_name)
					self[v[1]] = v[2]
					v[2].Parent = self
					setmetatable(v[2],getmetatable(multi:newConnection()))
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
									if data[i] == "\1SELF_REF" then
										data[i] = me
									elseif data[i] == "\1PARENT_REF" then
										data[i] = me.Parent
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
		local cp = {}
		local multi, thread = require("multi"):init()
		local function copy(obj)
			if type(obj) ~= 'table' then return obj end
			local res = {}
			for k, v in pairs(obj) do res[copy(k)] = copy(v) end
			return res
		end
		cp.is_init = true
		cp.proxy_link = self.proxy_link
		cp.name = self.name
		cp.funcs = copy(self._funcs)
		cp.init = function(self)
			local multi, thread = require("multi"):init()
			if multi.integration then
				GLOBAL = multi.integration.GLOBAL
				THREAD = multi.integration.THREAD
			end
			local proxy = THREAD.waitFor(self.proxy_link)
			for i,v in pairs(proxy) do
				print("proxy",i,v)
			end
			proxy.funcs = self.funcs
			return proxy:init()
		end
		return cp
	end
	self:create(c)
	return c
end

local targets = {}
local references = {}

local jid = -1
function multi:newSystemThreadedProcessor(cores)

	local name = "STP_"..multi.randomString(4) -- set a random name if none was given.

	local autoscale = autoscale or false -- Will scale up the number of cores that the process uses.
	local c = {}
	
	setmetatable(c,{__index = multi})
	
	c.Type = multi.registerType("s_process", "s_processes")
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

	function c:pushJob(ID, name, ...)
		local tq = THREAD.waitFor(self.Name .. "_target_tq_" .. ID):init()
		tq:push{name, jid, multi.pack(...)}
        jid = jid - 1
        return jid + 1
    end

	c.jobqueue:registerFunction("packObj",function(obj)
		local multi, thread = require("multi"):init()

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

	local implement = {
		"newLoop",
		"newTLoop",
		"newUpdater",
		"newEvent",
		"newAlarm",
		"newStep",
		"newTStep",
		"newService"
	}

	for _, method in pairs(implement) do
		c[method] = function(self, ...)
			proxy = self.spawnTask(method, ...)
			proxy:init()
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
		return self.jobqueue:newFunction(func, holdme)
	end

	function c:newSharedTable(name)
		if not name then multi.error("You must provide a name when creating a table!") end
		local tbl_name = "TABLE_"..multi.randomString(8)
		self.jobqueue:doToAll(function(tbl_name, interaction)
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

	return c
end

