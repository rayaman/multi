package.path = "./?.lua;?/init.lua;"..package.path
local multi,thread = require("multi"):init()
--[[ Testing...
Before AVG: 522386
Test 1 AVG: 
]]
local sleep_for = 5

local function bench(_,steps)
	print("Steps/5s: "..steps)
	os.exit()
end
multi:benchMark(sleep_for,multi.Priority_Core,"Core:"):OnBench(bench)
multi:newThread("Thread 1",function(a,b,c)
	print(a,b,c)
	while true do
		print(1)
		thread.sleep(1) -- We just need to run things
		print("1 ...")
	end
end,1,2,3)

multi:newThread("Thread 2",function(a,b,c)
	print(a,b,c)
	while true do
		print(2)
		thread.sleep(1) -- We just need to run things
		print("2 ...")
	end
end,4,5,6)

-- multi.OnExit(function()
-- 	print("Total: ".. a)
-- end)

multi:mainloop()