package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi:newThread(function()
	function test()
		thread.sleep(1)
		return 1,2
	end
	--This returns instantly even though the function isn't done!
	test().connect(function(a,b)
		print("Connected:",a,b)
	end)
	-- This waits for the returns since we are demanding them
	a,b = test()
	print("Waited:",a,b)
	os.exit()
end)
--min,hour,day,wday,month
multi:mainloop()
