Current Multi Version: 14.2.0

# Multi static variables
`multi.Version` -- The current version of the library

`multi.Priority_Core` -- Highest level of pirority that can be given to a process
</br>`multi.Priority_Very_High`
</br>`multi.Priority_High`
</br>`multi.Priority_Above_Normal`
</br>`multi.Priority_Normal` -- The default level of pirority that is given to a process
</br>`multi.Priority_Below_Normal`
</br>`multi.Priority_Low`
</br>`multi.Priority_Very_Low`
</br>`multi.Priority_Idle` -- Lowest level of pirority that can be given to a process

# Multi Runners
`multi:lightloop()` -- A light version of the mainloop
</br>`multi:mainloop([TABLE settings])` -- This runs the mainloop by having its own internal while loop running
</br>`multi:threadloop([TABLE settings])` -- This runs the mainloop by having its own internal while loop running, but prioritizes threads over multi-objects
</br>`multi:uManager([TABLE settings])` -- This runs the mainloop, but does not have its own while loop and thus needs to be within a loop of some kind.

# Multi Settings

**Note:** Most settings have been fined tuned to be at the peak of performance already, however preLoop, protect (Which drastically lowers preformance), and stopOnError should be used freely to fit your needs.

| Setting | Type: default | Purpose |
|-|-|-|
| preLoop | function: nil | This is a function that is called after all the important components of the library are loaded. This is called once only. The first and only argument passed is a reference to itself. |
| protect | boolean: false | This runs code within a protected call. To catch when errors happen see built in connections |
| stopOnError | boolean: false | This setting is used with protect. If an object crashes due to some error should it be paused? |
| priority | number: 0 | This sets the priority scheme. Look at the P-Charts below for examples. |
| auto_priority | boolean: false | **Note: This overrides any value set for priority!** If auto priority is enabled then priority scheme 3 is used and processes are considered for "recheck" after a certain amount of time. If a process isn't taking too long to complete anymore then it will be reset to core, if it starts to take a lot of time all of a sudden it will be set to idle. |
| auto_stretch | number: 1 | For use with auto_priority. Modifies the internal reperesentation of idle time by multiplying multi.Priority_Idle by the value given |
| auto_delay | number: 3 | For use with auto_priority. This changes the time in seconds that process are "rechecked" |
| auto_lowerbound | number: multi.Priority_Idle | For use with auto_priority. The lowerbound is what is considered to be idle time. A higher value combined with auto_stretch allows one to fine tune how pirority is managed. |

# P-Chart: Priority 1

P1 follows a forumla that resembles this: ~n=I*PRank</br>Where **n** is the amount of steps given to an object with PRank and where I is the idle time see chart below. The aim of this priority scheme was to make core objects run fastest while letting idle processes get decent time as well.

| Priority: n | PRank | Formula |
|-|-|-|
| Core: 3322269 | 7 | n = ~**I***7 |
| High: 2847660 | 6 | n = ~**I***6 |
| Above_Normal: 2373050 | 5 | n = ~**I***5 |
| Normal: 1898440 | 4 | n = ~**I***4 |
| Below_Normal: 1423830 | 3 | n = ~**I***3 |
| Low: 949220 | 2 | n = ~**I***2 |
| **I**dle: 474610 | 1 | n = ~**I***1 |

**General Rule:** ~n=**I***PRank

# P-Chart: Priority 2

P2 follows a formula that resembles this: ~n=n*4 where n starts as the initial idle time, see chart below. The goal of this one was to make core process’ higher while keeping idle process’ low.

| Priority: n |
|-|
| Core: 6700821|
| High: 1675205|
| Above_Normal: 418801|
| Normal: 104700|
| Below_Normal: 26175|
| Low: 6543|
| **I**dle: 1635|

**General Rule:** `~n=n*4` Where the inital n = **I**

# P-Chart: Priority 3
P3 Ignores using a basic formula and instead bases its processing time on the amount of cpu time is there. If cpu-time is low and a process is set at a lower priority it will get its time reduced. There is no formula, at idle almost all process work at the same speed!

