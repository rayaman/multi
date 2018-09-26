Mulit Version: 12.3.0

Table of contents
-----------------
[TOC]
Multi static variables
------------------------
`multi.Version` -- The current version of the library
`multi.Priority_Core` -- Highest level of pirority that can be given to a process
`multi.Priority_High`
`multi.Priority_Above_Normal`
`multi.Priority_Normal` -- The default level of pirority that is given to a process
`multi.Priority_Below_Normal`
`multi.Priority_Low`
`multi.Priority_Idle` -- Lowest level of pirority that can be given to a process

Multi Runners
-------------
`multi:mainloop([TABLE settings])` -- This runs the mainloop by having its own internal while loop running
`multi:threadloop([TABLE settings])` -- This runs the mainloop by having its own internal while loop running, but prioritizes threads over multi-objects
`multi:uManager([TABLE settings])` -- This runs the mainloop, but does not have its own while loop and thus needs to be within a loop of some kind.

Multi Settings
--------------

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

P1 follows a forumla that resembles this: ~n=I*PRank where n is the amount of steps given to an object with PRank and where I is the idle time see chart below. The aim of this priority scheme was to make core objects run fastest while letting idle processes get decent time as well.

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
|-|-|
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


Multi constructors - Multi-Objs
-------------------------------
**Processors**
`proc = multi:newProcessor([STRING: file nil])`

**Non-Actors**
`timer = multi:newTimer()`
`conn = multi:newConnection([BOOLEAN protect true])`
`nil = multi:newJob(FUNCTION func, STRING name)`
`func = multi:newFunction(FUNCTION func)`

**Actors**
`event = multi:newEvent(FUNCTION task)`
`updater =  multi:newUpdater([NUMBER skip 1])`
`alarm = multi:newAlarm([NUMBER 0])`
`loop = multi:newLoop(FUNCTION func)`
`tloop = multi:newTLoop(FUNCTION func ,NUMBER: [set 1])`
`step = multi:newStep(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])`
`tstep = multi:newStep(NUMBER start, NUMBER reset, [NUMBER count 1], [NUMBER set 1])`
`trigger = multi:newTrigger(FUNCTION: func)`
`stamper = multi:newTimeStamper()`
`watcher = multi:newWatcher(STRING name)`
`watcher = multi:newWatcher(TABLE namespace, STRING name)`
`cobj = multi:newCustomObject(TABLE objRef, BOOLEAN isActor)`

Note: A lot of methods will return self as a return. This is due to the ability to chain that was added in 12.x.x

Processor
---------
`proc = multi:newProcessor([STRING file nil])`
Creates a processor runner that acts like the multi runner. Actors and Non-Actors can be created on these objects. Pausing a process pauses all objects that are running on that process.

An optional argument file is used if you want to load a file containing the processor data.
Note: This isn't portable on all areas where lua is used. Some interperters disable loadstring so it is not encouraged to use the file method for creating processors

`loop = Processor:getController()` -- returns the loop that runs the "runner" that drives this processor
`self = Processor:Start()` -- Starts the processor
`self = Processor:Pause()` -- Pauses the processor
`self = Processor:Resume()` -- Resumes a paused processor
`nil = Processor:Destroy()` -- Destroys the processor and all of the Actors running on it

Example
```lua
multi = require("multi")
proc = multi:newProcessor()
proc:newTLoop(function() -- create a t loop that runs every second
	print("Hi!")
end,1) -- where we set the 1 second
proc:Start() -- let's start the processor
multi:mainloop() -- the main runner that drives everything
```

Timers
------
timer = multi:newTimer()
Creates a timer object that can keep track of time

**self** = timer:Start() -- Starts the timer
time_elapsed = timer:Get() -- Returns the time elapsed since timer:Start() was called
boolean = timer:isPaused() -- Returns if the timer is paused or not
**self** = timer:Pause() -- Pauses the timer, it skips time that would be counted during the time that it is paused
**self** = timer:Resume() -- Resumes a paused timer. **See note below**
**self** = timer:tofile(**STRING** path) -- Saves the object to a file at location path

