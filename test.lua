package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
alarm=multi:newAlarm(3) -- in seconds can go to .001 uses the built in os.clock()
alarm:OnRing(function(a)
	print("3 Seconds have passed!")
	a:Reset(n) -- if n were nil it will reset back to 3, or it would reset to n seconds
end)
multi:mainloop()
