package.path="?/init.lua;?.lua;"..package.path
local GLOBAL,sThread=require("multi.intergration.lanesManager").init()
multi:newSystemThread("test1",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(1,nil,"Thread 1"):OnBench(function(self,c) GLOBAL["T1"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test2",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(1,nil,"Thread 2"):OnBench(function(self,c) GLOBAL["T2"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test3",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(1,nil,"Thread 3"):OnBench(function(self,c) GLOBAL["T3"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test4",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(1,nil,"Thread 4"):OnBench(function(self,c) GLOBAL["T4"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test5",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(1,nil,"Thread 5"):OnBench(function(self,c) GLOBAL["T5"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test6",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
	multi:benchMark(1,nil,"Thread 6"):OnBench(function(self,c) GLOBAL["T6"]=c multi:Stop() end)
	multi:mainloop()
end)
multi:newSystemThread("test6",function() -- spawns a thread in another lua process
	print("Bench: ",sThread.waitFor("T1")+sThread.waitFor("T2")+sThread.waitFor("T3")+sThread.waitFor("T4")+sThread.waitFor("T5")+sThread.waitFor("T6"))
end)
multi:mainloop()