**Note:** If a timer was paused after 1 second then resumed a second later and Get() was called a second later, timer would have 2 seconds counted though 3 really have passed.

Connections
-----------
Arguable my favorite object in this library, next to threads

`conn = multi:newConnection([BOOLEAN protect true])`
Creates a connection object and defaults to a protective state. All calls will run within pcall()

`self = conn:HoldUT([NUMBER n 0])` -- Will hold futhur execution of the thread until the connection was triggered. If n is supplied the connection must be triggered n times before it will allow ececution to continue.
`self = conn:FConnect(FUNCTION func)` -- Creates a connection that is forced to execute when Fire() is called.  returns or nil = conn:Fire(...) -- Triggers the connection with arguments ..., "returns" if non-nil is a table containing return values from the triggered connections. [**Deprecated:**  Planned removal in 14.x.x]
`self = conn:Bind(TABLE t)` -- sets the table to hold the connections. Leaving it alone is best unless you know what you are doing
`self = conn:Remove()` -- removes the bind that was put in place. This will also destroy all connections that existed before.
`link = conn:connect(FUNCTION func, [STRING name nil], [NUMBER num #conns+1])` -- Connects to the object using function func which will recieve the arguments passed by Fire(...). You can name a connection, which allows you to use conn:getConnection(name). Names must be unique! num is simple the position in the order in which connections are triggered. The return Link is the link to the connected event that was made. You can remove this event or even trigger it specifically if need be.
`link:Fire(...)` -- Fires the created event
`bool = link:Destroy()` -- returns true if success.
`subConn = conn:getConnection(STRING name, BOOLEAN ingore)` -- returns the sub connection which matches name.
returns or nil subConn:Fire() -- "returns" if non-nil is a table containing return values from the triggered connections.
`self = conn:tofile(STRING path)` -- Saves the object to a file at location path

The connect feature has some syntax sugar to it as seen below
`link = conn(FUNCTION func, [STRING name nil], [NUMBER #conns+1])`

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

Jobs
----
`nil = multi:newJob(FUNCTION func, STRING name)` -- Adds a job to a queue of jobs that get executed after some time. func is the job that is being ran, name is the name of the job.
`nil = multi:setJobSpeed(NUMBER n)` -- seconds between when each job should be done.
`bool, number = multi:hasJobs()` -- returns true if there are jobs to be processed. And the number of jobs to be processed
`num = multi:getJobs()` -- returns the number of jobs left to be processed.
`number = multi:removeJob(STRING name)` -- removes all jobs of name, name. Returns the number of jobs removed

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

Functions
---------
`func = multi:newFunction(FUNCTION func)`
These objects used to have more of a *function* before corutine based threads came around, but the main purpose now is the ablity to have pausable function calls

`... = func(...)` -- This is how you call your function. The first argument passed is itself when your function is triggered. See example.
`self = func:Pause()`
`self = func:Resume()`

Note: A paused function will return: nil, true

Example:
```lua
local multi = require("multi")
printOnce = multi:newFunction(function(self,msg)
	print(msg)
    self:Pause()
	return "I won't work anymore"
end)
a=printOnce("Hello World!")
b,c=printOnce("Hello World!")
print(a,b,c)
```
Universal Actor functions
-------------------------
All of these functions are found on actors
`self = multiObj:Pause()` -- Pauses the actor from running
`self = multiObj:Resume()` -- Resumes the actor that was paused
`nil = multiObj:Destroy()` -- Removes the object from the mainloop
`bool = multiObj:isPaused()` -- Returns true if the object is paused, false otherwise
`string = multiObj:getType()` -- Returns the type of the object
`self = multiObj:SetTime(n)` -- Sets a timer, and creates a special "timemaster" actor, which will timeout unless ResolveTimer is called
`self = multiObj:ResolveTimer(...)` -- Stops the timer that was put onto the multiObj from timing out
`self = multiObj:OnTimedOut(func)` -- If ResolveTimer was not called in time this event will be triggered. The function connected to it get a refrence of the original object that the timer was created on as the first argument.
`self = multiObj:OnTimerResolved(func)` -- This event is triggered when the timer gets resolved. Same argument as above is passed, but the variable arguments that are accepted in resolvetimer are also passed as well.
`self = multiObj:Reset(n)` -- In the cases where it isn't obvious what it does, it acts as Resume()

