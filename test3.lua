local multi,thread = require("multi"):init()
local GLOBAL,THREAD = require("multi.integration.threading"):init()

function sleep(n)
	if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end
-- local GLOBAL,THREAD = {},{}-- require("multi.integration.lanesManager.threads").init(__GlobalLinda,__SleepingLinda)
-- local count = 1
-- local started = false
-- local livingThreads = {}
-- local threads = {}
-- multi.SystemThreads = {}
-- function multi:newSystemThread(name, func, ...)
-- 	--multi.InitSystemThreadErrorHandler()
-- 	local rand = math.random(1, 10000000)
-- 	local return_linda = lanes.linda()
-- 	local c = {}
-- 	c.name = name
-- 	c.Name = name
-- 	c.Id = count
-- 	c.loadString = {"base","package","os","io","math","table","string","coroutine"}
-- 	livingThreads[count] = {true, name}
-- 	c.returns = return_linda
-- 	c.Type = "sthread"
-- 	c.creationTime = os.clock()
-- 	c.alive = true
-- 	c.priority = THREAD.Priority_Normal
-- 	c.thread = lanes.gen("*",func)(...)
-- 	count = count + 1
-- 	function c:kill()
-- 		self.thread:cancel()
-- 		multi.print("Thread: '" .. self.name .. "' has been stopped!")
-- 		self.alive = false
-- 	end
-- 	table.insert(multi.SystemThreads, c)
-- 	c.OnDeath = multi:newConnection()
-- 	c.OnError = multi:newConnection()
-- 	GLOBAL["__THREADS__"] = livingThreads
-- 	return c
-- end

multi:newSystemThread("test",function()
	print("Hello World!")
end)

multi:newThread("Test thread",function()
	while true do
		thread.sleep(1)
		print("...")
	end
end)
multi:mainloop()