package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
conn = multi:newSystemThreadedConnection("test"):init()
multi:newSystemThread("Work",function()
	local multi = require("multi")
	conn = THREAD.waitFor("test"):init()
	conn(function(...)
		print(...)
	end)
	multi:newTLoop(function()
		conn:Fire("meh2")
	end,1)
	multi:mainloop()
end)
multi.OnError(function(a,b,c)
	print(c)
end)
multi:newTLoop(function()
	conn:Fire("meh")
end,1)
conn(function(...)
	print(">",...)
end)

--~ jq = multi:newSystemThreadedJobQueue()
--~ jq:registerJob("test",function(a)
--~ 	return "Hello",a
--~ end)
--~ jq.OnJobCompleted(function(ID,...)
--~ 	print(ID,...)
--~ end)
--~ for i=1,16 do
--~ 	jq:pushJob("test",5)
--~ end
multi:mainloop()
