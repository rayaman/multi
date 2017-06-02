require("multi.threading")
function multi:newThreadedAlarm(name,set)
	local c=self:newTBase()
	c.Type='alarmThread'
	c.timer=self:newTimer()
	c.set=set or 0
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.set)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
		self.timer:Resume()
	end
	function c:Reset(n)
		if n then self.set=n end
		self.rest=false
		self.timer:Reset(n)
	end
	function c:OnRing(func)
		table.insert(self.func,func)
	end
	function c:Pause()
		self.timer:Pause()
		self.rest=true
	end
	c.rest=false
	c.updaterate=multi.Priority_Low -- skips
	c.restRate=0 -- secs
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if c.timer:Get()>=c.set then
					c:Pause()
					for i=1,#c.func do
						c.func[i](c)
					end
				end
				thread.skip(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
