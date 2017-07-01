package.path="?/init.lua;?.lua;"..package.path
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
multi:newAlarm(2):OnRing(function(self)
	GLOBAL["NumOfCores"]=sThread.getCores()
end)
multi:newAlarm(7):OnRing(function(self)
	GLOBAL["AnotherTest"]=true
end)
multi:newAlarm(13):OnRing(function(self)
	GLOBAL["FinalTest"]=true
end)
multi:newSystemThread("test",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	print("Waiting for variable: NumOfCores")
	print("Got it: ",sThread.waitFor("NumOfCores"))
	sThread.hold(function()
		return GLOBAL["AnotherTest"] -- note this would hold the entire systemthread. Spawn a coroutine thread using multi:newThread() or multi:newThreaded...
	end)
	print("Holding works!")
	multi:newThread("tests",function()
		thread.hold(function()
			return GLOBAL["FinalTest"] -- note this will not hold the entire systemthread. As seen with the TLoop constantly going!
		end)
		print("Final test works!")
		os.exit()
	end)
	local a=0
	multi:newTLoop(function()
		a=a+1
		print(a)
	end,.5)
	multi:mainloop()
end)
multi:mainloop()