There are 2 settings for this: Core and Idle. If a process takes too long then it is set to idle. Otherwise it will stay core.

Example of settings:
```lua
settings = {
	preLoop = function(m)
    	print("All settings have been loaded!")
    end,
    protect = false,
    stopOnError = false,
    priority = 0,
    auto_priority = false,
    auto_stretch = 1,
    auto_delay = 3,
    auto_lowerbound = multi.Priority_Idle
}

-- Below are how the runners work

multi:mainloop(settings)

-- or

multi:threadloop(settings)

-- or

while true do
	multi:uManager(settings)
end
```

# Non-Actors
`timer = multi:newTimer()`
</br>`conn = multi:newConnection([BOOLEAN protect true])`
</br>`nil = multi:newJob(FUNCTION func, STRING name)`
</br>`func = multi:newFunction(FUNCTION func)`
</br>`trigger = multi:newTrigger(FUNCTION: func)`

# Actors
`event = multi:newEvent(FUNCTION task)`
</br>`updater =  multi:newUpdater([NUMBER skip 1])`
</br>`alarm = multi:newAlarm([NUMBER 0])`
</br>`loop = multi:newLoop(FUNCTION func)`
</br>`tloop = multi:newTLoop(FUNCTION func ,NUMBER: [set 1])`
</br>`step = multi:newStep(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])`
</br>`tstep = multi:newStep(NUMBER start, NUMBER reset, [NUMBER count 1], [NUMBER set 1])`
</br>`trigger = multi:newTrigger(FUNCTION: func)`
</br>`stamper = multi:newTimeStamper()`
</br>`watcher = multi:newWatcher(STRING name)`
</br>`watcher = multi:newWatcher(TABLE namespace, STRING name)`
</br>`cobj = multi:newCustomObject(TABLE objRef, BOOLEAN isActor)`

**Note:** A lot of methods will return itself as a return. This allows for chaining of methods to work.

# Non-Actor: Timers
timer = multi:newTimer()
Creates a timer object that can keep track of time

**self** = timer:Start() -- Starts the timer
time_elapsed = timer:Get() -- Returns the time elapsed since timer:Start() was called
boolean = timer:isPaused() -- Returns if the timer is paused or not
**self** = timer:Pause() -- Pauses the timer, it skips time that would be counted during the time that it is paused
**self** = timer:Resume() -- Resumes a paused timer. **See note below**
**self** = timer:tofile(**STRING** path) -- Saves the object to a file at location path

**Note:** If a timer was paused after 1 second then resumed a second later and Get() was called a second later, timer would have 2 seconds counted though 3 really have passed.

# Non-Actor: Connections
Arguable my favorite object in this library, next to threads

`conn = multi:newConnection([BOOLEAN protect true])`
Creates a connection object and defaults to a protective state. All calls will run within pcall()

`self = conn:HoldUT([NUMBER n 0])` -- Will hold futhur execution of the thread until the connection was triggered. If n is supplied the connection must be triggered n times before it will allow ececution to continue.
</br>`self = conn:FConnect(FUNCTION func)` -- Creates a connection that is forced to execute when Fire() is called.  returns or nil = conn:Fire(...) -- Triggers the connection with arguments ..., "returns" if non-nil is a table containing return values from the triggered connections. [**Deprecated:**  Planned removal in 14.x.x]
</br>`self = conn:Bind(TABLE t)` -- sets the table to hold the connections. Leaving it alone is best unless you know what you are doing
</br>`self = conn:Remove()` -- removes the bind that was put in place. This will also destroy all connections that existed before.
</br>`link = conn:connect(FUNCTION func, [STRING name nil], [NUMBER num #conns+1])` -- Connects to the object using function func which will recieve the arguments passed by Fire(...). You can name a connection, which allows you to use conn:getConnection(name). Names must be unique! num is simple the position in the order in which connections are triggered. The return Link is the link to the connected event that was made. You can remove this event or even trigger it specifically if need be.
</br>`link:Fire(...)` -- Fires the created event
</br>`bool = link:Destroy()` -- returns true if success.
</br>`subConn = conn:getConnection(STRING name, BOOLEAN ingore)` -- returns the sub connection which matches name.
returns or nil subConn:Fire() -- "returns" if non-nil is a table containing return values from the triggered connections.
</br>`self = conn:tofile(STRING path)` -- Saves the object to a file at location path

