package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi:scheduleJob({min = 15, hour = 14},function()
	print("hi!")
end)
--min,hour,day,wday,month
multi:mainloop()
