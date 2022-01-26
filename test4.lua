package.path = "./?.lua;?/init.lua;"..package.path
local multi,thread = require("multi"):init()
--[[ Testing...
Before AVG: 522386
Test 1 AVG: 
]]
local sleep_for = 5
local conn = multi:newConnection()
local function bench(_,steps)
	print("Steps/5s: "..steps)
	os.exit()
end
local ready = false
multi:newAlarm(3):OnRing(function()
	conn:Fire()
	ready = true
end)
multi:benchMark(sleep_for,multi.Priority_Core,"Core:"):OnBench(bench)
multi:newThread("Thread 1",function()
	error("Testing 1")
end)

multi:newThread("Thread 2",function()
	thread.sleep(2)
	error("Testing 2")
end)
multi:newThread("Thread 3",function()
	thread.sleep(1)
	return "Complete 3"
end)

-- multi.OnExit(function()
-- 	print("Total: ".. a)
-- end)

multi:mainloop()