The connect feature has some syntax sugar to it as seen below
</br>`link = conn(FUNCTION func, [STRING name nil], [NUMBER #conns+1])`

Example:
```lua
local multi = require("multi")
-- Let’s create the events
yawn={}
OnCustomSafeEvent=multi:newConnection(true) -- lets pcall the calls in case something goes wrong default
OnCustomEvent=multi:newConnection(false) -- let’s not pcall the calls and let errors happen.
OnCustomEvent:Bind(yawn) -- create the connection lookup data in yawn

-- Let’s connect to them, a recent update adds a nice syntax to connect to these
cd1=OnCustomSafeEvent:Connect(function(arg1,arg2,...)
  print("CSE1",arg1,arg2,...)
end,"bob") -- let’s give this connection a name
cd2=OnCustomSafeEvent:Connect(function(arg1,arg2,...)
  print("CSE2",arg1,arg2,...)
end,"joe") -- let’s give this connection a name
cd3=OnCustomSafeEvent:Connect(function(arg1,arg2,...)
  print("CSE3",arg1,arg2,...)
end) -- let’s not give this connection a name

-- Using syntax sugar
OnCustomEvent(function(arg1,arg2,...)
  print(arg1,arg2,...)
end)

-- Now within some loop/other object you trigger the connection like
OnCustomEvent:Fire(1,2,"Hello!!!") -- fire all connections

-- You may have noticed that some events have names! See the following example!
OnCustomSafeEvent:getConnection("bob"):Fire(1,100,"Bye!") -- fire only bob!
OnCustomSafeEvent:getConnection("joe"):Fire(1,100,"Hello!") -- fire only joe!!
OnCustomSafeEvent:Fire(1,100,"Hi Ya Folks!!!") -- fire them all!!!

-- Connections have more to them than that though!
-- As seen above cd1-cd3 these are hooks to the connection object. This allows you to remove a connection
-- For Example:
cd1:Remove() -- remove this connection from the master connection object
print("------")
OnCustomSafeEvent:Fire(1,100,"Hi Ya Folks!!!") -- fire them all again!!!
-- To remove all connections use:
OnCustomSafeEvent:Remove()
print("------")
OnCustomSafeEvent:Fire(1,100,"Hi Ya Folks!!!") -- fire them all again!!!
```

# Non-Actor: Jobs
`nil = multi:newJob(FUNCTION func, STRING name)` -- Adds a job to a queue of jobs that get executed after some time. func is the job that is being ran, name is the name of the job.
</br>`nil = multi:setJobSpeed(NUMBER n)` -- seconds between when each job should be done.
</br>`bool, number = multi:hasJobs()` -- returns true if there are jobs to be processed. And the number of jobs to be processed
</br>`num = multi:getJobs()` -- returns the number of jobs left to be processed.
</br>`number = multi:removeJob(STRING name)` -- removes all jobs of name, name. Returns the number of jobs removed

**Note:** Jobs may be turned into actual objects in the future.

Example:
```lua
local multi = require("multi")
print(multi:hasJobs())
multi:setJobSpeed(1) -- set job speed to 1 second
multi:newJob(function()
    print("A job!")
end,"test")

multi:newJob(function()
    print("Another job!")
    multi:removeJob("test") -- removes all jobs with name "test"
end,"test")

multi:newJob(function()
    print("Almost done!")
end,"test")

multi:newJob(function()
    print("Final job!")
end,"test")
print(multi:hasJobs())
print("There are "..multi:getJobs().." jobs in the queue!")
multi:mainloop()
```

