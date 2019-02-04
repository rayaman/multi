Current Multi Version: 13.0.0

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


Multi constructors - Multi-Objs
-------------------------------
**Processors**
`proc = multi:newProcessor([STRING: file nil])`

**Non-Actors**
`timer = multi:newTimer()`
`conn = multi:newConnection([BOOLEAN protect true])`
`nil = multi:newJob(FUNCTION func, STRING name)`
`func = multi:newFunction(FUNCTION func)`
`trigger = multi:newTrigger(FUNCTION: func)`

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

Non-Actor: Timers
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

Non-Actor: Connections
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

Non-Actor: Jobs
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

Non-Actor: Functions
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

Non-Actor: Triggers 
--------
`trigger = multi:newTrigger(FUNCTION: func(...))` -- A trigger is the precursor of connection objects. The main difference is that only one function can be binded to the trigger.
`self = trigger:Fire(...)` -- Fires the function that was connected to the trigger and passes the arguments supplied in Fire to the function given.


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
`self = multiObj:SetName(STRING name)`

Actor: Events
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

Actor: Updates
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

Actor: Alarms
------
`alarm = multi:newAlarm([NUMBER 0])` -- creates an alarm which waits n seconds
Alarms ring after a certain amount of time, but you need to reset the alarm every time it rings! Use a TLoop if you do not want to have to reset.

`self = alarm:Reset([NUMBER sec current_time_set])` -- Allows one to reset an alarm, optional argument to change the time until the next ring.
`self = alarm:OnRing(FUNCTION func` -- Allows one to connect to the alarm event which is triggerd after a certain amount of time has passed.

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

Actor: Loops
-----
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

Actor: TLoops
------
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

Actor: Steps
-----
`step = multi:newStep(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])` -- Steps were originally introduced to bs used as for loops that can run parallel with other code. When using steps think of it like this: `for i=start,reset,count do` When the skip argument is given, each time the step object is given cpu cycles it will be skipped by n cycles. So if skip is 1 every other cpu cycle will be alloted to the step object.

`self = step:OnStart(FUNCTION func(self))` -- This connects a function to an event that is triggered everytime a step starts.
`self = step:OnStep(FUNCTION func(self,i))` -- This connects a function to an event that is triggered every step or cycle that is alloted to the step object
`self = step:OnEnd(FUNCTION func(self))` -- This connects a function to an event that is triggered when a step reaches its goal
`self = step:Update(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])` -- Update can be used to change the goals of the step. You should call step:Reset() after using Update to restart the step.

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

Actor: TSteps
------
`tstep = multi:newStep(NUMBER start, NUMBER reset, [NUMBER count 1], [NUMBER set 1])` -- TSteps work just like steps, the only difference is that instead of skip, we have set which is how long in seconds it should wait before triggering the OnStep() event.

`self = tstep:OnStart(FUNCTION func(self))` -- This connects a function to an event that is triggered everytime a step starts.
`self = tstep:OnStep(FUNCTION func(self,i))` -- This connects a function to an event that is triggered every step or cycle that is alloted to the step object
`self = tstep:OnEnd(FUNCTION func(self))` -- This connects a function to an event that is triggered when a step reaches its goal
`self = tstep:Update(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER set 1])` -- Update can be used to change the goals of the step. You should call step:Reset() after using Update to restart the step.
`self = tstep:Reset([NUMBER n set])` -- Allows you to reset a tstep that has ended, but also can change the time between each trigger.

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

