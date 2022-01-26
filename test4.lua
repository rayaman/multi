package.path = "./?.lua;?/init.lua;"..package.path
local multi,thread = require("multi"):init()
--[[ Testing...
Before AVG: 522386
Test 1 AVG: 
]]
local sleep_for = 100000
local conn = multi:newConnection()
local function bench(_,steps)
	print("Steps/5s: "..steps)
	os.exit()
end
local ready = false
multi:newAlarm(3):OnRing(function()
	conn:Fire()
end)
multi:benchMark(sleep_for,multi.Priority_Core,"Core:"):OnBench(bench)
multi:newThread("Thread 1",function()
	while true do
		thread.hold(conn) -- We just need to run things
	end
end)

multi:newThread("Thread 2",function()
	thread.sleep(1)
	error("Hi")
end)

multi:newThread("Thread 3",function()
	while true do
		thread.sleep(1) -- We just need to run things
		print("3 ...")
	end
end)

-- multi.OnExit(function()
-- 	print("Total: ".. a)
-- end)

multi:mainloop()