# Universal Actor methods
All of these functions are found on actors
</br>`self = multiObj:Pause()` -- Pauses the actor from running
</br>`self = multiObj:Resume()` -- Resumes the actor that was paused
</br>`nil = multiObj:Destroy()` -- Removes the object from the mainloop
</br>`bool = multiObj:isPaused()` -- Returns true if the object is paused, false otherwise
</br>`string = multiObj:getType()` -- Returns the type of the object
</br>`self = multiObj:SetTime(n)` -- Sets a timer, and creates a special "timemaster" actor, which will timeout unless ResolveTimer is called
</br>`self = multiObj:ResolveTimer(...)` -- Stops the timer that was put onto the multiObj from timing out
</br>`self = multiObj:OnTimedOut(func)` -- If ResolveTimer was not called in time this event will be triggered. The function connected to it get a refrence of the original object that the timer was created on as the first argument.
</br>`self = multiObj:OnTimerResolved(func)` -- This event is triggered when the timer gets resolved. Same argument as above is passed, but the variable arguments that are accepted in resolvetimer are also passed as well.
</br>`self = multiObj:Reset(n)` -- In the cases where it isn't obvious what it does, it acts as Resume()
</br>`self = multiObj:SetName(STRING name)`

# Actor: Events
`event = multi:newEvent(FUNCTION task)`
The object that started it all. These are simply actors that wait for a condition to take place, then auto triggers an event. The event when triggered once isn't triggered again unless you Reset() it.

`self = SetTask(FUNCTION func)` -- This function is not needed if you supplied task at construction time
</br>`self = OnEvent(FUNCTION func)` -- Connects to the OnEvent event passes argument self to the connectee

Example:
```lua
local multi = require("multi")
count=0
-- A loop object is used to demostrate how one could use an event object.
loop=multi:newLoop(function(self,dt)
	count=count+1
end)
event=multi:newEvent(function() return count==100 end) -- set the event
event:OnEvent(function(self) -- connect to the event object
	loop:Destroy() -- destroys the loop from running!
	print("Stopped that loop!",count)
end) -- events like alarms need to be reset the Reset() command works here as well
multi:mainloop()
```

# Actor: Updaters
`updater =  multi:newUpdater([NUMBER skip 1])` -- set the amount of steps that are skipped
Updaters are a mix between both loops and steps. They were a way to add basic priority management to loops (until a better way was added). Now they aren't as useful, but if you do not want the performance hit of turning on priority then they are useful to auro skip some loops. Note: The performance hit due to priority management is not as bas as it used to be. 

`self = updater:SetSkip(NUMBER n)` -- sets the amount of steps that are skipped
</br>`self = OnUpdate(FUNCTION func)` -- connects to the main trigger of the updater which is called every nth step

Example:
```lua
local multi = require("multi")
updater=multi:newUpdater(5000) -- simple, think of a loop with the skip feature of a step
updater:OnUpdate(function(self)
	print("updating...")
end)
multi:mainloop()
```

# Actor: Alarms
`alarm = multi:newAlarm([NUMBER 0])` -- creates an alarm which waits n seconds
Alarms ring after a certain amount of time, but you need to reset the alarm every time it rings! Use a TLoop if you do not want to have to reset.

`self = alarm:Reset([NUMBER sec current_time_set])` -- Allows one to reset an alarm, optional argument to change the time until the next ring.
</br>`self = alarm:OnRing(FUNCTION func` -- Allows one to connect to the alarm event which is triggerd after a certain amount of time has passed.

Example:
```lua
local multi = require("multi")
alarm=multi:newAlarm(3) -- in seconds can go to .001 uses the built in os.clock()
alarm:OnRing(function(a)
	print("3 Seconds have passed!")
	a:Reset(n) -- if n were nil it will reset back to 3, or it would reset to n seconds
end)
multi:mainloop()
```

# Actor: Loops
`loop = multi:newLoop(FUNCTION func)` -- func the main connection that you can connect to. Is optional, but you can also use OnLoop(func) to connect as well.
Loops are events that happen over and over until paused. They act like a while loop.