Actor: Time Stampers
-------------
`stamper = multi:newTimeStamper()` -- This allows for long time spans as well as short time spans.
`stamper = stamper:OhSecond(NUMBER second, FUNCTION func)` -- This takes a value between 0 and 59. This event is called once every second! Not once every second! If you want seconds then use alarms*****! 0 is the start of every minute and 59 is the end of every minute.
`stamper = stamper:OhMinute(NUMBER minute, FUNCTION func)` -- This takes a value between 0 and 59. This event is called once every hour*****! Same concept as OnSecond()
`stamper = stamper:OhHour(NUMBER hour, FUNCTION func)` -- This takes a value between 0 and 23. This event is called once every day*****! 0 is midnight and 23 is 11pm if you use 12 hour based time.
`stamper = stamper:OnDay(STRING/NUMBER day, FUNCTION func)` -- So the days work like this 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'. When in string form this is called every week. When in number form this is called every month*****!
There is a gotcha though with this. Months can have 28,29,30, and 31 days to it, which means that something needs to be done when dealing with the last few days of a month. I am aware of this issue and am looking into a solution that is simple and readable. I thought about allowing negitive numbers to allow one to eaisly use the last day of a month. -1 is the last day of the month where -2 is the second to last day of the month. You can go as low as -28 if you want, but this provides a nice way to do something near the end of the month that is lua like.
`stamper = stamper:OnMonth(NUMBER month,FUNCTION func)` -- This takes a value between 1 and 12. 1 being January and 12 being December. Called once per year*****.
`stamper = stamper:OnYear(NUMBER year,FUNCTION func)` -- This takes a number yy. for example 18 do not use yyyy format! Odds are you will not see this method triggered more than once, unless science figures out the whole life extension thing. But every century this event is triggered*****! I am going to be honest though, the odds of a system never reseting for 100 years is very unlikely, so if I used 18 (every 18th year in each century every time i load my program this event will be triggered). Does it actually work? I have no idea tbh it should, but can i prove that without actually testing it? Yes by using fake data thats how.
`stamper = stamper:OnTime(NUMBER hour,NUMBER minute,NUMBER second,FUNCTION func)` -- This takes in a time to trigger, hour, minute, second. This triggeres once a day at a certain time! Sort of like setting an alarm! You can combine events to get other effects like this!
`stamper = stamper:OnTime(STRING time,FUNCTION func)` -- This takes a string time that should be formatted like this: "hh:mm:ss" hours minutes and seconds must be given as parameters! Otherwise functions as above!

*****If your program crashes or is rebooted than the data in RAM letting the code know that the function was already called will be reset! This means that if an event set to be triggered on Monday then you reboot the code it will retrigger that event on the same day if the code restarts. In a future update I am planning of writing to the disk for OnHour/Day/Week/Year events. This will be an option that can be set on the object.

Examples:
**OnSecond**
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
local a = 0
ts:OnSecond(0,function()
	a=a+1
	print("New Minute: "..a.." <"..os.date("%M")..">")
end)
multi:mainloop()
```
**OnMinute**
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
local a = 0
ts:OnSecond(0,function()
	a=a+1
	print("New Hour: "..a.." <"..os.date("%I")..">")
end)
multi:mainloop()
```
**OnHour**
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
ts:OnHour(0,function()
	print("New Day")
end)
multi:mainloop()

