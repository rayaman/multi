package.path = "../?/init.lua;../?.lua;"..package.path
multi, thread = require("multi"):init{print=true,warn=true,error=true,debugging=true}
require("multi.integration.priorityManager")

multi.debugging.OnObjectCreated(function(obj, process)
	multi.print("Created:", obj.Type, "in", process.Type, process:getFullName())
end)

multi.debugging.OnObjectDestroyed(function(obj, process)
	multi.print("Destroyed:", obj.Type, "in", process.Type, process:getFullName())
end)

-- test = multi:newProcessor("Test")
-- test:setPriorityScheme(multi.priorityScheme.TimeBased)

-- test:newUpdater(10000000):OnUpdate(function()
-- 	print("Print is slowish")
-- end)

-- print("Running...")

-- local conn1, conn2 = multi:newConnection(), multi:newConnection()
-- conn3 = conn1 + conn2

-- conn1(function()
-- 	print("Hi 1")
-- end)

-- conn2(function()
-- 	print("Hi 2")
-- end)

-- conn3(function()
-- 	print("Hi 3")
-- end)

-- function test(a,b,c)
-- 	print("I run before all and control if execution should continue!")
-- 	return a>b
-- end

-- conn4 = test .. conn1

-- conn5 = conn2 .. function() print("I run after it all!") end

-- conn4:Fire(3,2,3)
-- -- This second one won't trigger the Hi's
-- conn4:Fire(1,2,3)

-- conn5(function()
-- 	print("Test 1")
-- end)

-- conn5(function()
-- 	print("Test 2")
-- end)

-- conn5(function()
-- 	print("Test 3")
-- end)

-- conn5:Fire()
multi.print("Testing thread:newProcessor()")

proc = thread:newProcessor("Test")

proc:newLoop(function()
	multi.print("Running...")
	thread.sleep(1)
end)

proc:newThread(function()
	while true do
		multi.warn("Everything is a thread in this proc!")
		thread.sleep(1)
	end
end)

proc:newAlarm(5):OnRing(function(a)
	multi.print(";) Goodbye")
	a:Destroy()
end)

multi:mainloop()


-- local conn1, conn2, conn3 = multi:newConnection(nil,nil,true), multi:newConnection(), multi:newConnection()

-- local link = conn1(function()
-- 	print("Conn1, first")
-- end)

-- local link2 = conn1(function()
-- 	print("Conn1, second")
-- end)

-- local link3 = conn1(function()
-- 	print("Conn1, third")
-- end)

-- local link4 = conn2(function()
-- 	print("Conn2, first")
-- end)

-- local link5 = conn2(function()
-- 	print("Conn2, second")
-- end)

-- local link6 = conn2(function()
-- 	print("Conn2, third")
-- end)

-- print("Links 1-6",link,link2,link3,link4,link5,link6)
-- conn1:Lock(link)
-- print("All conns\n-------------")
-- conn1:Fire()
-- conn2:Fire()

-- conn1:Unlock(link)

-- conn1:Unconnect(link3)
-- conn2:Unconnect(link6)
-- print("All conns Edit\n---------------------")
-- conn1:Fire()
-- conn2:Fire()

-- thread:newThread(function()
-- 	print("Awaiting status")
-- 	thread.hold(conn1 + (conn2 * conn3))
-- 	print("Conn or Conn2 and Conn3")
-- end)

-- multi:newAlarm(1):OnRing(function()
-- 	print("Conn")
-- 	conn1:Fire()
-- end)
-- multi:newAlarm(2):OnRing(function()
-- 	print("Conn2")
-- 	conn2:Fire()
-- end)
-- multi:newAlarm(3):OnRing(function()
-- 	print("Conn3")
-- 	conn3:Fire()
-- 	os.exit()
-- end)


-- local conn = multi:newSystemThreadedConnection("conn"):init()

-- multi:newSystemThread("Thread_Test_1", function()
-- 	local multi, thread = require("multi"):init()
-- 	local conn = GLOBAL["conn"]:init()
-- 	local console = THREAD.getConsole()
-- 	conn(function(a,b,c)
-- 		console.print(THREAD:getName().." was triggered!",a,b,c)
-- 	end)
-- 	multi:mainloop()
-- end)

-- multi:newSystemThread("Thread_Test_2", function()
-- 	local multi, thread = require("multi"):init()
-- 	local conn = GLOBAL["conn"]:init()
-- 	local console = THREAD.getConsole()
-- 	conn(function(a,b,c)
-- 		console.print(THREAD:getName().." was triggered!",a,b,c)
-- 	end)
-- 	multi:newAlarm(2):OnRing(function()
-- 		console.print("Fire 2!!!")
-- 		conn:Fire(4,5,6)
-- 		THREAD.kill()
-- 	end)

-- 	multi:mainloop()
-- end)
-- local console = THREAD.getConsole()
-- conn(function(a,b,c)
-- 	console.print("Mainloop conn got triggered!",a,b,c)
-- end)

-- alarm = multi:newAlarm(1)
-- alarm:OnRing(function()
-- 	console.print("Fire 1!!!")
-- 	conn:Fire(1,2,3) 
-- end)

-- alarm = multi:newAlarm(3):OnRing(function()
-- 	multi:newSystemThread("Thread_Test_3",function()
-- 		local multi, thread = require("multi"):init()
-- 		local conn = GLOBAL["conn"]:init()
-- 		local console = THREAD.getConsole()
-- 		conn(function(a,b,c)
-- 			console.print(THREAD:getName().." was triggered!",a,b,c)
-- 		end)
-- 		multi:newAlarm(4):OnRing(function()
-- 			console.print("Fire 3!!!")
-- 			conn:Fire(7,8,9)
-- 		end)
-- 		multi:mainloop()
-- 	end)
-- end)

-- multi:newSystemThread("Thread_Test_4",function()
-- 	local multi, thread = require("multi"):init()
-- 	local conn = GLOBAL["conn"]:init()
-- 	local conn2 = multi:newConnection()
-- 	local console = THREAD.getConsole()
-- 	multi:newAlarm(2):OnRing(function()
-- 		conn2:Fire()
-- 	end)
-- 	multi:newThread(function()
-- 		console.print("Conn Test!")
-- 		thread.hold(conn + conn2)
-- 		console.print("It held!")
-- 	end)
-- 	multi:mainloop()
-- end)

-- multi:mainloop()