`self = OnLoop(FUNCTION func)`  -- func the main connection that you can connect to. Alllows multiple connections to one loop if need be.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
local a = 0
loop = multi:newLoop(function()
	a = a + 1
    if a == 1000 then
    	print("a = 1000")
    	loop:Pause()
    end
end)
multi:mainloop()
```

# Actor: TLoops
`tloop = multi:newTLoop(FUNCTION func ,NUMBER: [set 1])` -- TLoops are pretty much the same as loops. The only difference is that they take set which is how long it waits, in seconds, before triggering function func.

`self = OnLoop(FUNCTION func)`  -- func the main connection that you can connect to. Alllows multiple connections to one TLoop if need be.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
local a = 0
loop = multi:newTLoop(function()
	a = a + 1
    if a == 10 then
    	print("a = 10")
    	loop:Pause()
    end
end,1)
multi:mainloop()
```

# Actor: Steps
`step = multi:newStep(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])` -- Steps were originally introduced to bs used as for loops that can run parallel with other code. When using steps think of it like this: `for i=start,reset,count do` When the skip argument is given, each time the step object is given cpu cycles it will be skipped by n cycles. So if skip is 1 every other cpu cycle will be alloted to the step object.

`self = step:OnStart(FUNCTION func(self))` -- This connects a function to an event that is triggered everytime a step starts.
</br>`self = step:OnStep(FUNCTION func(self,i))` -- This connects a function to an event that is triggered every step or cycle that is alloted to the step object
</br>`self = step:OnEnd(FUNCTION func(self))` -- This connects a function to an event that is triggered when a step reaches its goal
</br>`self = step:Update(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])` -- Update can be used to change the goals of the step. You should call step:Reset() after using Update to restart the step.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
multi:newStep(1,10,1,0):OnStep(function(step,pos)
	print(step,pos)
end):OnEnd(fucntion(step)
	step:Destroy()
end)
multi:mainloop()
```

# Actor: TSteps
`tstep = multi:newStep(NUMBER start, NUMBER reset, [NUMBER count 1], [NUMBER set 1])` -- TSteps work just like steps, the only difference is that instead of skip, we have set which is how long in seconds it should wait before triggering the OnStep() event.

`self = tstep:OnStart(FUNCTION func(self))` -- This connects a function to an event that is triggered everytime a step starts.
</br>`self = tstep:OnStep(FUNCTION func(self,i))` -- This connects a function to an event that is triggered every step or cycle that is alloted to the step object
</br>`self = tstep:OnEnd(FUNCTION func(self))` -- This connects a function to an event that is triggered when a step reaches its goal
</br>`self = tstep:Update(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER set 1])` -- Update can be used to change the goals of the step. You should call step:Reset() after using Update to restart the step.
</br>`self = tstep:Reset([NUMBER n set])` -- Allows you to reset a tstep that has ended, but also can change the time between each trigger.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
multi:newTStep(1,10,1,1):OnStep(function(step,pos)
	print(step,pos)
end):OnEnd(fucntion(step)
	step:Destroy()
end)
multi:mainloop()
```

# Coroutine based Threading (CBT)
Helpful methods are wrapped around the builtin coroutine module which make it feel like real threading.

# threads.* used within threaded enviroments
`thread.sleep(NUMBER n)` -- Holds execution of the thread until a certain amount of time has passed
</br>`thread.hold(FUNCTION func)` -- Hold execttion until the function returns true
</br>`thread.skip(NUMBER n)` -- How many cycles should be skipped until I execute again
</br>`thread.kill()` -- Kills the thread
</br>`thread.yeild()` -- Is the same as using thread.skip(0) or thread.sleep(0), hands off control until the next cycle
</br>`thread.isThread()` -- Returns true if the current running code is inside of a coroutine based thread
</br>`thread.getCores()` -- Returns the number of cores that the current system has. (used for system threads)
</br>`thread.set(STRING name, VARIABLE val)` -- A global interface where threads can talk with eachother. sets a variable with name and its value
</br>`thread.get(STRING name)` -- Gets the data stored in name
</br>`thread.waitFor(STRING name)` -- Holds executon of a thread until variable name exists

