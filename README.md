# multi Version: 1.8.6 (System Threaded Job Queues gets an update!) 

**NOTE: I have been studying a lot about threading in the past few weeks and have some awesome additions in store! They will take a while to come out though. The goal of the library is still to provide a simple and efficient way to multi task in lua**

In Changes you'll find documentation for(In Order):
- System Threaded Job Queues
- New mainloop functions
- System Threaded Tables
- System Threaded Benchmark
- System Threaded Queues
- Threading related features
- And backwards compat stuff

My multitasking library for lua. It is a pure lua binding if you ingore the integrations and the love2d compat. If you find any bugs or have any issues please let me know :). **If you don't see a table of contents try using the ReadMe.html file. It is eaiser to navigate the readme**</br>

[TOC]

INSTALLING
----------
To install copy the multi folder into your enviroment and you are good to go</br>

**or** use luarocks

```
luarocks install multi
```
Discord
-------
For real-time assistance with my libraries! A place where you can ask questions and get help with any of my libraries. Also you can request features and stuff there as well.</br>
https://discord.gg/U8UspuA</br>

Planned features/TODO
---------------------
- [x] ~~Add system threads for love2d that works like the lanesManager (loveManager, slight differences).~~
- [x] ~~Improve performance of the library~~
- [x] ~~Improve coroutine based threading scheduling~~
- [ ] Improve love2d Idle thread cpu usage... Tricky Look at the rambling section for insight.
- [ ] Add more control to coroutine based threading
- [ ] Add more control to system based threading
- [ ] Fix the performance when using system threads in love2d
- [ ] Make practical examples that show how you can solve real problems
- [x] ~~Add more features to support module creators~~
- [x] ~~Make a framework for eaiser thread task distributing~~
- [x] ~~Fix Error handling on threaded multi objects~~ Non threaded multiobjs will crash your program if they error though! Use multi:newThread() of multi:newSystemThread() if your code can error! Unless you use multi:protect() this however lowers performance!
- [x] ~~Add multi:OnError(function(obj,err))~~
- [ ] sThread.wrap(obj) **May or may not be completed** Theory: Allows interaction in one thread to affect it in another. The addition to threaded tables may make this possible!
- [ ] SystemThreaded Actors -- After some tests i figured out a way to make this work... It will work slightly different though. This is due to the actor needing to be splittable...
- [ ] LoadBalancing for system threads (Once SystemThreaded Actors are done)
- [ ] Add more integrations
- [ ] Finish the wiki stuff. (11% done)
- [ ] Test for unknown bugs

Known Bugs/Issues
-----------------
In regards to integrations, thread cancellation works slightly different for love2d and lanes. Within love2d I was unable to (To lazy to...) not use the multi library within the thread. A fix for this is to call `multi:Stop()` when you are done with your threaded code! This may change however if I find a way to work around this. In love2d in order to mimic the GLOBAL table I needed the library to constantly sync tha data... You can use the sThread.waitFor(varname), or sThread.hold(func) methods to sync the globals, to get the value instead of using GLOBAL and this could work. If you want to go this route I suggest setting multi.isRunning=true to prevent the auto runner from doing its thing! This will make the multi manager no longer function, but thats the point :P

Another bug concerns the SystemThreadedJobQueue, Only 1 can be used for now... Creating more may not be a good idea.

And systemThreadedTables only supports 1 table between the main and worker thread! They do not work when shared between 2 or more threads. If you need that much flexiblity ust the GLOBAL table that all threads have.

For module creators using this library. I suggest using SystemThreadedQueues for data transfer instead of SystemThreadedTables for rapid data transfer, If you plan on having Constants that will always be the same then a table is a good idea! They support up to **n** threads and can be messed with and abused as much as you want :D

Love2D SystemThreadedTAbles do not send love2d userdata, use queues instead for that!

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
The library is modular so you only need to require what you need to. Because of this, the global enviroment is altered</br>

