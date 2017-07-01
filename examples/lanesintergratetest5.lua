package.path="?/init.lua;"..package.path -- slightly different usage of the code
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
queue=multi:newSystemThreadedQueue("QUEUE")
queue:push(1)
queue:push(2)
queue:push(3)
queue:push(4)
queue:push(5)
queue:push(6)
multi:newSystemThread("STHREAD_1",function()
	queue=sThread.waitFor("QUEUE"):init()
	GLOBAL["QUEUE"]=nil
	data=queue:pop()
	while data do
		print(data)
		data=queue:pop()
	end
end)
multi:newThread("THREAD_1",function()
	while true do
		if GLOBAL["QUEUE"]==nil then
			print("Deleted a Global!")
			break
		end
		thread.skip(1)
	end
end)
multi:mainloop()
