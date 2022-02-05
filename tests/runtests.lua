if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    package.path="multi/?.lua;multi/?/init.lua;multi/?.lua;multi/?/?/init.lua;"..package.path
    require("lldebugger").start()
else
    package.path="./?.lua;../?/init.lua;../?.lua;../?/?/init.lua;"..package.path
end
--[[
    This file runs all tests.
    Format:
        Expected:
            ...
            ...
            ...
        Actual:
            ...
            ...
            ...
    
    Each test that is ran should have a 5 second pause after the test is complete
    The expected and actual should "match" (Might be impossible when playing with threads)
    This will be pushed directly to the master as tests start existing.
]]
local multi, thread = require("multi"):init{priority=true}
local good = false
local proc = multi:newProcessor("Test")
proc:newAlarm(3):OnRing(function()
	good = true
end)

runTest = thread:newFunction(function()
    local alarms,tsteps,steps,loops,tloops,updaters,events=false,0,0,0,0,0,false
    print("Testing Basic Features. If this fails most other features will probably not work!")
    proc:newAlarm(2):OnRing(function(a)
        alarms = true
        a:Destroy()
    end)
    proc:newTStep(1,10,1,.1):OnStep(function(t)
        tsteps = tsteps + 1
    end).OnEnd(function(step)
        step:Destroy()
    end)
    proc:newStep(1,10):OnStep(function(s)
        steps = steps + 1
    end).OnEnd(function(step)
        step:Destroy()
    end)
    local loop = proc:newLoop(function(l)
        loops = loops + 1
    end)
    proc:newTLoop(function(t)
        tloops = tloops + 1
    end,.1)
    local updater = proc:newUpdater(1):OnUpdate(function()
        updaters = updaters + 1
    end)
    local event = proc:newEvent(function()
        return alarms
    end)
    event.OnEvent(function(evnt)
		evnt:Destroy()
        events = true
        print("Alarms: Ok")
        print("Events: Ok")
        if tsteps == 10 then print("TSteps: Ok") else print("TSteps: Bad!") end
        if steps == 10 then print("Steps: Ok") else print("Steps: Bad!") end
        if loops > 100 then print("Loops: Ok") else print("Loops: Bad!") end
        if tloops > 10 then print("TLoops: Ok") else print("TLoops: Bad!") end
        if updaters > 100 then print("Updaters: Ok") else print("Updaters: Bad!") end
    end)
	thread.hold(event.OnEvent)
    print("Starting Connection and Thread tests!")
	func = thread:newFunction(function(count)
		print("Starting Status test: ",count)
		local a = 0
		while true do
			a = a + 1
			thread.sleep(.1)
			thread.pushStatus(a,count)
			if a == count then break end
		end
		return "Done"
	end)
    local ret = func(10)
    local ret2 = func(15)
    local ret3 = func(20)
	local s1,s2,s3 = 0,0,0
	ret.OnError(function(...)
		print("Error:",...)
	end)
    ret.OnStatus(function(part,whole)
		s1 = math.ceil((part/whole)*1000)/10
    end)
    ret2.OnStatus(function(part,whole)
        s2 = math.ceil((part/whole)*1000)/10
    end)
    ret3.OnStatus(function(part,whole)
        s3 = math.ceil((part/whole)*1000)/10
    end)
	ret.OnReturn(function()
		print("Done")
	end)
	local err, timeout = thread.hold(ret.OnReturn + ret2.OnReturn + ret3.OnReturn)
	if s1 == 100 and s2 == 100 and s3 == 100 then
		print("Threads: Ok")
	else
		print("Threads OnStatus or thread.hold(conn) Error!")
	end
	if timeout then
		print("Threads or Connection Error!")
	else
		print("Connection Test 1: Ok")
	end
	conn1 = proc:newConnection()
	conn2 = proc:newConnection()
	conn3 = proc:newConnection()
	local c1,c2,c3,c4 = false,false,false,false
	local a = conn1(function()
		c1 = true
	end)
	local b = conn2(function()
		c2 = true
	end)
	local c = conn3(function()
		c3 = true
	end)
	local d = conn3(function()
		c4 = true
	end)
	conn1:Fire()
	conn2:Fire()
	conn3:Fire()
	if c1 and c2 and c3 and c4 then
		print("Connection Test 2: Ok")
	else
		print("Connection Test 2: Error")
	end
	c3 = false
	c4 = false
	d:Destroy()
	conn3:Fire()
	if c3 and not(c4) then
		print("Connection Test 3: Ok")
	else
		print("Connection Test 3: Error removing connection")
	end
	os.exit() -- End of tests
end)
runTest().OnError(function(...)
	print("Error:",...)
end)
while true do
	proc.run()
end