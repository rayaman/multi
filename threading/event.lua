require("multi.threading")
function multi:newThreadedEvent(name,task)
	local c=self:newTBase()
	c.Type='eventThread'
	c.Task=task or function() end
	function c:OnEvent(func)
		table.insert(self.func,func)
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.Task)
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
	c.rest=false
	c.updaterate=0
	c.restRate=1
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				ref:sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if c.Task(self) then
					for _E=1,#c.func do
						c.func[_E](c)
					end
					c:Pause()
				end
				ref:sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
