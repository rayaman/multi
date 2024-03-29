package.path = "../?/init.lua;../?.lua;./init.lua;./?.lua;"..package.path

local multi, thread = require("multi"):init{print=true,warn=true,error=true}--{priority=true}
local good = false
local proc = multi:newProcessor("Test")

proc.Start()

proc:newAlarm(3):OnRing(function()
	good = true
end)

runTest = thread:newFunction(function()
    local alarms,tsteps,steps,loops,tloops,updaters,events=false,0,0,0,0,0,false
    multi.print("Testing Basic Features. If this fails most other features will probably not work!")
    proc:newAlarm(2):OnRing(function(a)
        alarms = true
        a:Destroy()
    end)
    proc:newTStep(1,10,1,.1):OnStep(function(t)
        tsteps = tsteps + 1
    end):OnEnd(function(step)
        step:Destroy()
    end)
    proc:newStep(1,10):OnStep(function(s)
        steps = steps + 1
    end):OnEnd(function(step)
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
        multi.success("Alarms: Ok")
        multi.success("Events: Ok")
        if tsteps == 10 then multi.success("TSteps: Ok") else multi.error("TSteps: Bad!") end
        if steps == 10 then multi.success("Steps: Ok") else multi.error("Steps: Bad!") end
        if loops > 100 then multi.success("Loops: Ok") else multi.error("Loops: Bad!") end
        if tloops > 10 then multi.success("TLoops: Ok") else multi.error("TLoops: Bad!") end
        if updaters > 100 then multi.success("Updaters: Ok") else multi.error("Updaters: Bad!") end
    end)
	thread.hold(event.OnEvent)
    multi.print("Starting Connection and Thread tests!")
	func = thread:newFunction(function(count)
		multi.print("Starting Status test: ",count)
		local a = 0
		while true do
			a = a + 1
			thread.sleep(.1)
			thread.pushStatus(a,count)
			if a == count then break end
		end
		return "Done", true, math.random(1,10000)
	end)
    local ret = func(10)
    local ret2 = func(15)
    local ret3 = func(20)
	local s1,s2,s3 = 0,0,0
	ret.OnError(function(...)
		multi.error("Func 1:",...)
	end)
	ret2.OnError(function(...)
		multi.error("Func 2:",...)
	end)
	ret3.OnError(function(...)
		multi.error("Func 3:",...)
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

	ret.OnReturn(function(...)
		multi.success("Done 1",...)
	end)
	ret2.OnReturn(function(...)
		multi.success("Done 2",...)
	end)
	ret3.OnReturn(function(...)
		multi.success("Done 3",...)
	end)
	
	local err, timeout = thread.hold(ret.OnReturn * ret2.OnReturn * ret3.OnReturn)

	if s1 == 100 and s2 == 100 and s3 == 100 then
		multi.success("Threads: All tests Ok")
	else
		if s1>0 and s2>0 and s3 > 0 then
			multi.success("Thread OnStatus: Ok")
		else
			multi.error("Threads OnStatus or thread.hold(conn) Error!")
		end
		if timeout then
			multi.error("Connection Error!")
		else
			multi.success("Connection Test 1: Ok")
		end
		multi.error("Connection holding Error!")
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
		multi.success("Connection Test 2: Ok")
	else
		multi.error("Connection Test 2: Error")
	end
	c3 = false
	c4 = false
	conn3:Unconnect(d)
	conn3:Fire()
	if c3 and not(c4) then
		multi.success("Connection Test 3: Ok")
	else
		multi.error("Connection Test 3: Error removing connection")
	end
	if not love then
		local ec = 0
		multi.print("Testing pseudo threading")
		capture = io.popen("lua tests/threadtests.lua p"):read("*a")
		if capture:lower():match("error") then
			ec = ec + 1
			os.exit(1)
		else
			io.write(capture)
		end
		multi.print("Testing lanes threading")
		capture = io.popen("lua tests/threadtests.lua l"):read("*a")
		if capture:lower():match("error") then
			ec = ec + 1
			os.exit(1)
		else
			io.write(capture)
		end
		os.exit(0)
	end
end)

local handle = runTest()

handle.OnError(function(...)
	multi.error("Something went wrong with the test!")
	print(...)
end)

if not love then
	multi:mainloop()
else
	local hold = thread:newFunction(function()
		thread.hold(handle.OnError + handle.OnReturn)
	end, true)
	hold()
	multi.print("Starting Threading tests!")
end