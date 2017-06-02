require("multi")
function multi:newLoop(func)
	local c=self:newBase()
	c.Type='loop'
	c.Start=self.clock()
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
		for i=1,#self.func do
			self.func[i](self.Parent.clock()-self.Start,self)
		end
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	self:create(c)
	return c
end
