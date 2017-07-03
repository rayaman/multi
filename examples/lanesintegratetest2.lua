package.path="?/init.lua;?.lua;"..package.path
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
multi:newSystemThread("test1",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 1"):OnBench(function(self,c) GLOBAL["T1"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test2",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 2"):OnBench(function(self,c) GLOBAL["T2"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test3",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 3"):OnBench(function(self,c) GLOBAL["T3"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test4",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 4"):OnBench(function(self,c) GLOBAL["T4"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test5",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 5"):OnBench(function(self,c) GLOBAL["T5"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test6",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 6"):OnBench(function(self,c) GLOBAL["T6"]=c multi:Stop() end)
	multi:mainloop()
	print("Bench: ",comma_value(tostring(sThread.waitFor("T1")+sThread.waitFor("T2")+sThread.waitFor("T3")+sThread.waitFor("T4")+sThread.waitFor("T5")+sThread.waitFor("T6"))))
	GLOBAL["DONE"]=true
end)
multi:newThread("test0",function()
	-- sThread.waitFor("DONE") -- lets hold the main thread completely so we don't eat up cpu
	-- os.exit()
	-- when the main thread is holding there is a chance that error handling on the system threads may not work!
	-- instead we can do this
	while true do
		thread.skip(1) -- allow error handling to take place... Otherwise lets keep the main thread running on the low
		sThread.sleep(.001) -- Sleeping for .001 is a greeat way to keep cpu usage down. Make sure if you aren't doing work to rest. Abuse the hell out of GLOBAL if you need to :P
		if GLOBAL["DONE"] then
			os.exit()
		end
	end
end)
GLOBAL["Bench"]=60
multi:mainloop()
