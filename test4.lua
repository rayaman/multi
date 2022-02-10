package.path = "./?.lua;?/init.lua;"..package.path
local multi,thread = require("multi"):init()
--[[ Testing...
Before AVG: 522386
Test 1 AVG: 
]]
local sleep_for = 1
local conn = multi:newConnection()
local test = {}
local function bench(_,steps)
	print("Steps/1s: "..steps)
	--os.exit()
end
proc = multi:newProcessor("Test")

proc.Start()

multi:newTLoop(function()
	
end,1)

-- thread:newThread(function()
-- 	while true do
-- 		thread.sleep(1)
-- 		print("Proc: ".. tostring(proc.isActive()))
-- 	end
-- end)

local func = proc:newFunction(function(a,b,c)
	print("Testing proc functions!")
	error("Testing")
	return "Please", "Smile", 123
end)

func("Some","tests","needed").connect(function(a,b,c)
	print("Return",a,b,c)
end)

multi:mainloop()