#Changes
[TOC]
Update: 2.0.0 Big update
------------------------
**Note:** After doing some testing, I have noticed that using multi-objects are slightly, quite a bit, faster than using (coroutines)multi:newthread(). Only create a thread if there is no other possibility! System threads are different and will improve performance if you know what you are doing. Using a (coroutine)thread as a loop with a timer is slower than using a TLoop! If you do not need the holding features I strongly recommend that you use the multi-objects. This could be due to the scheduler that I am using, and I am looking into improving the performance of the scheduler for (coroutine)threads. This is still a work in progress so expect things to only get better as time passes!

#Added:
- require("multi.integration.networkManager")
- multi:newNode([name])
- multi:newMaster(name)

**Note:** There are many ways to work this. You could send functions/methods to a node like haw systemThreadedJobQueue work. Or you could write the methods you want in advance in each node file and send over the command to run the method with arguments ... and it will return the results. Network threading is different than system threading. Data transfer is really slow compared to system threading. In fact the main usage for this feature in the library is mearly for experments. Right now I honestly do not know what I want to do with this feature and what I am going to add to this feature. The ablitiy to use this frature like a system thread will be possible, but there are some things that differ.

#Changed:
- multi:mainloop(settings) -- now takes a table of settings
- multi:uManager(settings) -- now takes a table of settings
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

#Improvements:
- Updated the ThreadedConsole, now 100x faster!
- Updated the ThreadedConections, .5x faster!
- Both multi:uManager(settings) and multi:mainloop(settings) provide about the same performance! Though uManager is slightly slower due to function overhead, but still really close.
- Revamped pausing mulit-objects they now take up less memory when being used

#Removed:
- require("multi.all") -- We are going into a new version of the library so this is nolonger needed
- require("multi.compat.backwards[1,5,0]") -- This is really old and is no longer supported going forward
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
- multi:oneTime(func,...) -- never seen use of this, plus multi-functions can do this by pausing the function after the first use, and is much faster anyway
- multi:reboot() -- removed due to having no real use
- multi:hold() -- removed due to threads being able to do the same thing and way better too
- multi:waitFor() -- the thread variant does something completely different
- multi.resurrect() -- removed due to being useless

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
Update: 1.11.1
--------------
Love2d change:
I didn't make a mistake but didn't fully understand how the new love.run function worked.
So, it works by returning a function that allows for running the mainloop. So, this means that we can do something like this:

```lua
multi:newLoop(love.run()) -- Run the mainloop here, cannot use thread.* when using this object

-- or

multi:newThread("MainLoop",love.run()) -- allows you to use the thread.*

--And you'll need to throw this in at the end
multi:mainloop()
```

For the long-time users of this library you know of the amazing multitasking features that the library has. Used correctly you can have insane power. The priority management system should be quite useful with this change. 
NOTE: **multiobj:hold() will be removed in the next version!** This is something I feel should be changed, since threads(coroutines) do the job great, and way better than my holding method that I throw together 5 years ago. I doubt this is being used by many anyway. Version 1.11.2 or version 2.0.0 will have this change. The next update may be either, bug fixes if any or network parallelism.

TODO: Add auto priority adjustments when working with priority and stuff... If the system is under heavy load it will dial some things deemed as less important down and raise the core processes.

Update: 1.11.0
--------------
Added:
- SystemThreadedConsole(name) -- Allow each thread to print without the sync issues that make prints merge and hard to read.

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


Update: 1.10.0
--------------
**Note:** The library is now considered to be stable!
**Upcoming:** Network parallelism is on the way. It is in the works and should be released soon

#Added:
- isMainThread true/nil
- multi:newSystemThreadedConnection(name,protect) -- Works like normal connections, but are able to trigger events across threads

Example of threaded connections
```lua
package.path="?/init.lua;?.lua;"..package.path
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

#Fixed:
**loveManager** and **shared threading objects**
- sThread.waitFor()
- sThread.hold()
- some typos
- SystemThreadedTables (They now work on both lanes and love2d as expected)

Example of threaded tables
```lua
package.path="?/init.lua;?.lua;"..package.path
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