# CBT: newThread()
`th = multi:newThread([STRING name,] FUNCTION func)` -- Creates a new thread with name and function.

Constants
---
`th.Name` -- Name of thread
</br>`th.Type` -- Type="thread"
</br>`th.TID` -- Thread ID

Methods
---
`conn = th.OnError(FUNCTION: callback)` -- Connect to an event which is triggered when an error is encountered within a thread
</br>`conn = th.OnDeath(FUNCTION: callback)` -- Connect to an event which is triggered when the thread had either been killed or stopped running. (Not triggered when there is an error!)
</br>`boolean = th:isPaused()`* -- Returns true if a thread has been paused
</br>`(self)th = th:Pause()`* -- Pauses a thread
</br>`(self)th = th:Resume()`* -- Resumes a paused thread
</br>`(self)th = th:Kill()`* -- Kills a thread
</br>`(self)th = th:Destroy()*` -- Destroys a thread

*When using these methods on a thread directly you are making a request to a thread! The thread may not accept your request, but it most likely will. You can contorl the thread flow within the thread's function itself

Examples:
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
multi:newThread("Example of basic usage",function()
	while true do
    	thread.sleep(1)
        print("We just made an alarm!")
    end
end)
multi:mainloop()
```


HERE


System Threads (ST) - Multi-Integration Getting Started
-------------------------------------------------------
The system threads need to be required seperatly.
```lua
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()# -- We will talk about the global and thread interface that is returned
GLOBAL, THREAD = require("multi.integration.loveManager").init()
GLOBAL, THREAD = require("luvitManager")-- There is a catch to this*
```
Using this integration modifies some methods that the multi library has.
`multi:canSystemThread()` -- Returns true is system threading is possible
`multi:getPlatform()` -- Returns (for now) either "lanes", "love2d" and "luvit"
This variable is created on the main thread only inside of the multi namespace: multi.isMainThread = true
This is used to know which thread is the main thread. When network threads are being discussed there is a gotcha that needs to be addressed.

`*` GLOBAL and THREAD do not work currently when using the luvit integration
`#`So you may have noticed that when using the lanes manager you need to make the global and thread local, this is due to how lanes copies local variables between states. Also love2d does not require this, actually things will break if this is done! Keep these non local since the way threading is handled at the lower level is much different anyway so GLOBAL and THREAD is automatically set up for use within a spawned thread!

ST - THREAD namespace
---------------------
`THREAD.set(STRING name, VALUE val)` -- Sets a value in GLOBAL
`THREAD.get(STRING name)` -- Gets a value in GLOBAL
`THREAD.waitFor(STRING name)` -- Waits for a value in GLOBAL to exist
`THREAD.testFor(STRING name, VALUE val, STRING sym)` -- **NOT YET IMPLEMENTED** but planned
`THREAD.getCores()` -- Returns the number of actual system threads/cores
`THREAD.kill()` -- Kills the thread
`THREAD.getName()` -- Returns the name of the working thread
`THREAD.sleep(NUMBER n)` -- Sleeps for an amount of time stopping the current thread
`THREAD.hold(FUNCTION func)` -- Holds the current thread until a condition is met
`THREAD.getID()` -- returns a unique ID for the current thread. This varaiable is visible to the main thread as well by accessing it through the returned thread object. OBJ.Id

ST - GLOBAL namespace
---------------------
Treat global like a table.
```lua
GLOBAL["name"] = "Ryan"
print(GLOBAL["name"])
```
Removes the need to use THREAD.set() and THREAD.get()
ST - System Threads
-------------------
`systemThread = multi:newSystemThread(STRING thread_name,FUNCTION spawned_function,ARGUMENTS ...)` -- Spawns a thread with a certain name.
`systemThread:kill()` -- kills a thread; can only be called in the main thread!
`systemThread.OnError(FUNCTION(systemthread,errMsg,errorMsgWithThreadName))`

System Threads are the feature that allows a user to interact with systen threads. It differs from regular coroutine based thread in how it can interact with variables. When using system threads the GLOBAL table is the "only way"* to send data. Spawning a System thread is really simple once all the required libraries are in place. See example below:

