package.path = "./?/init.lua;?.lua;lua5.4/share/lua/5.4/?/init.lua;lua5.4/share/lua/5.4/?.lua;"--..package.path
package.cpath = "lua5.4/lib/lua/5.4/?/core.dll;"--..package.cpath
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

local conn = multi:newSystemThreadedConnection("conn"):init()

multi:newSystemThread("Thread_Test_1",function()
	local multi, thread = require("multi"):init()
	local conn = GLOBAL["conn"]:init()
	local console = THREAD.getConsole()
	conn(function()
		console.print(THREAD:getName().." was triggered!")
	end)
	multi:mainloop()
end)

multi:newSystemThread("Thread_Test_2",function()
	local multi, thread = require("multi"):init()
	local conn = GLOBAL["conn"]:init()
	local console = THREAD.getConsole()
	conn(function(a,b,c)
		console.print(THREAD:getName().." was triggered!",a,b,c)
	end)
	multi:newAlarm(3):OnRing(function()
		console.print("Fire 2!!!")
		conn:Fire(4,5,6)
		--THREAD.kill()
	end)

	multi:mainloop()
end)

conn(function(a,b,c)
	print("Mainloop conn got triggered!",a,b,c)
end)

alarm = multi:newAlarm(1)
alarm:OnRing(function()
	print("Fire 1!!!")
	conn:Fire(1,2,3) 
end)

alarm = multi:newAlarm(3):OnRing(function()
	multi:newSystemThread("Thread_Test_3",function()
		local multi, thread = require("multi"):init()
		local conn = GLOBAL["conn"]:init()
		local console = THREAD.getConsole()
		conn(function(a,b,c)
			console.print(THREAD:getName().." was triggered!",a,b,c)
		end)
		multi:newAlarm(4):OnRing(function()
			console.print("Fire 3!!!")
			conn:Fire(7,8,9)
		end)
		multi:mainloop()
	end)
end)

multi:newSystemThread("Thread_Test_4",function()
	local multi, thread = require("multi"):init()
	local conn = GLOBAL["conn"]:init()
	local conn2 = multi:newConnection()
	local console = THREAD.getConsole()
	multi:newAlarm(2):OnRing(function()
		conn2:Fire()
	end)
	multi:newThread(function()
		console.print("Conn Test!")
		thread.hold(conn + conn2)
		console.print("It held!")
	end)
	multi:mainloop()
end)

multi:mainloop()