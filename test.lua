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
	thread.sleep(1) -- Internally this throws a yield call which sends to the scheduler to sleep 1 second for this thread!
	return 1,math.random(2,100)
end)
multi:newThread(function()
	while true do
		thread.skip()
		co = co + 1
	end
end)
-- We can get around the yielding across metamethods by using a threadedFunction
-- For Example
example = {}
setmetatable(example,{
	__newindex = function(t,k,v) -- Using a threaded function inside of a normal function
		print("Inside metamethod",t,k,v)
		local a,b = test().wait() -- This function holds the code and "yields" see comment inside the test function!
		-- we should see a 1 seconde delay since the function sleeps for a second than returns
		print("We did it!",a,b)
		rawset(t,k,v)
		-- This means by using a threaded function we can get around the yielding across metamethods.
		-- This is useful if you aren't using luajit, or if you using lua in an enviroment that is on version 5.1
		-- There is a gotcha however, if using code that was meant to work with another coroutine based scheduler this may not work
	end,
	__index = thread:newFunction(function(t,k,v) -- Using a threaded function as the metamethod
		-- This works by returning a table with a __call metamethod. Will this work? Will lua detect this as a function or a table?
		thread.sleep(1)
		return "You got a string"
	end,true) -- Tell the code to force a wait and to identify as a function. We need to do this for metamethods
	-- If we don't pass true this is a table with a __call metamethod
})
example["test"] = "We set a variable!"
print(example["test"])
print(example.hi)
-- When not in a threaded enviroment at root level we need to tell the code that we are waiting! Alternitavely after the function argument we can pass true to force a wait 
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