```lua
local multi = require("multi") -- keep this global when using lanes or implicitly define multi within the spawned thread
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
multi:newSystemThread("Example thread",function()
	local multi = require("multi") -- we are in a thread so lets not refer to that upvalue!
	print("We have spawned a thread!")
	-- we could do work but theres no need to we can save that for other examples
	print("Lets have a non ending loop!")
	while true do
		-- If this was not in a thread execution would halt for the entire process
	end
end,"A message that we are passing") -- There are restrictions on what can be passed!

tloop = multi:newTLoop(function()
	print("I'm still kicking!")
end,1)
multi:mainloop()
```

*This isn't entirely true, as of right now the compatiablity with the lanes library and love2d engine have their own methods to share data, but if you would like to have your code work in both enviroments then using the GLOBAL table and the data structures provided by the multi library will ensure this happens. If you do not plan on having support for both platforms then feel free to use linda's in lanes and channels in love2d.

Note: luvit currently has very basic support, it only allows the spawning of system threads, but no way to send data back and forth as of yet. I do not know if this is doable or not, but I will keep looking into it. If I can somehow emulate System Threaded Queues and the GLOBAL tabke then all other datastructures will work!

ST - System Threaded Objects
----------------------------
Great we are able to spawn threads, but unless your working with a process that works on passed data and then uses a socket or writes to the disk I can't do to much with out being able to pass data between threads. This section we will look at how we can share objects between threads. In order to keep the compatibility between both love2d and lanes I had to format the system threaded objects in a strange way, but they are consistant and should work on both enviroments.

When creating objects with a name they are automatically exposed to the GLOBAL table. Which means you can retrieve them from a spawned thread. For example we have a queue object, which will be discussed in more detail next.

```lua
-- Exposing a queue
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init() -- The standard setup above
queue = multi:newSystemThreadedQueue("myQueue"):init() -- We create and initiate the queue for the main thread
queue:push("This is a test!") -- We push some data onto the queue that other threads can consume and do stuff with
multi:newSystemThread("Example thread",function() -- Create a system thread
	queue = THREAD.waitFor("myQueue"):init() -- Get the queue. It is good pratice to use the waitFor command when getting objects. If it doesn't exist yet we wait for it, preventing future errors. It is possible for the data to not ve present when a thread is looking for it! Especally when using the love2d module, my fault needs some rewriting data passing on the GLOBAL is quite slow, but the queue internally uses channels so after it is exposed you should have good speeds!
    local data = queue:pop() -- Get the data
    print(data) -- print the data
end)
multi:mainloop()
```

ST - SystemThreadedQueue
------------------------
`queue(nonInit) = multi:newSystemThreadedQueue(STRING name)` -- You must enter a name!
`queue = queue:init()` -- initiates the queue, without doing this it will not work
`void = queue:push(DATA data)` -- Pushes data into a queue that all threads that have been shared have access to
`data = queue:pop()` -- pops data from the queue removing it from all threads
`data = queue:peek()` -- looks at data that is on the queue, but dont remove it from the queue

This object the System Threaded Queue is the basis for all other data structures that a user has access to within the "shared" objects.

General tips when using a queue. You can always pop from a queue without worrying if another thread poped that same data, BUT if you are peeking at a queue there is the possibility that another thread popped the data while you are peeking and this could cause an issue, depends on what you are doing though. It's important to keep this in mind when using queues.

Let's get into some examples:
```lua
multi = require("multi")
thread_names = {"Thread_A","Thread_B","Thread_C","Thread_D"}
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
queue = multi:newSystemThreadedQueue("myQueue"):init()
for _,n in pairs(thread_names) do
	multi:newSystemThread(n,function()
		queue = THREAD.waitFor("myQueue"):init()
		local name = THREAD.getName()
		local data = queue:pop()
		while data do
			print(name.." "..data)
			data = queue:pop()
		end
	end)
end
for i=1,100 do
	queue:push(math.random(1,1000))
end
multi:newEvent(function() -- Felt like using the event object, I hardly use them for anything non internal
	return not queue:peek()
end):OnEvent(function()
	print("No more data within the queue!")
	os.exit()
end)
multi:mainloop()
```

