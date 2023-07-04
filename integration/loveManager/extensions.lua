--[[
MIT License

Copyright (c) 2022 Ryan Ward

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

if not ISTHREAD then
	multi, thread = require("multi").init()
	GLOBAL = multi.integration.GLOBAL
	THREAD = multi.integration.THREAD
else
	GLOBAL = multi.integration.GLOBAL
	THREAD = multi.integration.THREAD
end

function multi:newSystemThreadedQueue(name)
	local name = name or multi.randomString(16)
	local c = {}
	c.Name = name
	c.Type = multi.SQUEUE
	local fRef = {"func",nil}
	function c:init()
		local q = {}
		q.chan = love.thread.getChannel(self.Name)
		function q:push(dat)
			if type(dat) == "function" then
				fRef[2] = THREAD.dump(dat)
				self.chan:push(fRef)
				return
			else
				self.chan:push(dat)
			end
		end
		function q:pop()
			local dat = self.chan:pop()
			if type(dat)=="table" and dat[1]=="func" then
				return THREAD.loadDump(dat[2])
			else
				return dat
			end
		end
		function q:peek()
			local dat = self.chan:peek()
			if type(dat)=="table" and dat[1]=="func" then
				return THREAD.loadDump(dat[2])
			else
				return dat
			end
		end
		return q
	end

	THREAD.package(name,c)

	self:create(c)

	return c
end

function multi:newSystemThreadedTable(name)
	local name = name or multi.randomString(16)
    
	local c = {}

    c.Name = name
	c.Type = multi.STABLE

    function c:init()
        return THREAD.createTable(self.Name)
    end

    THREAD.package(name,c)

	self:create(c)

	return c
end

local jqc = 1
function multi:newSystemThreadedJobQueue(n)
	local c = {}

	c.cores = n or THREAD.getCores()
	c.registerQueue = {}
	c.Type = multi.SJOBQUEUE
	c.funcs = THREAD.createStaticTable("__JobQueue_"..jqc.."_table")
	c.queue = love.thread.getChannel("__JobQueue_"..jqc.."_queue")
	c.queueReturn = love.thread.getChannel("__JobQueue_"..jqc.."_queueReturn")
	c.queueAll = love.thread.getChannel("__JobQueue_"..jqc.."_queueAll")
	c.id = 0
	c.OnJobCompleted = multi:newConnection()

	local allfunc = 0

	function c:doToAll(func)
		local f = THREAD.dump(func)
		for i = 1, self.cores do
			self.queueAll:push({allfunc,f})
		end
		allfunc = allfunc + 1
	end
	function c:registerFunction(name,func)
		if self.funcs[name] then
			error("A function by the name "..name.." has already been registered!") 
		end
		self.funcs[name] = func
	end
	function c:pushJob(name,...)
		self.id = self.id + 1
		self.queue:push{name,self.id,...}
		return self.id
	end
	function c:isEmpty()
        return queueJob:peek()==nil
    end
	local nFunc = 0
    function c:newFunction(name,func,holup) -- This registers with the queue
        if type(name)=="function" then
            holup = func
            func = name
            name = "JQ_Function_"..nFunc
        end
        nFunc = nFunc + 1
        c:registerFunction(name,func)
        return thread:newFunction(function(...)
            local id = c:pushJob(name,...)
            local link
            local rets
            link = c.OnJobCompleted(function(jid,...)
                if id==jid then
                    rets = multi.pack(...)
                end
            end)
            return thread.hold(function()
                if rets then
                    return multi.unpack(rets) or multi.NIL
                end
            end)
        end,holup),name
    end
	thread:newThread("jobManager",function()
		while true do
			thread.yield()
			local dat = c.queueReturn:pop()
			if dat then
				c.OnJobCompleted:Fire(multi.unpack(dat))
			end
		end
	end)
	for i=1,c.cores do
		multi:newSystemThread("JobQueue_"..jqc.."_worker_"..i,function(jqc)
			local multi, thread = require("multi"):init()
			require("love.timer")
			local function atomic(channel)
				return channel:pop()
			end
			local clock = os.clock
			local funcs = THREAD.createStaticTable("__JobQueue_"..jqc.."_table")
			local queue = love.thread.getChannel("__JobQueue_"..jqc.."_queue")
			local queueReturn = love.thread.getChannel("__JobQueue_"..jqc.."_queueReturn")
			local lastProc = clock()
			local queueAll = love.thread.getChannel("__JobQueue_"..jqc.."_queueAll")
			local registry = {}
			_G["__QR"] = queueReturn
			setmetatable(_G,{__index = funcs})
			thread:newThread("startUp",function()
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						THREAD.loadDump(queueAll:pop()[2])()
					end
				end
			end)
			thread:newThread("runner",function()
				thread.sleep(.1)
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						THREAD.loadDump(queueAll:pop()[2])()
					end
					local dat = queue:performAtomic(atomic)
					if dat then
						multi:newThread("Test",function()
							lastProc = os.clock()
							local name = table.remove(dat,1)
							local id = table.remove(dat,1)
							local tab = {funcs[name](multi.unpack(dat))}
							table.insert(tab,1,id)
							queueReturn:push(tab)
						end)
					end
				end
			end):OnError(function(...)
				error(...)
			end)
			thread:newThread("Idler",function()
				while true do
					thread.yield()
					if clock()-lastProc> 2 then
						THREAD.sleep(.05)
					else
						THREAD.sleep(.001)
					end
				end
			end)
			multi:mainloop()
		end,jqc)
	end

	jqc = jqc + 1

	self:create(c)

	return c
end

function multi:newSystemThreadedConnection(name)
	local name = name or multi.randomString(16)

	local c = {}

	c.Type = multi.SCONNECTION
	c.CONN = 0x00
	c.TRIG = 0x01
	c.PING = 0x02
	c.PONG = 0x03

	local subscribe = love.thread.getChannel("SUB_STC_" .. name)

	function c:init()

		self.subscribe = love.thread.getChannel("SUB_STC_" .. self.Name)

		function self:Fire(...)
			local args = multi.pack(...)
			if self.CID == THREAD_ID then -- Host Call
				for _, link in pairs(self.links) do
					love.thread.getChannel(link):push{self.TRIG, args}
				end
				self.proxy_conn:Fire(...)
			else
				self.subscribe:push{self.TRIG, args}
			end
		end

		local multi, thread = require("multi"):init()
		self.links = {}
		self.proxy_conn = multi:newConnection()
		local mt = getmetatable(self.proxy_conn)
		setmetatable(self, {__index = self.proxy_conn, __call = function(t,func) self.proxy_conn(func) end, __add = mt.__add})
		if self.CID == THREAD_ID then return self end
		thread:newThread("STC_CONN_MAN" .. self.Name,function()
			local item
			local string_self_ref = "LSF_" .. multi.randomString(16)
			local link_self_ref = love.thread.getChannel(string_self_ref)
			self.subscribe:push{self.CONN, string_self_ref}
			while true do
				item = thread.hold(function()
					return link_self_ref:peek()
				end)
				if item[1] == self.PING then
					link_self_ref:push{self.PONG}
					link_self_ref:pop()
				elseif item[1] == self.CONN then
					if string_self_ref ~= item[2] then
						table.insert(self.links, love.thread.getChannel(item[2]))
					end
					link_self_ref:pop()
				elseif item[1] == self.TRIG then
					self.proxy_conn:Fire(multi.unpack(item[2]))
					link_self_ref:pop()
				else
					-- This shouldn't be the case
				end
			end
		end).OnError(multi.error)
		return self
	end

	local function remove(a, b)
		local ai = {}
		local r = {}
		for k,v in pairs(a) do ai[v]=true end
		for k,v in pairs(b) do 
			if ai[v]==nil then table.insert(r,a[k]) end
		end
		return r
	end

	c.CID = THREAD_ID
	c.Name = name
	c.links = {} -- All triggers sent from main connection. When a connection is triggered on another thread, they speak to the main then send stuff out.
	
	-- Locals will only live in the thread that creates the original object
	local ping
	local pong = function(link, links)
		local res = thread.hold(function()
			return love.thread.getChannel(link):peek()[1] == c.PONG
		end,{sleep=3})

		if not res then
			for i=1,#links do 
				if links[i] == link then
					table.remove(links,i,link)
					break
				end
			end
		else
			love.thread.getChannel(link):pop()
		end
	end

	ping = thread:newFunction(function(self)
		ping:Pause()

		multi.ForEach(self.links, function(link) -- Sync new connections
			love.thread.getChannel(link):push{self.PING}
			multi:newThread("pong Thread", pong, link, self.links)
		end)

		thread.sleep(3)

		ping:Resume()
	end, false)

	local function fire(...)
		for _, link in pairs(c.links) do
			love.thread.getChannel(link):push {c.TRIG, multi.pack(...)}
		end
	end

	thread:newThread("STC_SUB_MAN"..name,function()
		local item
		while true do
			thread.yield()
			-- We need to check on broken connections
			ping(c) -- Should return instantlly and process this in another thread
			item = thread.hold(function() -- This will keep things held up until there is something to process
				return c.subscribe:pop()
			end)
			if item[1] == c.CONN then

				multi.ForEach(c.links, function(link) -- Sync new connections
					love.thread.getChannel(item[2]):push{c.CONN, link}
				end)
				c.links[#c.links+1] = item[2]

			elseif item[1] == c.TRIG then
				fire(multi.unpack(item[2]))
				c.proxy_conn:Fire(multi.unpack(item[2]))
			end
		end
	end).OnError(multi.error)
	--- ^^^ This will only exist in the init thread

	THREAD.package(name,c)

	self:create(c)

	return c
end
require("multi.integration.sharedExtensions")