Update: 1.9.2
-------------
Added:
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
Updated:
- LoadBalancing, well better load balancing than existed before. This one allowed for multiple processes to have their own load reading. Calling this on the multi object will return the total load for the entire multi environment... loads of other processes are indeed affected by what other processes are doing. However, if you combine propriety to the mix of things then you will get differing results... these results however will most likely be higher than normal... different priorities will have different default thresholds of performance.

Fixed:
- Thread.getName() should now work on lanes and love2d, haven't tested it much with the luvit side of things...
- A bug with the lovemanager table.remove arguments were backwards
- The queue object in the love2d threading has been fixed! It now supports sending all objects (even functions if no upvalues are present!)

Changed:
- SystemThreadedJobQueues now have built in load management so they are not constantly at 100% CPU usage.
- SystemThreadedJobQueues pushJob now returns an id of that job which will match the same one that OnJobCompleted returns


Update: 1.9.1
-------------
Added:
- Integration "multi.integration.luvitManager"
- Limited... Only the basic multi:newSystemThread(...) will work
- Not even data passing will work other than arguments... If using the bin library, you can pass tables and function... Even full objects if inner recursion is not present.

Updated:
- multi:newSystemThread(name,func,...)
- It will not pass the ... to the func(). Do not know why this wasn't done in the first place
- Also multi:getPlatform(will now return "luvit" if using luvit... Though Idk if module creators would use the multi library when inside the luvit environment

Update: 1.9.0
-------------
Added:
- multiobj:ToString() -- returns a string representing the object
- multi:newFromString(str) -- creates an object from a string

Works on threads and regular objects. Requires the latest bin library to work!
```lua
talarm=multi:newThreadedAlarm("AlarmTest",5)
talarm:OnRing(function()
 	print("Ring!")
end)
bin.new(talarm:ToString()):tofile("test.dat")
-- multi:newFromString(bin.load("test.dat"))
```
-- A more seamless way to use this will be made in the form of state saving.
This is still a WIP
processes, timers, timemasters, watchers, and queuers have not been worked on yet
Update: 1.8.7
-------------
Added:
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
Update: 1.8.6
-------------
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
Update: 1.8.5
-------------
Added:
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
Update: 1.8.4
-------------
Added:
- multi:newSystemThreadedJobQueue()
- Improved stability of the library
- Fixed a bug that made the benchmark and getload commands non-thread(coroutine) safe
- Tweaked the loveManager to help improve idle CPU usage
- Minor tweaks to the coroutine scheduling

# Using multi:newSystemThreadedJobQueue()
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

Update: 1.8.3
-------------
Added:</br>
**New Mainloop functions** Below you can see the slight differences... Function overhead is not too bad in lua but has a real difference. multi:mainloop() and multi:unprotectedMainloop() use the same algorithm yet the dedicated unprotected one is slightly faster due to having less function overhead.
- multi:mainloop()\* -- Bench:  16830003 Steps in 3 second(s)!
- multi:protectedMainloop() -- Bench:  16699308 Steps in 3 second(s)!
- multi:unprotectedMainloop() -- Bench:  16976627 Steps in 3 second(s)!
- multi:prioritizedMainloop1() -- Bench:  15007133 Steps in 3 second(s)!
- multi:prioritizedMainloop2() -- Bench:  15526248 Steps in 3 second(s)!

\* The OG mainloop function remains the same and old methods to achieve what we have with the new ones still exist

These new methods help by removing function overhead that is caused through the original mainloop function. The one downside is that you no longer have the flexibility to change the processing during runtime.

However there is a work around! You can use processes to run multiobjs as well and use the other methods on them.

I may make a full comparison between each method and which is faster, but for now trust that the dedicated ones with less function overhead are infect faster. Not by much but still faster.

Update: 1.8.2
-------------
Added:</br>
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
# Using multi:newSystemThreadedTable(name)
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

Update: 1.8.1
-------------
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
- multi:canSystemThread() -- true if an integration was added false otherwise (For module creation)
- Fixed a few bugs in the loveManager

# Using multi:systemThreadedBenchmark()
```lua
package.path="?/init.lua;"..package.path
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
multi:systemThreadedBenchmark(3):OnBench(function(self,count)
	print("First Bench: "..count)
	multi:systemThreadedBenchmark(3,"All Threads: ")
end)
multi:mainloop()
```

# Using multi:newSystemThreadedQueue()
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
function multi:newSystemThreadedQueue(name) -- in love2d this will spawn a channel on both ends
	local c={}
	c.name=name
	if love then
		if love.thread then
			function c:init()
				self.chan=love.thread.getChannel(self.name)
				function self:push(v)
					self.chan:push(v)
				end
				function self:pop()
					return self.chan:pop()
				end
				GLOBAL[self.name]=self
				return self
			end
			return c
		else
			error("Make sure you required the love.thread module!")
		end
	else
		c.linda=lanes.linda()
		function c:push(v)
			self.linda:send("Q",v)
		end
		function c:pop()
			return ({self.linda:receive(0,"Q")})[2]
		end
		function c:init()
			return self
		end
		GLOBAL[name]=c
	end
	return c
end
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
# In Lanes
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
Update: 1.7.6
-------------
Fixed:
Typos like always
Added:</br>
multi:getPlatform() -- returns "love2d" if using the love2d platform or returns "lanes" if using lanes for threading</br>
examples files</br>
In Events added method setTask(func)</br>
The old way still works and is more convent to be honest, but I felt a method to do this was needed for completeness.</br>

Updated:
some example files to reflect changes to the core. Changes allow for less typing</br>
loveManager to require the compat if used so you don't need 2 require line to retrieve the library</br>

Update: 1.7.5
-------------
Fixed some typos in the readme... (I am sure there are more there are always more)</br>
Added more features for module support</br>
TODO:</br>
Work on performance of the library... I see 3 places where I can make this thing run quicker</br>

I'll show case some old versions of the multitasking library eventually so you can see its changes in days past!</br>

Update: 1.7.4
-------------
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
Update: 1.7.3
-------------
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

Update: 1.7.2
-------------
Moved updaters, loops, and alarms into the init.lua file. I consider them core features and they are referenced in the init.lua file so they need to exist there. Threaded versions are still separate though. Added another example file

Update: 1.7.1 Bug Fixes Only
-------------

Update: 1.7.0
-------------
Modified: multi.integration.lanesManager.lua
It is now in a stable and simple state Works with the latest lanes version! Tested with version 3.11 I cannot promise that everything will work with earlier versions. Future versions are good though.</br>
Example Usage:</br>
sThread is a handle to a global interface for system threads to interact with themselves</br>
thread is the interface for multithreads as seen in the threading section</br>

GLOBAL a table that can be used throughout each and every thread

sThreads have a few methods</br>
sThread.set(name,val) -- you can use the GLOBAL table instead modifies the same table anyway</br>
sThread.get(name) -- you can use the GLOBAL table instead modifies the same table anyway</br>
sThread.waitFor(name) -- waits until a value exists, if it does it returns it</br>
sThread.getCores() -- returns the number of cores on your cpu</br>
sThread.sleep(n) -- sleeps for a bit stopping the entire thread from running</br>
sThread.hold(n) -- sleeps until a condition is met</br>
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

Update: 1.6.0
-------------
Changed: steps and loops
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
```lua
require("multi.all")
require("multi.compat.backwards[1,5,0]") -- allows for the use of features that were scrapped/changed in 1.6.0+
```
Update: 1.5.0
-------------
Added:
- An easy way to manage timeouts
- Small bug fixes

Update: 1.4.1 - First Public release of the library
-------------

**IMPORTANT:**
Every update I make aims to make things simpler more efficient and just better, but a lot of old code, which can be really big, uses a lot of older features. I know the pain of having to rewrite everything. My promise to my library users is that I will always have backwards support for older features! New ways may exist that are quicker and easier, but the old features/methods will be supported.</br>**Note:** Version 2.x.x sort of breaks this promise. Sorry about that, but a new major version means changes that had to be made. Not too much has changed though and base code is 100% compatiable. What changed was how you init the library and some files that were removed due to not really being used by what i have seen. The older backwards compat file was for an older version of the library that was changed before the public release had any traction. The goal is still to provide a easy way to multitask in lua. I'll try my best however to ensure that not much changes and that changes are easy to make if they are introduced.
