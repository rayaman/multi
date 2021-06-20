Current Multi Version: 15.0.0

# Multi static variables
`multi.Version` — The current version of the library

`multi.Priority_Core` — Highest level of pirority that can be given to a process
</br>`multi.Priority_Very_High`
</br>`multi.Priority_High`
</br>`multi.Priority_Above_Normal`
</br>`multi.Priority_Normal` — The default level of pirority that is given to a process
</br>`multi.Priority_Below_Normal`
</br>`multi.Priority_Low`
</br>`multi.Priority_Very_Low`
</br>`multi.Priority_Idle` — Lowest level of pirority that can be given to a process

# Multi Runners
`multi:lightloop()` — A light version of the mainloop doesn't run Coroutine based threads
</br>`multi:loveloop([BOOLEAN: light true])` — Run's all the love related features as well
</br>`multi:mainloop([TABLE settings])` — This runs the mainloop by having its own internal while loop running
</br>`multi:threadloop([TABLE settings])` — This runs the mainloop by having its own internal while loop running, but prioritizes threads over multi-objects
</br>`multi:uManager([TABLE settings])` — This runs the mainloop, but does not have its own while loop and thus needs to be within a loop of some kind.

# Multi Settings

**Note:** Most settings have been fined tuned to be at the peak of performance already, however preLoop, protect (Which drastically lowers preformance), and stopOnError should be used freely to fit your needs.

| Setting         | Type: default               | Purpose                                                                                                                                                                                                                                                                                                                                                     |
| --------------- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| preLoop         | function: nil               | This is a function that is called after all the important components of the library are loaded. This is called once only. The first and only argument passed is a reference to itself.                                                                                                                                                                      |
| protect         | boolean: false              | This runs code within a protected call. To catch when errors happen see built in connections                                                                                                                                                                                                                                                                |
| stopOnError     | boolean: false              | This setting is used with protect. If an object crashes due to some error should it be paused?                                                                                                                                                                                                                                                              |
| priority        | number: 0                   | This sets the priority scheme. Look at the P-Charts below for examples.                                                                                                                                                                                                                                                                                     |
| auto_priority   | boolean: false              | **Note: This overrides any value set for priority!** If auto priority is enabled then priority scheme 3 is used and processes are considered for "recheck" after a certain amount of time. If a process isn't taking too long to complete anymore then it will be reset to core, if it starts to take a lot of time all of a sudden it will be set to idle. |
| auto_stretch    | number: 1                   | For use with auto_priority. Modifies the internal reperesentation of idle time by multiplying multi.Priority_Idle by the value given                                                                                                                                                                                                                        |
| auto_delay      | number: 3                   | For use with auto_priority. This changes the time in seconds that process are "rechecked"                                                                                                                                                                                                                                                                   |
| auto_lowerbound | number: multi.Priority_Idle | For use with auto_priority. The lowerbound is what is considered to be idle time. A higher value combined with auto_stretch allows one to fine tune how pirority is managed.                                                                                                                                                                                |

# P-Chart: Priority 1

P1 follows a forumla that resembles this: ~n=I*PRank</br>Where **n** is the amount of steps given to an object with PRank and where I is the idle time see chart below. The aim of this priority scheme was to make core objects run fastest while letting idle processes get decent time as well.

| Priority: n           | PRank | Formula      |
| --------------------- | ----- | ------------ |
| Core: 3322269         | 7     | n = ~**I***7 |
| High: 2847660         | 6     | n = ~**I***6 |
| Above_Normal: 2373050 | 5     | n = ~**I***5 |
| Normal: 1898440       | 4     | n = ~**I***4 |
| Below_Normal: 1423830 | 3     | n = ~**I***3 |
| Low: 949220           | 2     | n = ~**I***2 |
| **I**dle: 474610      | 1     | n = ~**I***1 |

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

multi:lightloop() -- lighter version of mainloop. Everything except priority management for non service objects will function like normal!

-- or

multi:mainloop(settings) -- normal runner

-- or

multi:threadloop(settings) -- Prioritizes threads over multi-objs

-- or

while true do
	multi:uManager(settings) -- allows you to run the multi main loop within another loop
