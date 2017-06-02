require("multi")
function multi:newTLoop(func,set)
	local c=self:newBase()
	c.Type='tloop'
	c.set=set or 0
	c.timer=self:newTimer()
	c.life=0
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
	function c:Act()
		if self.timer:Get()>=self.set then
			self.life=self.life+1
			for i=1,#self.func do
				self.func[i](self,self.life)
			end
			self.timer:Reset()
		end
	end
	function c:Resume()
		self.Parent.Resume(self)
		self.timer:Resume()
	end
	function c:Pause()
		self.timer:Pause()
		self.Parent.Pause(self)
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	self:create(c)
	return c
end
