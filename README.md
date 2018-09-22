# multi Version: 12.2.2 Some more bug fixes

My multitasking library for lua. It is a pure lua binding, if you ignore the integrations and the love2d compat. If you find any bugs or have any issues, please let me know . **If you don't see a table of contents try using the ReadMe.html file. It is easier to navigate than readme**</br>

[TOC]

INSTALLING
----------
Note: The latest version of Lua lanes is required if you want to make use of system threads on lua 5.1+. I will update the dependencies for Lua rocks since this library should work fine on lua 5.1+ You also need the lua-net library and the bin library. all installed automatically using luarocks. however you can do this manually if lanes and luasocket are installed. Links:
https://github.com/rayaman/bin
https://github.com/rayaman/multi
https://github.com/rayaman/net

To install copy the multi folder into your environment and you are good to go</br>
If you want to use the system threads, then you'll need to install lanes!
**or** use luarocks

```
luarocks install multi
```
Note: Soon you may be able to run multitasking code on multiple machines, network parallelism. This however will have to wait until I hammer out some bugs within the core of system threading itself.

See the rambling section to get an idea of how this will work.

Discord
-------
For real-time assistance with my libraries! A place where you can ask questions and get help with any of my libraries. Also, you can request features and stuff there as well.</br>
https://discord.gg/U8UspuA</br>

Planned features/TODO
---------------------
- [ ] Make practical examples that show how you can solve real problems
- [ ] Finish the wiki stuff. (11% done) -- It's been at 11% for so long. I really need to get on this!
- [ ] Test for unknown bugs -- This is always going on
- [x] ~~Network Parallelism~~ This was fun, I have some more plans for this as well

Known Bugs/Issues
-----------------
~~A bug concerns the SystemThreadedJobQueue, only 1 can be used for now. Might change in a future update~~ :D Fixed

Usage:</br>
-----
```lua
-- Basic usage Alarms: Have been moved to the core of the library require("multi") would work as well
require("multi") -- gets the entire library
alarm=multi:newAlarm(3) -- in seconds can go to .001 uses the built in os.clock()
alarm:OnRing(function(a)
  print("3 Seconds have passed!")
  a:Reset(n) -- if n were nil it will reset back to 3, or it would reset to n seconds
end)
multi:mainloop() -- the main loop of the program, multi:umanager() exists as well to allow integration in other loops Ex: love2d love.update function. More on this binding in the wiki!
```
The library is modular, so you only need to require what you need to. Because of this, the global environment is altered</br>

There are many useful objects that you can use</br>
Check out the wiki for detailed usage, but here are the objects:</br>
- Process#</br>
- Queue#</br>
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
- Trigger</br>
- Task</br>
- Job</br>
- Function</br>
- Watcher</br>
Note: *Both a process and queue act like the multi namespace but allows for some cool things. Because they use the other objects an example on them will be done last*</br>
*Uses the built in coroutine features of lua, these have an interesting interaction with the other means of multi-tasking</br>
Triggers are kind of useless after the creation of the Connection</br>
Watchers have no real purpose as well I made it just because.</br>

# Examples of each object being used</br>
We already showed alarms in action so let’s move on to a Loop object

Throughout these examples I am going to do some strange things to show other features of the library!

LOOPS
-----
```lua
-- Loops: Have been moved to the core of the library require("multi") would work as well
require("multi") -- gets the entire library
count=0
loop=multi:newLoop(function(self,dt) -- dt is delta time and self are a reference to itself
  count=count+1
  if count > 10 then
    self:Break() -- All methods on the multi objects are upper camel case, whereas methods on the multi or process/queuer namespace are lower camel case
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

This library aims to be Async like. Everything is still on one thread *unless you are using the lanes integration module WIP* (A stable WIP, more on that later)

EVENTS
------
```lua
-- Events, these were the first objects introduced into the library. I seldomly use them in their pure form though, but later you'll see their advance uses!
-- Events on their own don't really do much... We are going to need 2 objects at least to get something going
require("multi") -- gets the entire library
count=0
-- let’s use the loop again to add to count!
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