There are many useful objects that you can use</br>
Check out the wiki for detailed usage, but here are the objects:</br>
- Process#</br>
- QueueQueuer#</br>
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
Note: *Both a process and queue act like the multi namespace, but allows for some cool things. Because they use the other objects an example on them will be done last*</br>
*Uses the built in coroutine features of lua, these have an interesting interaction with the other means of multi-tasking</br>
Triggers are kind of useless after the creation of the Connection</br>
Watchers have no real purpose as well I made it just because.</br>

# Examples of each object being used</br>
We already showed alarms in action so lets move on to a Loop object

Throughout these examples I am going to do some strange things in order to show other features of the library!

LOOPS
-----
```lua
-- Loops: Have been moved to the core of the library require("multi") would work as well
require("multi") -- gets the entire library
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

This library aims to be Async like. In reality everything is still on one thread *unless you are using the lanes integration module WIP* (More on that later)

EVENTS
------
```lua
-- Events, these were the first objects introduced into the library. I seldomly use them in their pure form though, but later on you'll see their advance uses!
-- Events on there own don't really do much... We are going to need 2 objects at least to get something going
require("multi") -- gets the entire library
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

STEPS
-----
```lua
require("multi")
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

TLOOPS
------
```lua
require("multi")
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

Connections
-----------
These are my favorite objects and you'll see why. They are very useful objects for ASync connections!

```lua
require("multi")
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
CSE2	1	100	Hi Ya Folks!!!</br>
CSE3	1	100	Hi Ya Folks!!!</br>
</br>

You may think timers should be bundled with alarms, but they are a bit different and have cool features</br>
TIMERS
------
```lua
-- You see the thing is that all time based objects use timers eg. Alarms, TSteps, and Loops. Timers are more low level!
require("multi")
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

