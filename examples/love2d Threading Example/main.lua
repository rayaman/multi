require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
--IMPORTANT
-- Do not make the above local, this is the one difference that the lanesManager does not have
-- If these are local the functions will have the upvalues put into them that do not exist on the threaded side
-- You will need to ensure that the function does not refer to any upvalues in its code. It will print an error if it does though
-- Also each thread has a .1 second delay! This is used to generate a random values for each thread!
require("core.GuiManager") -- allows the use of graphics in the program.
gui.ff.Color=Color.Black
function comma_value(amount)
	local formatted = amount
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end
multi:newSystemThread("test1",function() -- Another difference is that the multi library is already loaded in the threaded enviroment as well as a call to multi:mainloop()
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 1"):OnBench(function(self,c) GLOBAL["T1"]=c multi:Stop() end)
end)
multi:newSystemThread("test2",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 2"):OnBench(function(self,c) GLOBAL["T2"]=c multi:Stop() end)
end)
multi:newSystemThread("test3",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 3"):OnBench(function(self,c) GLOBAL["T3"]=c multi:Stop() end)
end)
multi:newSystemThread("test4",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 4"):OnBench(function(self,c) GLOBAL["T4"]=c multi:Stop() end)
end)
multi:newSystemThread("test5",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 5"):OnBench(function(self,c) GLOBAL["T5"]=c multi:Stop() end)
end)
multi:newSystemThread("test6",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 6"):OnBench(function(self,c) GLOBAL["T6"]=c multi:Stop() end)
end)
multi:newSystemThread("Combiner",function() -- spawns a thread in another lua process
	function comma_value(amount)
		local formatted = amount
		while true do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then
				break
			end
		end
		return formatted
	end
	local b=comma_value(tostring(sThread.waitFor("T1")+sThread.waitFor("T2")+sThread.waitFor("T3")+sThread.waitFor("T4")+sThread.waitFor("T5")+sThread.waitFor("T6")))
	GLOBAL["DONE"]=b
end)
multi:newThread("test0",function()
	-- sThread.waitFor("DONE") -- lets hold the main thread completely so we don't eat up cpu
	-- os.exit()
	-- when the main thread is holding there is a chance that error handling on the system threads may not work!
	-- instead we can do this
	while true do
		thread.skip(1) -- allow error handling to take place... Otherwise lets keep the main thread running on the low
		-- Before we held just because we could... But this is a game and we need to have logic continue
		--sThreadM.sleep(.001) -- Sleeping for .001 is a greeat way to keep cpu usage down. Make sure if you aren't doing work to rest. Abuse the hell out of GLOBAL if you need to :P
		if GLOBAL["DONE"] then
			t.text="Bench: "..GLOBAL["DONE"]
		end
	end
end)
GLOBAL["Bench"]=3
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
