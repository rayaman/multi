require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init{threadNamespace="THREAD"} -- load the love2d version of the lanesManager and requires the entire multi library
--IMPORTANT
-- Do not make the above local, this is the one difference that the lanesManager does not have
-- If these are local the functions will have the up-values put into them that do not exist on the threaded side
-- You will need to ensure that the function does not refer to any up-values in its code. It will print an error if it does though
-- Also each thread has a .1 second delay! This is used to generate a random values for each thread!
require("core.GuiManager") -- allows the use of graphics in the program.
gui.ff.Color=Color.Black
multi:newSystemThread("Test_Thread_1",function()
	require("multi")
	test = sThread.waitFor("testthing"):init()
	multi:newTLoop(function()
		print("------")
		for i,v in pairs(test.tab) do
			print("T1",i,v)
		end
	end,1)
	multi:mainloop()
end)
multi:newSystemThread("Test_Thread_1",function()
	require("multi")
	test = sThread.waitFor("testthing"):init()
	multi:newTLoop(function()
		print("------")
		for i,v in pairs(test.tab) do
			print("T2",i,v)
		end
	end,1)
	multi:mainloop()
end)
test = multi:newSystemThreadedTable("testthing"):init()
multi:newTLoop(function()
	local a,b = multi.randomString(8),multi.randomString(4)
	print(">",a,b)
	test[a]=b
end,1)