UPDATER
-------
```lua
-- Updaters: Have been moved to the core of the library require("multi") would work as well
require("multi")
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
A process allows you to group the Actor objects within a controlable interface
```lua
require("multi")
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
These fix the hold problem that you get with regular objects, and they work exactly the same! They even have some extra features that make them really useful.</br>
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
The uses of the Function object allows one to have a method that can run free in a sense
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
Tasks allow you to run a block of code before the multi mainloops does it thing. Tasks still have a use, but depending on how you program they aren't needed.</br>
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
Jobs were a strange feature that was created for throttling connections! When I was building a irc bot around this library I couldn't have messages posting too fast due to restrictions. Jobs allowed functions to be added to a queue that were executed after a certain amount of time has passed
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
------------------
```lua
-- Note: I used a tloop so I could control the output of the program a bit.
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

Changes
-------
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
- Tweaked the loveManager to help improve idle cpu usage
- Minor tweaks to the coroutine scheduling

# Using multi:newSystemThreadedJobQueue()
First you need to create the object
This works the same way as love2d as it does with lanes... It is getting increasing harder to make both work the same way with speed in mind... Anyway...
```lua
-- Creating the object using lanes manager to show case this. Examples has the file for love2d
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
jQueue=multi:newSystemThreadedJobQueue(n) -- this internally creates System threads. By defualt it will use the # of processors on your system You can set this number though.
-- Only create 1 jobqueue! For now making more than 1 is buggy. You only really need one though. Just register new functions if you want 1 queue to do more. The one reason though is keeping track of jobIDs. I have an idea that I will roll out in the next update.
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
jQueue.OnJobCompleted(function(JOBID,n) -- whenever a job is completed you hook to the event that is called. This passes the JOBID folled by the returns of the job
	-- JOBID is the completed job, starts at 1 and counts up by 1.
	-- Threads finish at different times so jobids may be passed out of order! Be sure to have a way to order them
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

Thats it from this version!

Update: 1.8.3
-------------
Added:</br>
**New Mainloop functions** Below you can see the slight differences... Function overhead is not too bad in lua, but has a real difference. multi:mainloop() and multi:unprotectedMainloop() use the same algorithm yet the dedicated unprotected one is slightly faster due to having less function overhead.
- multi:mainloop()\* -- Bench:  16830003 Steps in 3 second(s)!
- multi:protectedMainloop() -- Bench:  16699308 Steps in 3 second(s)!
- multi:unprotectedMainloop() -- Bench:  16976627 Steps in 3 second(s)!
- multi:prioritizedMainloop1() -- Bench:  15007133 Steps in 3 second(s)!
- multi:prioritizedMainloop2() -- Bench:  15526248 Steps in 3 second(s)!

\* The OG mainloop function remains the same and old methods to achieve what we have with the new ones still exist

These new methods help by removing function overhead that is caused through the original mainloop function. The one downside is that you no longer have the flexiblity to change the processing during runtime.

However there is a work around! You can use processes to run multiobjs as well and use the other methods on them.

I may make a full comparison between each method and which is faster, but for now trust that the dedicated ones with less function overhead are infact faster. Not by much but still faster. :D

Update: 1.8.2
-------------
Added:</br>
- multi:newsystemThreadedTable(name) NOTE: Metatables are not supported in transfers. However there is a work around obj:init() that you see does this. Take a look in the multi/integration/shared/shared.lua files to see how I did it!
- Modified the GLOBAL metatable to sync before doing its tests
- multi._VERSION was multi.Version, felt it would be more consistant this way... I left the old way of getting the version just incase someone has used that way. It will eventually be gone. Also multi:getVersion() will do the job just as well and keep your code nice and update related bug free!
- Also everything that is included in the: multi/integration/shared/shared.lua (Which is loaded automatically) works in both lanes and love2d enviroments!

The threaded table is setup just like the threaded queue.</br>
It provids GLOBAL like features without having to write to GLOBAL!</br>
This is useful for module creators who want to keep their data private, but also use GLOBAL like coding.</br>
It has a few features that makes it a bit better than plain ol GLOBAL (For now...)
(ThreadedTable - TT for short)
- TT:waitFor(name)
- TT:sync()
- TT["var"]=value
- print(TT["var"])

we also have the "sync" method, this one was made for love2d because we do a syncing trick to get data in a table format. The lanes side has a sync method as well so no worries. Using indexing calls sync once and may grab your variable. This allows you to have the lanes indexing 'like' syntax when doing regular indexing in love2d side of the module. As of right now both sides work flawlessly! And this effect is now the GLOBAL as well</br>

On GLOBALS sync is a internal method for keeping the GLOBAL table in order. You can still use sThread.waitFor(name) to wait for variables that may of may not yet exist!

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
-- love2d gaming lua! NOTE: this is in main4.lua in the love2d examples
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
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
```

Update: 1.8.1
-------------
No real change!</br>
Changed the structure of the library. Combined the coroutine based threads into the core!</br>
Only compat and integrations are not part of the core and never will be by nature.</br>
This should make the library more convient to use.</br>
I left multi/all.lua file so if anyone had libraries/projects that used that it will still work!</br>
Updated from 1.7.6 to 1.8.0</br> (How much thread could a thread thread if a thread could thread thread?)
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
Quick Note: queues shared across multiple objects will be pulling from the same "queue" keep this in mind when coding! ~~Also the queue respects direction a push on the thread side cannot be popped on the thread side... Same goes for the mainthread!</br>~~ Turns out i was wrong about this...
```lua
-- in love2d, this file will be in the same example folder as before, but is named main2.lua
require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
--IMPORTANT
-- Do not make the above local, this is the one difference that the lanesManager does not have
-- If these are local the functions will have the upvalues put into them that do not exist on the threaded side
-- You will need to ensure that the function does not refer to any upvalues in its code. It will print an error if it does though
-- Also each thread has a .1 second delay! This is used to generate a random values for each thread!
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
The old way still works and is more convient to be honest, but I felt a method to do this was ok.</br>

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
The loveManager integration that mimics the lanesManager integration almost exactly to keep coding in both enviroments as close to possible. This is done mostly for library creation support!</br>
An example of the loveManager in action using almost the same code as the lanesintergreationtest2.lua</br>
NOTE: This code has only been tested to work on love2d version 1.10.2 thoough it should work version 0.9.0
```lua
require("core.Library") -- Didn't add this to a repo yet! Will do eventually... Allows for injections and other cool things
require("multi.compat.love2d") -- allows for multitasking and binds my libraies to the love2d engine that i am using
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
		thread.skip(1) -- allow error handling to take place... Otherwise lets keep the main thread running on the low
		-- Before we held just because we could... But this is a game and we need to have logic continue
		--sThreadM.sleep(.001) -- Sleeping for .001 is a greeat way to keep cpu usage down. Make sure if you aren't doing work to rest. Abuse the hell out of GLOBAL if you need to :P
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
It is now in a stable and simple state Works with the latest lanes version! Tested with version 3.11 I cannot promise that everything will work with eariler versions. Future versions are good though.</br>
Example Usage:</br>
sThread is a handle to a global interface for system threads to interact with themself</br>
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
Update: 1.5.0
-------------
Added:
- An easy way to manage timeouts
- Small bug fixes

Update: 1.4.1 - First Public release of the library
-------------

IMPORTANT:</br>
Every update I make aims to make things simpler more efficent and just better, but a lot of old code, which can be really big, uses a lot of older features. I know the pain of having to rewrite everything. My promise to my library users is that I will always have backwards support for older features! New ways may exist that are quicker and eaiser, but the old features/methods will be supported.</br>
Rambling
--------
Love2d Sleeping reduces the cpu time making my load detection think the system is under more load, thus preventing it from sleeping... I will look into other means. As of right now it will not eat all of your cpu if threads are active. For now I suggest killing threads that aren't needed anymore. On lanes threads at idle use 0% cpu and it is amazing. A state machine may solve what I need though. One state being idle state that sleeps and only goes into the active state if a job request or data is sent to it... after some time of not being under load it wil switch back into the idle state... We'll see what happens.

Love2d doesn't like to send functions through channels. By defualt it does not support this. I achieve this by dumping the function and loadstring it on the thread. This however is slow. For the System Threaded Job Queue I had to change my original idea of sending functions as jobs. The current way you do it now is register a job functions once and then call that job across the thread through a queue. Each worker thread pops from the queue and returns the job. The Job ID is automatically updated and allows you to keep track of the order that the data comes in. A table with # indexes can be used to originze the data...

In regards to benchmarking. If you see my bench marks and are wondering they are 10x better its because I am using luajit for my tests. I highly recommend using luajit for my library, but lua 5.1 will work just as well, but not as fast.

So while working on the jobQueue:doToAll() method I figured out why love2d's threaded tables were acting up when more than 1 thread was sharing the table. It turns out 1 thread was eating all of the pops from the queue and starved all of the other queues... Ill need to use the same trick I did with GLOBAL to fix the problem... However at the rate I am going threading in love will become way slower. I might use the regualr GLOBAL to manage data internally for threadedtables...

It has been awhile since I had to bring out the Multi Functions... Syncing within threads are a pain! I had no idea what a task it would be to get something as simple as syncing data was going to be... I will probably add a SystemThreadedSyncer in the future because it will make life eaiser for you guys as well. SystemThreadedTables are still not going to work on love2d, but will work fine on lanes... I have a solution and it is being worked on... Depending on when I pust the next update to this library the second half of this ramble won't apply anymore

I have been using this (EventManager --> MultiManager --> now multi) for my own purposes and started making this when I first started learning lua. You are able to see how the code changed and evolved throughout the years. I tried to include all the versions that still existed on my HDD.

I added my old versions to this library... It started out as the EventManager and was kinda crappy but it was the start to this library. It kept getting better and better until it became what it is today. There are some features that nolonger exist in the latest version, but they were remove because they were useless... I added these files to the github so for those interested can see into my mind in a sense and see how I developed the library before I used github.

The first version of the EventManager was function based not object based and benched at about 2000 steps per second... Yeah that was bad... I used loadstring and it was a mess... Take a look and see how it grew throughout the years I think it may intrest some of you guys!
