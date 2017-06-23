# multi Version: 1.7.0 (Taking multi-tasking to the next level)

My multitasking library for lua</br>
To install copy the multi folder into your enviroment and you are good to go</br>

It is a pure lua binding if you ingore the intergrations</br>

If you find any bugs or have any issues please let me know :)

Also I will eventually add an example folder with a lot of examples for how you can use this library. Don't konw when that will be though :P

# Discord
For real-time assistance with my libraries! A place where you can ask questions and get help with any of my libraries</br>
https://discord.gg/U8UspuA</br>

View Changes: https://github.com/rayaman/multi#changes

Usage:</br>
```lua
--Basic usage
require("multi.all") -- gets the entire library
alarm=multi:newAlarm(3) -- in seconds can go to .001 uses the built in os.clock()
alarm:OnRing(function(a)
  print("3 Seconds have passed!")
  a:Reset(n) -- if n were nil it will reset back to 3, or it would reset to n seconds
end)
multi:mainloop() -- the main loop of the program, multi:umanager() exists as well to allow intergration in other loops Ex: love2d love.update function. More on this binding in the wiki!
```
The library is modular so you only need to require what you need to. Because of this, the global enviroment is altered</br>

There are many useful objects that you can use</br>
Check out the wiki for detailed usage, but here are the objects:</br>
- Process#</br>
- Queuer#</br>
- Alarm</br>
- Loop</br>
- Event</br>
- Step</br>
- Range</br>
- TStep</br>
- TLoop</br>
- Condition</br>
- Connection</br>
- Timer</br>
- Updater</br>
- Thread*</br>
- Trigger**</br>
- Task</br>
- Job</br>
- Function</br>
- Watcher***</br>
#Both a process and queue act like the multi namespace, but allows for some cool things. Because they use the other objects an example on them will be done last</br>
*Uses the built in coroutine features of lua, these have an interesting interaction with the other means of multi-tasking</br>
**Triggers are kind of useless after the creation of the Connection</br>
***Watchers have no real purpose as well I made it just because.</br>

# Examples of each object being used</br>
We already showed alarms in action so lets move on to a Loop object

Throughout these examples I am going to do some strange things in order to show other features of the library!

