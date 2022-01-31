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
	while true do
		thread.sleep(1)
		print("Test 1")
		thread.hold(conn)
		print("Conn sleep test")
		error("hi")
	end
end).OnError(print) 

multi:newThread("Thread 2",function()
	print("Thread 2")
	return "it worked"
end):OnDeath(print):OnError(error)
multi:newThread("Thread 3",function()
	thread.hold(function()
		return ready
	end)
	print("Function test")
	return "Yay we did it"
end).OnDeath(print)

-- multi.OnExit(function()
-- 	print("Total: ".. a)
-- end)

multi:mainloop()