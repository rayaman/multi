function objectTests(multi,thread)
    local alarms,tsteps,steps,loops,tloops,updaters,events=false,0,0,0,0,0,false
    print("Testing Basic Features. If this fails most other features will probably not work!")
    multi:newAlarm(2):OnRing(function(a)
        alarms = true
        a:Destroy()
    end)
    multi:newTStep(1,10,1,.1):OnStep(function(t)
        tsteps = tsteps + 1
    end):OnEnd(function(step)
        step:Destroy()
    end)
    multi:newStep(1,10):OnStep(function(s)
        steps = steps + 1
    end):OnEnd(function(step)
        step:Destroy()
    end)
    local loop = multi:newLoop(function(l)
        loops = loops + 1
    end)
    multi:newTLoop(function(t)
        tloops = tloops + 1
    end,.1)
    local updater = multi:newUpdater(1):OnUpdate(function()
        updaters = updaters + 1
    end)
    local event = multi:newEvent(function()
        return alarms
    end)
    event.OnEvent(function(evnt)
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
end
return objectTests