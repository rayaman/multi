# Changes
[TOC]
Update 14.0.0 Consistency, Additions and Stability
-------------
Added:
- multi.init() -- Initlizes the library! Must be called for multiple files to have the same handle. Example below
- thread.holdFor(NUMBER sec, FUNCTION condition) -- Works like hold, but timesout when a certain amount of time has passed!
- multi.hold(function or number) -- It's back and better than ever! Normal multi objs without threading will all be halted where threads will still run. If within a thread continue using thread.hold() and thread.sleep()
- thread.holdWithin(NUMBER; cycles,FUNCTION; condition) -- Holds until the condition is met! If the number of cycles passed is equal to cycles, hold will return a timeout error
- multi.holdFor(NUMBER; seconds,FUNCTION; condition) -- Follows the same rules as multi.hold while mimicing the functionality of thread.holdWithin
**Note:** when hold has a timeout the first argument will return nil and the second atgument will be TIMEOUT, if not timed out hold will return the values from the conditions
- thread objects now have hooks that allow you to interact with it in more refined ways!
-- tObj.OnDeath(self,status,returns[...]) -- This is a connection that passes a reference to the self, the status, whether or not the thread ended or was killed, and the returns of the thread.
-- tObj.OnError(self,error) -- returns a reference to self and the error as a string
-- **Limitations:** only 7 returns are possible! This was done because creating and destroying table objects are slow. (The way the scheduler works this would happen every cycle and thats no good) Instead I capture the return values from coroutine.resume into local variables and only allowed it to collect 7 max.
- thread.run(function) -- Can only be used within a thread, creates another thread that can do work, but automatically returns whatever from the run function -- Use thread newfunctions for a more powerful version of thread.run()
- thread:newFunction(FUNCTION; func)
-- returns a function that gives you the option to wait or connect to the returns of the function.
-- func().wait() -- waits for the function to return works both within a thread and outside of one
-- func().connect() -- connects to the function finishing
-- func() -- If your function does not return anything you dont have to use wait or connect at all and the function will return instantly. You could also use wait() to hold until the function does it thing
-- If the created function encounters an error, it will return nil, the error message!
- special variable multi.NIL was added to allow error handling in threaded functions.
-- multi.NIL can be used in to force a nil value when using thread.hold()
- All functions created in the root of a thread are now converted to threaded functions, which allow for wait and connect features. **Note:** these functions are local to the function! And are only converted if they aren't set as local! Otherwise the function
- lanes threads can now have their priority set using: sThread.priority = 
-- thread.Priority_Core
-- thread.Priority_High
-- thread.Priority_Above_Normal
-- thread.Priority_Normal
-- thread.Priority_Below_Normal
-- thread.Priority_Low
-- thread.Priority_Idle
- thread.hold() and multi.hold() now accept connections as an argument. See example below

```lua
package.path = "./?/init.lua;"..package.path
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
package.path = "./?/init.lua;" .. package.path
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
- Connections had a preformance issue where they would create a non function when using connection.getConnection() of a non existing label.
- An internal mismanagement of the threads scheduler was fixed. Now it should be quicker and free of bugs
- Thread error management is the integrations was not properly implemented. This is now fixed

Removed:
- multi:newWatcher() -- No real use
- multi:newCustomObject() -- No real use

Changed:
- Connections connect function can now chain connections
```lua
	package.path = "./?/init.lua;"..package.path
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
- Finish the rework of the networkManager - It "works", but there are packet losses that I cannot explain. I do not know what is causing this at all. Ill fix when I figure it out!
- If all goes well, the future will contain quality of code features. I'll keep an eye out for bugs