STEPS
-----
```lua
require("multi")
-- Steps, are like for loops but non-blocking... You can run a loop to infinity and everything will still run I will combine Steps with Ranges in this example.
step1=multi:newStep(1,10,1,0) -- Some explaining is due. Argument 1 is the Start # Argument 2 is the ResetAt # (inclusive) Argument 3 is the count # (in our case we are counting by +1, this can be -1 but you need to adjust your start and resetAt numbers)
-- The 4th Argument is for skipping. This is useful for timing and for basic priority management. A priority management system is included!
step2=multi:newStep(10,1,-1,1) -- a second step, notice the slight changes!
step1:OnStart(function(self)
  print("Step Started!")
end)
step1:OnStep(function(self,pos)
  if pos<=10 then -- The step only goes to 10
    print("Stepping... "..pos)
   else
    print("How did I get here?")
   end
end)
step1:OnEnd(function(self)
  print("Done!")
  -- We finished here, but I feel like we could have reused this step in some way... I could use Reset() , but what if I wanted to change it...
  if self.endAt==10 then -- lets only loop once
	self:Update(1,11,1,0) -- oh now we can reach that else condition!
  end
  -- Note Update() will restart the step!
end)

-- step2 is bored let’s give it some love :P
step2.range=step2:newRange() -- Set up a range object to have a nested step in a sense! Each nest requires a new range
-- it is in your interest not to share ranges between objects! You can however do it if it suits your needs though
step2:OnStep(function(self,pos)
  -- for 1=1,math.huge do
    --  print("I am holding the code up because I can!")
  --end
  -- We don’t want to hold things up, but we want to nest.
  -- Note a range is not necessary if the nested for loop has a small range, if however, the range is rather large you may want to allow other objects to do some work
  for i in self.range(1,100) do
    print(pos,i) -- Now our nested for loop is using a range object which allows for other objects to get some CPU time while this one is running
  end
end)
-- TSteps are just like alarms and steps mixed together, the only difference in construction is the 4th Argument. On a TStep that argument controls time. The default is 1
-- The Reset(n) works just like you would figure!
step3=multi:newTStep(1,10,.5,2) -- lets go from 1 to 10 counting by .5 every 2 seconds
step3:OnStep(function(self,pos)
  print("Ok "..pos.."!")
end)
multi:mainloop()
```
# Output

Note: the output on this one is huge!!! So, I had to ... some parts! You need to run this for yourself to see what is going on!</br>
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

TLOOPS
------
```lua
require("multi")
-- TLoops are loops that run ever n second. We will also look at condition objects as well
-- Here we are going to modify the old loop to be a little different
count=0
loop=multi:newTLoop(function(self) -- We are only going to count with this loop but doing so using a condition!
  while self:condition(self.cond) do
    count=count+1
  end
  print("Count is "..count.."!")
  self:Destroy() -- Lets destroy this object, casting it to the dark abyss MUHAHAHA!!!
  -- the reference to this object will be a phantom object that does nothing!
end,1) -- Notice the ',1' after the function! This is where you put your time value!
loop.cond=multi:newCondition(function() return count<=100 end) -- conditions need a bit of work before I am happy with them
multi:mainloop()
```
# Output
Count is 101!

Connections
-----------
These are my favorite objects and you'll see why. They are very useful objects for ASync connections!

```lua
require("multi")
-- Let’s create the events
yawn={} -- ill just leave that there
OnCustomSafeEvent=multi:newConnection(true) -- lets pcall the calls in case something goes wrong default
OnCustomEvent=multi:newConnection(false) -- let’s not pcall the calls and let errors happen... We are good at coding though so let’s get a speed advantage by not pcalling. Pcalling is useful for plugins and stuff that may have been coded badly and you can ignore those connections if need be.
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

-- no need for connect, but I kept that function because of backwards compatibility.
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
# Output
1	2	Hello!!!</br>
CSE1	1	100	Bye!</br>
CSE2	1	100	Hello!</br>
CSE1	1	100	Hi Ya Folks!!!</br>
CSE2	1	100	Hi Ya Folks!!!</br>
CSE3	1	100	Hi Ya Folks!!!</br>
CSE2	1	100	Hi Ya Folks!!!</br>
CSE3	1	100	Hi Ya Folks!!!</br>
</br>

You may think timers should be bundled with alarms, but they are a bit different and have cool features</br>
TIMERS
------
```lua
-- You see the thing is that all time-based objects use timers e.g. Alarms, TSteps, and Loops. Timers are more low level!
require("multi")
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end -- we will use this later!

timer=multi:newTimer()
timer:Start()
-- let’s do a mock alarm
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
Note: This will make more sense when you run it for yourself</br>
3 second(s) have passed!</br>
3.001</br>
3.001</br>
4.002</br>
4.002</br>
4.002</br>
5.003</br>