end
```

# Non-Actors
`timer = multi:newTimer()`
- `conn = multi:newConnection([BOOLEAN protect true])`
- `func = multi:newFunction(FUNCTION func)`

# Actors
- `event = multi:newEvent(FUNCTION task)`
- `updater =  multi:newUpdater([NUMBER skip 1])`
- `alarm = multi:newAlarm([NUMBER 0])`
- `loop = multi:newLoop(FUNCTION func)`
- `tloop = multi:newTLoop(FUNCTION func ,NUMBER: [set 1])`
- `step = multi:newStep(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])`
- `tstep = multi:newStep(NUMBER start, NUMBER reset, [NUMBER count 1], [NUMBER set 1])`

**Note:** A lot of methods will return itself as a return. This allows for chaining of methods to work.

# Non-Actor: Timers
`timer = multi:newTimer()` — Creates a timer object that can keep track of time

- **self** = timer:Start() — Starts the timer
- time_elapsed = timer:Get() — Returns the time elapsed since timer:Start() was called
- boolean = timer:isPaused() — Returns if the timer is paused or not
- **self** = timer:Pause() — Pauses the timer, it skips time that would be counted during the time that it is paused
- **self** = timer:Resume() — Resumes a paused timer. **See note below**
- **self** = timer:tofile(**STRING** path) — Saves the object to a file at location path

**Note:** If a timer was paused after 1 second then resumed a second later and Get() was called a second later, timer would have 2 seconds counted though 3 really have passed.

# Non-Actor: Connections
`conn = multi:newConnection([BOOLEAN: protect true],FUNCTION: callback, BOOLEAN: kill false)` — 
Creates a connection object and defaults to a protective state. All calls will run within pcall() callback if it exists will be triggered each time the connection is fired. kill when set to true makes the connection object work like a queue. Where all the events that are fired is removed from the queue.
- `self = conn:HoldUT([NUMBER n 0])` — Will hold futhur execution of the thread until the connection was triggered. If n is supplied the connection must be triggered n times before it will allow ececution to continue.
- `conntable_old = conn:Bind(TABLE conntable)` — sets the table to hold the connections. A quick way to destroy all connections is by binding it to a new table.
- `conntable = conn:Remove()` — Removes all connections. Returns the conntable
- `link = conn:connect(FUNCTION func, [STRING name nil], [NUMBER num #conns+1])` — Connects to the object using function func which will recieve the arguments passed by Fire(...). You can name a connection, which allows you to use conn:getConnection(name). Names must be unique! num is simple the position in the order in which connections are triggered. The return Link is the link to the connected event that was made. You can remove this event or even trigger it specifically if need be.
- `link:Fire(...)` — Fires the created event
- `bool = link:Destroy()` — returns true if success.
- `subConn = conn:getConnection(STRING name, BOOLEAN ingore)` — returns the sub connection which matches name.
returns or nil
	- subConn:Fire() — "returns" if non-nil is a table containing return values from the triggered connections.
- `self = conn:tofile(STRING path)` — Saves the object to a file at location path

The connect feature has some syntax sugar to it as seen below
- `link = conn(FUNCTION func, [STRING name nil], [NUMBER #conns+1])`

Example:
```lua
multi,thread = require("multi"):init()
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

# Semi-Actors: timeouts
Timeouts are a collection of methods that allow you to handle timeouts. These only work on multi-objs, and much of the functionality can easly be done now using threads!

```lua
package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()

loop = multi:newLoop(function()
	-- do stuff
end)

loop:SetTime(3)
multi:newAlarm(2):OnRing(function()
	-- some condition that leads to resolving the timer
	loop:ResolveTimer(true,"We good")
	multi:newAlarm(2):OnRing(function()
		loop:SetTime(2)
	end)
end)

loop:OnTimedOut(function()
	print("Timeout")
end)

loop:OnTimerResolved(function(self,...)
	print(...)
end)

multi:mainloop()
```
As mentioned above this is made much easier using threads
```lua
package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi, thread = require("multi"):init()
func = thread:newFunction(function(a)
	return thread.holdFor(3,function()
		return a==5 and "This is returned" -- Condition being tested!
	end)
end,true)
print(func(5))
print(func(0))
-- You actually do not need the light/mainloop or any runner for threaded functions to work
-- multi:lightloop()
```

# Semi-Actors: scheduleJob
`multi:scheduleJob(TABLE: time, FUNCTION: callback)`
- `TABLE: time`
	- `NUMBER: time.min` — Minute(0-59) Repeats every hour
	- `NUMBER: time.hour` — Hour(0-23) Repeats every day
	- `NUMBER: time.day` — Day of month(1-31) repeats every month
	- `NUMBER: time.wday` — Weekday(0-6) repeats every week
	- `NUMBER: time.month` — Month(1-12) repeats every year
- `FUNCTION: callback`
	- Called when the time table is matched

Example:
```lua
package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
multi:scheduleJob({min = 30},function() -- Every hour at minute 30 this event will be triggered! You can mix and match as well!
	print("Hi")
end)
multi:scheduleJob({min = 30,hour = 0},function() -- Every day at 12:30AM this event will be triggered
	print("Hi")
end)
multi:mainloop()
```

# Universal Actor methods
All of these functions are found on actors
- `self = multiObj:Pause()` — Pauses the actor from running
- `self = multiObj:Resume()` — Resumes the actor that was paused
- `nil = multiObj:Destroy()` — Removes the object from the mainloop
- `bool = multiObj:isPaused()` — Returns true if the object is paused, false otherwise
- `string = multiObj:getType()` — Returns the type of the object
- `self = multiObj:SetTime(n)` — Sets a timer, and creates a special "timemaster" actor, which will timeout unless ResolveTimer is called
- `self = multiObj:ResolveTimer(...)` — Stops the timer that was put onto the multiObj from timing out
- `self = multiObj:OnTimedOut(func)` — If ResolveTimer was not called in time this event will be triggered. The function connected to it get a refrence of the original object that the timer was created on as the first argument.
- `self = multiObj:OnTimerResolved(func)` — This event is triggered when the timer gets resolved. Same argument as above is passed, but the variable arguments that are accepted in resolvetimer are also passed as well.
- `self = multiObj:Reset(n)` — In the cases where it isn't obvious what it does, it acts as Resume()
- `self = multiObj:SetName(STRING name)`

# Actor: Events
`event = multi:newEvent(FUNCTION task)` — The object that started it all. These are simply actors that wait for a condition to take place, then auto triggers an event. The event when triggered once isn't triggered again unless you Reset() it.

- `self = event:SetTask(FUNCTION func)` — This function is not needed if you supplied task at construction time
- `self = event:OnEvent(FUNCTION func)` — Connects to the OnEvent event passes argument self to the connectee

Example:
```lua
multi,thread = require("multi"):init()
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
`updater =  multi:newUpdater([NUMBER skip 1])` — set the amount of steps that are skipped. 

Updaters are a mix between both loops and steps. They were a way to add basic priority management to loops (until a better way was added). Now they aren't as useful, but if you do not want the performance hit of turning on priority then they are useful to auro skip some loops. Note: The performance hit due to priority management is not as bas as it used to be. 

- `self = updater:SetSkip(NUMBER n)` — sets the amount of steps that are skipped
- `self = OnUpdate(FUNCTION func)` — connects to the main trigger of the updater which is called every nth step

Example:
```lua
multi,thread = require("multi"):init()
updater=multi:newUpdater(5000) -- simple, think of a loop with the skip feature of a step
updater:OnUpdate(function(self)
	print("updating...")
end)
multi:mainloop()
```

# Actor: Alarms
`alarm = multi:newAlarm([NUMBER 0])` — creates an alarm which waits n seconds
Alarms ring after a certain amount of time, but you need to reset the alarm every time it rings! Use a TLoop if you do not want to have to reset.

- `self = alarm:Reset([NUMBER sec current_time_set])` — Allows one to reset an alarm, optional argument to change the time until the next ring.
- `self = alarm:OnRing(FUNCTION func` — Allows one to connect to the alarm event which is triggerd after a certain amount of time has passed.

Example:
```lua
multi,thread = require("multi"):init()
alarm=multi:newAlarm(3) -- in seconds can go to .001 uses the built in os.clock()
alarm:OnRing(function(a)
	print("3 Seconds have passed!")
	a:Reset(n) -- if n were nil it will reset back to 3, or it would reset to n seconds
end)
multi:mainloop()
```

# Actor: Loops
`loop = multi:newLoop(FUNCTION func)` — func the main connection that you can connect to. Is optional, but you can also use OnLoop(func) to connect as well.
Loops are events that happen over and over until paused. They act like a while loop.

- `self = OnLoop(FUNCTION func)` — func the main connection that you can connect to. Alllows multiple connections to one loop if need be.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
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
`tloop = multi:newTLoop(FUNCTION func ,NUMBER: [set 1])` — TLoops are pretty much the same as loops. The only difference is that they take set which is how long it waits, in seconds, before triggering function func.

- `self = OnLoop(FUNCTION func)` — func the main connection that you can connect to. Alllows multiple connections to one TLoop if need be.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
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
`step = multi:newStep(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])` — Steps were originally introduced to bs used as for loops that can run parallel with other code. When using steps think of it like this: `for i=start,reset,count do` When the skip argument is given, each time the step object is given cpu cycles it will be skipped by n cycles. So if skip is 1 every other cpu cycle will be alloted to the step object.

- `self = step:OnStart(FUNCTION func(self))` — This connects a function to an event that is triggered everytime a step starts.
- `self = step:OnStep(FUNCTION func(self,i))` — This connects a function to an event that is triggered every step or cycle that is alloted to the step object
- `self = step:OnEnd(FUNCTION func(self))` — This connects a function to an event that is triggered when a step reaches its goal
- `self = step:Update(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER skip 0])` — Update can be used to change the goals of the step.
- `self = step:Reset()` — Resets the step

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi:newStep(1,10,1,0):OnStep(function(step,pos)
	print(step,pos)
end):OnEnd(fucntion(step)
	step:Destroy()
end)
multi:mainloop()
```

# Actor: TSteps
`tstep = multi:newStep(NUMBER start, NUMBER reset, [NUMBER count 1], [NUMBER set 1])` — TSteps work just like steps, the only difference is that instead of skip, we have set which is how long in seconds it should wait before triggering the OnStep() event.

- `self = tstep:OnStart(FUNCTION func(self))` — This connects a function to an event that is triggered everytime a step starts.
- `self = tstep:OnStep(FUNCTION func(self,i))` — This connects a function to an event that is triggered every step or cycle that is alloted to the step object
- `self = tstep:OnEnd(FUNCTION func(self))` — This connects a function to an event that is triggered when a step reaches its goal
- `self = tstep:Update(NUMBER start,*NUMBER reset, [NUMBER count 1], [NUMBER set 1])` — Update can be used to change the goals of the step. You should call step:Reset() after using Update to restart the step.
- `self = tstep:Reset([NUMBER n set])` — Allows you to reset a tstep that has ended, but also can change the time between each trigger.

Example:
```lua
package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi:newTStep(1,10,1,1):OnStep(function(step,pos)
	print(step,pos)
end):OnEnd(fucntion(step)
	step:Destroy()
end)
multi:mainloop()
```

# Coroutine based Threading (CBT)
Helpful methods are wrapped around the builtin coroutine module which make it feel like real threading.

**threads.\* used within threaded enviroments**
- `thread.sleep(NUMBER n)` — Holds execution of the thread until a certain amount of time has passed
- `VARIABLE returns = thread.hold(FUNCTION func)` — Hold execution until the function returns non nil. All returns are passed to the thread once the conditions have been met. To pass nil use `multi.NIL`\*
- `thread.skip(NUMBER n)` — How many cycles should be skipped until I execute again
- `thread.kill()` — Kills the thread
- `thread.yeild()` — Is the same as using thread.skip(0) or thread.sleep(0), hands off control until the next cycle
- `BOOLEAM bool = thread.isThread()` — Returns true if the current running code is inside of a coroutine based thread
- `NUMBER conres = thread.getCores()` — Returns the number of cores that the current system has. (used for system threads)
- `thread.set(STRING name, VARIABLE val)` — A global interface where threads can talk with eachother. sets a variable with name and its value
- `thread.get(STRING name)` — Gets the data stored in name
- `VARIABLE val = thread.waitFor(STRING name)` — Holds executon of a thread until variable name exists
- `thread.request(THREAD th,STRING cmd, VARIABLE args)` — Sends a request to the selected thread telling it to do a certain command
- `th = thread.getRunningThread()` — Returns the currently running thread
- `VARIABLE returns or nil, "TIMEOUT" = thread.holdFor(NUMBER: sec, FUNCTION: condition)` — Holds until a condidtion is met, or if there is a timeout nil,"TIMEOUT"
- `VARIABLE returns or nil, "TIMEOUT" = thread.holdWithin(NUMBER: skip, FUNCTION: func)` — Holds until a condition is met or n cycles have happened.
- `returns or handler = thread:newFunction(FUNCTION: func, [BOOLEAN: holdme false])` — func: The function you want to be threaded. holdme: If true the function waits until it has returns and then returns them. Otherwise the function returns a table
	- `handler.connect(Function: func(returns))` — Connects to the event that is triggered when the returns are avaiable
	- `VARIAABLE returns = handler.wait()` — Waits until returns are avaiable and then returns them

<b>\*</b>A note about multi.NIL, this should only be used within the hold and hold like methods. thread.hold(), thread.holdFor(), and thread.holdWithin() methods. This is not needed within threaded functions! The reason hold prevents nil and false is because it is testing for a condition so the first argument needs to be non nil nor false! multi.NIL should not be used anywhere else. Sometimes you may need to pass a 'nil' value or return. While you could always return true or something you could use multi.NIL to force a nil value through a hold like method.

# CBT: newService(FUNCTION: func)
`serv = newService(FUNCTION: func(self,TABLE: data))` — func is called each time the service is updated think of it like a loop multi-obj. self is the service object and data is a private table that only the service can see. 
- `serv.OnError(FUNCTION: func)` — connection that fired if there is an error
- `serv.OnStopped(FUNCTION: func(serv))` — connection that is fired when a service is stopped
- `serv.OnStarted(FUNCTION: func(serv))` — connection that is fired when a service is started
- `serv.Start()` — Starts the service
- `serv.Stop()` — Stops the service and destroys the data table
- `serv.Pause()` — Pauses the service
- `serv.Resume()` — Resumes the service
- `serv.GetUpTime()` — Returns the amount of time the service has been running
- `serv.SetPriority(PRIORITY: pri)` — Sets the priority of the service
	- `multi.Priority_Core`
	- `multi.Priority_Very_High`
	- `multi.Priority_High`
	- `multi.Priority_Above_Normal`
	- `multi.Priority_Normal` **Default**
	- `multi.Priority_Below_Normal`
	- `multi.Priority_Low`
	- `multi.Priority_Very_Low`
	- `multi.Priority_Idle`
- `serv.SetScheme(NUMBER: n)` — Sets the scheme of the priority management
	- `1` **Default** — uses a time based style of yielding. thread.sleep()
	- `2` — uses a cycle based style of yielding. thread.skip()
- `CONVERTS(serv) = serv.Destroy()` — Stops the service then Destroys the service triggering all events! The service becomes a destroyed object

Example:
```lua
-- Jobs are not natively part of the multi library. I planned on adding them, but decided against it. Below is the code that would have been used.
-- Implementing a job manager using services
package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi.Jobs = multi:newService(function(self,jobs)
	local job = table.remove(jobs,1)
	if job and job.removed==nil then
		job.func()
	end
end)
multi.Jobs.OnStarted(function(self,jobs)
	function self:newJob(func,name)
		table.insert(jobs,{
			func = func,
			name = name,
			removeJob = function(self) self.removed = true end
		})
	end
	function self:getJobs(name)
		local tab = {}
		if not name then return jobs end
		for i=1,#jobs do
			if name == jobs[i].name then
				table.insert(tab,jobs[i])
			end
		end
		return tab
	end
	function self:removeJobs(name)
		for i=1,#jobs do
			if name ~= nil and name == jobs[i].name then
				jobs[i]:removeJob()
			elseif name == nil then
				jobs[i]:removeJob()
			end
		end
	end
end)
multi.Jobs.SetPriority(multi.Priority_Normal)
multi.Jobs.Start()

-- Testing job stuff
function pushJobs()
	multi.Jobs:newJob(function()
		print("job called")
	end) -- No name job
	multi.Jobs:newJob(function()
        print("job called2")
	end,"test")
	multi.Jobs:newJob(function()
		print("job called3")
	end,"test2")
end
pushJobs()
pushJobs()
local jobs = multi.Jobs:getJobs() -- gets all jobs
local jobsn = multi.Jobs:getJobs("test") -- gets all jobs names 'test'
jobsn[1]:removeJob() -- Select a job and remove it
multi.Jobs:removeJobs("test2") -- Remove all jobs names 'test2'
multi.Jobs.SetScheme(1) -- Jobs are internally a service, so setting scheme and priority
multi.Jobs.SetPriority(multi.Priority_Core)
multi:mainloop()
```

# CBT: newThread()
`th = multi:newThread([STRING name,] FUNCTION func)` — Creates a new thread with name and function.

when within a thread, if you have any holding code you will want to use thread.* to give time to other threads while your code is running.
Constants
---
- `th.Name` — Name of thread
- `th.Type` — Type="thread"
- `th.TID` — Thread ID
- `conn = th.OnError(FUNCTION: callback)` — Connect to an event which is triggered when an error is encountered within a thread
- `conn = th.OnDeath(FUNCTION: callback)` — Connect to an event which is triggered when the thread had either been killed or stopped running. (Not triggered when there is an error!)
- `boolean = th:isPaused()`\* — Returns true if a thread has been paused
- `self = th:Pause()`\* — Pauses a thread
- `self = th:Resume()`\* — Resumes a paused thread
- `self = th:Kill()`\* — Kills a thread
- `self = th:Destroy()`\* — Destroys a thread

<b>*</b>Using these methods on a thread directly you are making a request to a thread! The thread may not accept your request, but it most likely will. You can contorl the thread flow within the thread's function itself

Examples:
```lua
package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi:newThread("Example of basic usage",function()
	while true do
    	thread.sleep(1)
        print("We just made an alarm!")
    end
end)
multi:mainloop()
```

# CBT: newISOThread()
`th = multi:newThread([STRING name,] FUNCTION func, TABLE: env)` — Creates a new thread with name and function func. Sets the enviroment of the func to env. Both the thread.* and multi.* are automatically placed in the enviroment.

When within a thread, if you have any holding code you will want to use thread.* to give time to other threads while your code is running. This type of thread does not have access to outside local or globals. Only what is in the env can be seen. (This thread was made so pesudo threading could work)
Constants
---
- `th.Name` — Name of thread
- `th.Type` — Type="thread"
- `th.TID` — Thread ID
- `conn = th.OnError(FUNCTION: callback)` — Connect to an event which is triggered when an error is encountered within a thread
- `conn = th.OnDeath(FUNCTION: callback)` — Connect to an event which is triggered when the thread had either been killed or stopped running. (Not triggered when there is an error!)
- `boolean = th:isPaused()`\* — Returns true if a thread has been paused
- `self = th:Pause()`\* — Pauses a thread
- `self = th:Resume()`\* — Resumes a paused thread
- `self = th:Kill()`\* — Kills a thread
- `self = th:Destroy()`\* — Destroys a thread

<b>*</b>Using these methods on a thread directly you are making a request to a thread! The thread may not accept your request, but it most likely will. You can contorl the thread flow within the thread's function itself
```lua
package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
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
        thread.sleep(1)
        print("Testing 1 ...",a,b,test)
    end
end).OnError(function(self,msg)
    print(msg)
end)

-- All upvalues are stripped! no access to the global, multi and thread are exposed however
multi:newISOThread("ISO Thread 2",function()
    while true do
        thread.sleep(1)
        print("Testing 2 ...",a,b,test) -- a and b are nil, but test is true
    end
end,{test=true,print=print})

.OnError(function(self,msg)
    print(msg)
end)

multi:mainloop()
```
# System Threads (ST) - Multi-Integration Getting Started
The system threads need to be required seperatly.
```lua
-- I recommend keeping these as globals. When using lanes you can use local and things will work, but if you use love2d and locals, upvalues are not transfered over threads and this can be an issue
GLOBAL, THREAD = require("multi.integration.threading"):init() -- We will talk about the global and thread interface that is returned
GLOBAL, THREAD = require("multi.integration.loveManager"):init()
GLOBAL, THREAD = require("luvitManager") --*
```
Using this integration modifies some methods that the multi library has.
- `multi:canSystemThread()` — Returns true if system threading is possible.
- `multi:getPlatform()` — Returns (for now) either "lanes", "love2d" and "luvit"
- `multi.isMainThread = true` — This is only modified on the main thread. So code that moves from one thread to another knows where it's at.

<b>*</b>GLOBAL and THREAD do not do anything when using the luvit integration

# ST - THREAD namespace
- `THREAD.set(STRING name, VALUE val)` — Sets a value in GLOBAL
- `THREAD.get(STRING name)` — Gets a value in GLOBAL
- `THREAD.waitFor(STRING name)` — Waits for a value in GLOBAL to exist
- `THREAD.getCores()` — Returns the number of actual system threads/cores
- `THREAD.kill()` — Kills the thread
- `THREAD.getName()` — Returns the name of the working thread
- `THREAD.sleep(NUMBER n)` — Sleeps for an amount of time stopping the current thread
- `THREAD.hold(FUNCTION func)` — Holds the current thread until a condition is met
- `THREAD.getID()` — returns a unique ID for the current thread. This varaiable is visible to the main thread as well as by accessing it through the returned thread object. OBJ.Id

# ST - GLOBAL namespace
Treat global like a table.
```lua
GLOBAL["name"] = "Ryan"
print(GLOBAL["name"])
```
Removes the need to use THREAD.set() and THREAD.get()

ST - System Threads
-------------------
- `systemThread = multi:newSystemThread(STRING thread_name, FUNCTION spawned_function,ARGUMENTS ...)` — Spawns a thread with a certain name.
- `systemThread:kill()` — kills a thread; can only be called in the main thread!
- `systemThread.OnError(FUNCTION(systemthread,errMsg,errorMsgWithThreadName))`

System Threads are the feature that allows a user to interact with systen threads. It differs from regular coroutine based thread in how it can interact with variables. When using system threads the GLOBAL table is the "only way"* to send data. Spawning a System thread is really simple once all the required libraries are in place. See example below:

```lua
multi,thread = require("multi"):init() -- keep this global when using lanes or implicitly define multi within the spawned thread
local GLOBAL, THREAD = require("multi.integration.threading").init()
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

<b>*</b>This isn't entirely true, as of right now the compatiablity with the lanes library and love2d engine have their own methods to share data, but if you would like to have your code work in both enviroments then using the GLOBAL table and the data structures provided by the multi library will ensure this happens. If you do not plan on having support for both platforms then feel free to use linda's in lanes and channels in love2d.

**Note:** luvit currently has very basic support, it only allows the spawning of system threads, but no way to send data back and forth as of yet. I do not know if this is doable or not, but I will keep looking into it.

# ST - System Threaded Objects
Great we are able to spawn threads, but unless your working with a process that works on passed data and then uses a socket or writes to the disk I can't do to much with out being able to pass data between threads. This section we will look at how we can share objects between threads. In order to keep the compatibility between both love2d and lanes I had to format the system threaded objects in a strange way, but they are consistant and should work on both enviroments.

When creating objects with a name they are automatically exposed to the GLOBAL table. Which means you can retrieve them from a spawned thread. For example we have a queue object, which will be discussed in more detail next.

```lua
-- Exposing a queue
multi,thread = require("multi"):init()
local GLOBAL, THREAD = require("multi.integration.threading").init() -- The standard setup above
queue = multi:newSystemThreadedQueue("myQueue"):init() -- We create and initiate the queue for the main thread
queue:push("This is a test!") -- We push some data onto the queue that other threads can consume and do stuff with
multi:newSystemThread("Example thread",function() -- Create a system thread
	queue = THREAD.waitFor("myQueue"):init() -- Get the queue. It is good pratice to use the waitFor command when getting objects. If it doesn't exist yet we wait for it, preventing future errors. It is possible for the data to not ve present when a thread is looking for it! Especally when using the love2d module, my fault needs some rewriting data passing on the GLOBAL is quite slow, but the queue internally uses channels so after it is exposed you should have good speeds!
    local data = queue:pop() -- Get the data
    print(data) -- print the data
end)
multi:mainloop()
```

# ST - SystemThreadedQueue
- `queue(nonInit) = multi:newSystemThreadedQueue(STRING name)` — You must enter a name!
- `queue = queue:init()` — initiates the queue, without doing this it will not work
- `void = queue:push(DATA data)` — Pushes data into a queue that all threads that have been shared have access to
- `data = queue:pop()` — pops data from the queue removing it from all threads
- `data = queue:peek()` — looks at data that is on the queue, but dont remove it from the queue

Let's get into some examples:
```lua
multi,thread = require("multi"):init()
thread_names = {"Thread_A","Thread_B","Thread_C","Thread_D"}
local GLOBAL, THREAD = require("multi.integration.threading"):init()
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

# ST - Using the Console
`console = THREAD.getConsole()`

This does guarantee an order to console output, it does ensure that all things are on nice neat lines
```lua
multi,thread = require("multi"):init()
local GLOBAL, THREAD = require("multi.integration.threading"):init()

console.print("Hello World!")
```
# ST - SystemThreadedJobQueue
`jq = multi:newSystemThreadedJobQueue([NUMBER: threads])` — Creates a system threaded job queue with an optional number of threads
- `jq.cores = (supplied number) or (the number of cores on your system*2)`
- `jq.OnJobCompleted(FUNCTION: func(jID,...))` — Connection that is triggered when a job has been completed. The jobID and returns of the job are supplies as arguments
- `self = jq:doToAll(FUNCTION: func)` — Send data to every thread in the job queue. Useful if you want to require a module and have it available on all threads
- `self = jq:registerFunction(STRING: name, FUNCTION: func)` — Registers a function on the job queue. Name is the name of function func
- `jID = jq:pushJob(STRING: name,[...])` — Pushes a job onto the jobqueue
- `handler = jq:newFunction([STRING: name], FUNCTION: func)` — returns a threaded Function that wraps around jq.registerFunction, jq.pushJob() and jq.OnJobCompleted() to provide an easy way to create and work with the jobqueue
	- `handler.connect(Function: func(returns))` — Connects to the event that is triggered when the returns are avaiable
	- `VARIAABLE returns = handler.wait()` — Waits until returns are avaiable and then returns them
**Note:** Created functions using this method act as normal functions on the queue side of things. So you can call the functions from other queue functions as if they were normal functions.

Example:
```lua
package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
GLOBAL, THREAD = require("multi.integration.threading"):init()
local jq = multi:newSystemThreadedJobQueue(4) -- job queue using 4 cores
jq:doToAll(function()
	Important = 15
end)
jq:registerFunction("test",function(a,b)
	--print(a,b,a+b)
	return true
end)
jq.OnJobCompleted(function(jid,arg)
	print(jid,arg)
end)
local jid = jq:pushJob("test",10,5)
print("Job pushed! ID = ".. jid)
local func = jq:newFunction("test2",function(a,b)
    print(a,b,a*b)
    return
end)
print("Waited",func(10,5).wait())
func(5,5).connect(function(ret)
    print("Connected",ret)
    os.exit()
end)
multi:mainloop()
```
# ST - SystemThreadedTable
`stt = multi:newSystemThreadedTable(STRING: name)`
- `stt:init()` — Used to init object over threads
- `stt[var] = val`
- `val = stt[var]`

Example:
```lua
package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
GLOBAL, THREAD = require("multi.integration.threading"):init()
local stt = multi:newSystemThreadedTable("stt")
stt["hello"] = "world"
multi:newSystemThread("test thread",function()
    local stt = GLOBAL["stt"]:init()
    print(stt["hello"])
end)
multi:mainloop()
```
# Network Threads - Multi-Integration WIP Being Reworked
More of a fun project of mine then anything core to to the library it will be released and documented when it is ready. I do not have a timeframe for this