You have probable noticed that the output from this is a total mess! Well I though so too, and created the system threaded console!

ST - SystemThreadedConsole
--------------------------
`console(nonInit) = multi:newSystemThreadedConsole(STRING name)` -- Creates a console object called name. The name is mandatory!
`concole = console:inti()` -- initiates the console object
`console:print(...)` -- prints to the console
`console:write(msg)` -- writes to the console, to be fair you wouldn't want to use this one.

The console makes printing from threads much cleaner. We will use the same example from above with the console implemented and compare the outputs and how readable they now are!

```lua
multi = require("multi")
thread_names = {"Thread_A","Thread_B","Thread_C","Thread_D"}
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
multi:newSystemThreadedConsole("console"):init()
queue = multi:newSystemThreadedQueue("myQueue"):init()
for _,n in pairs(thread_names) do
	multi:newSystemThread(n,function()
		local queue = THREAD.waitFor("myQueue"):init()
		local console = THREAD.waitFor("console"):init()
		local name = THREAD.getName()
		local data = queue:pop()
		while data do
        	--THREAD.sleep(.1) -- uncomment this to see them all work
			console:print(name.." "..data)
			data = queue:pop()
		end
	end)
end
for i=1,100 do
	queue:push(math.random(1,1000))
end
multi:newEvent(function()
	return not queue:peek()
end):OnEvent(function()
	multi:newAlarm(.1):OnRing(function() -- Well the mainthread has to read from an internal queue so we have to wait a sec
		print("No more data within the queue!")
		os.exit()
	end)
end)
multi:mainloop()
```

As you see the output here is so much cleaner, but we have a small gotcha, you probably noticed that I used an alarm to delay the exiting of the program for a bit. This is due to how the console object works, I send all the print data into a queue that the main thread then reads and prints out when it looks at the queue. This should not be an issue since you gain so much by having clean outputs!

Another thing to note, because system threads are put to work one thread at a time, really quick though, the first thread that is loaded is able to complete the tasks really fast, its just printing after all. If you want to see all the threads working uncomment the code with THREAD.sleep(.1)

ST - SystemThreadedJobQueue
---------------------------

ST - SystemThreadedConnection - WIP*
-----------------------------
`connection(nonInit) = multi:newSystemThreadedConnection(name,protect)` -- creates a connecion object
`connection = connection:init()` -- initaties the connection object
`connectionID = connection:connect(FUNCTION func)` -- works like the regular connect function
`void = connection:holdUT(NUMBER/FUNCTION n)` -- works just like the regular holdut function
`void = connection:Remove()` -- works the same as the default
`voic = connection:Fire(ARGS ...)` -- works the same as the default

In the current form a connection object requires that the multi:mainloop() is running on the threads that are sharing this object! By extention since SystemThreadedTables rely on SystemThreadedConnections they have the same requirements. Both objects should not be used for now. 

Since the current object is not in a stable condition, I will not be providing examples of how to use it just yet!

*The main issue we have with the connection objects in this form is proper comunication and memory managament between threads. For example if a thread crashes or no longer exists the current apporach to how I manage the connection objects will cause all connections to halt. This feature is still being worked on and has many bugs to be patched out. for now only use for testing purposes.

ST - SystemThreadedTable - WIP*
------------------------

ST - SystemThreadedBenchmark
----------------------------
`bench = multi:SystemThreadedBenchmark(NUMBER seconds)` -- runs a benchmark for a certain amount of time
`bench:OnBench(FUNCTION callback(NUMBER steps/second))`
```lua
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
multi:SystemThreadedBenchmark(1).OnBench(function(...)
	print(...)
end)
multi:mainloop()
```
ST - SystemThreadedExecute WIP* Might remove
--------------------------

Network Threads - Multi-Integration
-----------------------------------
