require("multi")
function multi:newUpdater(skip)
	local c=self:newBase()
	c.Type='updater'
	c.pos=1
	c.skip=skip or 1
	function c:Act()
		if self.pos>=self.skip then
			self.pos=0
			for i=1,#self.func do
				self.func[i](self)
			end
		end
		self.pos=self.pos+1
	end
	function c:setSkip(n)
		self.skip=n
	end
	c.OnUpdate=self.OnMainConnect
	self:create(c)
	return c
end