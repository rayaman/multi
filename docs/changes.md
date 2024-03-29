# Changelog
Table of contents
---
[Update 16.0.1 - Bug fix](#update-1531---bug-fix)</br>
[Update 16.0.0 - Connecting the dots](#update-1600---getting-the-priorities-straight)</br>
[Update 15.3.1 - Bug fix](#update-1531---bug-fix)</br>
[Update 15.3.0 - A world of connections](#update-1530---a-world-of-connections)</br>
[Update 15.2.1 - Bug fix](#update-1521---bug-fix)</br>
[Update 15.2.0 - Upgrade Complete](#update-1520---upgrade-complete)</br>
[Update 15.1.0 - Hold the thread!](#update-1510---hold-the-thread)</br>
[Update 15.0.0 - The art of faking it](#update-1500---the-art-of-faking-it)</br>
[Update 14.2.0 - Bloatware Removed](#update-1420---bloatware-removed)</br>
[Update 14.1.0 - A whole new world of possibilities](#update-1410---a-whole-new-world-of-possibilities)</br>
[Update 14.0.0 - Consistency, Additions and Stability](#update-1400---consistency-additions-and-stability)</br>
[Update 13.1.0 - Bug fixes and features added](#update-1310---bug-fixes-and-features-added)</br>
[Update 13.0.0 - Added some documentation, and some new features too check it out!](#update-1300---added-some-documentation-and-some-new-features-too-check-it-out)</br>
[Update 12.2.2 - Time for some more bug fixes!](#update-1222---time-for-some-more-bug-fixes)</br>
[Update 12.2.1 - Time for some bug fixes!](#update-1221---time-for-some-bug-fixes)</br>
[Update 12.2.0 - The chains of binding](#update-1220---the-chains-of-binding)</br>
[Update 12.1.0 - Threads just can't hold on anymore](#update-1210---threads-just-cant-hold-on-anymore)</br>
[Update: 12.0.0 - Big update (Lots of additions some changes)](#update-1200---big-update-lots-of-additions-some-changes)</br>
[Update: 1.11.1 - Small Clarification on Love](#update-1111---small-clarification-on-love)</br>
[Update: 1.11.0](#update-1110)</br>
[Update: 1.10.0](#update-1100)</br>
[Update: 1.9.2](#update-192)</br>
[Update: 1.9.1 - Threads can now argue](#update-191---threads-can-now-argue)</br>
[Update: 1.9.0](#update-190)</br>
[Update: 1.8.7](#update-187)</br>
[Update: 1.8.6](#update-186)</br>
[Update: 1.8.5](#update-185)</br>
[Update: 1.8.4](#update-184)</br>
[Update: 1.8.3 - Mainloop recieves some needed overhauling](#update-183---mainloop-recieves-some-needed-overhauling)</br>
[Update: 1.8.2](#update-182)</br>
[Update: 1.8.1](#update-181)</br>
[Update: 1.7.6](#update-176)</br>
[Update: 1.7.5](#update-175)</br>
[Update: 1.7.4](#update-174)</br>
[Update: 1.7.3](#update-173)</br>
[Update: 1.7.2](#update-172)</br>
[Update: 1.7.1 - Bug Fixes Only](#update-171---bug-fixes-only)</br>
[Update: 1.7.0 - Threading the systems](#update-170---threading-the-systems)</br>
[Update: 1.6.0](#update-160)</br>
[Update: 1.5.0](#update-150)</br>
[Update: 1.4.1 (4/10/2017) - First Public release of the library](#update-141-4102017---first-public-release-of-the-library)</br>
[Update: 1.4.0 (3/20/2017)](#update-140-3202017)</br>
[Update: 1.3.0 (1/29/2017)](#update-130-1292017)</br>
[Update: 1.2.0 (12.31.2016)](#update-120-12312016)</br>
[Update: 1.1.0](#update-110)</br>
[Update: 1.0.0](#update-100)</br>
[Update: 0.6.3](#update-063)</br>
[Update: 0.6.2](#update-062)</br>
[Update: 0.6.1-6](#update-061-6)</br>
[Update: 0.5.1-6](#update-051-6)</br>
[Update: 0.4.1](#update-041)</br>
[Update: 0.3.0 - The update that started it all](#update-030---the-update-that-started-it-all)</br>
[Update: EventManager 2.0.0](#update-eventmanager-200)</br>
[Update: EventManager 1.2.0](#update-eventmanager-120)</br>
[Update: EventManager 1.1.0](#update-eventmanager-110)</br>
[Update: EventManager 1.0.0 - Error checking](#update-eventmanager-100---error-checking)</br>
[Version: EventManager 0.0.1 - In The Beginning things were very different](#version-eventmanager-001---in-the-beginning-things-were-very-different)

# Update 16.0.1 - Bug fix
Fixed
---
- thread.pushStatus() wasn't properly working when forwarding events from THREAD.pushStatus OnStatus connection. This bug also caused stack overflow errors with the following code
```lua
func = thread:newFunction(function()
	for i=1,10 do
		thread.sleep(1)
		thread.pushStatus(i)
	end
end)

func2 = thread:newFunction(function()
	local ref = func()
	ref.OnStatus(function(num)
		-- do stuff with this data

		thread.pushStatus(num*2) -- Technically this is not ran within a thread. This is ran outside of a thread inside the thread handler. 
	end)
end)

local handler = func2()
handler.OnStatus(function(num)
	print(num)
end)

multi:mainloop()
```

# Update 16.0.0 - Getting the priorities straight

## Added New Integration: **priorityManager**

Allows the user to have multi auto set priorities (Requires chronos). Also adds the functionality to create your own runners (multi:mainloop(), multi:umanager()) that you can set using the priority manager. Even if you do not have `chronos` installed all other features will still work!
- Allows the creation of custom priorityManagers

Added
---
- thread.defer(func) -- When using a co-routine thread or co-routine threaded function, defer will call it's function at the end of the the threads life through normal execution or an error. In the case of a threaded function, when the function returns or errors.
- multi:setTaskDelay(delay), Tasks which are now tied to a processor can have an optional delay between the execution between each task. Useful perhaps for rate limiting. Without a delay all grouped tasks will be handled in one step. `delay` can be a function as well and will be processed as if thread.hold was called.
- processor's now have a boost function which causes it to run its processes the number of times specified in the `boost(count)` function
- thread.hold will now use a custom hold method for objects with a `Hold` method. This is called like `obj:Hold(opt)`. The only argument passed is the optional options table that thread.hold can pass. There is an exception for connection objects. While they do contain a Hold method, the Hold method isn't used and is there for proxy objects, though they can be used in non proxy/thread situations. Hold returns all the arguments that the connection object was fired with.
- shared_table = STP:newSharedTable(tbl_name) -- Allows you to create a shared table that all system threads in a process have access to. Returns a reference to that table for use on the main thread. Sets `_G[tbl_name]` on the system threads so you can access it there.
	```lua
	package.path = "?/init.lua;?.lua;"..package.path

	multi, thread = require("multi"):init({print=true})
	THREAD, GLOBAL = require("multi.integration.lanesManager"):init()

	stp = multi:newSystemThreadedProcessor(8)

	local shared = stp:newSharedTable("shared")

	shared["test"] = "We work!"

	for i=1,5 do
		-- There is a bit of overhead when creating threads on a process. Takes some time, mainly because we are creating a proxy.
		stp:newThread(function()
			local multi, thread = require("multi"):init()
			local shared = _G["shared"]
			print(THREAD_NAME, shared.test, shared.test2)
			multi:newAlarm(.5):OnRing(function() -- Play around with the time. System threads do not create instantly. They take quite a bit of time to get spawned.
				print(THREAD_NAME, shared.test, shared.test2)
			end)
		end)
	end

	shared["test2"] = "We work!!!"

	multi:mainloop()
	```

	Output:
	```
	INFO: Integrated Lanes Threading!
	STJQ_cPXT8GOx   We work!        nil
	STJQ_hmzdYDVr   We work!        nil
	STJQ_3lwMhnfX   We work!        nil
	STJQ_hmzdYDVr   We work!        nil
	STJQ_cPXT8GOx   We work!        nil
	STJQ_cPXT8GOx   We work!        We work!!!
	STJQ_hmzdYDVr   We work!        We work!!!
	STJQ_3lwMhnfX   We work!        We work!!!
	STJQ_hmzdYDVr   We work!        We work!!!
	STJQ_cPXT8GOx   We work!        We work!!!
	```

- multi:chop(obj) -- We cannot directly interact with a local object on lanes, so we chop the object and set some globals on the thread side. Should use like: `mulit:newProxy(multi:chop(multi:newThread(function() ...  end)))`
- multi:newProxy(ChoppedObject) -- Creates a proxy object that allows you to interact with an object on a thread
	
	**Note:** Objects with __index=table do not work with the proxy object! The object must have that function in it's own table for proxy to pick it up and have it work properly. Connections on a proxy allow you to subscribe to an event on the thread side of things. The function that is being connected to happens on the thread!
- multi:newSystemThreadedProcessor(name) -- Works like newProcessor(name) each object created returns a proxy object that you can use to interact with the objects on the system thread
	```lua
	package.path = "?/init.lua;?.lua;"..package.path

	multi, thread = require("multi"):init({print=true})
	THREAD, GLOBAL = require("multi.integration.lanesManager"):init()

	stp = multi:newSystemThreadedProcessor("Test STP")

	alarm = stp:newAlarm(3)

	alarm._OnRing:Connect(function(alarm)
		print("Hmm...", THREAD_NAME)
	end)
	```
	Output:
	```
	Hmm...  SystemThreadedJobQueue_A5tp
	```
	Internally the SystemThreadedProcessor uses a JobQueue to handle things. The proxy function allows you to interact with these objects as if they were on the main thread, though there actions are carried out on the main thread.

	Proxies can also be shared between threads, just remember to use proxy:getTransferable() before transferring and proxy:init() on the other end. (We need to avoid copying over coroutines)

	The work done with proxies negates the usage of multi:newSystemThreadedConnection(), the only difference is you lose the metatables from connections.

	You cannot connect directly to a proxy connection on the non proxy thread, you can however use proxy_conn:Hold() or thread.hold(proxy_conn) to emulate this, see below.

	```lua
	package.path = "?/init.lua;?.lua;"..package.path

	multi, thread = require("multi"):init({print=true, warn=true, error=true})
	THREAD, GLOBAL = require("multi.integration.lanesManager"):init()

	stp = multi:newSystemThreadedProcessor(8)

	tloop = stp:newTLoop(nil, 1)

	multi:newSystemThread("Testing proxy copy",function(tloop)
		local function tprint (tbl, indent)
			if not indent then indent = 0 end
			for k, v in pairs(tbl) do
				formatting = string.rep("  ", indent) .. k .. ": "
				if type(v) == "table" then
					print(formatting)
					tprint(v, indent+1)
				else
					print(formatting .. tostring(v))      
				end
			end
		end
		local multi, thread = require("multi"):init()
		tloop = tloop:init()
		print("tloop type:",tloop.Type)
		print("Testing proxies on other threads")
		thread:newThread(function()
			while true do
				thread.hold(tloop.OnLoop)
				print(THREAD_NAME,"Loopy")
			end
		end)
		tloop.OnLoop(function(a)
			print(THREAD_NAME, "Got loop...")
		end)
		multi:mainloop()
	end, tloop:getTransferable()).OnError(multi.error)

	print("tloop", tloop.Type)

	thread:newThread(function()
		print("Holding...")
		thread.hold(tloop.OnLoop)
		print("Held on proxied no proxy connection 1")
	end).OnError(print)

	thread:newThread(function()
		tloop.OnLoop:Hold()
		print("held on proxied no proxy connection 2")
	end)

	tloop.OnLoop(function()
		print("OnLoop",THREAD_NAME)
	end)

	thread:newThread(function()
		while true do
			tloop.OnLoop:Hold()
			print("OnLoop",THREAD_NAME)
		end
	end).OnError(multi.error)

	multi:mainloop()
	```
	Output:
	```
	INFO: Integrated Lanes Threading! 1
	tloop   proxy
	Holding...
	tloop type:     proxy
	Testing proxies on other threads
	OnLoop  STJQ_W9SZGB6Y
	STJQ_W9SZGB6Y   Got loop...
	OnLoop  MAIN_THREAD
	Testing proxy copy      Loopy
	Held on proxied no proxy connection 1
	held on proxied no proxy connection 2
	OnLoop  STJQ_W9SZGB6Y
	STJQ_W9SZGB6Y   Got loop...
	Testing proxy copy      Loopy
	OnLoop  MAIN_THREAD
	OnLoop  STJQ_W9SZGB6Y
	STJQ_W9SZGB6Y   Got loop...

	... (Will repeat every second)

	Testing proxy copy      Loopy
	OnLoop  MAIN_THREAD
	OnLoop  STJQ_W9SZGB6Y
	STJQ_W9SZGB6Y   Got loop...

	...
	```

	The proxy version can only subscribe to events on the proxy thread, which means that connection metamethods will not work with the proxy version (`_OnRing` on the non proxy thread side), but the (`OnRing`) version will work. Cleverly handling the proxy thread and the non proxy thread will allow powerful connection logic. Also this is not a full system threaded connection. **Proxies should only be used between 2 threads!** To keep things fast I'm using simple queues to transfer data. There is no guarantee that things will work!

	Currently supporting:
	- proxyLoop = STP:newLoop(...)
	- proxyTLoop = STP:newTLoop(...)
	- proxyUpdater = STP:newUpdater(...)
	- proxyEvent = STP:newEvent(...)
	- proxyAlarm = STP:newAlarm(...)
	- proxyStep = STP:newStep(...)
	- proxyTStep = STP:newTStep(...)
	- proxyThread = STP:newThread(...)
	- proxyService = STP:newService(...)
	- threadedFunction = STP:newFunction(...)

	Unique:
	- STP:newSharedTable(name)
	
	</br>

	**STP** functions (The ones above) cannot be called within coroutine based thread when using lanes. This causes thread.hold to break. Objects(proxies) returned by these functions are ok to use in coroutine based threads!
	```lua
	package.path = "?/init.lua;?.lua;"..package.path

	multi, thread = require("multi"):init({print=true})
	THREAD, GLOBAL = require("multi.integration.lanesManager"):init()

	stp = multi:newSystemThreadedProcessor()

	alarm = stp:newAlarm(3)

	alarm.OnRing:Connect(function(alarm)
		print("Hmm...", THREAD_NAME)
	end)

	thread:newThread(function()
		print("Holding...")
		local a = thread.hold(alarm.OnRing) -- it works :D
		print("We work!")
	end)

	multi:mainloop()
	```

- multi.OnObjectDestroyed(func(obj, process)) now supplies obj, process just like OnObjectCreated
- thread:newProcessor(name) -- works mostly like a normal process, but all objects are wrapped within a thread. So if you create a few loops, you can use thread.hold() call threaded functions and wait and use all features that using coroutines provide.
- multi.Processors:getHandler() -- returns the thread handler for a process
- multi.OnPriorityChanged(self, priority) -- Connection is triggered whenever the priority of an object is changed!
- multi.setClock(clock_func) -- If you have access to a clock function that works like os.clock() you can set it using this function. The priorityManager if chronos is installed sets the clock to it's current version.
- multi:setCurrentTask() -- Used to set the current processor. Used in custom processors.
- multi:setCurrentProcess() -- Used to set the current processor. It should only be called on a processor object
- multi.success(...) -- Sends a success. Green `SUCCESS` mainly used for tests
- multi.warn(...) -- Sends a warning. Yellow `WARNING`
- multi.error(err) -- When called this function will gracefully kill multi, cleaning things up. Red `ERROR`
	
	**Note:** If you want to have multi.print, multi.warn and multi.error to work you need to enable them in settings 
	```lua
	multi, thread = require("multi"):init {
		print=true,
		warn=true,
		error=true -- Errors will throw regardless. Setting to true will
		-- cause the library to force hard crash itself!
	}
	```
- THREAD.exposeEnv(name) -- Merges set env into the global namespace of the system thread it was called in.
- THREAD.setENV(table [, name]) -- Set a simple table that will be merged into the global namespace. If a name is supplied the global namespace will not be merged. Call THREAD.exposeEnv(name) to expose that namespace within a thread. 
	
	**Note:** To maintain compatibility between each integration use simple tables. No self references, and string indices only.
	```lua
	THREAD.setENV({
		shared_function = function()
			print("I am shared!")
		end
	})
	```
	When this function is used it writes to a special variable that is read at thread spawn time. If this function is then ran later it can be used to set a different env and be applied to future spawned threads.
- THREAD.getENV() can be used to manage advanced uses of the setENV() functionality
- Connection objects now support the % function. This supports a function % connection object. What it does is allow you to **mod**ify the incoming arguments of a connection event.
	```lua
	local conn1 = multi:newConnection()
	local conn2 = function(a,b,c) return a*2, b*2, c*2 end % conn1
	conn2(function(a,b,c)
		print("Conn2",a,b,c)
	end)
	conn1(function(a,b,c)
		print("Conn1",a,b,c)
	end)
	conn1:Fire(1,2,3)
	conn2:Fire(1,2,3)
	```
	Output:
	```
	Conn2   2       4       6
	Conn1   1       2       3
	Conn2	1		2		3
	```
	**Note:** Conn1 does not get modified, however firing conn1 will also fire conn2 and have it's arguments modified. Also firing conn2 directly **does not** modify conn2's arguments!
	See it's implementation below:
	```lua
	__mod = function(obj1, obj2)
		local cn = multi:newConnection()
		if type(obj1) == "function" and type(obj2) == "table" then
			obj2(function(...)
				cn:Fire(obj1(...))
			end)
		else
			error("Invalid mod!", type(obj1), type(obj2),"Expected function, connection(table)")
		end
		return cn
	end
	```
- The len operator `#` will return the number of connections in the object!
	```
		local conn = multi:newConnection()
		conn(function() print("Test 1") end)
		conn(function() print("Test 2") end)
		conn(function() print("Test 3") end)
		conn(function() print("Test 4") end)
		print(#conn)
	```
	Output:
	```
	4
	```
- Connection objects can be negated -conn returns self so conn = -conn, reverses the order of connection events
	```lua
	local conn = multi:newConnection()
	conn(function() print("Test 1") end)
	conn(function() print("Test 2") end)
	conn(function() print("Test 3") end)
	conn(function() print("Test 4") end)

	print("Fire 1")
	conn:Fire()
	conn = -conn
	print("Fire 2")
	conn:Fire()
	```
	Output:
	```
	Fire 1
	Test 1
	Test 2
	Test 3
	Test 4
	Fire 2
	Test 4
	Test 3
	Test 2
	Test 1
	```
- Connection objects can be divided, function / connection
	This is a mix between the behavior between mod and concat, where the original connection can forward it's events to the new one as well as do a check like concat can. View it's implementation below:
	```lua
	__div = function(obj1, obj2) -- /
		local cn = self:newConnection()
		local ref
		if type(obj1) == "function" and type(obj2) == "table" then
			obj2(function(...)
				local args = {obj1(...)}
				if args[1] then
					cn:Fire(multi.unpack(args))
				end
			end)
		else
			multi.error("Invalid divide! ", type(obj1), type(obj2)," Expected function/connection(table)")
		end
		return cn
	end
	```
- Connection objects can now be concatenated with functions, not each other. For example:
	```lua
	multi, thread = require("multi"):init{print=true,findopt=true}

	local conn1, conn2 = multi:newConnection(), multi:newConnection()
	conn3 = conn1 + conn2

	conn1(function()
		print("Hi 1")
	end)

	conn2(function()
		print("Hi 2")
	end)

	conn3(function()
		print("Hi 3")
	end)

	function test(a,b,c)
		print("I run before all and control if execution should continue!")
		return a>b
	end

	conn4 = test .. conn1

	conn5 = conn2 .. function() print("I run after it all!") end

	conn4:Fire(3,2,3)

	-- This second one won't trigger the Hi's	
	conn4:Fire(1,2,3)

	conn5(function()
		print("Test 1")
	end)

	conn5(function()
		print("Test 2")
	end)

	conn5(function()
		print("Test 3")
	end)

	conn5:Fire()
	```

	Output:
	```
	I run before all and control if things go!
	Hi 3
	Hi 1
	Test 1
	Test 2
	Test 3
	I run after it all!
	```

	**Note:** Concat of connections does modify internal events on both connections depending on the direction func .. conn or conn .. func See implemention below:
	```lua
	__concat = function(obj1, obj2)
		local cn = multi:newConnection()
		local ref
		if type(obj1) == "function" and type(obj2) == "table" then
			cn(function(...)
				if obj1(...) then
					obj2:Fire(...)
				end
			end)
			cn.__connectionAdded = function(conn, func)
				cn:Unconnect(conn)
				obj2:Connect(func)
			end
		elseif type(obj1) == "table" and type(obj2) == "function" then
			ref = cn(function(...)
				obj1:Fire(...)
				obj2(...)
			end)
			cn.__connectionAdded = function()
				cn.rawadd = true
				cn:Unconnect(ref)
				ref = cn(function(...)
					if obj2(...) then
						obj1:Fire(...)
					end
				end)
			end
		else
			error("Invalid concat!", type(obj1), type(obj2),"Expected function/connection(table), connection(table)/function")
		end
		return cn
	end
	```

Changed
---
- multi:newTask(task) is not tied to the processor it is created on.
- `multi:getTasks()` renamed to `multi:getRunners()`, should help with confusion between multi:newTask()
- changed how multi adds unpack to the global namespace. Instead we capture that value into multi.unpack.
- multi:newUpdater(skip, func) -- Now accepts func as the second argument. So you don't need to call OnUpdate(func) after creation. 
- multi errors now internally call `multi.error` instead of `multi.print`
- Actors Act() method now returns true when the main event is fired. Steps/Loops always return true. Nil is returned otherwise.
- Connection:Connect(func, name) Now you can supply a name and name the connection.
- Connection:getConnection(name) This will return the connection function which you can do what you will with it.
- Fast connections are the only connections. Legacy connections have been removed completely. Not much should change on the users end. Perhaps some minor changes.
- conn:Lock(conn) When supplied with a connection reference (What is returned by Connect(func)) it will only lock that connection Reference and not the entire connection. Calling without any arguments will lock the entire connection.
- connUnlock(conn) When supplied with a connection reference it restores that reference and it can be fired again. When no arguments are supplied it unlocks the entire connection.

	**Note:** Lock and Unlock when supplied with arguments and not supplied with arguments operate on different objects. If you unlock an entire connection. Individual connection refs will not unlock. The same applies with locking. The entire connection and references are treated differently.

- multi.OnObjectCreated is only called when an object is created in a particular process. Proc.OnObjectCreated is needed to detect when an object is created within a process.
- multi.print shows "INFO" before it's message. Blue `INFO`
- Connections internals changed, not too much changed on the surface.
- newConnection(protect, func, kill)
	- `protect` disables fastmode, but protects the connection
	- `func` uses `..` and appends func to the connection so it calls it after all connections run. There is some internal overhead added when using this, but it isn't much.
	- `kill` removes the connection when fired
	
	**Note:** When using protect/kill connections are triggered in reverse order

Removed
---
- multi.CONNECTOR_LINK -- No longer used
- multi:newConnector() -- No longer used
- THREAD.getName() use THREAD_NAME instead
- THREAD.getID() use THREAD_ID instead
- conn:SetHelper(func) -- With the removal of old Connect this function is no longer needed
- connection events can no longer can be chained with connect. Connect only takes a function that you want to connect

Fixed
---
- Issue with luajit w/5.2 compat breaking with coroutine.running(), fixed the script to properly handle so thread.isThread() returns as expected!
- Issue with coroutine based threads where they weren't all being scheduled due to a bad for loop. Replaced with a while to ensure all threads are consumed properly. If a thread created a thread that created a thread that may or may not be on the same process, things got messed up due to the original function not being built with these abstractions in mind.
- Issue with thread:newFunction() where a threaded function will keep a record of their returns and pass them to future calls of the function.
- Issue with multi:newTask(func) not properly handling tasks to be removed. Now uses a thread internally to manage things.
- multi.isMainThread was not properly handled in each integration. This has been resolved.
- Issue with pseudo threading env's being messed up. Required removal of getName and getID!
- connections being multiplied together would block the entire connection object from pushing events! This is not the desired effect I wanted. Now only the connection reference involved in the multiplication is locked!
- multi:reallocate(processor, index) has been fixed to work with the current changes of the library.
- Issue with lanes not handling errors properly. This is now resolved
- Oversight with how pushStatus worked with nesting threaded functions, connections and forwarding events. Changes made and this works now!
	```lua
	func = thread:newFunction(function()
		for i=1,10 do
			thread.sleep(1)
			thread.pushStatus(i)
		end
	end)

	func2 = thread:newFunction(function()
		local ref = func()
		ref.OnStatus(function(num)
			-- do stuff with this data

			thread.pushStatus(num*2) -- Technically this is not ran within a thread. This is ran outside of a thread inside the thread handler. 
		end)
	end)

	local handler = func2()
	handler.OnStatus(function(num)
		print(num)
	end)
	```

ToDo
---
- Network Manager, I know I said it will be in this release, but I'm still planning it out.

# Update 15.3.1 - Bug fix
Fixed
---
- Issue where multiplying connections triggered events improperly
```lua
local multi, thread = require("multi"):init()
conn1 = multi:newConnection()
conn2 = multi:newConnection(); -- To remove function ambiguity

(conn1 * conn2)(function() print("Triggered!") end)

conn1:Fire()
conn2:Fire()

-- Looks like this is triggering a response. It shouldn't. We need to account for this
conn1:Fire()
conn1:Fire()
-- Triggering conn1 twice counted as a valid way to trigger the virtual connection (conn1 * conn2)

-- Now in 15.3.1, this works properly and the above doesn't do anything. Internally connections are locked until the conditions are met.
conn2:Fire()
```

# Update 15.3.0 - A world of Connections

Full Update Showcase
```lua
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

local conn = multi:newSystemThreadedConnection("conn"):init()

multi:newSystemThread("Thread_Test_1",function()
	local multi, thread = require("multi"):init()
	local conn = GLOBAL["conn"]:init()
	conn(function()
		print(THREAD:getName().." was triggered!")
	end)
	multi:mainloop()
end)

multi:newSystemThread("Thread_Test_2",function()
	local multi, thread = require("multi"):init()
	local conn = GLOBAL["conn"]:init()
	conn(function(a,b,c)
		print(THREAD:getName().." was triggered!",a,b,c)
	end)
	multi:newAlarm(2):OnRing(function()
		print("Fire 2!!!")
		conn:Fire(4,5,6)
		THREAD.kill()
	end)

	multi:mainloop()
end)

conn(function(a,b,c)
	print("Mainloop conn got triggered!",a,b,c)
end)

alarm = multi:newAlarm(1)
alarm:OnRing(function()
	print("Fire 1!!!")
	conn:Fire(1,2,3) 
end)

alarm = multi:newAlarm(3):OnRing(function()
	multi:newSystemThread("Thread_Test_3",function()
		local multi, thread = require("multi"):init()
		local conn = GLOBAL["conn"]:init()
		conn(function(a,b,c)
			print(THREAD:getName().." was triggered!",a,b,c)
		end)
		multi:newAlarm(2):OnRing(function()
			print("Fire 3!!!")
			conn:Fire(7,8,9)
		end)
		multi:mainloop()
	end)
end)

multi:newSystemThread("Thread_Test_4",function()
	local multi, thread = require("multi"):init()
	local conn = GLOBAL["conn"]:init()
	local conn2 = multi:newConnection()
	multi:newAlarm(2):OnRing(function()
		conn2:Fire()
	end)
	multi:newThread(function()
		print("Conn Test!")
		thread.hold(conn + conn2)
		print("It held!")
	end)
	multi:mainloop()
end)

multi:mainloop()
```

Added
---
- `multi:newConnection():Unconnect(conn_link)` Fastmode previously didn't have the ability to be unconnected to. This method works with both fastmode and non fastmode. `fastMode` will be made the default in v16.0.0 (This is a breaking change for those using the Destroy method, use this time to migrate to using `Unconnect()`)
- `thread.chain(...)` allows you to chain `thread.hold(FUNCTIONs)` together
	```lua
	while true do
		thread.chain(hold_function_1, hold_function_2)
	end
	```
	If the first function returns true, it moves on to the next one. if expanded it follows:
	```lua
	while true do
		thread.hold(hold_function_1)
		thread.hold(hold_function_2)
	end
	```
- Experimental option to multi settings: `findopt`. When set to `true` it will print out a message when certain pattern are used with this library. For example if an anonymous function is used in thread.hold() within a loop. The library will trigger a message alerting you that this isn't the most performant way to use thread.hold().
- `multi:newSystemThreadedConnection()`

	Allows one to trigger connection events across threads. Works like how any connection would work. Supports all of the features, can even be `added` with non SystemThreadedConnections as demonstrated in the full showcase.
- `multi:newConnection():SetHelper(func)`

	Sets the helper function that the connection object uses when creating connection links.

- `multi.ForEach(table, callback_function)`

	Loops through the table and calls callback_function with each element of the array. 

- If a name is not supplied when creating threads and threaded objects; a name is randomly generated. Unless sending through an established channel/queue you might not be able to easily init the object.

Changed
---
- Internally all `OnError` events are now connected to with multi.print, you must pass `print=true` to the init settings when initializing the multi object. `require("multi"):init{print=true}`
- All actors now use fastmode on connections
- Performance enhancement with processes that are pumped. Instead of automatically running, by suppressing the creation of an internal loop object that would manage the process, we bypass that freeing up memory and adding a bit more speed.
- `Connection:fastMode() or Connection:SetHelper()` now returns a reference to itself
- `Connection:[connect, hasConnections, getConnection]` changed to be `Connection:[Connect, HasConnections, getConnections]`. This was done in an attempt to follow a consistent naming scheme. The old methods still will work to prevent old code breaking.
- `Connections when added(+) together now act like 'or', to get the 'and' feature multiply(*) them together.`

	**Note:** This is a potentially breaking change for using connections.

	```lua
	multi, thread = require("multi"):init{print=true}
	-- GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

	local conn1, conn2, conn3 = multi:newConnection(), multi:newConnection(), multi:newConnection()

	thread:newThread(function()
		print("Awaiting status")
		thread.hold(conn1 + (conn2 * conn3))
		print("Conn or Conn2 and Conn3")
	end)

	multi:newAlarm(1):OnRing(function()
		print("Conn")
		conn1:Fire()
	end)

	multi:newAlarm(2):OnRing(function()
		print("Conn2")
		conn2:Fire()
	end)

	multi:newAlarm(3):OnRing(function()
		print("Conn3")
		conn3:Fire()
	end)
	```

Removed
---
- Connection objects methods removed:
	- holdUT(), HoldUT() -- With the way `thread.hold(conn)` interacts with connections this method was no longer needed. To emulate this use `multi.hold(conn)`. `multi.hold()` is able to emulate what `thread.hold()` outside of a thread, albeit with some drawbacks.

Fixed
---
- SystemThreaded Objects variables weren't consistent.
- Issue with connections being multiplied only being able to have a combined fire once

ToDo
---

- Work on network parallelism (I am really excited to start working on this. Not because it will have much use, but because it seems like a cool addition/project to work on. I just need time to actually do work on stuff)

# Update 15.2.1 - Bug fix
Fixed issue #41
---

# Update 15.2.0 - Upgrade Complete

Full Update Showcase

```lua
package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.threading"):init()

-- Using a system thread, but both system and local threads support this!
-- Don't worry if you don't have lanes or love2d. PesudoThreading will kick in to emulate the threading features if you do not have access to system threading.
func = THREAD:newFunction(function(count)
	print("Starting Status test: ",count)
	local a = 0
	while true do
		a = a + 1
		THREAD.sleep(.1)
		-- Push the status from the currently running threaded function to the main thread
		THREAD.pushStatus(a,count)
		if a == count then break end
	end
	return "Done"
end)

thread:newThread("test",function()
	local ret = func(10)
	ret.OnStatus(function(part,whole)
		print("Ret1: ",math.ceil((part/whole)*1000)/10 .."%")
	end)
	print("TEST",func(5).wait())
	-- The results from the OnReturn connection is passed by thread.hold
	print("Status:",thread.hold(ret.OnReturn))
	print("Function Done!")
end).OnError(function(...)
	print("Error:",...)
end)

local ret = func(10)
local ret2 = func(15)
local ret3 = func(20)
local s1,s2,s3 = 0,0,0
ret.OnError(function(...)
	print("Error:",...)
end)
ret2.OnError(function(...)
	print("Error:",...)
end)
ret3.OnError(function(...)
	print("Error:",...)
end)
ret.OnStatus(function(part,whole)
	s1 = math.ceil((part/whole)*1000)/10
	print(s1)
end)
ret2.OnStatus(function(part,whole)
	s2 = math.ceil((part/whole)*1000)/10
	print(s2)
end)
ret3.OnStatus(function(part,whole)
	s3 = math.ceil((part/whole)*1000)/10
	print(s3)
end)

loop = multi:newTLoop()

function loop:testing()
	print("testing haha")
end

loop:Set(1)
t = loop:OnLoop(function()
	print("Looping...")
end):testing()

local proc = multi:newProcessor("Test")
local proc2 = multi:newProcessor("Test2")
local proc3 = proc2:newProcessor("Test3")
proc.Start()
proc2.Start()
proc3.Start()
proc:newThread("TestThread_1",function()
	while true do
		thread.sleep(1)
	end
end)
proc:newThread("TestThread_2",function()
	while true do
		thread.sleep(1)
	end
end)
proc2:newThread("TestThread_3",function()
	while true do
		thread.sleep(1)
	end
end)

thread:newThread(function()
	thread.sleep(1)
	local tasks = multi:getStats()

	for i,v in pairs(tasks) do
		print("Process: " ..i.. "\n\tTasks:")
		for ii,vv in pairs(v.tasks) do
			print("\t\t"..vv:getName())
		end
		print("\tThreads:")
		for ii,vv in pairs(v.threads) do
			print("\t\t"..vv:getName())
		end
	end

	thread.sleep(10) -- Wait 10 seconds then kill the process!
	os.exit()
end)

multi:mainloop()
```

Added:
---
- `multi:getStats()`
	- Returns a structured table where you can access data on processors there tasks and threads:
		```lua
		-- Upon calling multi:getStats() the table below is returned
		get_Stats_Table {
			proc_1 -- table
			proc_2 -- table
			...
			proc_n -- table
		}
		proc_Table {
			tasks = {alarms,steps,loops,etc} -- All multi objects
			threads = {thread_1,thread_2,thread_3,etc} -- Thread objects
		}
		-- Refer to the objects documentation to see how you can interact with them
		```
	- Reference the Full update showcase for the method in action
- `multi:newProcessor(name, nothread)`
	- If no thread is true auto sets the processor as Active, so proc.run() will start without the need for proc.Start()

- `multi:getProcessors()`
	- Returns a list of all processors

- `multi:getName()`
	- Returns the name of a processor

- `multi:getFullName()`
	- Returns the fullname/entire process tree of a process

- Processors can be attached to processors

- `multi:getTasks()`
	- Returns a list of all non thread based objects (loops, alarms, steps, etc)

- `multi:getThreads()`
	- Returns a list of all threads on a process

- `multi:newProcessor(name, nothread).run()`
	- New function run to the processor object to 

- `multi:newProcessor(name, nothread):newFunction(func, holdme)`
	- Acts like thread:newFunction(), but binds the execution of that threaded function to the processor

- `multi:newTLoop()` member functions
	- `TLoop:Set(set)` - Sets the time to wait for the TLoop

- `multi:newStep()` member functions
	- `Step:Count(count)` - Sets the amount a step should count by

- `multi:newTStep()` member functions
	- `TStep:Set(set)` - Sets the time to wait for the TStep


Changed:
---
- `thread.hold(connectionObj)` now passes the returns of that connection to `thread.hold()`! See Exampe below: 
	```lua
	multi, thread = require("multi"):init()

	func = thread:newFunction(function(count)
		local a = 0
		while true do
			a = a + 1
			thread.sleep(.1)
			thread.pushStatus(a,count)
			if a == count then break end
		end
		return "Done", 1, 2, 3
	end)

	thread:newThread("test",function()
		local ret = func(10)
		ret.OnStatus(function(part,whole)
			print("Ret1: ",math.ceil((part/whole)*1000)/10 .."%")
		end)
		print("Status:",thread.hold(ret.OnReturn))
		print("Function Done!")
		os.exit()
	end).OnError(function(...)
		print("Error:",...)
	end)

	multi:mainloop()
	```
	Output:
	```
	Ret1:   10%
	Ret1:   20%
	Ret1:   30%
	Ret1:   40%
	Ret1:   50%
	Ret1:   60%
	Ret1:   70%
	Ret1:   80%
	Ret1:   90%
	Ret1:   100%
	Status: Done    1       2       3       nil     nil     nil     nil     nil     nil     nil     nil     nil     nil     nil     nil
	Function Done!
	```

- Modified how threads are handled internally. This changes makes it so threads "regardless of amount" should not impact performance. What you do in the threads might. This change was made by internally only processing one thread per step per processor. If you have 10 processors that are all active expect one step to process 10 threads. However if one processor has 10 threads each step will only process one thread. Simply put each addition of a thread shouldn't impact performance as it did before.
- Moved `multi:newThread(...)` into the thread interface (`thread:newThread(...)`), code using `multi:newThread(...)` will still work. Also using `process:newThread(...)` binds the thread to the process, meaning if the process the thread is bound to is paused so is the thread.
	
- multi:mainloop(~~settings~~)/multi:uManager(~~settings~~) no longer takes a settings argument, that has been moved to multi:init(settings)
	| Setting | Description |
	---|---
	print | When set to true parts of the library will print out updates otherwise no internal printing will be done
	priority | When set to true, the library will prioritize different objects based on their priority
- `multi:newProcessor(name,nothread)` The new argument allows you to tell the system you won't be using the Start() and Stop() functions, rather you will handle the process yourself. Using the proc.run() function. This function needs to be called to pump the events.
	- Processors now also use lManager instead of uManager.
- `multi.hold(n,opt)` now supports an option table like thread.hold does.
- Connection Objects now pass on the parent object if created on a multiobj. This was to allow chaining to work properly with the new update

	```lua
	multi,thread = require("multi"):init()

	loop = multi:newTLoop()

	function loop:testing()
    	print("testing haha")
	end

	loop:Set(1)
	t = loop:OnLoop(function()
		print("Looping...")
	end):testing()

	multi:mainloop()
	
	--[[Returns as expected:

		testing haha
		Looping...
		Looping...
		Looping...
		...
		Looping...
		Looping...
		Looping...
	]]
	```

	While chaining on the OnSomeEventMethod() wasn't really a used feature, I still wanted to keep it just incase someone was relying on this working. And it does have it uses

- All Multi Objects now use Connection objects

	`multiobj:OnSomeEvent(func)` or `multiobj.OnSomeEvent(func)`

- Connection Objects no longer Fire with syntax sugar when attached to an object:

	`multiobj:OnSomeEvent(...)` No longer triggers the Fire event. As part of the update to make all objects use connections internally this little used feature had to be scrapped!

- multi:newTStep now derives it's functionality from multi:newStep (Cut's down on code length a bit)

Removed:
---
- `multi:getTasksDetails()` Remade completely and now called `multi:getStats()`
- `multi:getError()` Removed when setting protect was removed
- `multi:FreeMainEvent()` The new changes with connections make's this function unnecessary 
- `multi:OnMainConnect(func)` See above
- `multi:connectFinal(func)` See above
- `multi:lightloop()` Cleaned up the mainloop/uManager method, actually faster than lightloop (Which should have been called liteloop)
- `multi:threadloop()` See above for reasons
- `multi setting: protect` This added extra complexity to the mainloop and not much benefit. If you feel a function will error use pcall yourself. This saves a decent amount of cycles, about 6.25% increase in performance.
- `multi:GetParentProcess()` use `multi.getCurrentProcess()` instead
- priority scheme 2, 3 and auto-priority have been removed! Only priority scheme 1 actually performed in a reasonable fashion so that one remained.
- `multi:newFunction(func)`
	- `thread:newFunction(func)` Has many more features and replaces what multi:newFunction did
- `multi.holdFor()` Now that multi.hold takes the option table that thread.hold has this feature can be emulated using that.

- Calling Fire on a connection no longer returns anything! Now that internal features use connections, I noticed how slow connections are and have increased their speed quite a bit. From 50,000 Steps per seconds to almost 7 Million. All other features should work just fine. Only returning values has been removed

Fixed:
---

- [Issue](https://github.com/rayaman/multi/issues/30) with Lanes crashing the lua state. Issue seemed to be related to my filesystem, since remounting the drive caused the issue to stop. (Windows)

- [Issue](https://github.com/rayaman/multi/issues/29) where System threaded functions not being up to date with threaded functions

- Issue where gettasksdetails() would try to process a destroyed object causing it to crash

- Issue with multi.hold() not pumping the mainloop and only the scheduler

ToDo:
---

- Work on network parallelism 


# Update 15.1.0 - Hold the thread!

Full Update Showcase

```lua
local multi,thread = require("multi"):init()

func = thread:newFunction(function(count)
    local a = 0
    while true do
        a = a + 1
        thread.sleep(.1)
        thread.pushStatus(a,count)
        if a == count then break end
    end
    return "Done"
end)

multi:newThread("Function Status Test",function()
    local ret = func(10)
    local ret2 = func(15)
    local ret3 = func(20)
    ret.OnStatus(function(part,whole)
        print("Ret1: ",math.ceil((part/whole)*1000)/10 .."%")
    end)
    ret2.OnStatus(function(part,whole)
        print("Ret2: ",math.ceil((part/whole)*1000)/10 .."%")
    end)
    ret3.OnStatus(function(part,whole)
        print("Ret3: ",math.ceil((part/whole)*1000)/10 .."%")
    end)
	-- Connections can now be added together, if you had multiple holds and one finished before others and wasn't consumed it would lock forever! This is now fixed
    thread.hold(ret2.OnReturn + ret.OnReturn + ret3.OnReturn)
    print("Function Done!")
    os.exit()
end)

test = thread:newFunction(function()
    return 1,2,nil,3,4,5,6,7,8,9
end,true)
print(test())
multi:newThread("testing",function()
    print("#Test = ",test())
    print(thread.hold(function()
        print("Hello!")
        return false
    end,{
        interval = 2,
        cycles = 3
    })) -- End result, 3 attempts within 6 seconds. If still false then timeout
    print("held")
end).OnError(function(...)
    print(...)
end)

sandbox = multi:newProcessor()
sandbox:newTLoop(function()
    print("testing...")
end,1)

test2 = multi:newTLoop(function()
    print("testing2...")
end,1)

sandbox:newThread("Test Thread",function()
    local a = 0
    while true do
        thread.sleep(1)
        a = a + 1
        print("Thread Test: ".. multi.getCurrentProcess().Name)
        if a == 10 then
            sandbox.Stop()
        end
    end
end).OnError(function(...)
    print(...)
end)
multi:newThread("Test Thread",function()
    while true do
        thread.sleep(1)
        print("Thread Test: ".. multi.getCurrentProcess().Name)
    end
end).OnError(function(...)
    print(...)
end)

sandbox.Start()

multi:mainloop()
```

Added:
---

- multi:newSystemThreadedJobQueue(n)
	
	`queue:isEmpty()`
	
	Returns true if the queue is empty, false if there are items in the queue. 

**Note:** a queue might be empty, but the job may still be running and not finished yet! Also if a registered function is called directly instead of pushed, it will not reflect inside the queue until the next cycle!

Example:
```lua
local multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.threading"):init() -- Auto detects your enviroment and uses what's available

jq = multi:newSystemThreadedJobQueue(5) -- Job queue with 4 worker threads
func = jq:newFunction("test",function(a,b)
    THREAD.sleep(2)
    return a+b
end)
for i = 1,10 do
    func(i,i*3).connect(function(data)
        print(data)
    end)
end

local a = true
b = false

multi:newThread("Standard Thread 1",function()
    while true do
        thread.sleep(.1)
        print("Empty:",jq:isEmpty())
    end
end).OnError(function(self,msg)
    print(msg)
end)
multi:mainloop()
```

## multi.TIMEOUT

`multi.TIMEOUT` is equal to "TIMEOUT", it is reccomended to use this incase things change later on. There are plans to change the timeout value to become a custom object instead of a string.

## new connections on threaded functions

- `func.OnStatus(...)`

	Allows you to connect to the status of a function see [thread.pushStatus()](#status-added-to-threaded-functions)

- `func.OnReturn(...)`

	Allows you to connect to the functions return event and capture its returns see [Example](#status-added-to-threaded-functions) for an example of it in use.

## multi:newProcessor(name)

```lua
local multi,thread = require("multi"):init()

-- Create a processor object, it works a lot like the multi object
sandbox = multi:newProcessor()

-- On our processor object create a TLoop that prints "testing..." every second
sandbox:newTLoop(function()
	print("testing...")
end,1)

-- Create a thread on the processor object
sandbox:newThread("Test Thread",function()
	-- Create a counter named 'a'
	local a = 0
	-- Start of the while loop that ends when a = 10
	while true do
		-- pause execution of the thread for 1 second
		thread.sleep(1)
		-- increment a by 1
		a = a + 1
		-- display the name of the current process
		print("Thread Test: ".. multi.getCurrentProcess().Name)
		if a == 10 then
			-- Stopping the processor stops all objects created inside that process including threads. In the backend threads use a regular multiobject to handle the scheduler and all of the holding functions. These all stop when a processor is stopped. This can be really useful to sandbox processes that might need to turned on and off with ease and not having to think about it.
			sandbox.Stop()
		end
	end
	-- Catch any errors that may come up
end).OnError(function(...)
	print(...)
end)

sandbox.Start() -- Start the process

multi:mainloop() -- The main loop that allows all processes to continue
```

**Note:** Processor objects have been added and removed many times in the past, but will remain with this update. 

| Attribute | Type | Returns | Description |
---|---|---|---
Start|Method()|self| Starts the process
Stop|Method()|self| Stops the process
OnError|Connection|connection| Allows connection to the process error handler
Type|Member:`string`|"process"| Contains the type of object
Active|Member:`boolean`|variable| If false the process is not active
Name|Member:`string`|variable| The name set at process creation
process|Thread|thread| A handle to a multi thread object 

**Note:** All tasks/threads created on a process are linked to that process. If a process is stopped all tasks/threads will be halted until the process is started back up.

## Connection can now be added together

Very useful when using thread.hold for multiple connections to trigger.

Iif you had multiple holds and one finished before others and wasn't consumed it would lock forever! This is now fixed

`print(conn + conn2 + conn3 + connN)`

Can be chained as long as you want! See example below

## Status added to threaded functions
- `thread.pushStatus(...)`
	
	Allows a developer to push a status from a function.

- `tFunc.OnStatus(func(...))`

	A connection that can be used on a function to view the status of the threaded function

Example:

```lua
local multi,thread = require("multi"):init()

func = thread:newFunction(function(count)
    local a = 0
    while true do
        a = a + 1
        thread.sleep(.1)
        thread.pushStatus(a,count)
        if a == count then break end
    end
    return "Done"
end)

multi:newThread("Function Status Test",function()
    local ret = func(10)
    local ret2 = func(15)
    local ret3 = func(20)
    ret.OnStatus(function(part,whole)
        --[[ Print out the current status. In this case every second it will update with:
		10%
		20%
		30%
		...
		100%

		Function Done!
		]]
        print(math.ceil((part/whole)*1000)/10 .."%")
    end)
    ret2.OnStatus(function(part,whole)
        print("Ret2: ",math.ceil((part/whole)*1000)/10 .."%")
    end)
    ret3.OnStatus(function(part,whole)
        print("Ret3: ",math.ceil((part/whole)*1000)/10 .."%")
    end)
	-- Connections can now be added together, if you had multiple holds and one finished before others and wasn't consumed it would lock forever! This is now fixed
    thread.hold(ret2.OnReturn + ret.OnReturn + ret3.OnReturn)
    print("Function Done!")
    os.exit()
end)
```

Changed:
---

- `f = thread:newFunction(func,holdme)`
	- Nothing changed that will affect how the object functions by default. The returned function is now a table that is callable and 3 new methods have been added:

	Method | Description
	---|---
	Pause() | Pauses the function, Will cause the function to return `nil, Function is paused`
	Resume() | Resumes the function
	holdMe(set) | Sets the holdme argument that existed at function creation
	
	```lua
	local multi, thread = require("multi"):init()

	test = thread:newFunction(function(a,b)
    	thread.sleep(1)
		return a,b
	end, true)

	print(test(1,2))

	test:Pause()

	print(test(1,2))

	test:Resume()

	print(test(1,2))

	--[[ -- If you left holdme nil/false

	print(test(1,2).connect(function(...)
		print(...)
	end))

	test:Pause()

	print(test(1,2).connect(function(...)
		print(...)
	end))

	test:Resume()

	print(test(1,2).connect(function(...)
		print(...)
	end))

	]]

	multi:mainloop()
	```

	**Output:**

	```
	1       2
	nil     Function is paused
	1       2
	```

	**If holdme is nil/false:**

	```
	nil     Function is paused


	1       2       nil...
	1       2       nil...
	```

- thread.hold(n,opt) [Ref. Issue](https://github.com/rayaman/multi/issues/24)
	- Added option table to thread.hold
		| Option | Description |
		---|---
		| interval | Time between each poll |
		| cycles | Number of cycles before timing out |
		| sleep | Number of seconds before timing out |
		| skip | Number of cycles before testing again, does not cause a timeout! |

		**Note:** cycles and sleep options cannot both be used at the same time. Interval and skip cannot be used at the same time either. Cycles take priority over sleep if both are present! HoldFor and HoldWithin can be emulated using the new features. Old functions will remain for backward compatibility.
		
		Using cycles, sleep or interval will cause a timeout; returning nil, multi.TIMEOUT
	- `n` can be a number and thread.hold will act like thread.sleep. When `n` is a number the option table will be ignored!

Removed:
---

- N/A

Fixed:
---

- Threaded functions not returning multiple values [Ref. Issue](https://github.com/rayaman/multi/issues/21)
- Priority Lists not containing Very_High and Very_Low from previous update
- All functions that should have chaining now do, reminder all functions that don't return any data return a reference to itself to allow chaining of method calls.

ToDo
---

- Work on network parallelism (I really want to make this, but time and getting it right is proving much more difficult)
- Work on QOL changes to allow cleaner code like [this](#connection-can-now-be-added-together)

# Update 15.0.0 - The art of faking it
Full Update Showcase
---
```lua
local multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.threading"):init() -- Auto detects your enviroment and uses what's available

jq = multi:newSystemThreadedJobQueue(4) -- Job queue with 4 worker threads
func = jq:newFunction("test",function(a,b)
    THREAD.sleep(2)
    return a+b
end)

for i = 1,10 do
    func(i,i*3).connect(function(data)
        print(data)
    end)
end

multi:newThread("Standard Thread 1",function()
    while true do
        thread.sleep(1)
        print("Testing 1 ...")
    end
end)

multi:newISOThread("ISO Thread 2",{test=true},function()
    while true do
        thread.sleep(1)
        print("Testing 2 ...")
    end
end)

multi:mainloop()
```
Note:
---
This was supposed to be released over a year ago, but work and other things got in my way. Pesudo Threading now works. The goal of this is so you can write modules that can be scaled up to utilize threading features when available.

Added:
---
- multi:newISOThread(name,func,env)
  - Creates an isolated thread that prevents both locals and globals from being accessed.
  - Was designed for the pesudoManager so it can emulate threads. You can use it as a super sandbox, but remember upvalues are also stripped which was intened for what I wanted them to do!
- Added new integration: pesudoManager, functions just like lanesManager and loveManager, but it's actually single threaded
  - This was implemented because, you may want to build your code around being multi threaded, but some systems/implemetations of lua may not permit this. Since we now have a "single threaded" implementation of multi threading. We can actually create scalable code where things automatcally are threaded if built correctly. I am planning on adding more threadedOjbects.
- In addition to adding pesudo Threading `multi.integration.threading` can now be used to autodetect which enviroment you are on and use the threading features.
	```
	GLOBAL,THREAD = require("multi.integration.threading"):init()
	```
	If you are using love2d it will use that, if you have lanes avaialble then it will use lanes. Otherwise it will use pesudo threading. This allows module creators to implement scalable features without having to worry about which enviroment they are in. Can now require a consistant module: `require("multi.integration.threading"):init()`

Changed:
---
- Documentation to reflect the changes made

Removed:
---
- CBT (Coroutine Based threading) has lost a feature, one that hasn't been used much, but broke compatiblity with anything above lua 5.1. My goal is to make my library work with all versions of lua above 5.1, including 5.4. Lua 5.2+ changed how enviroments worked which means that you can no longer modify an enviroment of function without using the debug library. This isn't ideal for how things in my library worked, but it is what it is. The feature lost is the one that converted all functions within a threaded enviroment into a threadedfunction. This in hindsight wasn't the best pratice and if it is the desired state you as the user can manually do that anyway. This shouldn't affect anyones code in a massive way.

Fixed:
---
- pseudoThreading and threads had an issue where they weren't executing properly
- lanesManager THREAD:get(STRING: name) not returning the value
- Issue where threaded function were not returning multiple values

Todo:
---
- Add more details to the documentation

# Update 14.2.0 - Bloatware Removed
Full Update Showcase
---
```lua
local multi,thread = require("multi"):init()

-- Testing destroying and fixed connections
c = multi:newConnection()
c1 = c(function()
    print("called 1")
end)
c2 = c(function()
    print("called 2")
end)
c3 = c(function()
    print("called 3")
end)

print(c1,c2.Type,c3)
c:Fire()
c2:Destroy()
print(c1,c2.Type,c3)
c:Fire()
c1:Destroy()
print(c1,c2.Type,c3)
c:Fire()

-- Destroying alarms and threads
local test = multi:newThread(function()
    while true do
        thread.sleep(1)
        print("Hello!")
    end
end)

test.OnDeath(function()
    os.exit() -- This is the last thing called.
end)

local alarm = multi:newAlarm(4):OnRing(function(a)
    print(a.Type)
    a:Destroy()
    print(a.Type)
    test:Destroy()
end)

multi:lightloop()
```
Going Forward:
---
- There is no longer any plans for sterilization! Functions do not play nice on different platforms and there is no simple way to ensure that things work.

Quality Of Life:
---
- threaded functions now return only the arguments that are needed, if it has trailing nils, they wont be returned like they used to.

Added:
---
- Type: destroyed
	- A special state of an object that causes that object to become immutable and callable. The object Type is always "destroyed" it cannot be changed. The object can be indexed to infinity without issue. Every part of the object can be called as if it were a function including the indexed parts. This is done incase you destroy an object and still "use" it somewhere. However, if you are expecting something from the object then you may still encounter an error, though the returned type is an instance of the destroyed object which can be indexed and called like normal. This object can be used in any way and no errors will come about with it.

Fixed:
---
- thread.holdFor(n,func) and thread.holdWithin(n,func) now accept a connection object as the func argument
- Issue with threaded functions not handling nil properly from returns. This has been resolved and works as expected.
- Issue with system threaded job queues newFunction() not allowing nil returns! This has be addressed and is no longer an issue.
- Issue with hold like functions not being able to return `false`
- Issue with connections not returning a handle for managing a specific conn object.
- Issue with connections where connection chaining wasn't working properly. This has been addressed.
	```lua
	local multi,thread = require("multi"):init()
	test = multi:newConnection()
	test(function(hmm)
		print("hi",hmm.t)
		hmm.t = 2
	end)(function(hmm)
		print("hi2",hmm.t)
		hmm.t = 3
	end)(function(hmm)
		print("hi3",hmm.t)
	end)
	test:Fire({t=1})
	```

Changed:
---
- Destroying an object converts the object into a 'destroyed' type.
- connections now have type 'connector_link'
	```lua
	OnExample = multi:newConnection() -- Type Connector, Im debating if I should change this name to multi:newConnector() and have connections to it have type connection
	conn = OnExample(...)
	print(conn.Type) -- connector_link
	```

Removed: (Cleaning up a lot of old features)
---
- Removed multi:newProcessor(STRING: file) — Old feature that is not really needed anymore. Create your multi-objs on the multi object or use a thread
- bin dependency from the rockspec
- Example folder and .html variants of the .md files
- multi:newTrigger() — Connections do everything this thing could do and more.
- multi:newHyperThreadedProcess(name)*
- multi:newThreadedProcess(name)*
- multi.nextStep(func)* — The new job System can be used instead to achieve this
- multi.queuefinal(self) — An Old method for a feature long gone from the library
- multi:setLoad(n)*
- multi:setThrestimed(n)*
- multi:setDomainName(name)*
- multi:linkDomain(name)*
- multi:_Pause()* — Use multi:Stop() instead!
- multi:isHeld()/multi:IsHeld()* Holding is handled differently so a held variable is no longer needed for chacking.
- multi.executeFunction(name,...)*
- multi:getError()* — Errors are nolonger gotten like that, multi.OnError(func) is the way to go
- multi.startFPSMonitior()*
- multi.doFPS(s)*

*Many features have become outdated/redundant with new features and additions that have been added to the library

# Update 14.1.0 - A whole new world of possibilities
Full Update Showcase
---
Something I plan on doing each version going forward
```lua
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
```
Going Forward:
---
- Finish the network manager
- Planning on finishing sterilization for the library.
- Might remove some objects: steps (multi:newStep()), tsteps (multi:newTStep), jobs (Planning to rework this), events (multi:newEvent()), tloop (multi:newTLoop()), triggers (multi:newTrigger())

Modified:
---
- thread.Priority_* has been moved into THREAD since it pertains to system threads. This only applies to lanes threads!
- 2 new priority options have been added. This addition modified how all options except Core behave. Core is still the highest and Idle is still the lowest!
	- multi.Priority_Core — Same: 1
	- multi.Priority_Very_High — Added: 4
	- multi.Priority_High — Was: 4 Now: 16
	- multi.Priority_Above_Normal — Was: 16 Now: 64
	- multi.Priority_Normal — Was: 64 Now: 256
	- multi.Priority_Below_Normal — Was: 256 Now: 1024
	- multi.Priority_Low — Was: 1024 Now: 4096
	- multi.Priority_Very_Low — Added: 16384
	- multi.Priority_Idle — Was: 4096 Now: 65536

Added:
---
- multi:lightloop() — Works like multi:mainloop()
	- Removes the extra features like priority management, load balancing and what not. Only the bare minimum is processed. If Priority management is something you liked to use the new Service object provides those features. You could alternatively use multi:mainloop() instead to use the non light features.
- serv = multi:newService(func)
	- (func(self,datatable))
		- self — Reference to the service
		- datatable — internal data space that the service can store data. Is reset/destroyed when the service is stopped.
	- serv.Type: service
	- serv.OnError(func) — Triggered if service crashes
	- serv.OnStopped(func) — Triggered if service was stopped (In the case of a crash OnStopped is not called)
	- serv.OnStarted(func) — Triggered when the service starts
	- serv.SetScheme(n) — How to manage priorities
		- n: 1 — **default** uses sleeping to manage priority (Less control, but much less expensive)
		- n: 2 — uses skipping to manage priority (Finer control, but more expensive)
	- serv.Stop() — Stops the service, the internal data table is wiped
	- serv.Pause() — Pauses the service
	- serv.Resume() — Resumes the service
	- serv.Start() — Starts the service
	- serv.GetUpTime() — Gets the uptime of the service. Time is only counted when the service is running, if the service is paused then it is nolonger being counted. If the service is started then the uptime reset!
	- serv.SetPriority(priority) — Sets the priority level for the service
		- multi.Priority_Core
		- multi.Priority_High
		- multi.Priority_Above_Normal
		- multi.Priority_Normal **default**
		- multi.Priority_Below_Normal
		- multi.Priority_Low
		- multi.Priority_Idle
- jq = multi:newSystemThreadedJobQueue(n) 
	- jq:newFunction([name optional],func,holup) — Provides a newFunction like syntax. If name is left blank a unique one is assigned. The second return after the function is the name of the function.
- console = THREAD:getConsole() — Now working on lanes and love2d, allows you to print from multiple threads while keeping the console from writing over each other
	- console.print(...)
	- console.write(str)
- multi:scheduleJob(time,func)
	- time.min — Minute a value of (0-59)
	- time.hour — Hour a value of (0-23)
	- time.day — Day of month a value of (1-31)
	- time.wday — Weekday a value of (0-6)
	- time.month — Month a value of (1-12)
- THREAD:newFunction(func,holup) — A system threaded based variant to thread:newFunction(func,holup) works the same way. Though this should only be used for intensive functions! Calling a STfunction has a decent amount of overhead, use wisely. System threaded jobqueue may be a better choice depending on what you are planning on doing.
- multi:loveloop() — Handles the run function for love2d as well as run the multi mainloop.
- multi.OnLoad(func) — A special connection that allows you to connect to the an event that triggers when the multi engine starts! This is slightly different from multi.PreLoad(func) Which connects before any variables have been set up in the multi table, before any settings are cemented into the core. In most cases they will operate exactly the same. This is a feature that was created with module creators in mind. This way they can have code be loaded and managed before the main loop starts.
- multi.OnExit(func) — A special connection that allows you to connect onto the lua state closing event.

Changed:
---
- threaded functions no longer auto detect the presence of arguments when within a threaded function. However, you can use the holup method to produce the same effect. If you plan on using a function in different ways then you can use .wait() and .connect() without setting the holup argument
- thread:newFunction(func,holup) — Added an argument holup to always force the threaded funcion to wait. Meaning you don't need to tell it to func().wait() or func().connect()
- multi:newConnection(protect,callback,kill) — Added the kill argument. Makes connections work sort of like a stack. Pop off the connections as they get called. So a one time connection handler.
	- I'm not sure callback has been documented in any form. callback gets called each and everytime conn:Fire() gets called! As well as being triggered for each connfunc that is part of the connection.
- modified the lanes manager to create globals GLOBAL and THREAD when a thread is started. This way you are now able to more closely mirror code between lanes and love. As of right now parity between both enviroments is now really good. Upvalues being copied by default in lanes is something that I will not try and mirror in love. It's better to pass what you need as arguments, this way you can keep things consistant. looping through upvalues and sterlizing them and sending them are very complex and slow. 

Removed:
---
- multi:newTimeStamper() — schedulejob replaces timestamper

Fixed:
---
- Issue where setting the priority of lanes Threads were not working since we were using the data before one could have a chance to set it. This has been resolved!
- Issue where connections object:conn() was firing based on the existance of a Type field. Now this only fires if the table contains a reference to itself. Otherwise it will connect instead of firing
- Issue where async functions connect wasn't properly triggering when a function returned
- Issue where async functions were not passing arguments properly.
- Issue where async functions were not handling errors properly
	- nil, err = func().wait() — When waiting
	- func().connect(function(err) end) — When connection
- Love2d had an issue where threads crashing would break the mainloop
- Issue where systemthreadedjobqueues pushJob() was not returning the jobID of the job that was pushed!
- Fixed bugs within the extensions.lua file for love threading
- Modified the thread.* methods to perform better (Tables were being created each time one of these methods were called! Which in turn slowed things down. One table is modified to get things working properly)
	- thread.sleep()
	- thread.hold()
	- thread.holdFor()
	- thread.holdWithin()
	- thread.skip()
	- thread.kill()
	- thread.yield()


# Update 14.0.0 - Consistency, Additions and Stability

Added:
---
- multi.init() — Initlizes the library! Must be called for multiple files to have the same handle. Example below
- thread.holdFor(NUMBER sec, FUNCTION condition) — Works like hold, but timesout when a certain amount of time has passed!
- multi.hold(function or number) — It's back and better than ever! Normal multi objs without threading will all be halted where threads will still run. If within a thread continue using thread.hold() and thread.sleep()
- thread.holdWithin(NUMBER; cycles,FUNCTION; condition) — Holds until the condition is met! If the number of cycles passed is equal to cycles, hold will return a timeout error
- multi.holdFor(NUMBER; seconds,FUNCTION; condition) — Follows the same rules as multi.hold while mimicing the functionality of thread.holdWithin
**Note:** when hold has a timeout the first argument will return nil and the second atgument will be TIMEOUT, if not timed out hold will return the values from the conditions
- thread objects now have hooks that allow you to interact with it in more refined ways!
-- tObj.OnDeath(self,status,returns[...]) — This is a connection that passes a reference to the self, the status, whether or not the thread ended or was killed, and the returns of the thread.
-- tObj.OnError(self,error) — returns a reference to self and the error as a string
-- **Limitations:** only 7 returns are possible! This was done because creating and destroying table objects are slow. (The way the scheduler works this would happen every cycle and thats no good) Instead I capture the return values from coroutine.resume into local variables and only allowed it to collect 7 max.
- thread.run(function) — Can only be used within a thread, creates another thread that can do work, but automatically returns whatever from the run function — Use thread newfunctions for a more powerful version of thread.run()
- thread:newFunction(FUNCTION: func)
-- returns a function that gives you the option to wait or connect to the returns of the function.
-- func().wait() — waits for the function to return works both within a thread and outside of one
-- func().connect() — connects to the function finishing
-- func() — If your function does not return anything you dont have to use wait or connect at all and the function will return instantly. You could also use wait() to hold until the function does it thing
-- If the created function encounters an error, it will return nil, the error message!
- special variable multi.NIL was added to allow error handling in threaded functions.
-- multi.NIL can be used in to force a nil value when using thread.hold()
- All functions created in the root of a thread are now converted to threaded functions, which allow for wait and connect features.

	**Note:** these functions are local to the function! And are only converted if they aren't set as local! Otherwise the function is converted into a threaded function

- lanes threads can now have their priority set using: sThread.priority = 
	- thread.Priority_Core
	- thread.Priority_High
	- thread.Priority_Above_Normal
	- thread.Priority_Normal
	- thread.Priority_Below_Normal
	- thread.Priority_Low
	- thread.Priority_Idle
- thread.hold() and multi.hold() now accept connections as an argument. See example below

```lua
local multi, thread = require("multi"):init()
conn = multi:newConnection()
multi:newThread(function()
    thread.hold(conn)
    print("Connection Fired!!!")
end)
multi:newAlarm(3):OnRing(function()
    conn:Fire()
end)
```

thread newFunction
```lua
func=thread:newFunction(function(...)
    print("Function running...")
    thread.sleep(1)
    return {1,2,3},"done"
end)
multi:newThread("Test",function()
	func().connect(function(...)
    	print(...)
    end)
end)
----OUTPUT----
> Function running...
> table: 0x008cf340       done    nil     nil     nil     nil     nil
```

thread newFunction using auto convert
```lua
multi, thread = require("multi").init()
a=5
multi:newThread("Test",function()
    function hmm() -- Auto converted into a threaded function
        return "Hello!",2
    end
    print(a)
    a=10
    print(hmm().wait())
end)
multi:newAlarm(3):OnRing(function()
    print(a)
end)
print(hmm)
multi:mainloop()
-----OUTPUT-----
> nil
> 5
> Hello!  2       nil     nil     nil     nil     nil -- The way I manage function returns is by allocating them to predefined locals. Because I pass these values regardless they technically get passed even when they are nil. This choice was made to keep the creation of tables to capture arguments then using unpack to pass them on when processing is done 
> 10
```

Fixed:
---
- Connections had a preformance issue where they would create a non function when using connection.getConnection() of a non existing label.
- An internal mismanagement of the threads scheduler was fixed. Now it should be quicker and free of bugs
- Thread error management is the integrations was not properly implemented. This is now fixed

Removed:
---
- multi:newWatcher() — No real use
- multi:newCustomObject() — No real use

Changed:
---
- Connections connect function can now chain connections
```lua
	
    local multi, thread = require("multi").init()
    test = multi:newConnection()
    test(function(a)
        print("test 1",a.Temp)
        a.Temp = "No!"
    end,function(a)
        print("test 2",a.Temp)
        a.Temp = "Maybe!"
    end,function(a)
        print("test 3",a.Temp)
    end)
    test:Fire({Temp="Yes!"})
```
- Ties in to the new function that has been added multi.init()
```lua
local multi, thread = require("multi").init() -- The require multi function still returns the multi object like before
```
- love/lanesManager system threading integration has been reworked. Faster and cleaner code! Consistant code as well

Note: Using init allows you to get access to the thread handle. This was done because thread was modifying the global space as well as multi. I wanted to not modify the global space anymore.
internally most of your code can stay the same, you only need to change how the library is required. I do toy a bit with the global space, buy I use a variable name that is invalid as a variable name. The variable name is  $multi. This is used internally to keep some records and maintain a clean space

Also when using intergrations things now look more consistant.
```lua
local multi, thread = require("multi").init()
local GLOBSL, THREAD = require("multi.integration.lanesManager").init() -- or whichever manager you are using
local nGLOBAL, nTHREAD = require("multi.intergration.networkManager).inti()
```
Note: You can mix and match integrations together. You can create systemthreads within network threads, and you can also create cotoutine based threads within bothe network and system threads. This gives you quite a bit of flexibility to create something awesome.

Going forward:
---
- Finish the rework of the networkManager - It "works", but there are packet losses that I cannot explain. I do not know what is causing this at all. Ill fix when I figure it out!
- If all goes well, the future will contain quality of code features. I'll keep an eye out for bugs

# Update 13.1.0 - Bug fixes and features added
-------------
Added:
---
- Connections:Lock() — Prevents a connection object form being fired
- Connections:Unlock() — Removes the restriction imposed by conn:Lock()
- new fucntions added to the thread namespace
-- thread.request(THREAD handle,STRING cmd,VARARGS args) — allows you to push thread requests from outside the running thread! Extremely powerful.
-- thread.exec(FUNCTION func) — Allows you to push code to run within the thread execution block!
- handle = multi:newThread() — now returns a thread handle to interact with the object outside fo the thread
-- handle:Pause()
-- handle:Resume()
-- handle:Kill()

Fixed:
---
- Minor bug with multi:newThread() in how names and functions were managed
- Major bug with the system thread handler. Saw healthy threads as dead ones
- Major bug the thread scheduler was seen creating a massive amount of 'event' causing memory leaks and hard crashes! This has been fixed by changing how the scheduler opperates. 
- newSystemThread()'s returned object now matches both the lanes and love2d in terms of methods that are usable. Error handling of System threads now behave the same across both love and lanes implementations.
- looks like I found a typo, thread.yeild -> thread.yield

Changed: 
---
- getTasksDetails("t"), the table varaiant, formats threads, and system threads in the same way that tasks are formatted. Please see below for the format of the task details
- TID has been added to multi objects. They count up from 0 and no 2 objects will have the same number
- thread.hold() — As part of the memory leaks that I had to fix thread.hold() is slightly different. This change shouldn't impact previous code at all, but thread.hold() can not only return at most 7 arguments!
- You should notice some faster code execution from threads, the changes improve preformance of threads greatly. They are now much faster than before!
- multi:threadloop() — No longer runs normal multi objects at all! The new change completely allows the multi objects to be seperated from the thread objects!
- local multi, thread = require("multi") — Since coroutine based threading has seen a change to how it works, requring the multi library now returns the namespace for the threading interface as well. For now I will still inject into global the thread namespace, but in release 13.2.0 or 14.0.0 It will be removed!


Tasks Details Table format
---
```
{ 
	["Tasks"] = { 
		{
			["TID"] = 0,
			["Type"] = scheduler,
			["Name"] = multi.thread,
			["Priority"] = Core,
			["Uptime"] = 6.752
			["Link"] = tableRef
		},
		...
	} ,

	["Systemthreads"] = { 
		{ 
			["Uptime"] = 6.752
			["Link"] = tableRef
			["Name"] = threadname
			["ThreadID"] = 0
		},
		...
	},

	["Threads"] = { 
		{ 
			["Uptime"] = 6.752
			["Link"] = tableRef
			["Name"] = threadname
			["ThreadID"] = 0
		},
		...
	},

	["ProcessName"] = multi.root,
	["CyclesPerSecondPerTask"] = 3560300,
	["MemoryUsage"] = 1846, in KB returned as a number
	["ThreadCount"] = 1,
	["SystemLoad"] = 0, as a % 100 is max 0 is min
	["PriorityScheme"] = Round-Robin
	["SystemThreadCount"] = 1
} 
```
# Update 13.0.0 - Added some documentation, and some new features too check it out!
-------------
**Quick note** on the 13.0.0 update:
This update I went all in finding bugs and improving performance within the library. I added some new features and the new task manager, which I used as a way to debug the library was a great help, so much so thats it is now a permanent feature. It's been about half a year since my last update, but so much work needed to be done. I hope you can find a use in your code to use my library. I am extremely proud of my work; 7 years of development, I learned so much about lua and programming through the creation of this library. It was fun, but there will always be more to add and bugs crawling there way in. I can't wait to see where this library goes in the future!

Fixed:
---
- Tons of bugs, I actually went through the entire library and did a full test of everything, I mean everything, while writing the documentation.

Changed:
---
- A few things, to make concepts in the library more clear.
- The way functions returned paused status. Before it would return "PAUSED" now it returns nil, true if paused
- Modified the connection object to allow for some more syntaxial suger!
- System threads now trigger an OnError connection that is a member of the object itself. multi.OnError() is no longer triggered for a system thread that crashes!

Connection Example:
```lua
loop = multi:newTLoop(function(self)
	self:OnLoops() -- new way to Fire a connection! Only works when used on a multi object, bin objects, or any object that contains a Type variable
end,1)
loop.OnLoops = multi:newConnection()
loop.OnLoops(function()
	print("Looping")
end)
multi:mainloop()
```

Function Example:
```lua
func = multi:newFunction(function(self,a,b)
	self:Pause()
	return 1,2,3
end)
print(func()) -- returns: 1, 2, 3
print(func()) -- nil, true
```

Removed:
---
- Ranges and conditions — corutine based threads can emulate what these objects did and much better!
- Due to the creation of hyper threaded processes the following objects are no more!
	- ~~multi:newThreadedEvent()~~
	- ~~multi:newThreadedLoop()~~
	- ~~multi:newThreadedTLoop()~~
	- ~~multi:newThreadedStep()~~
	- ~~multi:newThreadedTStep()~~
	- ~~multi:newThreadedAlarm()~~
	- ~~multi:newThreadedUpdater()~~
	- ~~multi:newTBase()~~ — Acted as the base for creating the other objects

These didn't have much use in their previous form, but with the addition of hyper threaded processes the goals that these objects aimed to solve are now possible using a process

Fixed:
---
- There were some bugs in the networkmanager.lua file. Desrtoy -> Destroy some misspellings.
- Massive object management bugs which caused performance to drop like a rock.
- Found a bug with processors not having the Destroy() function implemented properly.
- Found an issue with the rockspec which is due to the networkManager additon. The net Library and the multi Library are now codependent if using that feature. Going forward you will have to now install the network library separately
- Insane proformance bug found in the networkManager file, where each connection to a node created a new thread (VERY BAD) If say you connected to 100s of threads, you would lose a lot of processing power due to a bad implementation of this feature. But it goes further than this, the net library also creates a new thread for each connection made, so times that initial 100 by about 3, you end up with a system that quickly eats itself. I have to do tons of rewriting of everything. Yet another setback for the 13.0.0 release (Im releasing 13.0.0 though this hasn't been ironed out just yet)
- Fixed an issue where any argument greater than 256^2 or 65536 bytes is sent the networkmanager would soft crash. This was fixed by increading the limit to 256^4 or 4294967296. The fix was changing a 2 to a 4. Arguments greater than 256^4 would be impossible in 32 bit lua, and highly unlikely even in lua 64 bit. Perhaps someone is reading an entire file into ram and then sending the entire file that they read over a socket for some reason all at once!?
- Fixed an issue with processors not properly destroying objects within them and not being destroyable themselves
- Fixed a bug where pause and resume would duplicate objects! Not good
- Noticed that the switching of lua states, corutine based threading, is slower than multi-objs (Not by much though).
- multi:newSystemThreadedConnection(name,protect) — I did it! It works and I believe all the gotchas are fixed as well.
	- Issue one, if a thread died that was connected to that connection all connections would stop since the queue would get clogged! FIXED
	- There is one thing, the connection does have some handshakes that need to be done before it functions as normal!

Added:
---
- Documentation, the purpose of 13.0.0, orginally going to be 12.2.3, but due to the amount of bugs and features added it couldn't be a simple bug fix update.
- multi:newHyperThreadedProcess(STRING name) — This is a version of the threaded process that gives each object created its own coroutine based thread which means you can use thread.* without affecting other objects created within the hyper threaded processes. Though, creating a self contained single thread is a better idea which when I eventually create the wiki page I'll discuss
- multi:newConnector() — A simple object that allows you to use the new connection Fire syntax without using a multi obj or the standard object format that I follow.
- multi:purge() — Removes all references to objects that are contained withing the processes list of tasks to do. Doing this will stop all objects from functioning. Calling Resume on an object should make it work again.
- multi:getTasksDetails(STRING format) — Simple function, will get massive updates in the future, as of right now It will print out the current processes that are running; listing their type, uptime, and priority. More useful additions will be added in due time. Format can be either a string "s" or "t" see below for the table format
- multi:endTask(TID) — Use multi:getTasksDetails("t") to get the tid of a task
- multi:enableLoadDetection() — Reworked how load detection works. It gives better values now, but it still needs some work before I am happy with it
- THREAD.getID() — returns a unique ID for the current thread. This varaiable is visible to the main thread as well by accessing it through the returned thread object. OBJ.Id Do not confuse this with thread.* this refers to the system threading interface. Each thread, including the main thread has a threadID the main thread has an ID of 0!
- multi.print(...) works like normal print, but only prints if the setting print is set to true
- setting: `print` enables multi.print() to work
- STC: IgnoreSelf defaults to false, if true a Fire command will not be sent to the self
- STC: OnConnectionAdded(function(connID)) — Is fired when a connection is added you can use STC:FireTo(id,...) to trigger a specific connection. Works like the named non threaded connections, only the id's are genereated for you.
- STC: FireTo(id,...) — Described above.

```lua
local multi = require("multi")
conn = multi:newConnector()
conn.OnTest = multi:newConnection()
conn.OnTest(function()
	print("Yes!")
end)
test = multi:newHyperThreadedProcess("test")
test:newTLoop(function()
	print("HI!")
	conn:OnTest()
end,1)
test:newLoop(function()
	print("HEY!")
	thread.sleep(.5)
end)
multi:newAlarm(3):OnRing(function()
	test:Sleep(10)
end)
test:Start()
multi:mainloop()
```
Table format for getTasksDetails(STRING format)
```lua
{
	{TID = 1,Type="",Priority="",Uptime=0}
	{TID = 2,Type="",Priority="",Uptime=0}
	...
    {TID = n,Type="",Priority="",Uptime=0}
	ThreadCount = 0
	threads={
    	[Thread_Name]={
        	Uptime = 0
        }
    }
}
```
**Note:** After adding the getTasksDetails() function I noticed many areas where threads, and tasks were not being cleaned up and fixed the leaks. I also found out that a lot of tasks were starting by default and made them enable only. If you compare the benchmark from this version to last version you;ll notice a signifacant increase in performance.

**Going forward:**
- Work on system threaded functions
- work on the node manager
- patch up bugs
- finish documentstion

# Update 12.2.2 - Time for some more bug fixes!

Fixed:
--- 
- multi.Stop() not actually stopping due to the new pirority management scheme and preformance boost changes.

# Update 12.2.1 - Time for some bug fixes!

Fixed: SystemThreadedJobQueues
- You can now make as many job queues as you want! Just a warning when using a large amount of cores for the queue it takes a second or 2 to set up the jobqueues for data transfer. I am unsure if this is a lanes thing or not, but love2d has no such delay when setting up the jobqueue!
- You now connect to the OnReady in the jobqueue object. No more holding everything else as you wait for a job queue to be ready
- Jobqueues:doToAll now passes the queues multi interface as the first and currently only argument
- No longer need to use jobqueue.OnReady() The code is smarter and will send the pushed jobs automatically when the threads are ready

Fixed: SystemThreadedConnection
- They work the exact same way as before, but actually work as expected now. The issue before was how i implemented it. Now each connection knows the number of instances of that object that ecist. This way I no longer have to do fancy timings that may or may not work. I can send exactly enough info for each connection to consume from the queue.

Removed: multi:newQueuer
- This feature has no real use after corutine based threads were introduced. You can use those to get the same effect as the queuer and do it better too. 

Going forward:
- Will I ever finish steralization? Who knows, but being able to save state would be nice. The main issue is there is no simple way to save state. While I can provide methods to allow one to turn the objects into strings and back, there is no way for me to make your code work with it in a simple way. For now only the basic functions will be here.
- I need to make better documentation for this library as well. In its current state, all I have are examples and not a list of what is what.

Example
---
```lua
multi = require("multi")
GLOBAL, THREAD = require("multi.integration.lanesManager").init()
jq = multi:newSystemThreadedJobQueue()
jq:registerJob("test",function(a)
	return "Hello",a
end)
jq.OnJobCompleted(function(ID,...)
	print(ID,...)
end)
for i=1,16 do
	jq:pushJob("test",5)
end
multi:mainloop()
```

# Update 12.2.0 - The chains of binding
**Added:**
- multi.nextStep(func)
- Method chaining
- Priority 3 has been added!
- ResetPriority() — This will set a flag for a process to be re evaluated for how much of an impact it is having on the performance of the system.
- setting: auto_priority added! — If only lua os.clock was more fine tuned... milliseconds are not enough for this to work
- setting: auto_lowerbound added! — when using auto_priority this will allow you to set the lowbound for pirority. The defualt is a hyrid value that was calculated to reach the max potential with a delay of .001, but can be changed to whatever. Remember this is set to processes that preform really badly! If lua could handle more detail in regards to os.clock() then i would set the value a bit lower like .0005 or something like that
- setting: auto_stretch added! — This is another way to modify the extent of the lowest setting. This reduces the impact that a low preforming process has! Setting this higher reduces the number of times that a process is called. Only in effect when using auto_priotity
- setting: auto_delay added! — sets the time in seconds that the system will recheck for low performing processes and manage them. Will also upgrade a process if it starts to run better.
```lua
-- All methods that did not return before now return a copy of itself. Thus allowing chaining. Most if not all mutators returned nil, so chaining can now be done. I will eventually write up a full documentation of everything which will show this.
multi = require("multi")
multi:newStep(1,100):OnStep(function(self,i)
	print("Index: "..i)
end):OnEnd(function(self)
	print("Step is done!")
end)
multi:mainloop{
	priority = 3
}
```
Priority 3 works a bit differently than the other 2.

P1 follows a forumla that resembles this: ~n=I*PRank where n is the amount of steps given to an object with PRank and where I is the idle time see chart below. The aim of this priority scheme was to make core objects run fastest while letting idle processes get decent time as well.
```
C: 3322269	~I*7
H: 2847660	~I*6
A: 2373050	~I*5
N: 1898440	~I*4
B: 1423830	~I*3
L: 949220	 ~I*2
I: 474610	 ~I
~n=I*PRank
```
P2 follows a formula that resembles this: ~n=n*4 where n is the idle time, see chart below. The goal of this one was to make core process' higher while keeping idle process' low.
```
C: 6700821
H: 1675205
A: 418801
N: 104700
B: 26175
L: 6543
I: 1635
~n=n*4
```
P3 Ignores using a basic function and instead bases its processing time on the amount of cpu time is there. If cpu-time is low and a process is set at a lower priority it will get its time reduced. There is no formula, at idle almost all process work at the same speed!
```
C: 2120906
H: 2120906
A: 2120906
N: 2120906
B: 2120906
L: 2120906
I: 2120506
```

Auto Priority works by seeing what should be set high or low. Due to lua not having more persicion than milliseconds, I was unable to have a detailed manager that can set things to high, above normal, normal, ect. This has either high or low. If a process takes longer than .001 millisecond it will be set to low priority. You can change this by using the setting auto_lowest = multi.Priority_[PLevel] the defualt is low, not idle, since idle tends to get about 1 process each second though you can change it to idle using that setting. This is nolonger the case in version 16.0.0 multi has evolved ;)

**Improved:**
- Performance at the base level has been doubled! On my machine benchmark went from ~9mil to ~20 mil steps/s.
Note: If you write slow code this library's improvements wont make much of a difference.
- Loops have been optimised as well! Being the most used objects I felt they needed to be made as fast as possible

I usually give an example of the changes made, but this time I have an explantion for `multi.nextStep()`. It's not an entirely new feature since multi:newJob() does something like this, but is completely different. nextStep adds a function that is executed first on the next step. If multiple things are added to next step, then they will be executed in the order that they were added.

Note:
The upper limit of this libraries performance on my machine is ~39mil. This is simply a while loop counting up from 0 and stops after 1 second. The 20mil that I am currently getting is probably as fast as it can get since its half of the max performance possible, and each layer I have noticed that it doubles complexity. Throughout the years with this library I have seen massive improvements in speed. In the beginning we had only ~2000 steps per second. Fast right? then after some tweaks we went to about 300000 steps per second, then 600000. Some more tweaks brought me to ~1mil steps per second, then to ~4 mil then ~9 mil and now finally ~20 mil... the doubling effect that i have now been seeing means that odds are I have reach the limit. I will aim to add more features and optimize individule objects. If its possible to make the library even faster then I will go for it.


# Update 12.1.0 - Threads just can't hold on anymore
Fixed:
---
- bug causing arguments when spawning a new thread not going through

Changed:
---
- thread.hold() now returns the arguments that were pass by the event function
- event objects now contain a copy of what returns were made by the function that called it in a table called returns that exist inside of the object

```lua
multi = require("multi")
local a = 0
multi:newThread("test",function()
	print("lets go")
	b,c = thread.hold(function() -- This now returns what was managed here
		return b,"We did it!"
	end)
	print(b,c)
end)
multi:newTLoop(function()
	a=a+1
	if a == 5 then
		b = "Hello"
	end
end,1)
multi:mainloop()
```
**Note:** Only if the first return is non-nil/false will any other returns be passed! So while variable b above is nil the string "We did it!" will not be passed. Also while this seems simple enough to get working, I had to modify a bit on how the scheduler worked to add such a simple feature. Quite a bit is going on behind the scenes which made this a bit tricky to implement, but not hard. Just needed a bit of tinkering. Plus event objects have not been edited since the creation of the EventManager. They have remained mostly the same since 2011

Going forward:
---
Contunue to make small changes as I come about them. This change was inspired when working of the net library. I was addind simple binary file support over tcp, and needed to pass the data from the socket when the requested amount has been recieved. While upvalues did work, i felt returning data was cleaner and added this feature.

# Update: 12.0.0 - Big update (Lots of additions some changes)

**Note:** ~~After doing some testing, I have noticed that using multi-objects are slightly, quite a bit, faster than using (coroutines)multi:newthread(). Only create a thread if there is no other possibility! System threads are different and will improve performance if you know what you are doing. Using a (coroutine)thread as a loop with a 
is slower than using a TLoop! If you do not need the holding features I strongly recommend that you use the multi-objects. This could be due to the scheduler that I am using, and I am looking into improving the performance of the scheduler for (coroutine)threads. This is still a work in progress so expect things to only get better as time passes!~~ This was the reason threadloop was added. It binds the thread scheduler into the mainloop allowing threads to run much faster than before. Also the use of locals is now possible since I am not dealing with seperate objects. And finally, reduced function overhead help keeps the threads running better.

**Note:** The nodeManager is being reworked! This will take some time before it is in a stable state. The old version had some major issues that caused it to perform poorly.

**Note:** Version names were brought back to reality this update. When transistioning from EventManager to multi I stopped counting when in reality it was simply an overhaul of the previous library

Added:
---
- `nGLOBAL = require("multi.integration.networkManager").init()`
- `node = multi:newNode(tbl: settings)`
- `master = multi:newMaster(tbl: settings)`
- `multi:nodeManager(port)`
- `thread.isThread()` — for coroutine based threads
- New setting to the main loop, stopOnError which defaults to true. This will cause the objects that crash, when under protect, to be destroyed. So the error does not keep happening.
- multi:threadloop(settings) works just like mainloop, but prioritizes (corutine based) threads. Regular multi-objects will still work. This improves the preformance of (coroutine based) threads greatly.
- multi.OnPreLoad — an event that is triggered right before the mainloop starts

Changed:
- When a (corutine based)thread errors it does not print anymore! Conect to multi.OnError() to get errors when they happen!
- Connections get yet another update. Connect takes an additional argument now which is the position in the table that the func should be called. Note: Fire calls methods backwards so 1 is the back and the # of connections (the default value) is the beginning of the call table
- The love2d compat layer has now been revamped allowing module creators to connect to events without the user having to add likes of code for those events. Its all done automagically.
- This library is about 8 years old and using 2.0.0 makes it seem young. I changed it to 12.0.0 since it has some huge changes and there were indeed 12 major releases that added some cool things. Going forward I'll use major.minor.bugfix
- multi.OnError() is now required to capture errors that are thrown when in prorected mode.

Node:
---
- node:sendTo(name,data)
- node:pushTo(name,data)
- node:peek()
- node:pop()
- node:getConsole() — has only 1 function print which allows you to print to the master.

Master:
---
- master:doToAll(func)
- master:register(name,node,func)
- master:execute(name,node,...)
- master:newNetworkThread(tname,func,name,...)
- master:getFreeNode()
- master:getRandomNode()
- master:sendTo(name,data)
- master:pushTo(name,data)
- master:peek()
- master:pop()
- master:OnError(nodename, error) — if a node has an error this is triggered.

Bugs
---
- Fixed a small typo I made which caused a hard crash when a (coroutine) thread crashes. This only happened if protect was true.

Going forward:
---
- I am really excited to finally get this update out there, but left one important thing out. enabling of enviroments for each master connected to a node. This would allow a node to isolate code from multiple masters so they cannot interact with each other. This will come out in version 12.1.0 But might take a while due to the job hunt that I am currently going through.
- Another feature that I am on the fence about is adding channels. They would work like queues, but are named so you can seperate the data from different channels where only one portion of can see certain data. 
- I also might add a feature that allows different system threads to consume from a network queue if they are spaned on the same physical machine. This is possible at the moment, just doesn't have a dedicated object for handling this seamlessly. You can do this yourself though.
- Another feature that I am thinking of adding is crosstalk which is a setting that would allow nodes to talk to other nodes. I did not add it in this release since there are some issues that need to be worked out and its very messy atm. however since nodes are named. I may allow by default pushing data to another node, but not have the global table to sync since this is where the issue lies.
- Improve Performance
- Fix supporting libraries (Bin, and net need tons of work)
- Look for the bugs
- Figure out what I can do to make this library more awesome


**Note On Queues:** When it comes to network queues, they only send 1 way. What I mean by that is that if the master sends a message to a node, its own queue will not get populated at all. The reason for this is because syncing between which popped from what network queue would make things really slow and would not perform well at all. This means you have to code a bit differently. Use: master getFreeNode() to get the name of the node under the least amount of load. Then handle the sending of data to each node that way.

Now there is a little trick you can do. If you combine both networkmanager and systemthreading manager, then you could have a proxy queue for all system threads that can pull from that "node". Now data passing within a lan network, (And wan network if using the node manager, though p2p isn't working as i would like and you would need to open ports and make things work. Remember you can define an port for your node so you can port forward that if you want), is fast enough, but the waiting problem is something to consider. Ask yourseld what you are coding and if network paralisim is worth using.

**Note:** These examples assume that you have already connected the nodes to the node manager. Also you do not need to use the node manager, but sometimes broadcast does not work as expected and the master doesnot connect to the nodes. Using the node manager offers nice features like: removing nodes from the master when they have disconnected, and automatically telling the master when nodes have been added. A more complete example showing connections regardless of order will be shown in the example folder check it out. New naming scheme too.

**NodeManager.lua**
```lua
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
multi:nodeManager(12345) -- Host a node manager on port: 12345
print("Node Manager Running...")
settings = {
	priority = 0, — 1 or 2
	protect = false,
}
multi:mainloop(settings)
-- Thats all you need to run the node manager, everything else is done automatically

```

Side note: I had a setting called cross talk that would allow nodes to talk to each other. After some tought I decided to not allow nodes to talk to each other directly! You however can create another master withing the node. (The node will connect to its own master as well). This will give you the ability "Cross talk" with each node. Reimplementing the master features into each node directly was unnecessary. 

**Node.lua**
```lua
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
master = multi:newNode{
	allowRemoteRegistering = true, -- allows you to register functions from the master on the node, default is false
	name = nil, -- default value
	noBroadCast = true, -- if using the node manager, set this to true to prevent the node from broadcasting
	managerDetails = {"localhost",12345}, -- connects to the node manager if one exists
}
function RemoteTest(a,b,c) -- a function that we will be executing remotely
	print("Yes I work!",a,b,c)
end
settings = {
	priority = 0, -- 1 or 2
	protect = false, -- if something goes wrong we will crash hard, but the speed gain is good
}
multi:mainloop(settings)
```

**Master.lua**
```lua
-- Import the libraries
local multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
-- Act as a master node
master = multi:newMaster{
	name = "Main", -- the name of the master
	noBroadCast = true, -- if using the node manager, set this to true to avoid double connections
	managerDetails = {"localhost",12345}, -- the details to connect to the node manager (ip,port)
}
-- Send to all the nodes that are connected to the master
master:doToAll(function(node_name)
	master:register("TestFunc",node_name,function(msg)
		print("It works: "..msg)
	end)
	multi:newAlarm(2):OnRing(function(alarm)
		master:execute("TestFunc",node_name,"Hello!")
		alarm:Destroy()
	end)
	multi:newThread("Checker",function()
		while true do
			thread.sleep(1)
			if nGLOBAL["test"] then
				print(nGLOBAL["test"])
				thread.kill()
			end
		end
	end)
	nGLOBAL["test2"]={age=22}
end)

-- Starting the multitasker
settings = {
	priority = 0, -- 0, 1 or 2
	protect = false,
}
multi:mainloop(settings)
```

**Note:** There are many ways to work this. You could send functions/methods to a node like haw systemThreadedJobQueue work. Or you could write the methods you want in advance in each node file and send over the command to run the method with arguments ... and it will return the results. Network threading is different than system threading. Data transfer is really slow compared to system threading. In fact the main usage for this feature in the library is mearly for experments. Right now I honestly do not know what I want to do with this feature and what I am going to add to this feature. The ablitiy to use this frature like a system thread will be possible, but there are some things that differ.

Changed:
---
- multi:mainloop(settings) — now takes a table of settings
- multi:uManager(settings) — now takes a table of settings
- connections:holdUT(n) can take a number now. Where they will not continue until it gets triggered **n** times Added 3 updated ago, forgot to list it as a new feature
- The way you require the library has changed a bit! This will change how you start your code, but it isn't a big change.
- These changes have led to significant performance improvements

Modifying the global stack is not the best way to manage or load in the library.
```lua
-- Base Library
multi = require("multi")
-- In Lanes
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
-- In Love2d
multi = require("multi")
GLOBAL, THREAD = require("multi.integration.loveManager").init()
-- In Luvit
local timer = require("timer")
local thread = require("thread")
multi = require("multi")
require("multi.integration.luvitManager").init(thread,timer) -- Luvit does not cuttently have support for the global table or threads.
```

Improvements:
---
- Updated the ThreadedConsole, now 100x faster!
- Updated the ThreadedConections, .5x faster!
- Both multi:uManager(settings) and multi:mainloop(settings) provide about the same performance! Though uManager is slightly slower due to function overhead, but still really close.
- Revamped pausing mulit-objects they now take up less memory when being used

Removed:
---
- require("multi.all") — We are going into a new version of the library so this is nolonger needed
- require("multi.compat.backwards[1,5,0]") — This is really old and is no longer supported going forward
- multi:Do_Order()
- multi:enablePriority()
- multi:enablePriority2()
- multi:protect()
- multi:unProtect()
- multi:protectedMainloop()
- multi:unprotectedMainloop()
- multi:prioritizedMainloop1()
- multi:prioritizedMainloop2()
- Removed Tasks
- multi:oneTime(func,...) — never seen use of this, plus multi-functions can do this by pausing the function after the first use, and is much faster anyway
- multi:reboot() — removed due to having no real use
- multi:hold() — removed due to threads being able to do the same thing and way better too
- multi:waitFor() — the thread variant does something completely different
- multi.resurrect() — removed due to being useless

The new settings table makes all of these possible and removes a lot of function overhead that was going on before.

```lua
multi:mainloop{
	priority = 1, -- 1 or 2
	protect = true, -- Should I use pcall to ignore errors?
	preLoop = function(self) -- a function that is called before the mainloop does its thing
		multi:newTLoop(function()
			print("Hello whats up!")
			error(":P")
		end,1)
		multi.OnError(function(obj,err)
			print(err)
			obj:Destroy()
		end)
	end,
}
```
# Update: 1.11.1 - Small Clarification on Love
Love2d change:
I didn't fully understand how the new love.run() function worked.
So, it works by returning a function that allows updating the mainloop. So, this means that we can do something like this:

```lua
multi:newLoop(love.run()) -- Run the mainloop here, cannot use thread.* when using this object

-- or

multi:newThread("MainLoop",love.run()) -- allows you to use the thread.*

--And you'll need to throw this in at the end
multi:mainloop()
```

The priority management system should be quite useful with this change. 
NOTE: **multiobj:hold() will be removed in the next version!** This is something I feel should be changed, since threads(coroutines) do the job great, and way better than my holding method that I throw together 5 years ago. I doubt this is being used by many anyway. Version 1.11.2 or version 2.0.0 will have this change. The next update may be either, bug fixes if any or network parallelism.

TODO: Add auto priority adjustments when working with priority and stuff... If the system is under heavy load it will dial some things deemed as less important down and raise the core processes.

# Update: 1.11.0
Added:
- SystemThreadedConsole(name) — Allow each thread to print without the sync issues that make prints merge and hard to read.

```lua
-- MainThread:
console = multi:newSystemThreadedConsole("console"):init()
-- Thread:
console = THREAD.waitFor("console"):init()

-- using the console
console:print(...)
console:write(...) -- kind of useless for formatting code though. other threads can eaisly mess this up.
```

Fixed/Updated:
- Love2d 11.1 support is now here! Will now require these lines in your main.lua file

```lua
function love.update(dt)
	multi:uManager(dt) -- runs the main loop of the multitasking library
end
function love.draw()
    multi.dManager() -- If using my guimanager, if not omit this
end
```


# Update: 1.10.0
**Note:** The library is now considered to be stable!
**Upcoming:** Network parallelism is on the way. It is in the works and should be released soon

Added:
---
- isMainThread true/nil
- multi:newSystemThreadedConnection(name,protect) — Works like normal connections, but are able to trigger events across threads

Example of threaded connections
```lua
local GLOBAL,THREAD=require("multi.integration.lanesManager").init()
multi:newSystemThread("Test_Thread_1",function()
	connOut = THREAD.waitFor("ConnectionNAMEHERE"):init()
	connOut(function(arg)
		print(THREAD.getName(),arg)
	end)
	multi:mainloop()
end)
multi:newSystemThread("Test_Thread_2",function()
	connOut = THREAD.waitFor("ConnectionNAMEHERE"):init()
	connOut(function(arg)
		print(THREAD.getName(),arg)
	end)
	multi:mainloop()
end)
connOut = multi:newSystemThreadedConnection("ConnectionNAMEHERE"):init()
a=0
connOut(function(arg)
	print("Main",arg)
end)
multi:newTLoop(function()
	a=a+1
	connOut:Fire("Test From Main Thread: "..a.."\n")
end,1)
```

Fixed:
---
**loveManager** and **shared threading objects**
- sThread.waitFor()
- sThread.hold()
- some typos
- SystemThreadedTables (They now work on both lanes and love2d as expected)

Example of threaded tables
```lua
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
multi:newSystemThread("Test_Thread_1",function()
	require("multi")
	test = sThread.waitFor("testthing"):init()
	multi:newTLoop(function()
		print("------")
		for i,v in pairs(test.tab) do
			print("T1",i,v)
		end
	end,1)
	multi:mainloop()
end)
multi:newSystemThread("Test_Thread_1",function()
	require("multi")
	test = sThread.waitFor("testthing"):init()
	multi:newTLoop(function()
		print("------")
		for i,v in pairs(test.tab) do
			print("T2",i,v)
		end
	end,1)
	multi:mainloop()
end)
test = multi:newSystemThreadedTable("testthing"):init()
multi:newTLoop(function()
	local a,b = multi.randomString(8),multi.randomString(4)
	print(">",a,b)
	test[a]=b
end,1)
multi:mainloop()
```

# Update: 1.9.2
Added:
---
- (THREAD).kill() kills a thread. Note: THREAD is based on what you name it
- newTimeStamper() Part of the persistent systems... Useful for when you are running this library for a long amount of time... like months and years! Though daily, hourly, minute events do also exist.
Allows one to hook to timed events such as whenever the clock strikes midnight or when the day turns to Monday. The event is only done once though. so as soon as Monday is set it would trigger then not trigger again until next Monday
works for seconds, minutes, days, months, year.
```lua
stamper = multi:newTimeStamper()
stamper:OnTime(int hour,int minute,int second,func) or stamper:OnTime(string time,func) time as 00:00:00
stamper:OnHour(int hour,func)
stamper:OnMinute(int minute,func)
stamper:OnSecond(int second,func)
stamper:OnDay(int day,func) or stamper:OnDay(string day,func) Mon, Tues, Wed, etc...
stamper:OnMonth(int month,func)
stamper:OnYear(int year,func)
```
Improved:
---
- LoadBalancing, well better load balancing than existed before. This one allowed for multiple processes to have their own load reading. Calling this on the multi object will return the total load for the entire multi environment... loads of other processes are indeed affected by what other processes are doing. However, if you combine propriety to the mix of things then you will get differing results... these results however will most likely be higher than normal... different priorities will have different default thresholds of performance.

Fixed:
---
- Thread.getName() should now work on lanes and love2d, haven't tested it much with the luvit side of things...
- A bug with the lovemanager table.remove arguments were backwards
- The queue object in the love2d threading has been fixed! It now supports sending all objects (even functions if no upvalues are present!)

Changed:
---
- SystemThreadedJobQueues now have built in load management so they are not constantly at 100% CPU usage.
- SystemThreadedJobQueues pushJob now returns an id of that job which will match the same one that OnJobCompleted returns


# Update: 1.9.1 - Threads can now argue
Added:
---
- Integration "multi.integration.luvitManager"
- Limited... Only the basic multi:newSystemThread(...) will work
- Not even data passing will work other than arguments... If using the bin library, you can pass tables and function... Even full objects if inner recursion is not present.

Updated:
---
- multi:newSystemThread(name,func,...)
- It will now pass the ... to the func(). Do not know why this wasn't done in the first place
- Also multi:getPlatform(will now return "luvit" if using luvit... Though Idk if module creators would use the multi library when inside the luvit environment

# Update: 1.9.0
Added:
---
- multiobj:ToString() — returns a string representing the object
- multi:newFromString(str) — creates an object from a string

Works on threads and regular objects. Requires the latest bin library to work!
```lua
talarm=multi:newThreadedAlarm("AlarmTest",5)
talarm:OnRing(function()
 	print("Ring!")
end)
bin.new(talarm:ToString()):tofile("test.dat")
-- multi:newFromString(bin.load("test.dat"))
```
A more seamless way to use this will be made in the form of state saving.
This is still a WIP
processes, timers, timemasters, watchers, and queuers have not been worked on yet

# Update: 1.8.7
Added:
---
- multi.timer(func,...)

```lua
function test(a,b,c)
	print("Running...")
    a=0
    for i=1,1000000000 do
    	a=a+1
    end
    return a,b+c
end
print(multi.timer(test,1,2,3))
print(multi.timer(test,1,2,3))
-- multi.timer returns the time taken then the arguments from the function... Uses unpack so careful of nil values!
```

# Update: 1.8.6
Added:
- jobQueue:doToAll(function)
- jobQueue:start() is now required Call this after all calls to registerJob()'s. Calling it afterwards will not guarantee your next push job with that job will work. Not calling this will make pushing jobs impossible!
- Fixed a bug with love2d Threaded Queue
- Fixed some bugs
- Old versions of this library! It stems back from 2012 see rambling for more info...

This will run said function in every thread.
```lua
-- Going to use love2d code this time, almost the same as last time... See ramblings
require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
require("core.GuiManager")
gui.ff.Color=Color.Black
jQueue=multi:newSystemThreadedJobQueue()
jQueue:registerJob("TEST_JOB",function(a,s)
	math.randomseed(s)
	TEST_JOB2()
	return math.random(0,255)
end)
jQueue:registerJob("TEST_JOB2",function()
	print("Test Works!")
end)
-- 1.8.6 EXAMPLE Change
jQueue:start() -- This is now needed!
--
jQueue:doToAll(function()
	print("Doing this 2? times!")
end)
tableOfOrder={}
jQueue.OnJobCompleted(function(JOBID,n)
	tableOfOrder[JOBID]=n
	if #tableOfOrder==10 then
		t.text="We got all of the pieces!"
	end
end)
for i=1,10 do -- Job Name of registered function, ... varargs
	jQueue:pushJob("TEST_JOB","This is a test!",math.random(1,1000000))
end
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
```

# Update: 1.8.5
Added:
---
- SystemThreadedExecute(cmd)

Allows the execution of system calls without hold up. It is possible to do the same using io.popen()! You decide which works best for you!
```lua
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
cmd=multi:newSystemThreadedExecute("SystemThreadedExecuteTest.lua") -- This file is important!
cmd.OnCMDFinished(function(code) -- callback function to grab the exit code... Called when the command goes through
	print("Got Code: "..code)
end)
multi:newTLoop(function()
	print("...") -- lets show that we aren't being held up
end,1)
multi:mainloop()
```

# Update: 1.8.4
Added:
---
- multi:newSystemThreadedJobQueue()
- Improved stability of the library
- Fixed a bug that made the benchmark and getload commands non-thread(coroutine) safe
- Tweaked the loveManager to help improve idle CPU usage
- Minor tweaks to the coroutine scheduling

Using multi:newSystemThreadedJobQueue()
---
First you need to create the object
This works the same way as love2d as it does with lanes... It is getting harder to make both work the same way with speed in mind... Anyway...
```lua
-- Creating the object using lanes manager to show case this. Examples has the file for love2d
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
jQueue=multi:newSystemThreadedJobQueue(n) -- this internally creates System threads. By default it will use the # of processors on your system You can set this number though.
-- Only create 1 jobqueue! For now, making more than 1 is not supported. You only really need one though. Just register new functions if you want 1 queue to do more. The one reason though is keeping track of jobIDs. I have an idea that I will roll out in the ~~next update~~ eventually.
jQueue:registerJob("TEST_JOB",function(a,s)
	math.randomseed(s)
	-- We will push a random #
	TEST_JOB2() -- You can call other registered functions as well!
	return math.random(0,255) -- send the result to the main thread
end)
jQueue:registerJob("TEST_JOB2",function()
	print("Test Works!") -- this is called from the job since it is registered on the same queue
end)
tableOfOrder={} -- This is how we will keep order of our completed jobs. There is no guarantee that the order will be correct
jQueue.OnJobCompleted(function(JOBID,n) -- whenever a job is completed you hook to the event that is called. This passes the JOBID filled by the returns of the job
	-- JOBID is the completed job, starts at 1 and counts up by 1.
	-- Threads finish at different times so jobIDs may be passed out of order! Be sure to have a way to order them
	tableOfOrder[JOBID]=n -- we order ours by putting them into a table
	if #tableOfOrder==10 then
		print("We got all of the pieces!")
	end
end)
-- Lets push the jobs now
for i=1,10 do -- Job Name of registered function, ... varargs
	jQueue:pushJob("TEST_JOB","This is a test!",math.random(1,1000000))
end
print("I pushed all of the jobs :)")
multi:mainloop() -- Start the main loop :D
```

That’s it from this version!

# Update: 1.8.3 - Mainloop recieves some needed overhauling
Added:
---
**New Mainloop functions** Below you can see the slight differences... Function overhead is not too bad in lua but has a real difference. multi:mainloop() and multi:unprotectedMainloop() use the same algorithm yet the dedicated unprotected one is slightly faster due to having less function overhead.
- multi:mainloop()\* — Bench:  16830003 Steps in 3 second(s)!
- multi:protectedMainloop() — Bench:  16699308 Steps in 3 second(s)!
- multi:unprotectedMainloop() — Bench:  16976627 Steps in 3 second(s)!
- multi:prioritizedMainloop1() — Bench:  15007133 Steps in 3 second(s)!
- multi:prioritizedMainloop2() — Bench:  15526248 Steps in 3 second(s)!

\* The OG mainloop function remains the same and old methods to achieve what we have with the new ones still exist

These new methods help by removing function overhead that is caused through the original mainloop function. The one downside is that you no longer have the flexibility to change the processing during runtime.

However there is a work around! You can use processes to run multiobjs as well and use the other methods on them.

I may make a full comparison between each method and which is faster, but for now trust that the dedicated ones with less function overhead are infect faster. Not by much but still faster.

# Update: 1.8.2
Added:
---
- multi:newsystemThreadedTable(name) NOTE: Metatables are not supported in transfers. However there is a work around obj:init() does this. Look in the multi/integration/shared/shared.lua files to see how I did it!
- Modified the GLOBAL metatable to sync before doing its tests
- multi._VERSION was multi.Version, felt it would be more consistent this way... I left the old way of getting the version just in case someone has used that way. It will eventually be gone. Also multi:getVersion() will do the job just as well and keep your code nice and update related bug free!
- Also everything that is included in the: multi/integration/shared/shared.lua (Which is loaded automatically) works in both lanes and love2d environments!

The threaded table is setup just like the threaded queue.</br>
It provids GLOBAL like features without having to write to GLOBAL!</br>
This is useful for module creators who want to keep their data private, but also use GLOBAL like coding.</br>
It has a few features that makes it a bit better than plain ol GLOBAL (For now...)
(ThreadedTable - TT for short) This was modified by a recent version that removed the need for a sync command
- TT:waitFor(name)
- TT:sync()
- TT["var"]=value
- print(TT["var"])

we also have the "sync" method, this one was made for love2d because we do a syncing trick to get data in a table format. The lanes side has a sync method as well so no worries. Using indexing calls sync once and may grab your variable. This allows you to have the lanes indexing 'like' syntax when doing regular indexing in love2d side of the module. As of right now both sides work flawlessly! And this effect is now the GLOBAL as well</br>

On GLOBALS sync is a internal method for keeping the GLOBAL table in order. You can still use sThread.waitFor(name) to wait for variables that may or may not yet exist!

Time for some examples:
Using multi:newSystemThreadedTable(name)
---
```lua
-- lanes Desktop lua! NOTE: this is in lanesintergratetest6.lua in the examples folder
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
test=multi:newSystemThreadedTable("YO"):init()
test["test1"]="lol"
multi:newSystemThread("test",function()
	tab=sThread.waitFor("YO"):init()
	print(tab:has("test1"))
	sThread.sleep(3)
	tab["test2"]="Whats so funny?"
end)
multi:newThread("test2",function()
	print(test:waitFor("test2"))
end)
multi:mainloop()
```

```lua
-- love2d lua! NOTE: this is in main4.lua in the love2d examples
require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
require("core.GuiManager")
gui.ff.Color=Color.Black
test=multi:newSystemThreadedTable("YO"):init()
test["test1"]="lol"
multi:newSystemThread("test",function()
	tab=sThread.waitFor("YO"):init()
	print(tab["test1"])
	sThread.sleep(3)
	tab["test2"]="Whats so funny?"
end)
multi:newThread("test2",function()
	print(test:waitFor("test2"))
	t.text="DONE!"
end)
t=gui:newTextLabel("not done yet!",0,0,300,100)
t:centerX()
t:centerY()
```

# Update: 1.8.1
No real change!</br>
Changed the structure of the library. Combined the coroutine based threads into the core!</br>
Only compat and integrations are not part of the core and never will be by nature.</br>
This should make the library more convent to use.</br>
I left multi/all.lua file so if anyone had libraries/projects that used that it will still work!</br>
Updated from 1.7.6 to 1.8.0</br> (How much thread could a thread htread if a thread could thread thread?)
Added:</br>
- multi:newSystemThreadedQueue()
- multi:systemThreadedBenchmark()
- More example files
- multi:canSystemThread() — true if an integration was added false otherwise (For module creation)
- Fixed a few bugs in the loveManager

Using multi:systemThreadedBenchmark()
---
```lua
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
multi:systemThreadedBenchmark(3):OnBench(function(self,count)
	print("First Bench: "..count)
	multi:systemThreadedBenchmark(3,"All Threads: ")
end)
multi:mainloop()
```

Using multi:newSystemThreadedQueue()
---
Quick Note: queues shared across multiple objects will be pulling from the same "queue" keep this in mind when coding! ~~Also the queue respects direction a push on the thread side cannot be popped on the thread side... Same goes for the mainthread!</br>~~ Turns out I was wrong about this...
```lua
-- in love2d, this file will be in the same example folder as before, but is named main2.lua
require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
--IMPORTANT
-- Do not make the above local, this is the one difference that the lanesManager does not have
-- If these are local the functions will have the upvalues put into them that do not exist on the threaded side
-- You will need to ensure that the function does not refer to any upvalues in its code. It will print an error if it does though
-- Also, each thread has a .1 second delay! This is used to generate a random value for each thread!
require("core.GuiManager")
gui.ff.Color=Color.Black
queue=multi:newSystemThreadedQueue("QUEUE"):init()
queue:push("This is a test")
queue:push("This is a test2")
queue:push("This is a test3")
queue:push("This is a test4")
multi:newSystemThread("test2",function()
	queue=sThread.waitFor("QUEUE"):init()
	data=queue:pop()
	while data do
		print(data)
		data=queue:pop()
	end
	queue:push("DONE!")
end)
multi:newThread("test!",function()
	thread.hold(function() return queue:pop() end)
	t.text="Done!"
end)
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
```
In Lanes
---
```lua
-- The code is compatible with each other, I just wanted to show different things you can do in both examples
-- This file can be found in the examples folder as lanesintegrationtest4.lua
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
queue=multi:newSystemThreadedQueue("QUEUE"):init()
queue:push("This is a test")
queue:push("This is a test2")
queue:push("This is a test3")
queue:push("This is a test4")
multi:newSystemThread("test2",function()
	queue=sThread.waitFor("QUEUE"):init()
	data=queue:pop()
	while data do
		print(data)
		data=queue:pop()
	end
	queue:push("This is a test5")
	queue:push("This is a test6")
	queue:push("This is a test7")
	queue:push("This is a test8")
end)
multi:newThread("test!",function() -- this is a lua thread
	thread.sleep(.1)
	data=queue:pop()
	while data do
		print(data)
		data=queue:pop()
	end
end)
multi:mainloop()
```

# Update: 1.7.6
Fixed:
---
Typos like always
Added:
---
- multi:getPlatform() — returns "love2d" if using the love2d platform or returns "lanes" if using lanes for threading
- examples files
- In Events added method setTask(func) --The old way still works and is more convent to be honest, but I felt a method to do this was needed for completeness.

Improved:
---
- Some example files to reflect changes to the core. Changes allow for less typing</br>
loveManager to require the compat if used so you don't need 2 require line to retrieve the library</br>

# Update: 1.7.5
Fixed some typos in the readme... (I am sure there are more there are always more)</br>
Added more features for module support</br>
TODO:</br>
Work on performance of the library... I see 3 places where I can make this thing run quicker</br>

I'll show case some old versions of the multitasking library eventually so you can see its changes in days past!</br>

# Update: 1.7.4
Added: the example folder which will be populated with more examples in the near future!</br>
The loveManager integration that mimics the lanesManager integration almost exactly to keep coding in both environments as close to possible. This is done mostly for library creation support!</br>
An example of the loveManager in action using almost the same code as the lanesintergreationtest2.lua</br>
NOTE: This code has only been tested to work on love2d version 1.10.2 though it should work version 0.9.0
```lua
require("core.Library") -- Didn't add this to a repo yet! Will do eventually... Allows for injections and other cool things
require("multi.compat.love2d") -- allows for multitasking and binds my libraries to the love2d engine that i am using
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager
--IMPORTANT
-- Do not make the above local, this is the one difference that the lanesManager does not have
-- If these are local the functions will have the upvalues put into them that do not exist on the threaded side
-- You will need to ensure that the function does not refer to any upvalues in its code. It will print an error if it does though
-- Also each thread has a .1 second delay! This is used to generate a random values for each thread!
require("core.GuiManager") -- allows the use of graphics in the program.
gui.ff.Color=Color.Black
function comma_value(amount)
	local formatted = amount
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end
multi:newSystemThread("test1",function() -- Another difference is that the multi library is already loaded in the threaded enviroment as well as a call to multi:mainloop()
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 1"):OnBench(function(self,c) GLOBAL["T1"]=c multi:Stop() end)
end)
multi:newSystemThread("test2",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 2"):OnBench(function(self,c) GLOBAL["T2"]=c multi:Stop() end)
end)
multi:newSystemThread("test3",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 3"):OnBench(function(self,c) GLOBAL["T3"]=c multi:Stop() end)
end)
multi:newSystemThread("test4",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 4"):OnBench(function(self,c) GLOBAL["T4"]=c multi:Stop() end)
end)
multi:newSystemThread("test5",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 5"):OnBench(function(self,c) GLOBAL["T5"]=c multi:Stop() end)
end)
multi:newSystemThread("test6",function() -- spawns a thread in another lua process
	multi:benchMark(sThread.waitFor("Bench"),nil,"Thread 6"):OnBench(function(self,c) GLOBAL["T6"]=c multi:Stop() end)
end)
multi:newSystemThread("Combiner",function() -- spawns a thread in another lua process
	function comma_value(amount)
		local formatted = amount
		while true do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then
				break
			end
		end
		return formatted
	end
	local b=comma_value(tostring(sThread.waitFor("T1")+sThread.waitFor("T2")+sThread.waitFor("T3")+sThread.waitFor("T4")+sThread.waitFor("T5")+sThread.waitFor("T6")))
	GLOBAL["DONE"]=b
end)
multi:newThread("test0",function()
	-- sThread.waitFor("DONE") -- lets hold the main thread completely so we don't eat up cpu
	-- os.exit()
	-- when the main thread is holding there is a chance that error handling on the system threads may not work!
	-- instead we can do this
	while true do
		thread.skip(1) -- allow error handling to take place... Otherwise let’s keep the main thread running on the low
		-- Before we held just because we could... But this is a game and we need to have logic continue
		--sThreadM.sleep(.001) -- Sleeping for .001 is a great way to keep cpu usage down. Make sure if you aren't doing work to rest. Abuse the hell out of GLOBAL if you need to :P
		if GLOBAL["DONE"] then
			t.text="Bench: "..GLOBAL["DONE"]
		end
	end
end)
GLOBAL["Bench"]=3
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
```

# Update: 1.7.3
Changed how requiring the library works!
`require("multi.all")` Will still work as expected; however, with the exception of threading, compat, and integrations everything else has been moved into the core of the library.
```lua
-- This means that these are no longer required and will cause an error if done so
require("multi.loop")
require("multi.alarm")
require("multi.updater")
require("multi.tloop")
require("multi.watcher")
require("multi.tstep")
require("multi.step")
require("multi.task")
-- ^ they are all part of the core now
```

# Update: 1.7.2
Moved updaters, loops, and alarms into the init.lua file. I consider them core features and they are referenced in the init.lua file so they need to exist there. Threaded versions are still separate though. Added another example file

# Update: 1.7.1 - Bug Fixes Only
¯\\_(ツ)_/¯
---
# Update: 1.7.0 - Threading the systems
Modified: multi.integration.lanesManager.lua
It is now in a stable and simple state works with the latest lanes version! Tested with version 3.11 I cannot promise that everything will work with earlier versions. Future versions are good though.</br>
Example Usage:</br>
sThread is a handle to a global interface for system threads to interact with themselves</br>
thread is the interface for multithreads as seen in the threading section</br>

GLOBAL a table that can be used throughout each and every thread

sThreads have a few methods</br>
sThread.set(name,val) — you can use the GLOBAL table instead modifies the same table anyway</br>
sThread.get(name) — you can use the GLOBAL table instead modifies the same table anyway</br>
sThread.waitFor(name) — waits until a value exists, if it does it returns it</br>
sThread.getCores() — returns the number of cores on your cpu</br>
sThread.sleep(n) — sleeps for a bit stopping the entire thread from running</br>
sThread.hold(n) — sleeps until a condition is met</br>
```lua
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
require("multi.all")
multi:newAlarm(2):OnRing(function(self)
	GLOBAL["NumOfCores"]=sThread.getCores()
end)
multi:newAlarm(7):OnRing(function(self)
	GLOBAL["AnotherTest"]=true
end)
multi:newAlarm(13):OnRing(function(self)
	GLOBAL["FinalTest"]=true
end)
multi:newSystemThread("test",function() -- spawns a thread in another lua process
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the integration. You would need to require the interaction again though
	print("Waiting for variable: NumOfCores")
	print("Got it: ",sThread.waitFor("NumOfCores"))
	sThread.hold(function()
		return GLOBAL["AnotherTest"] -- note this would hold the entire systemthread. Spawn a coroutine thread using multi:newThread() or multi:newThreaded...
	end)
	print("Holding works!")
	multi:newThread("tests",function()
		thread.hold(function()
			return GLOBAL["FinalTest"] -- note this will not hold the entire systemthread. As seen with the TLoop constantly going!
		end)
		print("Final test works!")
		os.exit()
	end)
	local a=0
	multi:newTLoop(function()
		a=a+1
		print(a)
	end,.5)
	multi:mainloop()
end)
multi:mainloop()
```

# Update: 1.6.0
Changed:
---
- steps
- loops
```lua
-- Was
step:OnStep(function(pos,self) -- same goes for tsteps as well
	print(pos)
end)
multi:newLoop(function(dt,self)
	print(dt)
end)
-- Is now
step:OnStep(function(self,pos) -- same goes for tsteps as wellc
	print(pos)
end)
multi:newLoop(function(self,dt)
	print(dt)
end)
```
Reasoning I wanted to keep objects consistent, but a lot of my older libraries use the old way of doing things. Therefore, I added a backwards module

**Note from the future:** That module has been canned. To be honest most features this low in the changelog are outdated and probably do not work.
```lua
require("multi.all")
require("multi.compat.backwards[1,5,0]") -- allows for the use of features that were scrapped/changed in 1.6.0+
```
# Update: 1.5.0
Added:
---
- An easy way to manage timeouts
- Small bug fixes

# Update: 1.4.1 (4/10/2017) - First Public release of the library
Added:
- SystemThreading very infancy

Change:
---
- small change to the hold method to make it a bit more lightweight
	- Using a timer instead of an alarm object!
- Limits to hold:
	- cannot hold more than 1 object at a time, and doing so could cause a deadlock!

**Note:** Wow you looked back this far. Nice, while your at it take a look at the old versions to view the code how it was before my first initial release

Upcomming:
---
- Threaded objects wrapped in coroutines, so you can hold/sleep without problems!

# Update: 1.4.0 (3/20/2017)
Added:
---
- multiobj:reallocate(ProcessObj) — changes the parent process of an object
- ProcessObj:getController() — returns the mThread so you can opperate on it like a multiobj
Example 1
---
```lua
require("multimanager") -- require the library
int1=multi:newProcess() -- create a process
int1.NAME="int1" -- give it a name for example purposes
int2=multi:newProcess() -- create another process to reallocate
int2.NAME="int2" -- name this a different name
step=int1:newTStep(1,10) -- create a TStep so we can slowly see what is going on
step:OnStep(function(p,s) -- connect to the onstep event
	print(p,s.Parent.NAME) -- print the position and process name
end)
step:OnEnd(function(s) -- when the step ends lets reallocate it to the other process
	if s.Parent.NAME=="int1" then -- lets only do this if it is in the int1 process
		s:reallocate(int2) -- send it to int2
		s:Reset() -- reset the object
	else
		print("We are done!")
		os.exit() -- end the program when int2 did its thing
	end
end)
int1:Start() -- start process 1
int2:Start() -- start process 2
multi:mainloop() -- start the main loop
```
Fixed/Updated:
---
- queuer=multi:newQueuer([string: file])
- Alarms now preform as they should on a queuer
Example 2
---
```lua
int=multi:newQueuer()
step=int:newTStep(1,10,1,.5)
alarm=int:newAlarm(2)
step2=int:newTStep(1,5,1,.5)
step:OnStep(function(p,s)
	print(p)
end)
step2:OnStep(function(p,s)
	print(p,"!")
end)
alarm:OnRing(function(a)
	print("Ring1!!!")
end)
int:OnQueueCompleted(function(s)
	s:Pause()
	print("Done!")
	os.exit()
end)
int:Start()
multi:mainloop()
```

# Update: 1.3.0 (1/29/2017)
Added:
---
- Load detection!
	- multi.threshold — minimum amount of cycles that all mObjs should be allotted before the Manager is considered burdened. Defualt: 256
	- multi.threstimed — amount of time when counting the number of cycles, Greater gives a more accurate view of the load, but takes more time. Defualt: .001
	- multi:setThreshold(n) — method used to set multi.threshold
	- multi:setThrestimed(n) — method used to set multi.threstimed
	- multi:getLoad() — returns a number between 0 and 100

# Update: 1.2.0 (12.31.2016)
Added:
---
- connectionobj.getConnection(name) — returns a list of an instance (or instances) of a single connect made with connectionobj:connect(func,name) or connectionobj(func,name) if you can organize data before hand you can route info to certain connections thus saving a lot of cpu time. 

**NOTE:** Only one name per each connection... you can't have 2 of the same names in a dictonary... the last one will be used

Changed:
---
- Started keeping track of dates
- obj=multi:newConnection()
	- obj:connect(func,name) and obj(func,name)
	- Added the name argument to allow indexing specific connection objects... Useful when creating an async library

# Update: 1.1.0
Changed:
---
- multi:newConnection(protect) — Changed the way you are able to interact with it by adding the __call metamethod
Old Usage:
```lua
OnUpdate=multi:newConnection()
OnUpdate:connect(function(...)
	print("Updating",...)
end)
OnUpdate:Fire(1,2,3)
```
New Usage:
```lua
OnUpdate=multi:newConnection()
OnUpdate(function(...)
	print("Updating",...)
end)
OnUpdate:Fire(1,2,3)
```

# Update: 1.0.0
Added:
---
- Start of official changelog (internal)

# Update: 0.6.3
**Note:** No official changelog was made for versions this old. Doing code comparsions is way too much work

# Update: 0.6.2
**Note:** No official changelog was made for versions this old. Doing code comparsions is way too much work

# Update: 0.6.1-6
**Note:** No official changelog was made for versions this old. Doing code comparsions is way too much work

# Update: 0.5.1-6
**Note:** No official changelog was made for versions this old. Doing code comparsions is way too much work

# Update: 0.4.1
**Note:** No official changelog was made for versions this old. Doing code comparsions is way too much work

# Update: 0.3.0 - The update that started it all
Changed:
---
- Renamed the library to multi from EventManager and a ton of resturcturing
- Started the version numbering over

# Update: EventManager 2.0.0
Changed:
---
- Everything, complete restructuring of the library from function based to object based. Resembles the modern version of the library

Added:
---
- Love2d support basic
- event:benchMark()
- event:lManager() — like uManager, but for love2d
- event:uManager(dt) — you could pass the change in time to the method
- event:cManager()
- event:manager() — old version of mainloop()
- @onClose(func) — modifidable
- event:onDraw(func)
- event:onUpdate(func)
- @event:onStart() — modifidable
- event:stop()
- event:createTrigger(func)
- event:createTStep(start,reset,timer,count)
- event:createStep(start,reset,count,skip)
- event:createLoop()
- event:newTask(func)
- event:newAlarm(set,func,start)
- event:hold(task)
- event:oneETime(func) — One time function call
- event:oneTime(func)
# Update: EventManager 1.2.0
Changed:
---
- Made Alarms have their own load order, before alarms were grouped with events
- events started becoming more object like
- event:setAlarm => event:newAlarm() returns alarm object
Note: Weird period where both fuction based and object based features worked!

Added:
---
- event:Hold(task)
- event:destroyEvent(tag) — destroys an event

# Update: EventManager 1.1.0
Added:
---
- LoadOrder — allow you to change what was processed first events, steps, or updates
- event:setLoadOrder(str) — ESU,EUS,USE,UES,SEU,SUE
- event:createTStep(tag,reset,timer,endc) — works like steps but sleeps between loops
# Update: EventManager 1.0.0 - Error checking
Changed:
---
- Added error checking which would alert you when something was done wrong

# Version: EventManager 0.0.1 - In The Beginning things were very different
Usage:
---
```lua
require("BasicCommands")
require("EventManager")
event:setAlarm("test",1)
a=0
b=0
function Alarm_test(tag)
	print("Alarm: "..tag)
	a = 1
	b=b+1
	event:updateAlarm("test",1)
end
event:setEvent("test()","a == 1")
event:setEvent("test2()","b == 5")
function Event_test()
	print("Event! A=1 which means the alarm rang")
	a = 0
end
function Event_test2()
	event:Stop()
end
-- this might feel somewhat familiar
step = event:createStep("test",10,true)
function Step_test(pos)
	print(pos,self)
end
function Step_test_End(tag)
	step:Remove()
end
function event:OnCreate()
	print(event:stepExist("test"))
	print(event:eventExist("test"))
	print(event:alarmExist("test"))
end
function event:OnUpdate()
	-- Called every cycle
end
function event:OnClose()
	print("Manager was stopped!")
end
event:Manager()
--event:CManager()
--event:UManager() -- One of the few things that lived in name and spirit the u just became lowercase haha
```