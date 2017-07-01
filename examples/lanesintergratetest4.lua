local GLOBAL,sThread=require("multi.integration.lanesManager").init()
queue=multi:newSystemThreadedQueue("QUEUE"):init()
queue:push("This is a test")
queue:push("This is a test2")
queue:push("This is a test3")
queue:push("This is a test4")
multi:newSystemThread("test2",function()
	queue=sThread.waitFor("QUEUE"):init()
	data=queue:pop()
	while data do
		print(data)
		data=queue:pop()
	end
	queue:push("This is a test5")
	queue:push("This is a test6")
	queue:push("This is a test7")
	queue:push("This is a test8")
end)
multi:newThread("test!",function() -- this is a lua thread
	thread.sleep(.1)
	data=queue:pop()
	while data do
		print(data)
		data=queue:pop()
	end
end)
multi:mainloop()
