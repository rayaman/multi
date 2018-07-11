--[[
MIT License

Copyright (c) 2017 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
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
function multi:newSystemThreadedConnection(name,protect)
	local c={}
	c.name = name
	c.protect=protect
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	function c:init()
		local multi = require("multi")
		if multi:getPlatform()=="love2d" then
			GLOBAL=_G.GLOBAL
			sThread=_G.sThread
		end
		local conn = {}
		conn.name = self.name
		conn.count = 0
		if isMainThread then
			if GLOBAL[self.name.."THREADED_CONNQ"] then -- if this thing exists then lets grab it, we are doing something different here. instead of cleaning things up, we will gave a dedicated queue to manage things
				conn.queueCall = sThread.waitFor(self.name.."THREADED_CALLQ"):init()
			else
				conn.queueCall = multi:newSystemThreadedQueue(self.name.."THREADED_CALLQ"):init()
			end
		else
			local multi = require("multi") -- so things don't break, but also allows bi-directional connections to work
			conn.queueCall = sThread.waitFor(self.name.."THREADED_CALLQ"):init()
		end
		setmetatable(conn,{__call=function(self,...) return self:connect(...) end})
		conn.obj=multi:newConnection(self.protect)
		function conn:connect(func)
			return self.obj(func)
		end
		function conn:fConnect(func)
			return self.obj:fConnect(func)
		end
		function conn:holdUT(n)
			self.obj:holdUT(n)
		end
		function conn:Bind(t)
			self.obj:Bind(t)
		end
		function conn:Remove()
			self.obj:Remove()
		end
		function conn:getConnection(name,ingore)
			return self.obj:getConnection(name,ingore)
		end
		function conn:Fire(...)
			local args = {...}
			table.insert(args,1,multi.randomString(8))
			table.insert(args,1,self.name)
			table.insert(args,1,"F")
			self.queueCall:push(args)
			if self.trigger_self then
				self.obj:Fire(...)
			end
		end
		self.cleanup = .01
		function conn:SetCleanUpRate(n)
			self.cleanup=n or .01
		end
		conn.lastid=""
		conn.looper = multi:newLoop(function(self)
			local con = self.link
			local data = con.queueCall:peek()
			if not data then return end
			local id = data[3]
			if data[1]=="F" and data[2]==con.name and con.lastid~=id then
				con.lastid=id
				table.remove(data,1)-- Remove the first 3 elements
				table.remove(data,1)-- Remove the first 3 elements
				table.remove(data,1)-- Remove the first 3 elements
				con.obj:Fire(unpack(data))
				local alarm = multi:newAlarm(con.cleanup)
				alarm:OnRing(function()
					alarm:Destroy()
					local dat = con.queueCall:peek()
					if not dat then return end
					table.remove(data,1)-- Remove the first 3 elements
					table.remove(data,1)-- Remove the first 3 elements
					table.remove(data,1)-- Remove the first 3 elements
					if dat[3]==id then
						con.queueCall:pop()
					end
				end)
			end
		end)
		conn.HoldUT=conn.holdUT
		conn.looper.link=conn
		conn.Connect=conn.connect
		conn.FConnect=conn.fConnect
		conn.GetConnection=conn.getConnection
		return conn
	end
	GLOBAL[name]=c
	return c
end
function multi:systemThreadedBenchmark(n,p)
	n=n or 1
	local cores=multi.integration.THREAD.getCores()
	local queue=multi:newSystemThreadedQueue("QUEUE")
	multi.integration.GLOBAL["__SYSTEMBENCHMARK__"]=n
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	for i=1,cores do
		multi:newSystemThread("STHREAD_BENCH",function()
			local multi = require("multi")
			if multi:getPlatform()=="love2d" then
				GLOBAL=_G.GLOBAL
				sThread=_G.sThread
			end -- we cannot have upvalues... in love2d globals, not locals must be used
			queue=sThread.waitFor("QUEUE"):init() -- always wait for when looking for a variable at the start of the thread!
			multi:benchMark(sThread.waitFor("__SYSTEMBENCHMARK__")):OnBench(function(self,count)
				queue:push(count)
				multi:Stop()
			end)
			multi:mainloop()
		end)
	end
	local c={}
	c.tt=function() end
	c.p=p
	function c:OnBench(func)
		self.tt=func
	end
	multi:newThread("THREAD_BENCH",function()
		thread.sleep(n+.1)
		GLOBAL["QUEUE"]=nil -- time to clean up
		local num=0
		data=queue:pop()
		while data do
			num=num+data
			data=queue:pop()
		end
		if p then
			print(tostring(p)..num)
		end
		c.tt(c,num)
	end)
	return c
end
function multi:newSystemThreadedConsole(name)
	local c={}
	c.name = name
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	function c:init()
		local multi = require("multi")
		if multi:getPlatform()=="love2d" then
			GLOBAL=_G.GLOBAL
			sThread=_G.sThread
		end
		local cc={}
		if isMainThread then
			if GLOBAL["__SYSTEM_CONSLOE__"] then
				cc.stream = sThread.waitFor("__SYSTEM_CONSLOE__"):init()
			else
				cc.stream = multi:newSystemThreadedQueue("__SYSTEM_CONSLOE__"):init()
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
				end)
			end
		else
			cc.stream = sThread.waitFor("__SYSTEM_CONSLOE__"):init()
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
function multi:newSystemThreadedTable(name)
	local c={}
	c.name=name -- set the name this is important for identifying what is what
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	function c:init() -- create an init function so we can mimic on both love2d and lanes
		if multi:getPlatform()=="love2d" then
			GLOBAL=_G.GLOBAL
			sThread=_G.sThread
		end
		local cc={}
		cc.tab={}
		if isMainThread then
			cc.conn = multi:newSystemThreadedConnection(self.name.."_Tabled_Connection"):init()
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
			end,
		})
		return cc
	end
	GLOBAL[c.name]=c
	return c
