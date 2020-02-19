package.path="?.lua;?/init.lua;?.lua;"..package.path
local multi, thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.lanesManager"):init()
serv = multi:newService(function(self,data)
	print("Service Uptime: ",self:GetUpTime(),data.test)
end)
serv.OnError(function(...)
	print(...)
end)
serv.OnStarted(function(self,data)
	print("Started!",self.Type,data)
	data.test = "Testing..."
	-- self as reference to the object and data is a reference to the datatable that the service has access to
end)
serv:Start()
serv:SetPriority(multi.Priority_Idle)
t = THREAD:newFunction(function(...)
	print("This is a system threaded function!",...)
	THREAD.sleep(1) -- This is handled within a system thread! Note: this creates a system thread that runs then ends.
	return "We done!"
end)
print(t("hehe",1,2,3,true).connect(function(...)
	print("connected:",...)
end)) -- The same features that work with thread:newFunction() are here as well
multi.OnLoad(function()
	print("Code Loaded!") -- Connect to the load event
end)
t = os.clock()
co = 0
multi.OnExit(function(n)
	print("Code Exited: ".. os.clock()-t .." Count: ".. co) -- Lets print when things have ended
end)
test = thread:newFunction(function()
	thread.sleep(1) -- Internally this throws a yield call which sends to the scheduler to sleep 1 second for this thread!
	return 1,math.random(2,100)
end)
multi:newThread(function()
	while true do
		thread.skip() -- Even though we have a few metamethods "yielding" I used this as an example of things still happening and counting. It connects to the Code Exited event later on.
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
	end,true) -- Tell the code to force a wait. We need to do this for metamethods
})
example["test"] = "We set a variable!"
print(example["test"])
print(example.hi)
-- When not in a threaded enviroment at root level we need to tell the code that we are waiting! Alternitavely after the function argument we can pass true to force a wait 
c,d = test().wait()
print(c,d)
a,b = 6,7
multi:newThread(function()
	a,b = test().wait() -- Will modify Global
	print("Waited:",a,b)

	--This returns instantly even though the function isn't done!
	print("called")
	test().connect(function(a,b)
		print("Connected:",a,b)
		os.exit()
	end)
	print("Returned")
	-- This waits for the returns since we are demanding them
end)
local test = multi:newSystemThreadedJobQueue(4) -- Load up a queue that has 4 running threads
func = test:newFunction("test",function(a) -- register a function on the queue that has an async function feature
	test2() -- Call the other registered function on the queue
	return a..a
end,true)
func2 = test:newFunction("test2",function(a)
	print("ooo")
	console = THREAD:getConsole() 
	console.print("Hello!",true)
end,true) -- When called internally on the job queue the function is a normal sync function and not an async function.
multi:scheduleJob({min = 15, hour = 14},function()
	-- This function will be called once everyday at 2:15
	-- Using a combination of the values above you are able to schedule a time 
end)
print(func("1"))
print(func("Hello"))
print(func("sigh"))
multi:lightloop()