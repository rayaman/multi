require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
--IMPORTANT
-- Do not make the above local, this is the one difference that the lanesManager does not have
-- If these are local the functions will have the upvalues put into them that do not exist on the threaded side
-- You will need to ensure that the function does not refer to any upvalues in its code. It will print an error if it does though
-- Also each thread has a .1 second delay! This is used to generate a random values for each thread!
require("core.GuiManager")
gui.ff.Color=Color.Black
queue=multi:newSystemThreadedQueue("QUEUE"):init()
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
			t.text="Deleted a Global!"
			break
		end
		thread.skip() -- give cpu time to other processes
	end
end)
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