Update 13.1.0 Bug fixes and features added
-------------
Added: 
- Connections:Lock() -- Prevents a connection object form being fired
- Connections:Unlock() -- Removes the restriction imposed by conn:Lock()
- new fucntions added to the thread namespace
-- thread.request(THREAD handle,STRING cmd,VARARGS args) -- allows you to push thread requests from outside the running thread! Extremely powerful.
-- thread.exec(FUNCTION func) -- Allows you to push code to run within the thread execution block!
- handle = multi:newThread() -- now returns a thread handle to interact with the object outside fo the thread
-- handle:Pause()
-- handle:Resume()
-- handle:Kill()

Fixed:
- Minor bug with multi:newThread() in how names and functions were managed
- Major bug with the system thread handler. Saw healthy threads as dead ones
- Major bug the thread scheduler was seen creating a massive amount of 'event' causing memory leaks and hard crashes! This has been fixed by changing how the scheduler opperates. 
- newSystemThread()'s returned object now matches both the lanes and love2d in terms of methods that are usable. Error handling of System threads now behave the same across both love and lanes implementations.
- looks like I found a typo, thread.yeild -> thread.yield

Changed: 
- getTasksDetails("t"), the table varaiant, formats threads, and system threads in the same way that tasks are formatted. Please see below for the format of the task details
- TID has been added to multi objects. They count up from 0 and no 2 objects will have the same number
- thread.hold() -- As part of the memory leaks that I had to fix thread.hold() is slightly different. This change shouldn't impact previous code at all, but thread.hold() can not only return at most 7 arguments!
- You should notice some faster code execution from threads, the changes improve preformance of threads greatly. They are now much faster than before!
- multi:threadloop() -- No longer runs normal multi objects at all! The new change completely allows the multi objects to be seperated from the thread objects!
- local multi, thread = require("multi") -- Since coroutine based threading has seen a change to how it works, requring the multi library now returns the namespace for the threading interface as well. For now I will still inject into global the thread namespace, but in release 13.2.0 or 14.0.0 It will be removed!


# Tasks Details Table format
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
Update 13.0.0 Added some documentation, and some new features too check it out!
-------------
**Quick note** on the 13.0.0 update:
This update I went all in finding bugs and improving proformance within the library. I added some new features and the new task manager, which I used as a way to debug the library was a great help, so much so thats it is now a permanent feature. It's been about half a year since my last update, but so much work needed to be done. I hope you can find a use in your code to use my library. I am extremely proud of my work; 7 years of development, I learned so much about lua and programming through the creation of this library. It was fun, but there will always be more to add and bugs crawling there way in. I can't wait to see where this library goes in the future!

Fixed: Tons of bugs, I actually went through the entire library and did a full test of everything, I mean everything, while writing the documentation.
Changed: 
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
- Ranges and conditions -- corutine based threads can emulate what these objects did and much better!
- Due to the creation of hyper threaded processes the following objects are no more!
-- ~~multi:newThreadedEvent()~~
-- ~~multi:newThreadedLoop()~~
-- ~~multi:newThreadedTLoop()~~
-- ~~multi:newThreadedStep()~~
-- ~~multi:newThreadedTStep()~~
-- ~~multi:newThreadedAlarm()~~
-- ~~multi:newThreadedUpdater()~~
-- ~~multi:newTBase()~~ -- Acted as the base for creating the other objects

These didn't have much use in their previous form, but with the addition of hyper threaded processes the goals that these objects aimed to solve are now possible using a process

