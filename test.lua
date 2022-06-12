package.path = "./?/init.lua;?.lua;lua5.4/share/lua/?/init.lua;lua5.4/share/lua/?.lua;"..package.path
package.cpath = "lua5.4/lib/lua/?/core.dll;"..package.cpath
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

test = THREAD:newFunction(function()
	PNT()
	return 1,2
end,true)
multi:newThread(function()
	while true do
		print("...")
		thread.sleep(1)
	end
end)
multi:newAlarm(.1):OnRing(function() os.exit() end)
print(test())
print("Hi!")

multi:mainloop()