```
**OnDay**
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
ts:OnDay("Thu",function()
	print("It's thursday!")
end)
multi:mainloop()
```
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
ts:OnDay(2,function()
	print("Second day of the month!")
end)
multi:mainloop()
```
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
ts:OnDay(-1,function()
	print("Last day of the month!")
end)
multi:mainloop()
```
**OnYear**
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
ts:OnYear(19,function() -- They gonna wonder if they run this in 2018 why it no work :P
	print("We did it!")
end)
multi:mainloop()
```
**OnTime**
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
ts:OnTime(12,1,0,function()
	print("Whooooo")
end)
multi:mainloop()
```
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
ts = multi:newTimeStamper()
ts:OnTime("12:04:00",function()
	print("Whooooo")
end)
multi:mainloop()
```

Actor: Watchers 
--------
**Deprecated: ** This object was removed due to its uselessness. Metatables will work much better for what is being done. Perhaps in the future i will remake this method to use metamethods instead of basic watching every step. This will most likely be removed in the next version of the library or changed to use metatables and metamethods.
`watcher = multi:newWatcher(STRING name)` -- Watches a variable on the global namespace
`watcher = multi:newWatcher(TABLE namespace, STRING name)` -- Watches a variable inside of a table
`watcher = watcher::OnValueChanged(Function func(self, old_value, current_value))`

Example
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
test = {a=0}
watcher = multi:newWatcher(test,"a")
watcher:OnValueChanged(function(self, old_value, current_value)
	print(old_value,current_value)
end)
multi:newTLoop(function()
	test.a=test.a + 1
end,.5)
multi:mainloop()
```
Actor: Custom Object
--------------
`cobj = multi:newCustomObject(TABLE objRef, BOOLEAN isActor [false])` -- Allows you to create your own multiobject that runs each allotted step. This allows you to create your own object that works with all the features that each built in multi object does. If isActor is set to true you must have an `Act` method in your table. See example below. If an object is not an actor than the `Act` method will not be automatically called for you.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
local work = false
ticktock = multi:newCustomObject({
	timer = multi:newTimer(),
	Act = function(self)
		if self.timer:Get()>=1 then
			work = not work
			if work then
				self.OnTick:Fire()
			else
				self.OnTock:Fire()
			end
			self.timer:Reset()
		end
	end,
	OnTick = multi:newConnection(),
	OnTock = multi:newConnection(),
},true)
ticktock.OnTick(function()
	print("Tick")
end)
ticktock.OnTock(function()
	print("Tock")
end)
multi:mainloop()
```

Coroutine based Threading (CBT)
-------------------------
This was made due to the limitations of multiObj:hold(), which no longer exists. When this library was in its infancy and before I knew about coroutines, I actually tried to emulate what coroutines did in pure lua.
The threaded bariants of the non threaded objects do exist, but there isn't too much of a need to use them.

The main benefits of using the coroutine based threads is the thread.* namespace which gives you the ability to easily run code side by side.

A quick note on how threads are managed in the library. The library contains a scheduler which keeps track of coroutines and manages them. Coroutines take some time then give off processing to another coroutine. Which means there are some methods that you need to use in order to hand off cpu time to other coroutines or the main thread. You must hand off cpu time when inside of a non ending loop or your code will hang. Threads also have a slight delay before starting, about 3 seconds.

threads.*
---------
`thread.sleep(NUMBER n)` -- Holds execution of the thread until a certain amount of time has passed
`thread.hold(FUNCTION func)` -- Hold execttion until the function returns true
`thread.skip(NUMBER n)` -- How many cycles should be skipped until I execute again
`thread.kill()` -- Kills the thread
`thread.yeild()` -- Is the same as using thread.skip(0) or thread.sleep(0), hands off control until the next cycle
`thread.isThread()` -- Returns true if the current running code is inside of a coroutine based thread
`thread.getCores()` -- Returns the number of cores that the current system has. (used for system threads)
`thread.set(STRING name, VARIABLE val)` -- A global interface where threads can talk with eachother. sets a variable with name and its value
`thread.get(STRING name)` -- Gets the data stored in name
`thread.waitFor(STRING name)` -- Holds executon of a thread until variable name exists
`thread.testFor(STRING name,VARIABLE val,STRING sym)` -- holds execution untile variable name exists and is compared to val
sym can be equal to: "=", "==", "<", ">", "<=", or ">=" the way comparisan works is: "`return val sym valTested`"

CBT: Thread
-----------

`multi:newThread(STRING name,FUNCTION func)` -- Creates a new thread with name and function.
Note: newThread() returns nothing. Threads are opperated hands off everything that happens, does so inside of its functions.

Threads simplify many things that you would use non CBT objects for. I almost solely use CBT for my current programming. I will slso show the above custom object using threads instead. Yes its cool and can be done.

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
```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")

