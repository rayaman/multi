package.path="?.lua;?/init.lua;?.lua;"..package.path
local multi, thread = require("multi"):init()
function multi:newService(func) -- Priority managed threads
	local c = {}
	c.Type = "Service"
	c.OnError = multi:newConnection()
	c.OnStopped = multi:newConnection()
	c.OnStarted = multi:newConnection()
	local data = {}
	local active = false
	local time = multi:newTimer()
	local p = multi.Priority_Normal
	local scheme = 1
	local function process()
		thread.hold(function()
			return active
		end)
		func(c,data)
		if scheme == 1 then
			if (p^(1/3))/10 == .1 then
				thread.yield()
			else
				thread.sleep((p^(1/3))/10)
			end
		elseif scheme == 2 then
			thread.skip(math.abs(p-1)*32+1)
		end
	end
	multi:newThread(function()
		while true do
			process()
		end
	end).OnError = c.OnError -- use the threads onerror as our own
	function c.SetScheme(n)
		scheme = n
	end
	function c.Stop()
		c:OnStopped(c)
		time:Reset()
		time:Pause()
		data = {}
		time = {}
		active = false
	end
	function c.Pause()
		time:Pause()
		active = false
	end
	function c.Resume()
		time:Resume()
		active = true
	end
	function c.Start()
		c:OnStarted(c)
		time:Start()
		active = true
	end
	function c.getUpTime()
		return time:Get()
	end
	function c.setPriority(pri)
		p = pri
	end
	return c
end
serv = multi:newService(function(self,data)
	thread.sleep(1)
	error("sorry i crashed :'(")
end)
serv.OnError(function(...)
	print(...)
end)
serv.OnStarted(function(t)
	print("Started!",t.Type)
end)
serv:Start()
serv:setPriority(multi.Priority_Idle)
multi:mainloop()