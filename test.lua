package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi.OnLoad(function()
	print("Code Loaded!")
end)
t = os.clock()
co = 0
multi.OnExit(function(n)
	print("Code Exited: ".. os.clock()-t .." Count: ".. co)
end)
test = thread:newFunction(function()
	thread.sleep(1)
	return 1,math.random(2,100)
end)
multi:newThread(function()
	while true do
		thread.skip()
		co = co + 1
	end
end)
-- When not in a threaded enviroment at root level we need to tell the code that we are waiting!
c,d = test().wait()
print(c,d)
a,b = 6,7
multi:newThread(function()
	-- a,b = test().wait() -- Will modify Global
	-- when wait is used the special metamethod routine is not triggered and variables are set as normal
	a,b = test() -- Will modify GLocal
	-- the threaded function test triggers a special routine within the metamethod that alters the thread's enviroment instead of the global enviroment. 
	print("Waited:",a,b)
	--This returns instantly even though the function isn't done!
	test().connect(function(a,b)
		print("Connected:",a,b)
		os.exit()
	end)
	-- This waits for the returns since we are demanding them
end)
multi:mainloop()