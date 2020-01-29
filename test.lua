package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
a,b = 6,7
multi:newThread(function()
	function test()
		thread.sleep(1)
		return 1,2
	end
	a,b = test().wait()
	print("Waited:",a,b)
	--This returns instantly even though the function isn't done!
	test().connect(function(a,b)
		print("Connected:",a,b)
		os.exit()
	end)
	-- This waits for the returns since we are demanding them
end)
multi:newAlarm(2):OnRing(function()
	print(a,b)
end)
--min,hour,day,wday,month
multi:mainloop()
