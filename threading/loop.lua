require("multi.threading")
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
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				for i=1,#c.func do
					c.func[i](os.clock()-self.Start,c)
				end
				thread.sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
