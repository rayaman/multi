require("multi.threading")
function multi:newThreadedTLoop(name,func,n)
	local c=self:newTBase()
	c.Type='tloopThread'
	c.restN=n or 1
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
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				for i=1,#c.func do
					c.func[i](c)
				end
				thread.sleep(c.restN) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