function multi:newTickTock()
	local work = false
	local _alive = true
	local OnTick = multi:newConnection()
	local OnTock = multi:newConnection()
	local c =multi:newCustomObject{
		OnTick = OnTick,
		OnTock = OnTock,
		Destroy = function()
			_alive = false -- Threads at least how they work here now need a bit of data management for cleaning up objects. When a thread either finishes its execution of thread.kill() is called everything is removed from the scheduler letting lua know that it can garbage collect
		end
	}
	multi:newThread("TickTocker",function()
		while _alive do
			thread.sleep(1)
			work = not work
			if work then
				OnTick:Fire()
			else
				OnTock:Fire()
			end
		end
        thread.kill() -- When a thread gets to the end of it's ececution it will automatically be ended, but having this method is good to show what is going on with your code.
	end)
	return c
end
ticktock = multi:newTickTock()
ticktock.OnTick(function()
	print("Tick")
    -- The thread.* namespace works in all events that
end)
ticktock.OnTock(function()
	print("Tock")
end)
multi:mainloop()
```

```lua
package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")

multi:newThread("TickTocker",function()
	print("Waiting for variable a to exist...")
	ret,ret2 = thread.hold(function()
		return a~=nil, "test!"
	end)
	print(ret,ret2) -- The hold method returns the arguments when the first argument is true. This methods return feature is rather new and took more work then you think to get working. Since threads
end)
multi:newAlarm(3):OnRing(function() a = true end) -- allows a to exist

multi:mainloop()
```

CBT: Threaded Process
---------------------
`process = multi:newThreadedProcess(STRING name)` -- Creates a process object that is able allows all processes created on it to use the thread.* namespace

`nil = process:getController()` -- Returns nothing there is no "controller" when using threaded processes
`self = process:Start()` -- Starts the processor
`self = process:Pause()` -- Pauses the processor
`self = process:Resume()` -- Resumes a paused processor
`self = process:Kill()` -- Kills/Destroys the process thread
`self = process:Remove()` -- Destroys/Kills the processor and all of the Actors running on it
`self = process:Sleep(NUMBER n)` -- Forces a process to sleep for n amount of time
`self = process:Hold(FUNCTION/NUMBER n)` -- Forces a process to either test a condition or sleep.

Everything eles works as if you were using the multi.* interface. You can create multi objects on the process and the objects are able to use the thread.* interface.

Note: When using Hold/Sleep/Skip on an object created inside of a threaded process, you actually hold the entire process! Which means all objects on that process will be stopping until the conditions are met!

Example:
```lua
test = multi:newThreadedProcess("test")
test:newLoop(function()
	print("HI!")
end)
test:newLoop(function()
	print("HI2!")
	thread.sleep(.5)
end)
multi:newAlarm(3):OnRing(function()
	test:Sleep(10)
end)
test:Start()
multi:mainloop()
```

CBT: Hyper Threaded Process
---------------------------
`process = multi:newHyperThreadedProcess(STRING name)` -- Creates a process object that is able allows all processes created on it to use the thread.* namespace. Hold/Sleep/Skip can be used in each multi obj created without stopping each other object that is running, but allows for one to pause/halt a process and stop all objects running in that process.

`nil = process:getController()` -- Returns nothing there is no "controller" when using threaded processes
`self = process:Start()` -- Starts the processor
`self = process:Pause()` -- Pauses the processor
`self = process:Resume()` -- Resumes a paused processor
`self = process:Kill()` -- Kills/Destroys the process thread
`self = process:Remove()` -- Destroys/Kills the processor and all of the Actors running on it
`self = process:Sleep(NUMBER n)` -- Forces a process to sleep for n amount of time
`self = process:Hold(FUNCTION/NUMBER n)` -- Forces a process to either test a condition or sleep.

Example:
```lua
test = multi:newHyperThreadedProcess("test")
test:newLoop(function()
	print("HI!")
end)
test:newLoop(function()
	print("HI2!")
	thread.sleep(.5)
end)
multi:newAlarm(3):OnRing(function()
	test:Sleep(10)
end)
test:Start()
multi:mainloop()
```
Same example as above, but notice how this works opposed to the non hyper version

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