UPDATER
-------
```lua
-- Updaters: Have been moved to the core of the library require("multi") would work as well
require("multi")
updater=multi:newUpdater(5) -- simple, think of a look with the skip feature of a step
updater:OnUpdate(function(self)
  --print("updating...")
end)
-- Here every 5 steps the updater will do stuff!
-- But I feel it is now time to touch into priority management, so let’s get into basic priority stuff and get into a more advance version of it
--[[
multi.Priority_Core -- Highest form of priority
multi.Priority_High
multi.Priority_Above_Normal
multi.Priority_Normal -- The default form of priority
multi.Priority_Below_Normal
multi.Priority_Low
multi.Priority_Idle -- Lowest form of priority

Note: These only take effect when you enable priority, otherwise everything is at a core like level!
We aren't going to use regular objects to test priority, but rather benchmarks!
to set priority on an object though you would do
multiobj:setPriority(one of the above)
]]
-- let’s bench for 3 seconds using the 3 forms of priority! First no Priority
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
	-- Finally, the 3rd form
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
Note: These numbers will vary drastically depending on your compiler and CPU power</br>
Regular Bench:  2094137 Steps in 3 second(s)!</br>
P1</br>
Below_Normal: 236022 Steps in 3 second(s)!</br>
Normal: 314697 Steps in 3 second(s)!</br>
Above_Normal: 393372 Steps in 3 second(s)!</br>
High: 472047 Steps in 3 second(s)!</br>
Core: 550722 Steps in 3 second(s)!</br>
Low: 157348 Steps in 3 second(s)!</br>
Idle: 78674 Steps in 3 second(s)!</br>
P2</br>
Core: 994664 Steps in 3 second(s)!</br>
High: 248666 Steps in 3 second(s)!</br>
Above_Normal: 62166 Steps in 3 second(s)!</br>
Normal: 15541 Steps in 3 second(s)!</br>
Below_Normal: 3885 Steps in 3 second(s)!</br>
Idle: 242 Steps in 3 second(s)!</br>
Low: 971 Steps in 3 second(s)!</br>

Notice: Even though I started each bench at the same time the order that they finished differed the order is likely to vary on your machine as well!</br>

Processes
---------
A process allows you to group the Actor objects within a controllable interface
```lua
require("multi")
proc=multi:newProcess() -- takes an optional file as an argument, but for this example we aren't going to use that
-- a process works just like the multi object!
b=0
loop=proc:newTLoop(function(self)
	a=a+1
	proc:Pause() -- pauses the CPU cycler for this processor! Individual objects are not paused, however because they aren't getting CPU time they act as if they were paused
end,.1)
updater=proc:newUpdater(multi.Priority_Idle) -- priority can be used in skip arguments as well to manage priority without enabling it!
updater:OnUpdate(function(self)
	b=b+1
end)
a=0 -- a counter
loop2=proc:newLoop(function(self,dt)
	print("Let’s Go!")
	self:hold(3) -- this will keep this object from doing anything! Note: You can only have one hold active at a time! Multiple are possible, but results may not be as they seem see * for how hold works
	-- Within a process using hold will keep it alive until the hold is satisfied!
	print("Done being held for 1 second")
	self:hold(function() return a>10 end)
	print("A is now: "..a.." b is also: "..b)
	self:Destroy()
	self.Parent:Pause() -- let’s say you don't have the reference to the process!
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
Let’s Go!</br>
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
		while timer:Get()<task do -- This while loop is what makes using multiple holds tricky... If the outer while is good before the nested one then the outer one will have to wait! There is a way around this though!
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

Queuer (WIP)
------------
A queuer works just like a process however objects are processed in order that they were created...
```lua
require("multi")
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

Threads
-------
These fix the hold problem that you get with regular objects, and they work the same! They even have some extra features that make them really useful.</br>
```lua
require("multi")
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
Threadable Actors
-----------------
- Alarms
- Events
- Loop/TLoop
- Process
- Step/TStep

Functions
---------
If you ever wanted to pause a function then great now you can
The use of the Function object allows one to have a method that can run free in a sense
```lua
require("multi")
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

ThreadedUpdater
---------------

```lua
-- Works the same as a regular updater!
require("multi")
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

Triggers
--------
Triggers were what I used before connections became a thing, also Function objects are a lot like triggers and can be paused as well, while triggers cannot...</br>
They are simple to use, but in most cases you are better off using a connection</br>
```lua
require("multi")
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

Tasks
-----
Tasks allow you to run a block of code before the multi mainloop does it thing. Tasks still have a use but depending on how you program they aren't needed.</br>
```lua
require("multi")
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

Jobs
----
Jobs were a strange feature that was created for throttling connections! When I was building an IRC bot around this library I couldn't have messages posting too fast due to restrictions. Jobs allowed functions to be added to a queue that were executed after a certain amount of time has passed
```lua
require("multi") -- jobs use alarms I am pondering if alarms should be added to the core or if jobs should use timers instead...
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

Watchers
--------
Watchers allow you to monitor a variable and trigger an event when the variable has changed!
```lua
require("multi")
a=0
watcher=multi:newWatcher(_G,"a") -- watch a in the global environment
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
------------------
```lua
-- Note: I used a tloop, so I could control the output of the program a bit.
require("multi")
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

Rambling
--------
5/23/18:
When it comes to running code across different systems we run into a problem. It takes time to send objects from one matching to another. In the beginning only, local networks will be supported. I may add support to send commands to another network to do computing. Like having your own lua cloud. userdata will never be allowed to run on other machines. It is not possible unless the library you are using allows userdata to be turned into a string and back into an object. With this feature you want to send a command that will take time or needs tons of them done millions+, reason being networks are not that "fast" and only simple objects can be sent. If you mirror your environment then you can do some cool things.

The planned structure will be something like this:
multi-Single Threaded Multitasking
multi-Threads
multi-System Threads
multi-Network threads

where netThreads can contain systemThreads which can intern contain both Threads and single threaded multitasking

Nothing has been built yet, but the system will work something like this:
#host:
```lua
sGLOBAL, nGlobal,sThread=require("multi.integration.networkManager").init() -- This will determine if one is using lanes,love2d, or luvit
multi:Host("MainSystem") -- tell the network that this is the main system. Uses broadcast so that nodes know how to find the host!
nThread = multi:newNetworkThread("NetThread_1",function(...)
	-- basic usage
    nGLOBAL["RemoteVaraible"] = true -- will sync data to all nodes and the host
    sGLOBAL["LocalMachineVaraible"] = true -- will sync data to all system threads on the local machine
    return "Hello Network!" -- send "Hello Network" back to the host node
end)
multi:mainloop()
```
#node
```lua
GLOBAL,sThread=require("multi.integration.networkManager").init() -- This will determine if one is using lanes,love2d, or luvit
node = multi:newNode("NodeName","MainSystem") -- Search the network for the host, connect to it and be ready for requests!
-- On the main thread, a simple multi:newNetworkThread thread and non-system threads, you can access global data without an issue. When dealing with system threads is when you have a problem.
node:setLog{
	maxLines = 10000,
    cleanOnInterval = true,
    cleanInterval = "day", -- every day Supports(day, week, month, year)
    noLog = false -- default is false, make true if you do not need a log
}
node:settings{
	maxJobs = 100, -- Job queues will respect this as well as the host when it is figuring out which node is under the least load. Default: 0 or infinite
    sendLoadInterval = 60 -- every 60 seconds update the host of the nodes load
    sendLoad = true -- default is true, tells the server how stressed the system is
}
multi:mainloop()
-- Note: the node will contain a log of all the commands that it gets. A file called "NodeName.log" will contain the info. You can set the limit by lines or file size. Also, you can set it to clear the log every interval of time if an error does not exist. All errors are both logged and sent to the host as well. You can have more than one host and more than one node(duh :P).
```
The goal of the node is to set up a simple and easy way to run commands on a remote machine.

There are 2 main ways you can use this feature. 1. One node per machine with system threads being able to use the full processing power of the machine. 2. Multiple nodes on one machine where each node is acting like its own thread. And of course, a mix of the two is indeed possible.


Love2d Sleeping reduces the CPU time making my load detection think the system is under more load, thus preventing it from sleeping... I will investigate other means. As of right now it will not eat all your CPU if threads are active. For now, I suggest killing threads that aren't needed anymore. On lanes threads at idle use 0% CPU and it is amazing. A state machine may solve what I need though. One state being idle state that sleeps and only goes into the active state if a job request or data is sent to it... after some time of not being under load it will switch back into the idle state... We'll see what happens.

Love2d doesn't like to send functions through channels. By default, it does not support this. I achieve this by dumping the function and loadstring it on the thread. This however is slow. For the System Threaded Job Queue, I had to change my original idea of sending functions as jobs. The current way you do it now is register a job functions once and then call that job across the thread through a queue. Each worker thread pops from the queue and returns the job. The Job ID is automatically updated and allows you to keep track of the order that the data comes in. A table with # indexes can be used to organize the data...

Regarding benchmarking. If you see my bench marks and are wondering they are 10x better it’s because I am using luajit for my tests. I highly recommend using luajit for my library, but lua 5.1 will work just as well, but not as fast.

So, while working on the jobQueue:doToAll() method I figured out why love2d's threaded tables were acting up when more than 1 thread was sharing the table. It turns out 1 thread was eating all the pops from the queue and starved all the other queues... I’ll need to use the same trick I did with GLOBAL to fix the problem... However, at the rate I am going threading in love will become way slower. I might use the regular GLOBAL to manage data internally for threadedtables...

I have been using this (EventManager --> MultiManager --> now multi) for my own purposes and started making this when I first started learning lua. You can see how the code changed and evolved throughout the years. I tried to include all the versions that still existed on my HDD.

I added my old versions to this library... It started out as the EventManager and was kind of crappy, but it was the start to this library. It kept getting better and better until it became what it is today. There are some features that no longer exist in the latest version, but they were remove because they were useless... I added these files to the GitHub so for those interested can see into my mind in a sense and see how I developed the library before I used GitHub.

The first version of the EventManager was function based not object based and benched at about 2000 steps per second... Yeah that was bad... I used loadstring and it was a mess... Look and see how it grew throughout the years I think it may interest some of you guys!
