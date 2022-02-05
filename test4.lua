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
	os.exit()
end
proc = multi:newProcessor("Test")
for i = 1,400 do
	thread:newThread("Thread: "..i,function()
		while true do
			thread.sleep(.1)
		end
	end)
end
proc:benchMark(sleep_for,multi.Priority_Core,"Core:"):OnBench(bench)

while true do
	proc.run()
end