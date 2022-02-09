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

thread:newThread(function()
	thread.sleep(5)
	proc.Stop()
	thread.sleep(5)
	proc.Start()
end)

thread:newThread(function()
	while true do
		thread.sleep(1)
		print("...")
	end
end)

proc:newThread(function()
	while true do
		thread.sleep(1)
		print("Testing...")
	end
end)

multi:mainloop()