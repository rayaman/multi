package.path = "../?/init.lua;../?.lua;"..package.path
multi, thread = require("multi"):init{error=true,warning=true,print=true}--{priority=true}
proc = multi:newProcessor("Thread Test",true)
local LANES, LOVE, PSEUDO = 1, 2, 3
local env, we_good

if love then
    GLOBAL, THREAD = require("multi.integration.loveManager"):init()
    env = LOVE
elseif arg[1] == "l" then
    GLOBAL, THREAD = require("multi.integration.lanesManager"):init()
    env = LANES
elseif arg[1] == "p" then
    GLOBAL, THREAD = require("multi.integration.pseudoManager"):init()
    env = PSEUDO
else
    io.write("Test Pseudo(p), Lanes(l), or love(Run in love environment) Threading: ")
    choice = io.read()
    if choice == "p" then
        GLOBAL, THREAD = require("multi.integration.pseudoManager"):init()
        env = PSEUDO
    elseif choice == "l" then
        GLOBAL, THREAD = require("multi.integration.lanesManager"):init()
        env = LANES
    else
        error("Invalid threading choice")
    end
end

multi.print("Testing THREAD.setENV() if the multi_assert is not found then there is a problem")
THREAD.setENV({
    multi_assert = function(expected, actual, s)
        if expected ~= actual then
            multi.error(s .. " Expected: '".. tostring(expected) .."' Actual: '".. tostring(actual) .."'")
        end
    end
})

multi:newThread("Scheduler Thread",function()
    queue = multi:newSystemThreadedQueue("Test_Queue"):init()

    multi:newSystemThread("Test_Thread_0", function()
        print("The name should be Test_Thread_0",THREAD_NAME,THREAD_NAME,_G.THREAD_NAME)
    end)
    
    th1 = multi:newSystemThread("Test_Thread_1", function(a,b,c,d,e,f)
        queue = THREAD.waitFor("Test_Queue"):init()
        multi_assert("Test_Thread_1", THREAD_NAME, "Thread name does not match!")
        multi_assert("Passing some args", a, "First argument is not as expected 'Passing some args'")
        multi_assert(true, e, "Argument e is not true!")
        multi_assert("table", type(f), "Argument f is not a table!")
        queue:push("done")
    end,"Passing some args", 1, 2, 3, true, {"Table"}).OnError(function(self,err)
        multi.error(err)
        os.exit()
    end)

    if thread.hold(function()
        return queue:pop() == "done"
    end,{sleep=1}) == nil then
        thread.kill()
    end

    multi.success("Thread Spawning, THREAD namaspace in threads, global's working, and queues for passing data: Ok")

    func = THREAD:newFunction(function(a,b,c)
        assert(a == 3, "First argument expected '3' got '".. a .."'!")
        assert(b == 2, "Second argument expected '2' got '".. a .."'!")
        assert(c == 1, "Third argument expected '1' got '".. a .."'!")
        return 1, 2, 3, {"a table"}
    end, true) -- Hold this

    a, b, c, d = func(3,2,1)

    assert(a == 1, "First return was not '1'!")
    assert(b == 2, "Second return was not '2'!")
    assert(c == 3, "Third return was not '3'!")
    assert(d[1] == "a table", "Fourth return is not table, or doesn't contain 'a table'!")

    multi.success("Threaded Functions, arg passing, return passing, holding: Ok")

    test=multi:newSystemThreadedTable("YO"):init()
    test["test1"]="tabletest"
    local worked = false

    multi:newSystemThread("testing tables",function()
        tab=THREAD.waitFor("YO"):init()
        THREAD.hold(function() return tab["test1"] end)
        THREAD.sleep(.1)
        tab["test2"] = "Whats so funny?"
    end).OnError(multi.error)

    multi:newThread("test2",function()
        thread.hold(function() return test["test2"] end)
        worked = true
    end)

    t, val = thread.hold(function()
        return worked
    end,{sleep=1})

    if val == multi.TIMEOUT then
        multi.error("SystemThreadedTables: Failed")
        os.exit()
    end

    multi.success("SystemThreadedTables: Ok")

    local ready = false

    jq = multi:newSystemThreadedJobQueue(5) -- Job queue with 4 worker threads
    func = jq:newFunction("test-thread",function(a,b)
        THREAD.sleep(.2)
        return a+b
    end)
    local count = 0
    for i = 1,10 do
        func(i, i*3).OnReturn(function(data)
            count = count + 1
        end)
    end

    t, val = thread.hold(function()
        return count == 10
    end,{sleep=2})

    if val == multi.TIMEOUT then
        multi.error("SystemThreadedJobQueues: Failed")
        os.exit()
    end

    multi.success("SystemThreadedJobQueues: Ok")

    queue2 = multi:newSystemThreadedQueue("Test_Queue2"):init()
    multi:newSystemThread("Test_Thread_2",function()
        queue2 = THREAD.waitFor("Test_Queue2"):init()
        connOut = THREAD.waitFor("ConnectionNAMEHERE"):init()
        connOut(function(arg)
            queue2:push("Test_Thread_2")
        end)
        multi:mainloop()
    end).OnError(multi.error)
    multi:newSystemThread("Test_Thread_3",function()
        queue2 = THREAD.waitFor("Test_Queue2"):init()
        connOut = THREAD.waitFor("ConnectionNAMEHERE"):init()
        connOut(function(arg)
            queue2:push("Test_Thread_3")
        end)
        multi:mainloop()
    end).OnError(multi.error)
    connOut = multi:newSystemThreadedConnection("ConnectionNAMEHERE"):init()
    a=0
    connOut(function(arg)
        queue2:push("Main")
    end)
    for i=1,3 do
        thread.sleep(.1)
        connOut:Fire("Test From Main Thread: "..i.."\n")
    end
    thread.sleep(2)
    local count = 0
    multi:newThread(function()
        while count < 9 do
            if queue2:pop() then
                count = count + 1
            end
        end
    end).OnError(multi.error)
    _, err = thread.hold(function() return count == 9 end,{sleep=.3})
    if err == multi.TIMEOUT then
        multi.error("SystemThreadedConnections: Failed")
    end
    multi.success("SystemThreadedConnections: Ok")

    we_good = true
    os.exit()
end).OnError(multi.error)

multi.OnExit(function(err)
    if not we_good then
        multi.error("There was an error running some tests!")
        os.exit(1)
    else
        multi.success("Tests complete!")
    end
end)

multi:mainloop()