require("multi")
function multi:newTrigger(func)
	local c={}
	c.Type='trigger'
	c.trigfunc=func or function() end
	function c:Fire(...)
		self:trigfunc(...)
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.trigfunc)
		m:tofile(path)
	end
	self:create(c)
	return c
end
