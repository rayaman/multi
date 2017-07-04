package.path="?/init.lua;"..package.path
require("multi")
multi:newAlarm(5):OnRing(function()
	os.exit(10)
end)
multi:mainloop()
