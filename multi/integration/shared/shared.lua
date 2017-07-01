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
					self.chan:push(v)
				end
				function self:pop() -- pop from the channel
					return self.chan:pop()
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
		function c:init() -- mimic the feature that love2d requires, so code can be consistent
			return self
		end
		multi.intergration.GLOBAL[name]=c -- send the object to the thread through the global interface
	end
	return c
end
function multi:systemThreadedBenchmark(n,p)
	n=n or 1
	local cores=multi.intergration.THREAD.getCores()
	local queue=multi:newSystemThreadedQueue("QUEUE")
	multi.intergration.GLOBAL["__SYSTEMBENCHMARK__"]=n
	local sThread=multi.intergration.THREAD
	local GLOBAL=multi.intergration.GLOBAL
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
		multi.intergration.GLOBAL[name]=c -- send the object to the thread through the global interface
	end
	return c
end