Fixed:
- There were some bugs in the networkmanager.lua file. Desrtoy -> Destroy some misspellings.
- Massive object management bugs which caused performance to drop like a rock.
- Found a bug with processors not having the Destroy() function implemented properly.
- Found an issue with the rockspec which is due to the networkManager additon. The net Library and the multi Library are now codependent if using that feature. Going forward you will have to now install the network library separately
- Insane proformance bug found in the networkManager file, where each connection to a node created a new thread (VERY BAD) If say you connected to 100s of threads, you would lose a lot of processing power due to a bad implementation of this feature. But it goes further than this, the net library also creates a new thread for each connection made, so times that initial 100 by about 3, you end up with a system that quickly eats itself. I have to do tons of rewriting of everything. Yet another setback for the 13.0.0 release (Im releasing 13.0.0 though this hasn't been ironed out just yet)
- Fixed an issue where any argument greater than 256^2 or 65536 bytes is sent the networkmanager would soft crash. This was fixed by increading the limit to 256^4 or 4294967296. The fix was changing a 2 to a 4. Arguments greater than 256^4 would be impossible in 32 bit lua, and highly unlikely even in lua 64 bit. Perhaps someone is reading an entire file into ram and then sending the entire file that they read over a socket for some reason all at once!?
- Fixed an issue with processors not properly destroying objects within them and not being destroyable themselves
- Fixed a bug where pause and resume would duplicate objects! Not good
- Noticed that the switching of lua states, corutine based threading, is slower than multi-objs (Not by much though).
- multi:newSystemThreadedConnection(name,protect) -- I did it! It works and I believe all the gotchas are fixed as well.
-- Issue one, if a thread died that was connected to that connection all connections would stop since the queue would get clogged! FIXED
-- There is one thing, the connection does have some handshakes that need to be done before it functions as normal!

Added:
- Documentation, the purpose of 13.0.0, orginally going to be 12.2.3, but due to the amount of bugs and features added it couldn't be a simple bug fix update.
- multi:newHyperThreadedProcess(STRING name) -- This is a version of the threaded process that gives each object created its own coroutine based thread which means you can use thread.* without affecting other objects created within the hyper threaded processes. Though, creating a self contained single thread is a better idea which when I eventually create the wiki page I'll discuss
- multi:newConnector() -- A simple object that allows you to use the new connection Fire syntax without using a multi obj or the standard object format that I follow.
- multi:purge() -- Removes all references to objects that are contained withing the processes list of tasks to do. Doing this will stop all objects from functioning. Calling Resume on an object should make it work again.
- multi:getTasksDetails(STRING format) -- Simple function, will get massive updates in the future, as of right now It will print out the current processes that are running; listing their type, uptime, and priority. More useful additions will be added in due time. Format can be either a string "s" or "t" see below for the table format
- multi:endTask(TID) -- Use multi:getTasksDetails("t") to get the tid of a task
- multi:enableLoadDetection() -- Reworked how load detection works. It gives better values now, but it still needs some work before I am happy with it
- THREAD.getID() -- returns a unique ID for the current thread. This varaiable is visible to the main thread as well by accessing it through the returned thread object. OBJ.Id Do not confuse this with thread.* this refers to the system threading interface. Each thread, including the main thread has a threadID the main thread has an ID of 0!
- multi.print(...) works like normal print, but only prints if the setting print is set to true
- setting: `print` enables multi.print() to work
- STC: IgnoreSelf defaults to false, if true a Fire command will not be sent to the self
- STC: OnConnectionAdded(function(connID)) -- Is fired when a connection is added you can use STC:FireTo(id,...) to trigger a specific connection. Works like the named non threaded connections, only the id's are genereated for you.
- STC: FireTo(id,...) -- Described above.

```lua
package.path="?/init.lua;?.lua;"..package.path
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

Update 12.2.2 Time for some more bug fixes!
-------------
Fixed: multi.Stop() not actually stopping due to the new pirority management scheme and preformance boost changes.
Thats all for this update

Update 12.2.1 Time for some bug fixes!
-------------
Fixed: SystemThreadedJobQueues
- You can now make as many job queues as you want! Just a warning when using a large amount of cores for the queue it takes a second or 2 to set up the jobqueues for data transfer. I am unsure if this is a lanes thing or not, but love2d has no such delay when setting up the jobqueue!
- You now connect to the OnReady in the jobqueue object. No more holding everything else as you wait for a job queue to be ready
- Jobqueues:doToAll now passes the queues multi interface as the first and currently only argument
- No longer need to use jobqueue.OnReady() The code is smarter and will send the pushed jobs automatically when the threads are ready

Fixed: SystemThreadedConnection
- They work the exact same way as before, but actually work as expected now. The issue before was how i implemented it. Now each connection knows the number of instances of that object that ecist. This way I no longer have to do fancy timings that may or may not work. I can send exactly enough info for each connection to consume from the queue.

Removed: multi:newQueuer
- This feature has no real use after corutine based threads were introduced. You can use those to get the same effect as the queuer and do it better too. 

Going forwardGoing forward:
- Will I ever finish steralization? Who knows, but being able to save state would be nice. The main issue is there is no simple way to save state. While I can provide methods to allow one to turn the objects into strings and back, there is no way for me to make your code work with it in a simple way. For now only the basic functions will be here.
- I need to make better documentation for this library as well. In its current state, all I have are examples and not a list of what is what.

# Example
```lua
package.path="?/init.lua;?.lua;"..package.path
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

Update 12.2.0
-------------
**Added:**
- multi.nextStep(func)
- Method chaining
- Priority 3 has been added!
- ResetPriority() -- This will set a flag for a process to be re evaluated for how much of an impact it is having on the performance of the system.
- setting: auto_priority added! -- If only lua os.clock was more fine tuned... milliseconds are not enough for this to work
- setting: auto_lowerbound added! -- when using auto_priority this will allow you to set the lowbound for pirority. The defualt is a hyrid value that was calculated to reach the max potential with a delay of .001, but can be changed to whatever. Remember this is set to processes that preform really badly! If lua could handle more detail in regards to os.clock() then i would set the value a bit lower like .0005 or something like that
- setting: auto_stretch added! -- This is another way to modify the extent of the lowest setting. This reduces the impact that a low preforming process has! Setting this higher reduces the number of times that a process is called. Only in effect when using auto_priotity
- setting: auto_delay added! -- sets the time in seconds that the system will recheck for low performing processes and manage them. Will also upgrade a process if it starts to run better.
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
P3 Ignores using a basic funceion and instead bases its processing time on the amount of cpu time is there. If  cpu-time is low and a process is set at a lower priority it will get its time reduced. There is no formula, at idle almost all process work at the same speed!
```
C: 2120906
H: 2120906
A: 2120906
N: 2120906
B: 2120906
L: 2120906
I: 2120506
```

Auto Priority works by seeing what should be set high or low. Due to lua not having more persicion than milliseconds, I was unable to have a detailed manager that can set things to high, above normal, normal, ect. This has either high or low. If a process takes longer than .001 millisecond it will be set to low priority. You can change this by using the setting auto_lowest = multi.Priority_[PLevel] the defualt is low, not idle, since idle tends to get about 1 process each second though you can change it to idle using that setting.

**Improved:**
- Performance at the base level has been doubled! On my machine benchmark went from ~9mil to ~20 mil steps/s.
Note: If you write slow code this library's improbements wont make much of a difference.
- Loops have been optimised as well! Being the most used objects I felt they needed to be made as fast as possible

I usually give an example of the changes made, but this time I have an explantion for multi.nextStep(). It's not an entirely new feature since multi:newJob() does something like this, but is completely different. nextStep addes a function that is executed first on the next step. If multiple things are added to next step, then they will be executed in the order that they were added.

Note:
The upper limit of this libraries performance on my machine is ~39mil. This is simply a while loop counting up from 0 and stops after 1 second. The 20mil that I am currently getting is probably as fast as it can get since its half of the max performance possible, and each layer I have noticed that it doubles complexity. Throughout the years with this library I have seen massive improvements in speed. In the beginning we had only ~2000 steps per second. Fast right? then after some tweaks we went to about 300000 steps per second, then 600000. Some more tweaks brought me to ~1mil steps per second, then to ~4 mil then ~9 mil and now finally ~20 mil... the doubling effect that i have now been seeing means that odds are I have reach the limit. I will aim to add more features and optimize individule objects. If its possible to make the library even faster then I will go for it.


Update 12.1.0
-------------
Fixed:
- bug causing arguments when spawning a new thread not going through

Changed:
- thread.hold() now returns the arguments that were pass by the event function
- event objexts now contain a copy of what returns were made by the function that called it in a table called returns that exist inside of the object

```lua
package.path="?/init.lua;?.lua;"..package.path
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

# Going forward:
Contunue to make small changes as I come about them. This change was inspired when working of the net library. I was addind simple binary file support over tcp, and needed to pass the data from the socket when the requested amount has been recieved. While upvalues did work, i felt returning data was cleaner and added this feature.

Update: 12.0.0 Big update (Lots of additions some changes)
------------------------
**Note:** ~~After doing some testing, I have noticed that using multi-objects are slightly, quite a bit, faster than using (coroutines)multi:newthread(). Only create a thread if there is no other possibility! System threads are different and will improve performance if you know what you are doing. Using a (coroutine)thread as a loop with a 
is slower than using a TLoop! If you do not need the holding features I strongly recommend that you use the multi-objects. This could be due to the scheduler that I am using, and I am looking into improving the performance of the scheduler for (coroutine)threads. This is still a work in progress so expect things to only get better as time passes!~~ This was the reason threadloop was added. It binds the thread scheduler into the mainloop allowing threads to run much faster than before. Also the use of locals is now possible since I am not dealing with seperate objects. And finally, reduced function overhead help keeps the threads running better.

#Added:
- `nGLOBAL = require("multi.integration.networkManager").init()`
- `node = multi:newNode(tbl: settings)`
- `master = multi:newMaster(tbl: settings)`
- `multi:nodeManager(port)`
- `thread.isThread()` -- for coroutine based threads
- New setting to the main loop, stopOnError which defaults to true. This will cause the objects that crash, when under protect, to be destroyed. So the error does not keep happening.
- multi:threadloop(settings) works just like mainloop, but prioritizes (corutine based) threads. Regular multi-objects will still work. This improves the preformance of (coroutine based) threads greatly.
- multi.OnPreLoad -- an event that is triggered right before the mainloop starts

Changed:
- When a (corutine based)thread errors it does not print anymore! Conect to multi.OnError() to get errors when they happen!
- Connections get yet another update. Connect takes an additional argument now which is the position in the table that the func should be called. Note: Fire calls methods backwards so 1 is the back and the # of connections (the default value) is the beginning of the call table
- The love2d compat layer has now been revamped allowing module creators to connect to events without the user having to add likes of code for those events. Its all done automagically.
- This library is about 8 years old and using 2.0.0 makes it seem young. I changed it to 12.0.0 since it has some huge changes and there were indeed 12 major releases that added some cool things. Going forward I'll use major.minor.bugfix
- multi.OnError() is now required to capture errors that are thrown when in prorected mode.

#Node:
- node:sendTo(name,data)
- node:pushTo(name,data)
- node:peek()
- node:pop()
- node:getConsole() -- has only 1 function print which allows you to print to the master.

#Master:
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
- master:OnError(nodename, error) -- if a node has an error this is triggered.

#Bugs
- Fixed a small typo I made which caused a hard crash when a (coroutine) thread crashes. This only happened if protect was true.

#Going forward:
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
package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
multi:nodeManager(12345) -- Host a node manager on port: 12345
print("Node Manager Running...")
settings = {
	priority = 0, -- 1 or 2
	protect = false,
}
multi:mainloop(settings)
-- Thats all you need to run the node manager, everything else is done automatically

```

Side note: I had a setting called cross talk that would allow nodes to talk to each other. After some tought I decided to not allow nodes to talk to each other directly! You however can create another master withing the node. (The node will connect to its own master as well). This will give you the ability "Cross talk" with each node. Reimplementing the master features into each node directly was un nessacery. 

**Node.lua**
```lua
package.path="?/init.lua;?.lua;"..package.path
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
-- set up the package
package.path="?/init.lua;?.lua;"..package.path
-- Import the libraries
multi = require("multi")
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
