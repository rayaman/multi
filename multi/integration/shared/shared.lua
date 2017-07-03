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
function multi:newSystemThreadedQueue(name) -- in love2d this will spawn a channel on both ends
	local c={} -- where we will store our object
	c.name=name -- set the name this is important for the love2d side
	if love then -- check love
		if love.thread then -- make sure we can use the threading module
			function c:init() -- create an init function so we can mimic on bith love2d and lanes
				self.chan=love.thread.getChannel(self.name) -- create channel by the name self.name
				function self:push(v) -- push to the channel
					self.chan:push({type(v),resolveData(v)})
				end
				function self:pop() -- pop from the channel
					local tab=self.chan:pop()
					if not tab then return end
					return resolveType(tab[1],tab[2])
				end
				function self:peek()
					local tp,d=unpack{self.chan:peek()}
					return resolveType(tp,d)
				end
				GLOBAL[self.name]=self -- send the object to the thread through the global interface
				return self -- return the object
			end
			return c
		else
			error("Make sure you required the love.thread module!") -- tell the user if he/she didn't require said module
		end
	else
		c.linda=lanes.linda() -- lanes is a bit eaiser, create the linda on the main thread
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
function multi:systemThreadedBenchmark(n,p)
	n=n or 1
	local cores=multi.integration.THREAD.getCores()
	local queue=multi:newSystemThreadedQueue("QUEUE")
	multi.integration.GLOBAL["__SYSTEMBENCHMARK__"]=n
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	for i=1,cores do
		multi:newSystemThread("STHREAD_BENCH",function()
			require("multi")
			if multi:getPlatform()=="love2d" then
				GLOBAL=_G.GLOBAL
				sThread=_G.sThread
			end -- we cannot have upvalues... in love2d globals not locals must be used
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
function multi:newSystemThreadedTable(name)
	local c={} -- where we will store our object
	c.name=name -- set the name this is important for the love2d side
	if love then -- check love
		if love.thread then -- make sure we can use the threading module
			function c:init() -- create an init function so we can mimic on bith love2d and lanes
				self.tab={}
				self.chan=love.thread.getChannel(self.name) -- create channel by the name self.name
				function self:waitFor(name) -- pop from the channel
					repeat self:sync() until self[name]
					return self[name]
				end
				function self:sync()
					local data=self.chan:pop()
					while data do
						if type(data)=="string" then
							local cmd,tp,name,d=data:match("(%S-) (%S-) (%S-) (.+)")
							if cmd=="SYNC" then
								self.tab[name]=resolveType(tp,d) -- this is defined in the loveManager.lua file
							end
						else
							self.tab[name]=data
						end
						data=self.chan:pop()
					end
				end
				setmetatable(self,{
					__index=function(t,k)
						self:sync()
						return self.tab[k]
					end,
					__newindex=function(t,k,v)
						self:sync()
						self.tab[k]=v
						if type(v)=="userdata" then
							self.chan:push(v)
						else
							self.chan:push("SYNC "..type(v).." "..k.." "..resolveData(v)) -- this is defined in the loveManager.lua file
						end
					end,
				})
				GLOBAL[self.name]=self -- send the object to the thread through the global interface
				return self -- return the object
			end
			return c
		else
			error("Make sure you required the love.thread module!") -- tell the user if he/she didn't require said module
		end
	else
		c.linda=lanes.linda() -- lanes is a bit eaiser, create the linda on the main thread
		function c:waitFor(name)
			while self[name]==nil do
				-- Waiting
			end
			return self[name]
		end
		function c:sync()
			return -- just so we match the love2d side
		end
		function c:init() -- set the metatable
			setmetatable(self,{
				__index=function(t,k)
					return self.linda:get(k)
				end,
				__newindex=function(t,k,v)
					self.linda:set(k,v)
				end,
			})
			return self
		end
		multi.integration.GLOBAL[name]=c -- send the object to the thread through the global interface
	end
	return c
end
function multi:newSystemThreadedJobQueue(numOfCores)
	local c={}
	c.jobnum=1
	c.cores=numOfCores or multi.integration.THREAD.getCores()
	c.queueIN=multi:newSystemThreadedQueue("THREADED_JQ"):init()
	c.queueOUT=multi:newSystemThreadedQueue("THREADED_JQO"):init()
	c.REG=multi:newSystemThreadedTable("THREADED_JQ_F_REG"):init()
	-- registerJob(name,func)
	-- pushJob(...)
	function c:registerJob(name,func)
		self.REG[name]=func
	end
	function c:pushJob(name,...)
		self.queueOUT:push({self.jobnum,name,...})
		self.jobnum=self.jobnum+1
	end
	local GLOBAL=multi.integration.GLOBAL -- set up locals incase we are using lanes
	local sThread=multi.integration.THREAD -- set up locals incase we are using lanes
	GLOBAL["__JQ_COUNT__"]=c.cores
	for i=1,c.cores do
		multi:newSystemThread("System Threaded Job Queue Worker Thread #"..i,function()
			require("multi")
			__sleep__=.001
			if love then -- lets make sure we don't reference upvalues if using love2d
				GLOBAL=_G.GLOBAL
				sThread=_G.sThread
				__sleep__=.1
			end
			JQI=sThread.waitFor("THREADED_JQO"):init() -- Grab it
			JQO=sThread.waitFor("THREADED_JQ"):init() -- Grab it
			FGLOBAL=sThread.waitFor("THREADED_JQ_F_REG"):init() -- Grab it
			sThread.sleep(.1) -- lets wait for things to work out
			setmetatable(_G,{
				__index=FGLOBAL
			})
			GLOBAL["THREADED_JQ"]=nil -- remove it
			GLOBAL["THREADED_JQO"]=nil -- remove it
			GLOBAL["THREADED_JQ_F_REG"]=nil -- remove it
			multi:newLoop(function()
				sThread.sleep(__sleep__) -- lets allow cpu time for other processes on our system!
				local job=JQI:pop()
				if job then
					local ID=table.remove(job,1) -- return and remove
					local name=table.remove(job,1) -- return and remove
					local ret={FGLOBAL:waitFor(name)(unpack(job))} -- unpack the rest
					JQO:push({ID,ret})
				end
			end)
			multi:mainloop()
		end)
	end
	c.OnJobCompleted=multi:newConnection()
	c.updater=multi:newLoop(function(self)
		local data=self.link.queueIN:pop()
		while data do
			if data then
				self.link.OnJobCompleted:Fire(unpack(data))
			end
			data=self.link.queueIN:pop()
		end
	end)
	c.updater.link=c
	return c
end
