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
local multi, thread = require("multi"):init()

if not (GLOBAL and THREAD) then
	GLOBAL, THREAD = multi.integration.GLOBAL,multi.integration.THREAD
else
	lanes = require("lanes")
end

function multi:newSystemThreadedQueue(name)
	local name = name or multi.randomString(16)
	local c = {}
	c.Name = name
	c.linda = lanes.linda()
	function c:push(v)
		self.linda:send("Q", v)
	end
	function c:pop()
		return ({self.linda:receive(0, "Q")})[2]
	end
	function c:peek()
		return self.linda:get("Q")
	end
	function c:init()
		return self
	end
	GLOBAL[name or "_"] = c
	return c
end

function multi:newSystemThreadedTable(name)
	local name = name or multi.randomString(16)
    local c = {}
    c.link = lanes.linda()
	c.Name = name

	-- function c:getIndex()
	-- 	return c.link:dump()
	-- end

    function c:init()
        return self
    end
	
	setmetatable(c,{
        __index = function(t,k)
            return c.link:get(k)
        end,
        __newindex = function(t,k,v)
            c.link:set(k, v)
        end
    })

    GLOBAL[name or "_"] = c
	return c
end

function multi:newSystemThreadedJobQueue(n)
    local c = {}
    c.cores = n or THREAD.getCores()*2
    c.OnJobCompleted = multi:newConnection()
    local funcs = multi:newSystemThreadedTable():init()
    local queueJob = multi:newSystemThreadedQueue():init()
    local queueReturn = multi:newSystemThreadedQueue():init()
    local doAll = multi:newSystemThreadedQueue():init()
    local ID=1
    local jid = 1
    function c:isEmpty()
        return queueJob:peek()==nil
    end
    function c:doToAll(func)
        for i=1,c.cores do
            doAll:push{ID,func}
        end
        ID = ID + 1
        return self
    end
    function c:registerFunction(name,func)
        funcs[name]=func
        return self
    end
    function c:pushJob(name,...)
        queueJob:push{name,jid,{...}}
        jid = jid + 1
        return jid-1
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
			print("Called!")
            local id = c:pushJob(name,...)
            local link
            local rets
            link = c.OnJobCompleted(function(jid,...)
                if id==jid then
                    rets = {...}
                end
            end)
            return thread.hold(function()
                if rets then
                    return multi.unpack(rets) or multi.NIL
                end
            end)
        end,holup), name
    end
    thread:newThread("JobQueueManager",function()
        while true do
            local job = thread.hold(function()
                return queueReturn:pop()
            end)
            local id = table.remove(job,1)
            c.OnJobCompleted:Fire(id,multi.unpack(job))
        end
    end)
    for i=1,c.cores do
        multi:newSystemThread("SystemThreadedJobQueue",function(queue)
            local multi, thread = require("multi"):init()
            local idle = os.clock()
            local clock = os.clock
            local ref = 0
            setmetatable(_G,{__index = funcs})
            thread:newThread("JobHandler",function()
                while true do
                    local dat = thread.hold(function()
                        return queueJob:pop()
                    end)
                    idle = clock()
					thread:newThread("test",function()
						local name = table.remove(dat, 1)
						local jid = table.remove(dat, 1)
						local args = table.remove(dat, 1)
						queueReturn:push{jid, funcs[name](multi.unpack(args)), queue}
					end)
                end
            end).OnError(print)
            thread:newThread("DoAllHandler",function()
                while true do
                    local dat = thread.hold(function()
                        return doAll:peek()
                    end)
                    if dat then
                        if dat[1]>ref then
                            idle = clock()
                            ref = dat[1]
                            dat[2]()
                            doAll:pop()
                        end
                    end
                end
            end)
            thread:newThread("IdleHandler",function()
                while true do
                    thread.hold(function()
                        return clock()-idle>3
                    end)
                    THREAD.sleep(.01)
                end
            end)
            multi:mainloop()
        end,i).priority = thread.Priority_Core
    end
    return c
end

function multi:newSystemThreadedConnection(name)
	local name = name or multi.randomString(16)
	local c = {}
	c.CONN = 0x00
	c.TRIG = 0x01
	c.PING = 0x02
	c.PONG = 0x03
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
	c.subscribe = multi:newSystemThreadedQueue("SUB_STC_"..self.Name):init()
	c.Name = name
	c.links = {} -- All triggers sent from main connection. When a connection is triggered on another thread, they speak to the main then send stuff out.
	-- Locals will only live in the thread that creates the original object
	local ping
	local pong = function(link, links)
		local res = thread.hold(function()
			return link:peek()[1] == c.PONG
		end,{sleep=3})

		if not res then
			for i=1,#links do 
				if links[i] == link then
					table.remove(links,i,link)
					break
				end
			end
		else
			link:pop()
		end
	end

	ping = thread:newFunction(function(self)
		ping:Pause()
		multi.ForEach(self.links, function(link) -- Sync new connections
			link:push{self.PING}
			multi:newThread("pong Thread", pong, link, self.links)
		end)

		thread.sleep(3)

		ping:Resume()
	end,false)

	local function fire(...)
		for _, link in pairs(c.links) do
			link:push {c.TRIG, {...}}
		end
	end

	thread:newThread("STC_SUB_MAN"..name,function()
		local item
		local sub_func = function() -- This will keep things held up until there is something to process
			return c.subscribe:pop()
		end
		while true do
			thread.yield()
			-- We need to check on broken connections
			ping(c) -- Should return instantlly and process this in another thread
			item = thread.hold(sub_func)
			if item[1] == c.CONN then
				multi.ForEach(c.links, function(link) -- Sync new connections
					item[2]:push{c.CONN, link}
				end)
				c.links[#c.links+1] = item[2]
			elseif item[1] == c.TRIG then
				fire(multi.unpack(item[2]))
				c.proxy_conn:Fire(multi.unpack(item[2]))
			end
		end
	end)
	--- ^^^ This will only exist in the init thread

	function c:Fire(...)
		local args = {...}
		if self.CID == THREAD_ID then -- Host Call
			for _, link in pairs(self.links) do
				link:push {self.TRIG, args}
			end
			self.proxy_conn:Fire(...)
		else
			self.subscribe:push {self.TRIG, args}
		end
	end

	function c:init()
		local multi, thread = require("multi"):init()
		self.links = {}
		self.proxy_conn = multi:newConnection()
		local mt = getmetatable(self.proxy_conn)
		local tempMT = {}
		for i,v in pairs(mt) do
			tempMT[i] = v
		end
		tempMT.__index = self.proxy_conn
		tempMT.__call = function(t,func) self.proxy_conn(func) end
		setmetatable(self, tempMT)
		if self.CID == THREAD_ID then return self end
		thread:newThread("STC_CONN_MAN"..name,function()
			local item
			local link_self_ref = multi:newSystemThreadedQueue()
			self.subscribe:push{self.CONN, link_self_ref}
			while true do
				item = thread.hold(function()
					return link_self_ref:peek()
				end)
				if item[1] == self.PING then
					link_self_ref:push{self.PONG}
					link_self_ref:pop()
				elseif item[1] == self.CONN then
					if item[2].Name ~= link_self_ref.Name then
						table.insert(self.links, item[2])
					end
					link_self_ref:pop()
				elseif item[1] == self.TRIG then
					self.proxy_conn:Fire(multi.unpack(item[2]))
					link_self_ref:pop()
				else
					-- This shouldn't be the case
				end
			end
		end)
		return self
	end

	GLOBAL[name] = c

	return c
end