end
function multi:newSystemThreadedJobQueue(numOfCores)
	local c={}
	c.jobnum=1
	c.cores=numOfCores or multi.integration.THREAD.getCores()
	c.queueIN=multi:newSystemThreadedQueue("THREADED_JQ"):init()
	c.queueOUT=multi:newSystemThreadedQueue("THREADED_JQO"):init()
	c.queueALL=multi:newSystemThreadedQueue("THREADED_QALL"):init()
	c.REG=multi:newSystemThreadedQueue("THREADED_JQ_F_REG"):init()
	c.OnReady=multi:newConnection()
	function c:registerJob(name,func)
		for i=1,self.cores do
			self.REG:push({name,func})
		end
	end
	function c:pushJob(name,...)
		self.queueOUT:push({self.jobnum,name,...})
		self.jobnum=self.jobnum+1
		return self.jobnum-1
	end
	local GLOBAL=multi.integration.GLOBAL -- set up locals in case we are using lanes
	local sThread=multi.integration.THREAD -- set up locals in case we are using lanes
	function c:doToAll(func)
		local TaskName=multi.randomString(16)
		for i=1,self.cores do
			self.queueALL:push({TaskName,func})
		end
	end
	function c:start()
		multi:newEvent(function()
			return self.ThreadsLoaded==true
		end):OnEvent(function(evnt)
			GLOBAL["THREADED_JQ"]=nil -- remove it
			GLOBAL["THREADED_JQO"]=nil -- remove it
			GLOBAL["THREADED_JQ_F_REG"]=nil -- remove it
			self:doToAll(function()
				_G["__started__"]=true
				SFunc()
			end)
			evnt:Destroy()
		end)
	end
	GLOBAL["__JQ_COUNT__"]=c.cores
	for i=1,c.cores do
		multi:newSystemThread("System Threaded Job Queue Worker Thread #"..i,function(name,ind)
			local multi = require("multi")
			ThreadName=name
			__sleep__=.001
			if love then -- lets make sure we don't reference up-values if using love2d
				GLOBAL=_G.GLOBAL
				sThread=_G.sThread
				__sleep__=.1
			end
			JQI=sThread.waitFor("THREADED_JQO"):init() -- Grab it
			JQO=sThread.waitFor("THREADED_JQ"):init() -- Grab it
			REG=sThread.waitFor("THREADED_JQ_F_REG"):init() -- Grab it
			QALL=sThread.waitFor("THREADED_QALL"):init() -- Grab it
			QALLT={}
			FUNCS={}
			SFunc=multi:newFunction(function(self)
				MainLoop:Pause()
				multi:newAlarm(.1):OnRing(function(alarm)
					alarm:Destroy()
					MainLoop:Resume()
				end)
			end)
			multi:newLoop(function()
				local rd=REG:peek()
				if rd then
					if not FUNCS[rd[1]] then
						FUNCS[rd[1]]=rd[2]
						rd=nil -- lets clean up
						REG:pop()
					end
				end
				local d=QALL:peek()
				if d then
					if not QALLT[d[1]] then
						QALLT[d[1]]=true
						d[2]()
						d=nil -- lets clean up
						QALL:pop()
					end
				end
			end)
			setmetatable(_G,{
				__index=function(t,k)
					return FUNCS[k]
				end
			})
			lastjob=os.clock()
			MainLoop=multi:newLoop(function(self)
				if __started__ then
					local job=JQI:pop()
					if job then
						lastjob=os.clock()
						local d=QALL:peek()
						if d then
							if not QALLT[d[1]] then
								QALLT[d[1]]=true
								d[2]()
								d=nil -- lets clean up
								QALL:pop()
							end
						end
						local ID=table.remove(job,1) -- return and remove
						local name=table.remove(job,1) -- return and remove
						if FUNCS[name] then
							JQO:push({ID,FUNCS[name](unpack(job))})
						else
							self:hold(function() return FUNCS[name] end)
							JQO:push({ID,FUNCS[name](unpack(job))})
						end
					end
				end
			end)
			multi:newThread("Idler",function()
				while true do
					if os.clock()-lastjob>1 then
						sThread.sleep(.1)
					end
					thread.sleep(.001)
				end
			end)
			JQO:push({"_THREADINIT_"})
			if not love then
				multi:mainloop()
			end
		end,"Thread<"..i..">",i)
	end
	c.OnJobCompleted=multi:newConnection()
	c.threadsResponded = 0
	c.updater=multi:newLoop(function(self)
		local data=self.link.queueIN:pop()
		while data do
			if data then
				local a=unpack(data)
				print(a)
				if a=="_THREADINIT_" then
					self.link.threadsResponded=self.link.threadsResponded+1
					if self.link.threadsResponded==self.link.cores then
						self.link.ThreadsLoaded=true
						self.link.OnReady:Fire()
					end
				else
					self.link.OnJobCompleted:Fire(unpack(data))
				end
			end
			data=self.link.queueIN:pop()
		end
	end)
	c.updater.link=c
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
