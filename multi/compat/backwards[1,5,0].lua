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
multi.OnObjectCreated(function(obj)
	if obj.Type=="loop" then
		function obj:Act()
			for i=1,#self.func do
				self.func[i](self.Parent.clock()-self.Start,self)
			end
		end
	elseif obj.Type=="step" then
		function obj:Act()
			if self~=nil then
				if self.spos==0 then
					if self.pos==self.start then
						for fe=1,#self.funcS do
							self.funcS[fe](self)
						end
					end
					for i=1,#self.func do
						self.func[i](self.pos,self)
					end
					self.pos=self.pos+self.count
					if self.pos-self.count==self.endAt then
						self:Pause()
						for fe=1,#self.funcE do
							self.funcE[fe](self)
						end
						self.pos=self.start
					end
				end
			end
			self.spos=self.spos+1
			if self.spos>=self.skip then
				self.spos=0
			end
		end
	elseif obj.Type=="tstep" then
		function c:Act()
			if self.clock()-self.timer>=self.set then
				self:Reset()
				if self.pos==self.start then
					for fe=1,#self.funcS do
						self.funcS[fe](self)
					end
				end
				for i=1,#self.func do
					self.func[i](self.pos,self)
				end
				self.pos=self.pos+self.count
				if self.pos-self.count==self.endAt then
					self:Pause()
					for fe=1,#self.funcE do
						self.funcE[fe](self)
					end
					self.pos=self.start
				end
			end
		end
	end
end)
if thread then
	function multi:newThreadedLoop(name,func)
		local c=self:newTBase()
		c.Type='loopThread'
		c.Start=os.clock()
		if func then
			c.func={func}
		end
		function c:tofile(path)
			local m=bin.new()
			m:addBlock(self.Type)
			m:addBlock(self.func)
			m:addBlock(self.Active)
			m:tofile(path)
		end
		function c:Resume()
			self.rest=false
		end
		function c:Pause()
			self.rest=true
		end
		function c:OnLoop(func)
			table.insert(self.func,func)
		end
		c.rest=false
		c.updaterate=0
		c.restRate=.75
		multi:newThread(name,function(ref)
			while true do
				if c.rest then
					thread.sleep(c.restRate)
				else
					for i=1,#c.func do
						c.func[i](os.clock()-self.Start,c)
					end
					thread.sleep(c.updaterate)
				end
			end
		end)
		self:create(c)
		return c
	end
	function multi:newThreadedStep(name,start,reset,count,skip)
		local c=self:newTBase()
		local think=1
		c.Type='stepThread'
		c.pos=start or 1
		c.endAt=reset or math.huge
		c.skip=skip or 0
		c.spos=0
		c.count=count or 1*think
		c.funcE={}
		c.funcS={}
		c.start=start or 1
		if start~=nil and reset~=nil then
			if start>reset then
				think=-1
			end
		end
		function c:tofile(path)
			local m=bin.new()
			m:addBlock(self.Type)
			m:addBlock(self.func)
			m:addBlock(self.funcE)
			m:addBlock(self.funcS)
			m:addBlock({pos=self.pos,endAt=self.endAt,skip=self.skip,spos=self.spos,count=self.count,start=self.start})
			m:addBlock(self.Active)
			m:tofile(path)
		end
		function c:Resume()
			self.rest=false
		end
		function c:Pause()
			self.rest=true
		end
		c.Reset=c.Resume
		function c:OnStart(func)
			table.insert(self.funcS,func)
		end
		function c:OnStep(func)
			table.insert(self.func,1,func)
		end
		function c:OnEnd(func)
			table.insert(self.funcE,func)
		end
		function c:Break()
			self.rest=true
		end
		function c:Update(start,reset,count,skip)
			self.start=start or self.start
			self.endAt=reset or self.endAt
			self.skip=skip or self.skip
			self.count=count or self.count
			self:Resume()
		end
		c.updaterate=0
		c.restRate=.1
		multi:newThread(name,function(ref)
			while true do
				if c.rest then
					ref:sleep(c.restRate)
				else
					if c~=nil then
						if c.spos==0 then
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
					end
					c.spos=c.spos+1
					if c.spos>=c.skip then
						c.spos=0
					end
					ref:sleep(c.updaterate)
				end
			end
		end)
		self:create(c)
		return c
	end
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
		c.updaterate=0
		c.restRate=0
		multi:newThread(name,function(ref)
			while true do
				if c.rest then
					thread.sleep(c.restRate)
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
					thread.skip(c.updaterate)
				end
			end
		end)
		self:create(c)
		return c
	end
end
