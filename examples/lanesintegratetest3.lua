package.path="?/init.lua;?.lua;"..package.path -- Spawing threads using 1 method and the sThread.getCores() function!
local GLOBAL,sThread=require("multi.integration.lanesManager").init() -- loads the lanesManager and includes the entire multi library
local function comma_value(amount)
	local formatted = amount
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end
GLOBAL["BENCHCOUNT"],GLOBAL["CNUM"],GLOBAL["DONE"]=0,0,0
cores=sThread.getCores()
function benchmark() -- our single function that will be used across a bunch of threads
	require("multi.all") -- get the library
	local n=GLOBAL["CNUM"]; GLOBAL["CNUM"]=n+1 -- do some math so we can identify which thread is which
	multi:benchMark(sThread.waitFor("BENCH"),nil,"Thread "..n+1):OnBench(function(self,c) GLOBAL["BENCHCOUNT"]=GLOBAL["BENCHCOUNT"]+c; GLOBAL["DONE"]=GLOBAL["DONE"]+1; multi:Stop() end)
	-- ^ do the bench mark and add to the BENCHCOUNT GLOBAL value, then increment the DONE Value
	multi:mainloop()
end
for i=1,cores do -- loop based on the number of cores you have
	multi:newSystemThread("test"..i,benchmark) -- create a system thread based on the benchmark
end
multi:newThread("test0",function()
	while true do
		thread.skip(1)
		sThread.sleep(.001)
		if GLOBAL["DONE"]==cores then
			print(comma_value(tostring(GLOBAL["BENCHCOUNT"])))
			os.exit()
		end
	end
end)
GLOBAL["BENCH"]=10
print("Platform is: ",multi:getPlatform()) -- returns love2d or lanes depending on which platform you are using... If I add more intergrations then this method will be updated! corona sdk may see this library in the future...
multi:mainloop()
--[[ Output on my machine! I am using luajit and have 6 cores on my computer. Your numbers will vary, but it should look something like this
Intergrated Lanes!
Platform is: 	lanes
Thread 1 62442125 Steps in 10 second(s)!
Thread 2 61379095 Steps in 10 second(s)!
Thread 3 62772502 Steps in 10 second(s)!
Thread 4 62740684 Steps in 10 second(s)!
Thread 5 60926715 Steps in 10 second(s)!
Thread 6 61793175 Steps in 10 second(s)!
372,054,296
]]
