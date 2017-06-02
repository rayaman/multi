require("multi.threading")
function multi:newThreadedProcess(name)
	local c = {}
	setmetatable(c, multi)
	function c:newBase(ins)
		local ct = {}
		setmetatable(ct, self.Parent)
		ct.Active=true
		ct.func={}
		ct.ender={}
		ct.Id=0
		ct.PId=0
		ct.Act=function() end
		ct.Parent=self
		ct.held=false
		ct.ref=self.ref
		table.insert(self.Mainloop,ct)
		return ct
	end
	c.Parent=self
	c.Active=true
	c.func={}
	c.Id=0
	c.Type='process'
	c.Mainloop={}
	c.Tasks={}
	c.Tasks2={}
	c.Garbage={}
	c.Children={}
	c.Paused={}
	c.Active=true
	c.Id=-1
	c.Rest=0
	c.updaterate=.01
	c.restRate=.1
	c.Jobs={}
	c.queue={}
	c.jobUS=2
	c.rest=false
	function c:getController()
		return nil
	end
	function c:Start()
		self.rest=false
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	function c:Remove()
		self.ref:kill()
	end
	function c:kill()
		err=coroutine.yield({"_kill_"})
		if err then
			error("Failed to kill a thread! Exiting...")
		end
	end
	function c:sleep(n)
		if type(n)=="function" then
			ret=coroutine.yield({"_hold_",n})
		elseif type(n)=="number" then
			n = tonumber(n) or 0
			ret=coroutine.yield({"_sleep_",n})
		else
			error("Invalid Type for sleep!")
		end
	end
	c.hold=c.sleep
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				ref:Sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				c:uManager()
				ref:sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	return c
end
