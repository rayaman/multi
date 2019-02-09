--[[
MIT License

Copyright (c) 2018 Ryan Ward

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
multi = require("multi")
function multi:newSystemThreadedQueue(name) -- in love2d this will spawn a channel on both ends
	local c={} -- where we will store our object
	c.name=name -- set the name this is important for the love2d side
	if love then -- check love
		if love.thread then -- make sure we can use the threading module
			function c:init() -- create an init function so we can mimic on both love2d and lanes
				self.chan=love.thread.getChannel(self.name) -- create channel by the name self.name
				function self:push(v) -- push to the channel
					local tab
					if type(v)=="table" then
						tab = {}
						for i,c in pairs(v) do
							if type(c)=="function" then
								tab[i]="\1"..string.dump(c)
							else
								tab[i]=c
							end
						end
						self.chan:push(tab)
					else
						self.chan:push(c)
					end
				end
				function self:pop() -- pop from the channel
					local v=self.chan:pop()
					if not v then return end
					if type(v)=="table" then
						tab = {}
						for i,c in pairs(v) do
							if type(c)=="string" then
								if c:sub(1,1)=="\1" then
									tab[i]=loadstring(c:sub(2,-1))
								else
									tab[i]=c
								end
							else
								tab[i]=c
							end
						end
						return tab
					else
						return self.chan:pop()
					end
				end
				function self:peek()
					local v=self.chan:peek()
					if not v then return end
					if type(v)=="table" then
						tab = {}
						for i,c in pairs(v) do
							if type(c)=="string" then
								if c:sub(1,1)=="\1" then
									tab[i]=loadstring(c:sub(2,-1))
								else
									tab[i]=c
								end
							else
								tab[i]=c
							end
						end
						return tab
					else
						return self.chan:pop()
					end
				end
				GLOBAL[self.name]=self -- send the object to the thread through the global interface
				return self -- return the object
			end
			return c
		else
			error("Make sure you required the love.thread module!") -- tell the user if he/she didn't require said module
		end
	else
		c.linda=lanes.linda() -- lanes is a bit easier, create the linda on the main thread
		function c:push(v) -- push to the queue
			self.linda:send("Q",v)
		end
		function c:pop() -- pop the queue
			return ({self.linda:receive(0,"Q")})[2]
		end
		function c:peek()
			return self.linda:get("Q")
		end
		function c:init() -- mimic the feature that love2d requires, so code can be consistent
			return self
		end
		multi.integration.GLOBAL[name]=c -- send the object to the thread through the global interface
	end
	return c
end
-- NEEDS WORK
-- function multi:newSystemThreadedConnection(name,protect)
	-- local c={}
	-- local sThread=multi.integration.THREAD
	-- local GLOBAL=multi.integration.GLOBAL
	-- c.name = name or error("You must supply a name for this object!")
	-- c.protect = protect or false
	-- c.count = 0
	-- multi:newSystemThreadedQueue(name.."THREADED_CALLFIRE"):init()
	-- local qsm = multi:newSystemThreadedQueue(name.."THREADED_CALLSYNCM"):init()
	-- local qs = multi:newSystemThreadedQueue(name.."THREADED_CALLSYNC"):init()
	-- function c:init()
		-- _G.__Needs_Multi = true
		-- local multi = require("multi")
		-- if multi:getPlatform()=="love2d" then
			-- GLOBAL=_G.GLOBAL
			-- sThread=_G.sThread
		-- end
		-- local conns = 0
		-- local qF = sThread.waitFor(self.name.."THREADED_CALLFIRE"):init()
		-- local qSM = sThread.waitFor(self.name.."THREADED_CALLSYNCM"):init()
		-- local qS = sThread.waitFor(self.name.."THREADED_CALLSYNC"):init()
		-- qSM:push("OK")
		-- local conn = {}
		-- conn.obj = multi:newConnection(self.protect)
		-- setmetatable(conn,{__call=function(self,...) return self:connect(...) end})
		-- function conn:connect(func)
			-- return self.obj(func)
		-- end
		-- function conn:holdUT(n)
			-- self.obj:holdUT(n)
		-- end
		-- function conn:Remove()
			-- self.obj:Remove()
		-- end
		-- function conn:Fire(...)
			-- local args = {multi.randomString(8),...}
			-- for i = 1, conns do
				-- qF:push(args)
			-- end
		-- end
		-- local lastID = ""
		-- local lastCount = 0
		-- multi:newThread("syncer",function()
			-- while true do
				-- thread.skip(1)
				-- local fire = qF:peek()
				-- local count = qS:peek()
				-- if fire and fire[1]~=lastID then
					-- lastID = fire[1]
					-- qF:pop()
					-- table.remove(fire,1)
					-- conn.obj:Fire(unpack(fire))
				-- end
				-- if count and count[1]~=lastCount then
					-- conns = count[2]
					-- lastCount = count[1]
					-- qs:pop()
				-- end
			-- end
		-- end)
		-- return conn
	-- end
	-- multi:newThread("connSync",function()
		-- while true do
			-- thread.skip(1)
			-- local syncIN = qsm:pop()
			-- if syncIN then
				-- if syncIN=="OK" then
					-- c.count = c.count + 1
				-- else
					-- c.count = c.count - 1
				-- end
				-- local rand = math.random(1,1000000)
				-- for i = 1, c.count do
					-- qs:push({rand,c.count})
				-- end
			-- end
		-- end
	-- end)
	-- GLOBAL[name]=c
	-- return c
-- end
function multi:SystemThreadedBenchmark(n)
	n=n or 1
	local cores=multi.integration.THREAD.getCores()
	local queue=multi:newSystemThreadedQueue("THREAD_BENCH_QUEUE"):init()
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	local c = {}
	for i=1,cores do
		multi:newSystemThread("STHREAD_BENCH",function(n)
			local multi = require("multi")
			if multi:getPlatform()=="love2d" then
				GLOBAL=_G.GLOBAL
				sThread=_G.sThread
			end -- we cannot have upvalues... in love2d globals, not locals must be used
			queue=sThread.waitFor("THREAD_BENCH_QUEUE"):init() -- always wait for when looking for a variable at the start of the thread!
			multi:benchMark(n):OnBench(function(self,count)
				queue:push(count)
				sThread.kill()
				error("Thread was killed!")
			end)
			multi:mainloop()
		end,n)
	end
	multi:newThread("THREAD_BENCH",function()
		local count = 0
		local cc = 0
		while true do
			thread.skip(1)
			local dat = queue:pop()
			if dat then
				cc=cc+1
				count = count + dat
				if cc == cores then
					c.OnBench:Fire(count)
					thread.kill()
				end
			end
		end
	end)
	c.OnBench = multi:newConnection()
	return c
end
function multi:newSystemThreadedConsole(name)
	local c={}
	c.name = name
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	function c:init()
		_G.__Needs_Multi = true
		local multi = require("multi")
		if multi:getPlatform()=="love2d" then
			GLOBAL=_G.GLOBAL
			sThread=_G.sThread
		end
		local cc={}
		if multi.isMainThread then
			if GLOBAL["__SYSTEM_CONSOLE__"] then
				cc.stream = sThread.waitFor("__SYSTEM_CONSOLE__"):init()
			else
				cc.stream = multi:newSystemThreadedQueue("__SYSTEM_CONSOLE__"):init()
				multi:newLoop(function()
					local data = cc.stream:pop()
					if data then
						local dat = table.remove(data,1)
						if dat=="w" then
							io.write(unpack(data))
						elseif dat=="p" then
							print(unpack(data))
						end
					end
				end):setName("ST.consoleSyncer")
			end
		else
			cc.stream = sThread.waitFor("__SYSTEM_CONSOLE__"):init()
		end
		function cc:write(msg)
			self.stream:push({"w",tostring(msg)})
		end
		function cc:print(...)
			local tab = {...}
			for i=1,#tab do
				tab[i]=tostring(tab[i])
			end
			self.stream:push({"p",unpack(tab)})
		end
		return cc
	end
	GLOBAL[c.name]=c
	return c
end
-- NEEDS WORK
function multi:newSystemThreadedTable(name)
	local c={}
	c.name=name -- set the name this is important for identifying what is what
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	function c:init() -- create an init function so we can mimic on both love2d and lanes
		_G.__Needs_Multi = true
		local multi = require("multi")
		if multi:getPlatform()=="love2d" then
			GLOBAL=_G.GLOBAL
			sThread=_G.sThread
		end
		local cc={}
		cc.tab={}
		if multi.isMainThread then
			if not GLOBAL[self.name.."_Tabled_Connection"] then
				cc.conn = multi:newSystemThreadedConnection(self.name.."_Tabled_Connection"):init()
			end
		else
			cc.conn = sThread.waitFor(self.name.."_Tabled_Connection"):init()
		end
		function cc:waitFor(name)
			repeat multi:uManager() until tab[name]~=nil
			return tab[name]
		end
		local link = cc
		cc.conn(function(k,v)
			link.tab[k]=v
		end)
		setmetatable(cc,{
			__index=function(t,k)
				return t.tab[k]
			end,
			__newindex=function(t,k,v)
				t.tab[k]=v
				t.conn:Fire(k,v)
			end
		})
		return cc
	end
	GLOBAL[c.name]=c
	return c
end
local jobqueuecount = 0
local jqueues = {}
function multi:newSystemThreadedJobQueue(a,b)
	jobqueuecount=jobqueuecount+1
	local GLOBAL=multi.integration.GLOBAL
	local sThread=multi.integration.THREAD
	local c = {}
	c.numberofcores = 4
	c.idle = nil
	c.name = "SYSTEM_THREADED_JOBQUEUE_"..jobqueuecount
	-- This is done to keep backwards compatibility for older code
	if type(a)=="string" and not(b) then
		c.name = a
	elseif type(a)=="number" and not (b) then
		c.numberofcores = a
	elseif type(a)=="string" and type(b)=="number" then
		c.name = a
		c.numberofcores = b
	elseif type(a)=="number" and type(b)=="string" then
		c.name = b
		c.numberofcores = a
	end
	if jqueues[c.name] then
		error("A job queue by the name: "..c.name.." already exists!")
	end
	jqueues[c.name] = true
	c.isReady = false
	c.jobnum=1
	c.OnJobCompleted = multi:newConnection()
	local queueIN = self:newSystemThreadedQueue("QUEUE_IN_"..c.name):init()
	local queueCC = self:newSystemThreadedQueue("QUEUE_CC_"..c.name):init()
	local queueREG = self:newSystemThreadedQueue("QUEUE_REG_"..c.name):init()
	local queueJD = self:newSystemThreadedQueue("QUEUE_JD_"..c.name):init()
	local queueDA = self:newSystemThreadedQueue("QUEUE_DA_"..c.name):init()
	c.OnReady = multi:newConnection()
	function c:registerJob(name,func)
		for i = 1, self.numberofcores do
			queueREG:push({name,func})
		end
	end
	c.tempQueue = {}
	function c:pushJob(name,...)
		c.idle = os.clock()
		if not self.isReady then
			table.insert(c.tempQueue,{self.jobnum,name,...})
			self.jobnum=self.jobnum+1
			return self.jobnum-1
		else
			queueIN:push{self.jobnum,name,...}
			self.jobnum=self.jobnum+1
			return self.jobnum-1
		end
	end
	function c:doToAll(func)
		local r = multi.randomString(12)
		for i = 1, self.numberofcores do
			queueDA:push{r,func}
		end
	end
	for i=1,c.numberofcores do
		multi:newSystemThread(c.name.." Worker Thread #"..i,function(name)
			local multi = require("multi")
			if love then -- lets make sure we don't reference up-values if using love2d
				GLOBAL=_G.GLOBAL
				sThread=_G.sThread
			end
			local CC = sThread.waitFor("QUEUE_CC_"..name):init()
			CC:push("ready")
			local FUNCS={}
			local ids = {}
			local JQI = sThread.waitFor("QUEUE_IN_"..name):init()
			local JD = sThread.waitFor("QUEUE_JD_"..name):init()
			local REG = sThread.waitFor("QUEUE_REG_"..name):init()
			local DA = sThread.waitFor("QUEUE_DA_"..name):init()
			local lastjob = os.clock()
			multi:newLoop(function()
				local job=JQI:pop()
				local rd=REG:peek()
				local da=DA:peek()
				if rd then
					if not FUNCS[rd[1]] then
						FUNCS[rd[1]]=rd[2]
						rd=nil
						REG:pop()
					end
				end
				if da then
					if not ids[da[1]] then
						local meh = da[1]
						ids[da[1]]=true
						da[2](multi)
						da=nil
						DA:pop()
						multi:newAlarm(60):OnRing(function(a)
							ids[meh] = nil
							a:Destroy()
						end)
					end
				end
				if job then
					lastjob = os.clock()
					local ID=table.remove(job,1) -- return and remove
					local _name=table.remove(job,1) -- return and remove
					if FUNCS[_name] then
						JD:push({ID,FUNCS[_name](unpack(job))})
					else -- making use of that new holding feature
						JD:push({ID,FUNCS:waitFor(_name)(unpack(job))})
					end
				end
			end)
			multi:newLoop(function()
				if os.clock()-lastjob>1 then
					sThread.sleep(.1)
				end
			end)
			setmetatable(_G,{
				__index=function(t,k)
					return FUNCS[k]
				end
			})
			if not love then
				multi:mainloop()
			end
		end,c.name)
	end
	local clock = os.clock
	multi:newThread("JQ-"..c.name.." Manager",function()
		local _count = 0
		while _count<c.numberofcores do
			thread.skip()
			if queueCC:pop() then
				_count = _count + 1
			end
		end
		c.isReady = true
		for i=1,#c.tempQueue do
			queueIN:push(c.tempQueue[i])
		end
		c.tempQueue = nil
		c.OnReady:Fire(c)
		local dat
		while true do
			if not c.idle then
				thread.sleep(.5)
			else
				if clock() - c.idle >= 15 then
					c.idle = nil
				end
				thread.skip()
			end
			dat = queueJD:pop()
			if dat then
				c.idle = clock()
				c.OnJobCompleted:Fire(unpack(dat))
			end
		end
	end)
	return c
end
function multi:newSystemThreadedExecute(cmd)
	local c={}
	local GLOBAL=multi.integration.GLOBAL -- set up locals incase we are using lanes
	local sThread=multi.integration.THREAD -- set up locals incase we are using lanes
	local name="Execute_Thread"..multi.randomString(16)
	c.name=name
	GLOBAL[name.."CMD"]=cmd
	multi:newSystemThread(name,function()
		if love then -- lets make sure we don't reference upvalues if using love2d
			GLOBAL=_G.GLOBAL
			sThread=_G.sThread
			name=__THREADNAME__ -- global data same as the name we used in this functions creation
		end -- Lanes should take the local upvalues ^^^
		cmd=sThread.waitFor(name.."CMD")
		local ret=os.execute(cmd)
		GLOBAL[name.."R"]=ret
	end)
	c.OnCMDFinished=multi:newConnection()
	c.looper=multi:newLoop(function(self)
		local ret=GLOBAL[self.link.name.."R"]
		if ret then
			self.link.OnCMDFinished:Fire(ret)
			self:Destroy()
		end
	end)
	c.looper.link=c
	return c
end