Events
------
`event = multi:newEvent(FUNCTION task)`
The object that started it all. These are simply actors that wait for a condition to take place, then auto triggers an event. The event when triggered once isn't triggered again unless you Reset() it.

`self = SetTask(FUNCTION func)` -- This function is not needed if you supplied task at construction time
`self = OnEvent(FUNCTION func)` -- Connects to the OnEvent event passes argument self to the connectee

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

Updates
-------
`updater =  multi:newUpdater([NUMBER skip 1])` -- set the amount of steps that are skipped
Updaters are a mix between both loops and steps. They were a way to add basic priority management to loops (until a better way was added). Now they aren't as useful, but if you do not want the performance hit of turning on priority then they are useful to auro skip some loops. Note: The performance hit due to priority management is not as bas as it used to be. 

`self = updater:SetSkip(NUMBER n)` -- sets the amount of steps that are skipped
`self = OnUpdate(FUNCTION func)` -- connects to the main trigger of the updater which is called every nth step

Example:
```lua
local multi = require("multi")
updater=multi:newUpdater(5000) -- simple, think of a loop with the skip feature of a step
updater:OnUpdate(function(self)
	print("updating...")
end)
multi:mainloop()
```

Alarms
------
`alarm = multi:newAlarm([NUMBER 0])` -- creates an alarm which waits n seconds
Alarms ring after a certain amount of time, but you need to reset the alarm every time it rings! Use a TLoop if you do not want to have to reset.

`self = alarm:Reset([NUMBER sec current_time_set])` -- Allows one to reset an alarm, optional argument to change the time until the next ring.
`self = alarm:OnRing(FUNCTION func` -- Allows one to connect to the alarm event which is triggerd after a certain amount of time has passed.

```lua
local multi = require("multi")
alarm=multi:newAlarm(3) -- in seconds can go to .001 uses the built in os.clock()
alarm:OnRing(function(a)
	print("3 Seconds have passed!")
	a:Reset(n) -- if n were nil it will reset back to 3, or it would reset to n seconds
end)
multi:mainloop()
```

Loops
-----
`loop = multi:newLoop(FUNCTION func)` -- func the main connection that you can connect to. Is optional, but you can also use OnLoop(func) to connect as well.
Loops are events that happen over and over until paused. They act like a while loop.

`self = OnLoop(FUNCTION func)`  -- func the main connection that you can connect to. Alllows multiple connections to one loop if need be.

TLoops
------
`tloop = multi:newTLoop(FUNCTION func ,NUMBER: [set 1])`

Steps
-----
`step = multi:newStep(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])`

TSteps
------
`tstep = multi:newStep(NUMBER start, NUMBER reset, [NUMBER count 1], [NUMBER set 1])`

Triggers
--------
`trigger = multi:newTrigger(FUNCTION: func)`

Time Stampers WIP
-----------------
`stamper = multi:newTimeStamper()`

Watchers
--------
`watcher = multi:newWatcher(STRING name)`
`watcher = multi:newWatcher(TABLE namespace, STRING name)`

Custom Objects
--------------
`cobj = multi:newCustomObject(TABLE objRef, BOOLEAN isActor)`

Coroutine based Threading
-------------------------
This was made due to the limitations of multiObj:hold(), which no longer exists. When this library was in its infancy and before I knew about coroutines, I actually tried to emulate what coroutines did in pure lua. (Was ok, but only allowed for one pause of code ececution) Many objects were given threaded variants though, none are really needed since the base thread objects ant thread.* can be used to emulate those.

System Threads - Multi-core
---------------------------

