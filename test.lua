package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
--~ local GLOBAL,THREAD = require("multi.integration.lanesManager").init()
--~ nGLOBAL = require("multi.integration.networkManager").init()
--~ function table.print(tbl, indent)
--~ 	if type(tbl)~="table" then return end
--~ 	if not indent then indent = 0 end
--~ 	for k, v in pairs(tbl) do
--~ 		formatting = string.rep('  ', indent) .. k .. ': '
--~ 		if type(v) == 'table' then
--~ 			print(formatting)
--~ 			table.print(v, indent+1)
--~ 		else
--~ 			print(formatting .. tostring(v))
--~ 		end
--~ 	end
--~ end
--~ print(#multi.SystemThreads)
--~ multi:newThread("Detail Updater",function()
--~ 	while true do
--~ 		thread.sleep(1)
--~ 		print(multi:getTasksDetails())
--~ 		print("-----")
--~ 		table.print(multi:getTasksDetails("t"))
--~ 		io.read()
--~ 	end
--~ end)
--~ multi.OnSystemThreadDied(function(...)
--~ 	print("why you say dead?",...)
--~ end)
--~ multi.OnError(function(...)
--~ 	print(...)
--~ end)
--~ multi:newSystemThread("TestSystem",function()
--~ 	while true do
--~ 		THREAD.sleep(1)
--~ 		print("I'm alive")
--~ 	end
--~ end)
--~ print(#multi.SystemThreads)
--~ multi:mainloop{
--~ 	protect = false,
--~ 	print = true
--~ }
--~ function tprint (tbl, indent)
--~   if not indent then indent = 0 end
--~   for k, v in pairs(tbl) do
--~     formatting = string.rep("  ", indent) .. k .. ": "
--~     if type(v) == "table" then
--~       print(formatting)
--~       tprint(v, indent+1)
--~     elseif type(v) == 'boolean' then
--~       print(formatting .. tostring(v))
--~     else
--~       print(formatting .. tostring(v))
--~     end
--~   end
--~ end

--~ t = multi:newThread("test",function()
--~ 	while true do
--~ 		thread.sleep(.5)
--~ 		print("A test!")
--~ 	end
--~ end)
--~ multi:newAlarm(3):OnRing(function()
--~ 	multi:newAlarm(3):OnRing(function()
--~ 		t:Resume()
--~ 	end)
--~ 	t:Pause()
--~ end)
--~ multi.OnError(function(...)
--~ 	print(...)
--~ end)

--~ function test()
--~ 	while true do
--~ 		a=a+1
--~ 	end
--~ end
--~ g=string.dump(test)
--~ print(g)
--~ if g:find("thread") then
--~ 	print("Valid Thread!")
--~ elseif (g:find("K")) and not g:find("thread") then
--~ 	print("Invalid Thread!")
--~ else
--~ 	print("Should be safe")
--~ end
a=0
multi:newTLoop(function()
	a=a+1
end,1)
multi:newThread("Test",function()
	while true do
		--
	end
end)
multi:mainloop()
