require("multi.threading")
function multi:newThreadedUpdater(name,skip)
	local c=self:newTBase()
	c.Type='updaterThread'
	c.pos=1
	c.skip=skip or 1
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	c.OnUpdate=self.OnMainConnect
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
				c.pos=c.pos+1
				thread.skip(c.skip)
			end
		end
	end)
	self:create(c)
	return c
end
