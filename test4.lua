package.path = "./?.lua;?/init.lua;"..package.path
local multi,thread = require("multi"):init()
--[[ Testing...
Before AVG: 522386
Test 1 AVG: 
]]
local sleep_for = 1

local function bench(_,steps)
	print("Steps/5s: "..steps)
	os.exit()
end
multi:benchMark(sleep_for,multi.Priority_Core,"Core:"):OnBench(bench)
multi:newThread(function()
	while true do
		thread.sleep(1) -- We just need to run things
	end
end)

multi:newThread(function()
	while true do
		thread.sleep(1) -- We just need to run things
	end
end)

-- multi.OnExit(function()
-- 	print("Total: ".. a)
-- end)

multi:mainloop()