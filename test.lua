package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")

multi:newThread("TickTocker",function()
	print("Waiting for variable a to exist...")
	ret,ret2 = thread.hold(function()
		return a~=nil, "test!"
	end)
	print(ret,ret2) -- The hold method returns the arguments when the first argument is true. This methods return feature is rather new and took more work then you think to get working. Since threads
end)
multi:newAlarm(3):OnRing(function() a = true end) -- allows a to exist

multi:mainloop()

