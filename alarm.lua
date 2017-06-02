require("multi")
function multi:newAlarm(set)
	local c=self:newBase()
	c.Type='alarm'
	c.Priority=self.Priority_Low
	c.timer=self:newTimer()
	c.set=set or 0
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.set)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Act()
		if self.timer:Get()>=self.set then
			self:Pause()
			self.Active=false
			for i=1,#self.func do
				self.func[i](self)
			end
		end
	end
	function c:Resume()
		self.Parent.Resume(self)
		self.timer:Resume()
	end
	function c:Reset(n)
		if n then self.set=n end
		self:Resume()
		self.timer:Reset()
	end
	function c:OnRing(func)
		table.insert(self.func,func)
	end
	function c:Pause()
		self.timer:Pause()
		self.Parent.Pause(self)
	end
	self:create(c)
	return c
end
