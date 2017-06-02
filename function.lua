require("multi")
function multi:newFunction(func)
	local c={}
	c.func=func
	mt={
		__index=multi,
		__call=function(self,...) if self.Active then return self:func(...) end local t={...} return "PAUSED" end
	}
	c.Parent=self
	function c:Pause()
		self.Active=false
	end
	function c:Resume()
		self.Active=true
	end
	setmetatable(c,mt)
	self:create(c)
	return c
end