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
require("multi.threading")
function multi:newThreadedTStep(name,start,reset,count,set)
	local c=self:newTBase()
	local think=1
	c.Type='tstepThread'
	c.Priority=self.Priority_Low
	c.start=start or 1
	local reset = reset or math.huge
	c.endAt=reset
	c.pos=start or 1
	c.skip=skip or 0
	c.count=count or 1*think
	c.funcE={}
	c.timer=os.clock()
	c.set=set or 1
	c.funcS={}
	function c:Update(start,reset,count,set)
		self.start=start or self.start
		self.pos=self.start
		self.endAt=reset or self.endAt
		self.set=set or self.set
		self.count=count or self.count or 1
		self.timer=os.clock()
		self:Resume()
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.funcE)
		m:addBlock(self.funcS)
		m:addBlock({pos=self.pos,endAt=self.endAt,skip=self.skip,timer=self.timer,count=self.count,start=self.start,set=self.set})
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	function c:OnStart(func)
		table.insert(self.funcS,func)
	end
	function c:OnStep(func)
		table.insert(self.func,func)
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
	end
	function c:Break()
		self.Active=nil
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=os.clock()
		self:Resume()
	end
	c.updaterate=0--multi.Priority_Low -- skips
	c.restRate=0
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if os.clock()-c.timer>=c.set then
					c:Reset()
					if c.pos==c.start then
						for fe=1,#c.funcS do
							c.funcS[fe](c)
						end
					end
					for i=1,#c.func do
						c.func[i](c.pos,c)
					end
					c.pos=c.pos+c.count
					if c.pos-c.count==c.endAt then
						c:Pause()
						for fe=1,#c.funcE do
							c.funcE[fe](c)
						end
						c.pos=c.start
					end
				end
				thread.skip(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