# LOOPS
```lua
-- Loops
require("multi.all") -- gets the entire library
count=0
loop=multi:newLoop(function(self,dt) -- dt is delta time and self is a reference to itself
  count=count+1
  if count > 10 then
    self:Break() -- All methods on the multi objects are upper camel case, where as methods on the multi or process/queuer namespace are lower camel case
    -- self:Break() will stop the loop and trigger the OnBreak(func) method
    -- Stopping is the act of Pausing and deactivating the object! All objects can have the multiobj:Break() command on it!
  else
    print("Loop #"..count.."!")
  end
end)
loop:OnBreak(function(self)
  print("You broke me :(")
end)
multi:mainloop()
```
# Output
Loop #1!</br>
Loop #2!</br>
Loop #3!</br>
Loop #4!</br>
Loop #5!</br>
Loop #6!</br>
Loop #7!</br>
Loop #8!</br>
Loop #9!</br>
Loop #10!</br>
You broke me :(</br>


With loops out of the way lets go down the line

This library aims to be Async like. In reality everything is still on one thread *unless you are using the lanes intergration module WIP* (More on that later)

# EVENTS
```lua
-- Events, these were the first objects introduced into the library. I seldomly use them in their pure form though, but later on you'll see their advance uses!
-- Events on there own don't really do much... We are going to need 2 objects at least to get something going
require("multi.all") -- gets the entire library
count=0
-- lets use the loop again to add to count!
loop=multi:newLoop(function(self,dt)
  count=count+1
end)
event=multi:newEvent(function() return count==100 end) -- set the event
event:OnEvent(function(self) -- connect to the event object
  loop:Pause() -- pauses the loop from running!
  print("Stopped that loop!")
end) -- events like alarms need to be reset the Reset() command works here as well
multi:mainloop()
```
# Output
Stopped that loop!

# STEPS
```lua
require("multi.all")
-- Steps, are like for loops but non blocking... You can run a loop to infintity and everything will still run I will combine Steps with Ranges in this example.
step1=multi:newStep(1,10,1,0) -- Some explaining is due. Argument 1 is the Start # Argument 2 is the ResetAt # (inclusive) Argument 3 is the count # (in our case we are counting by +1, this can be -1 but you need to adjust your start and resetAt numbers)
-- The 4th Argument is for skipping. This is useful for timing and for basic priority management. A priority management system is included!
step2=multi:newStep(10,1,-1,1) -- a second step, notice the slight changes!
step1:OnStart(function(self)
  print("Step Started!")
end)
step1:OnStep(function(self,pos)
  if pos<=10 then -- what what is this? the step only goes to 10!!!
    print("Stepping... "..pos)
   else
    print("How did I get here?")
   end
end)
step1:OnEnd(function(self)
  print("Done!")
  -- We finished here, but I feel like we could have reused this step in some way... Yeah I soule Reset() it, but what if i wanted to change it...
  if self.endAt==10 then -- lets only loop once
	self:Update(1,11,1,0) -- oh now we can reach that else condition!
  end
  -- Note Update() will restart the step!
end)

-- step2 is bored lets give it some love :P
step2.range=step2:newRange() -- Set up a range object to have a nested step in a sense! Each nest requires a new range
-- it is in your interest not to share ranges between objects! You can however do it if it suits your needs though
step2:OnStep(function(self,pos)
  -- for 1=1,math.huge do
    --  print("Haha I am holding the code up because I can!!!")
  --end
  -- We dont want to hold things up, but we want to nest.
  -- Note a range is not nessary if the nested for loop has a small range, if however the range is rather large you may want to allow other objects to do some work
  for i in self.range(1,100) do
    print(pos,i) -- Now our nested for loop is using a range object which allows for other objects to get some cpu time while this one is running
  end
end)
-- TSteps are just like alarms and steps mixed together, the only difference in construction is the 4th Argument. On a TStep that argument controls time. The defualt is 1
-- The Reset(n) works just like you would figure!
step3=multi:newTStep(1,10,.5,2) -- lets go from 1 to 10 counting by .5 every 2 seconds
step3:OnStep(function(self,pos)
  print("Ok "..pos.."!")
end)
multi:mainloop()
```
# Output

Note: the output on this one is huge!!! So I had to ... some parts! You need to run this for your self to see what is going on!</br>
Step Started!</br>
Stepping... 1</br>
10	1</br>
Stepping... 2</br>
10	2</br>
Stepping... 3</br>
10	3</br>
...</br>
Ok 9.5!</br>
Ok 10!</br>

# TLOOPS
```lua
require("multi.all")
-- TLoops are loops that run ever n second. We will also look at condition objects as well
-- Here we are going to modify the old loop to be a little different
count=0
loop=multi:newTLoop(function(self) -- We are only going to coult with this loop, but doing so using a condition!
  while self:condition(self.cond) do
    count=count+1
  end
  print("Count is "..count.."!")
  self:Destroy() -- Lets destroy this object, casting it to the dark abyss MUHAHAHA!!!
  -- the reference to this object will be a phantom object that does nothing!
end,1) -- Notice the ',1' after the function! This is where you put your time value!
loop.cond=multi:newCondition(function() return count<=100 end) -- conditions need a bit of work before i am happy with them
multi:mainloop()
```
# Output
Count is 101!

# Connections
These are my favorite objects and you'll see why. They are very useful objects for ASync connections!

```lua
require("multi.all")
-- Lets create the events
yawn={} -- ill just leave that there
OnCustomSafeEvent=multi:newConnection(true) -- lets pcall the calls incase something goes wrong defualt
OnCustomEvent=multi:newConnection(false) -- lets not pcall the calls and let errors happen... We are good at coding though so lets get a speed advantage by not pcalling. Pcalling is useful for plugins and stuff that may have been coded badly and you can ingore those connections if need be.
OnCustomEvent:Bind(yawn) -- create the connection lookup data in yawn

-- Lets connect to them, a recent update adds a nice syntax to connect to these
cd1=OnCustomSafeEvent:Connect(function(arg1,arg2,...)
  print("CSE1",arg1,arg2,...)
end,"bob") -- lets give this connection a name
cd2=OnCustomSafeEvent:Connect(function(arg1,arg2,...)
  print("CSE2",arg1,arg2,...)
end,"joe") -- lets give this connection a name
cd3=OnCustomSafeEvent:Connect(function(arg1,arg2,...)
  print("CSE3",arg1,arg2,...)
end) -- lets not give this connection a name

-- no need for connect, but I kept that function because of backwards compatibility.
OnCustomEvent(function(arg1,arg2,...)
  print(arg1,arg2,...)
end)

-- Now within some loop/other object you trigger the connection like
OnCustomEvent:Fire(1,2,"Hello!!!") -- fire all conections

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
# Output
1	2	Hello!!!</br>
CSE1	1	100	Bye!</br>
CSE2	1	100	Hello!</br>
CSE1	1	100	Hi Ya Folks!!!</br>
CSE2	1	100	Hi Ya Folks!!!</br>
CSE3	1	100	Hi Ya Folks!!!</br>
------</br>
CSE2	1	100	Hi Ya Folks!!!</br>
CSE3	1	100	Hi Ya Folks!!!</br>
------</br>

You may think timers should be bundled with alarms, but they are a bit different and have cool features</br>
# TIMERS
```lua
-- You see the thing is that all time based objects use timers eg. Alarms, TSteps, and Loops. Timers are more low level!
require("multi.all")
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end -- we will use this later!

timer=multi:newTimer()
timer:Start()
-- lets do a mock alarm
set=3 -- 3 seconds
a=0
while timer:Get()<=set do
  -- waiting...
  a=a+1
end
print(set.." second(s) have passed!")
-- Timers can do one more thing that is interesting and that is pausing them!
timer:Pause()
print(timer:Get()) -- should be really close to 'set'
sleep(3)
print(timer:Get()) -- should be really close to 'set'
timer:Resume()
sleep(1)
print(timer:Get()) -- should be really close to the value of set + 1
timer:Pause()
print(timer:Get()) -- should be really close to 'set'
sleep(3)
print(timer:Get()) -- should be really close to 'set'
timer:Resume()
sleep(1)
print(timer:Get()) -- should be really close to the value of set + 2
```
# Output
Note: This will make more sense when you run it for your self</br>
3 second(s) have passed!</br>
3.001</br>
3.001</br>
4.002</br>
4.002</br>
4.002</br>
5.003</br>

# UPDATER
```lua
require("multi.all")
updater=multi:newUpdater(5) -- really simple, think of a look with the skip feature of a step
updater:OnUpdate(function(self)
  --print("updating...")
end)
-- Here every 5 steps the updater will do stuff!
-- But I feel it is now time to touch into priority management, so lets get into basic priority stuff and get into a more advance version of it
--[[
multi.Priority_Core -- Highest form of priority
multi.Priority_High
multi.Priority_Above_Normal
multi.Priority_Normal -- The defualt form of priority
multi.Priority_Below_Normal
multi.Priority_Low
multi.Priority_Idle -- Lowest form of priority

Note: These only take effect when you enable priority, otherwise everything is at a core like level!
We aren't going to use regular objects to test priority, but rather benchmarks!
to set priority on an object though you would do
multiobj:setPriority(one of the above)
]]
-- lets bench for 3 seconds using the 3 forms of priority! First no Priority
multi:benchMark(3,nil,"Regular Bench: "):OnBench(function() -- the onbench() allows us to do each bench after each other!
  print("P1\n---------------")
  multi:enablePriority()
  multi:benchMark(3,multi.Priority_Core,"Core:")
  multi:benchMark(3,multi.Priority_High,"High:")
  multi:benchMark(3,multi.Priority_Above_Normal,"Above_Normal:")
  multi:benchMark(3,multi.Priority_Normal,"Normal:")
  multi:benchMark(3,multi.Priority_Below_Normal,"Below_Normal:")
  multi:benchMark(3,multi.Priority_Low,"Low:")
  multi:benchMark(3,multi.Priority_Idle,"Idle:"):OnBench(function()
    print("P2\n---------------")
	-- Finally the 3rd form
    multi:enablePriority2()
    multi:benchMark(3,multi.Priority_Core,"Core:")
    multi:benchMark(3,multi.Priority_High,"High:")
    multi:benchMark(3,multi.Priority_Above_Normal,"Above_Normal:")
    multi:benchMark(3,multi.Priority_Normal,"Normal:")
    multi:benchMark(3,multi.Priority_Below_Normal,"Below_Normal:")
    multi:benchMark(3,multi.Priority_Low,"Low:")
    multi:benchMark(3,multi.Priority_Idle,"Idle:")
  end)
end)
multi:mainloop() -- Notice how the past few examples did not need this, well only actors need to be in a loop! More on this in the wiki.
```
# Output
Note: These numbers will vary drastically depending on your compiler and cpu power</br>
Regular Bench:  2094137 Steps in 3 second(s)!</br>
P1</br>
---------------</br>
Below_Normal: 236022 Steps in 3 second(s)!</br>
Normal: 314697 Steps in 3 second(s)!</br>
Above_Normal: 393372 Steps in 3 second(s)!</br>
High: 472047 Steps in 3 second(s)!</br>
Core: 550722 Steps in 3 second(s)!</br>
Low: 157348 Steps in 3 second(s)!</br>
Idle: 78674 Steps in 3 second(s)!</br>
P2</br>
---------------</br>
Core: 994664 Steps in 3 second(s)!</br>
High: 248666 Steps in 3 second(s)!</br>
Above_Normal: 62166 Steps in 3 second(s)!</br>
Normal: 15541 Steps in 3 second(s)!</br>
Below_Normal: 3885 Steps in 3 second(s)!</br>
Idle: 242 Steps in 3 second(s)!</br>
Low: 971 Steps in 3 second(s)!</br>

Notice: Even though I started each bench at the same time the order that they finished differed the order is likely to vary on your machine as well!</br>

# Processes
A process allows you to group the Actor objects within a controlable interface
```lua
require("multi.all")
proc=multi:newProcess() -- takes an optional file as an argument, but for this example we aren't going to use that
-- a process works just like the multi object!
b=0
loop=proc:newTLoop(function(self)
	a=a+1
	proc:Pause() -- pauses the cpu cycler for this processor! Individual objects are not paused, however because they aren't getting cpu time they act as if they were paused
end,.1)
updater=proc:newUpdater(multi.Priority_Idle) -- priority can be used in skip arguments as well to manage priority without enabling it!
updater:OnUpdate(function(self)
	b=b+1
end)
a=0 -- a counter
loop2=proc:newLoop(function(self,dt)
	print("Lets Go!")
	self:hold(3) -- this will keep this object from doing anything! Note: You can only have one hold active at a time! Multiple are possible, but results may not be as they seem see * for how hold works
	-- Within a process using hold will keep it alive until the hold is satisified!
	print("Done being held for 1 second")
	self:hold(function() return a>10 end)
	print("A is now: "..a.." b is also: "..b)
	self:Destroy()
	self.Parent:Pause() -- lets say you don't have the reference to the process!
	os.exit()
end)
-- Notice this is now being created on the multi namespace
event=multi:newEvent(function() return os.clock()>=1 end)
event:OnEvent(function(self)
	proc:Resume()
	self:Destroy()
end)
proc:Start()
multi:mainloop()
```
# Output
Lets Go!</br>
Done being held for 1 second</br>
A is now: 29 b is also: 479</br>

**Hold: This method works as follows**
```lua
function multi:hold(task)
	self:Pause() -- pause the current object
	self.held=true -- set held
	if type(task)=='number' then -- a sleep cmd
		local timer=multi:newTimer()
		timer:Start()
		while timer:Get()<task do -- This while loop is what makes using multiple holds tricky... If the outer while is good before the nested one then the outter one will have to wait! There is a way around this though!
			if love then
				self.Parent:lManager()
			else
				self.Parent:Do_Order()
			end
		end
		self:Resume()
		self.held=false
	elseif type(task)=='function' then
		local env=self.Parent:newEvent(task)
		env:OnEvent(function(envt) envt:Pause() envt.Active=false end)
		while env.Active do
			if love then
				self.Parent:lManager()
			else
				self.Parent:Do_Order()
			end
		end
		env:Destroy()
		self:Resume()
		self.held=false
	else
		print('Error Data Type!!!')
	end
end
```

# Queuer (WIP)
A queuer works just like a process however objects are processed in order that they were created...
```lua
queue = multi:newQueuer()
queue:newAlarm(3):OnRing(function()
	print("Ring ring!!!")
end)
queue:newStep(1,10):OnStep(function(self,pos)
	print(pos)
end)
queue:newLoop(function(self,dt)
	if dt==3 then
		self:Break()
		print("Done")
	end
end)
queue:Start()
multi:mainloop()
```
# Expected Output
Note: the queuer still does not work as expected!</br>
Ring ring!!!</br>
1</br>
2</br>
3</br>
4</br>
5</br>
6</br>
7</br>
8</br>
9</br>
10</br>
Done</br>
# Actual Output
Done</br>
1</br>
2</br>
3</br>
4</br>
5</br>
6</br>
7</br>
8</br>
9</br>
10</br>
Ring ring!!!</br>

# Threads
These fix the hold problem that you get with regular objects, and they work exactly the same! They even have some extra features that make them really useful.</br>
```lua
_require=require -- lets play with the require method a bit
function require(path)
	path=path:gsub("%*","all")
	_require(path)
end
require("multi.*") -- now I can use that lovely * symbol to require everything
test=multi:newThreadedProcess("main") -- you can thread processors and all Actors see note for a list of actors you can thread!
test2=multi:newThreadedProcess("main2")
count=0
test:newLoop(function(self,dt)
	count=count+1
	thread.sleep(.01)
end)
test2:newLoop(function(self,dt)
	print("Hello!")
	thread.sleep(1) -- sleep for some time
end)
-- threads take a name object then the rest as normal
step=multi:newThreadedTStep("step",1,10)
step:OnStep(function(self,p)
	print("step",p)
	thread.skip(21) -- skip n cycles
end)
step:OnEnd(function()
	print("Killing thread!")
	thread.kill() -- kill the thread
end)
loop=multi:newThreadedLoop("loop",function(self,dt)
	print(dt)
	thread.sleep(1.1)
end)
loop2=multi:newThreadedLoop("loop",function(self,dt)
	print(dt)
	thread.hold(function() return count>=100 end)
	print("Count is "..count)
	os.exit()
end)
alarm=multi:newThreadedAlarm("alarm",1)
alarm:OnRing(function(self)
	print("Ring")
	self:Reset()
end)
multi:mainloop()
```
# Output
Ring</br>
0.992</br>
0.992</br>
Hello!</br>
step	1</br>
step	2</br>
Hello!</br>
Ring</br>
2.092</br>
step	3</br>
Hello!</br>
Ring</br>
Count is 100</br>
# Threadable Actors
- Alarms
- Events
- Loop/TLoop
- Process
- Step/TStep

# Functions
If you ever wanted to pause a function then great now you can
The uses of the Function object allows one to have a method that can run free in a sense
```lua
require("multi.all")
func=multi:newFunction(function(self,arg1,arg2,...)
	self:Pause()
	return arg1
end)
print(func("Hello"))
print(func("Hello2")) -- returns PAUSED allows for the calling of functions that should only be called once. returns PAUSED instantly if paused
func:Resume()
print(func("Hello3"))
```
# Output
Hello</br>
PAUSED</br>
Hello3</br>

# ThreadedUpdater

```lua
-- Works the same as a regular updater!
require("multi.all")
multi:newThreadedUpdater("Test",10000):OnUpdate(function(self)
	print(self.pos)
end)
multi:mainloop()
```
# Output
1</br>
2</br>
...</br>
.inf</br>

# Triggers
Triggers were what I used before connections became a thing, also Function objects are a lot like triggers and can be paused as well, while triggers cannot...</br>
They are simple to use, but in most cases you are better off using a connection</br>
```lua
require("multi.trigger")
-- They work like connections but can only have one event binded to them
trig=multi:newTrigger(function(self,a,b,c,...)
	print(a,b,c,...)
end)
trig:Fire(1,2,3)
trig:Fire(1,2,3,"Hello",true)
```

# Output
1	2	3</br>
1	2	3	Hello	true</br>

# Tasks
Tasks allow you to run a block of code before the multi mainloops does it thing. Tasks still have a use, but depending on how you program they aren't needed.</br>
```lua
require("multi.loop")
require("multi.task")
multi:newTask(function()
	print("Hi!")
end)
multi:newLoop(function(self,dt)
	print("Which came first the task or the loop?")
	self:Break()
end)
multi:newTask(function()
	print("Hello there!")
end)
multi:mainloop()
```
# Output
Hi!</br>
Hello there!</br>
Which came first the task or the loop?</br>

As seen in the example above the tasks were done before anything else in the mainloop! This is useful when making libraries around the multitasking features and you need things to happen in a certain order!</br>

# Jobs
Jobs were a strange feature that was created for throttling connections! When I was building a irc bot around this library I couldn't have messages posting too fast due to restrictions. Jobs allowed functions to be added to a queue that were executed after a certain amount of time has passed
```lua
require("multi.alarm") -- jobs use alarms I am pondering if alarms should be added to the core or if jobs should use timers instead...
-- jobs are built into the core of the library so no need to require them
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
# Output
false	0</br>
true	4</br>
There are 4 jobs in the queue!</br>
A job!</br></br>
Another job!</br>

# Watchers
Watchers allow you to monitor a variable and trigger an event when the variable has changed!
```lua
require("multi.watcher")
require("multi.tloop")
a=0
watcher=multi:newWatcher(_G,"a") -- watch a in the global enviroment
watcher:OnValueChanged(function(self,old,new)
	print(old,new)
end)
tloop=multi:newTLoop(function(self)
	a=a+1
end,1)
multi:mainloop()
```
# Output
0	1</br>
1	2</br>
2	3</br>
...</br>
.inf-1	inf</br>

Timeout management
```lua
-- Note: I used a tloop so I could control the output of the program a bit.
require("multi.tloop")
a=0
inc=1 -- change to 0 to see it not met at all, 1 if you want to see the first condition not met but the second and 2 if you want to see it meet the condition on the first go.
loop=multi:newTLoop(function(self)
	print("Looping...")
	a=a+inc
	if a==14 then
		self:ResolveTimer("1","2","3") -- ... any number of arguments can be passed to the resolve handler
		-- this will also automatically pause the object that it is binded to
	end
end,.1)
loop:SetTime(1)
loop:OnTimerResolved(function(self,a,b,c) -- the handler will return the self and the passed arguments
	print("We did it!",a,b,c)
end)
loop:OnTimedOut(function(self)
	if not TheSecondTry then
		print("Loop timed out!",self.Type,"Trying again...")
		self:ResetTime(2)
		self:Resume()
		TheSecondTry=true
	else
		print("We just couldn't do it!") -- print if we don't get anything working
	end
end)
multi:mainloop()
```
# Output (Change the value inc as indicated in the comment to see the outcomes!)
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Loop timed out!	tloop	Trying again...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
Looping...</br>
We did it!	1	2	3</br>

# Changes
Updated from 1.7.1 to 1.7.2</br>
Moved updaters, loops, and alarms into the init.lua file. I consider them core features and they are referenced in the init.lua file so they need to exist there. Threaded versions are still separate though. Added another example file

Updated from 1.7.0 to 1.7.1 Bug fixes only

Updated from 1.6.0 to 1.7.0</br>
Modified: multi.intergration.lanesManager.lua
It is now in a stable and simple state Works with the latest lanes version! Tested with version 3.11 I cannot promise that everything will work with eariler versions. Future versions are good though.</br>
Example Usage:</br>
sThread is a handle to a global interface for threads to interact with themself</br>
thread is the interfact for multithreads as seen in the threading section</br>

GLOBAL a table that can be used throughout each and every thread

sThreads have a few methods</br>
sThread.set(name,val) -- you can use the GLOBAL table instead modifies the same table anyway</br>
sThread.get(name) -- you can use the GLOBAL table instead modifies the same table anyway</br>
sThread.waitFor(name) -- waits until a value exists, if it does it returns it</br>
sThread.getCores() -- returns the number of cores on your cpu</br>
sThread.sleep(n) -- sleeps for a bit stopping the entire thread from running</br>
sThread.hold(n) -- sleeps until a condition is met</br>
```lua
local GLOBAL,sThread=require("multi.intergration.lanesManager").init()
require("multi.alarm")
require("multi.threading")
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
	require("multi.all") -- now you can do all of your coding with the multi library! You could even spawn more threads from here with the intergration. You would need to require the interaction again though
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

Updated from 1.5.0 to 1.6.0</br>
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
step:OnStep(function(self,pos) -- same goes for tsteps as well
	print(pos)
end)
multi:newLoop(function(self,dt)
	print(dt)
end)
```
Reasoning I wanted to keep objects consistant, but a lot of my older libraries use the old way of doing things. Therefore I added a backwards module
```lua
require("multi.all")
require("multi.compat.backwards[1,5,0]") -- allows for the use of features that were scrapped/changed in 1.6.0+
```
Updated from 1.4.1 to 1.5.0
Added:
- An easy way to manage timeouts
- Small bug fixes

1.4.1 - First Public release of the library

IMPORTANT:</br>
Every update I make aims to make things simpler more efficent and just better, but a lot of old code, which can be really big, uses a lot of older features. I know the pain of having to rewrite everything. My promise to my library users is that I will always have backwards support for older features! New ways may exist that are quicker and eaiser, but the old features/methods will be supported.</br>
# TODO (In order of importance)
- Finish the wiki stuff. (10% done)</br>
- Test for unknown bugs</br>
