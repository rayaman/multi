package.path = "../?/init.lua;../?.lua;"..package.path
local multi, thread = require("multi"):init{print=true}--{priority=true}
local proc = multi:newProcessor("Test",true)
local LANES, LOVE, PSEUDO = 1, 2, 3
local env

if love then
    GLOBAL, THREAD = require("multi.integration.loveManager"):init()
    env = LOVE
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

THREAD.setENV({
    multi_assert = function(expected, actual, s)
        print("Testing")
        if expected ~= actual then
            error(s .. " Expected: '".. expected .."' Actual: '".. actual .."'")
        end
    end
})

multi:newThread("Scheduler Thread",function()
    print("Test 1: Thread Spawning, THREAD namaspace in threads, global's working, and queues for passing data.")
    
    queue = multi:newSystemThreadedQueue("Test_Queue"):init()
    
    th1 = multi:newSystemThread("Test_Thread_2", function(a,b,c,d,e,f)
        queue = THREAD.waitFor("Test_Queue"):init()
        print("!")
        multi_assert("Test_Thread_1", THREAD.getName(), "Thread name does not match!")
        print("!")
        multi_assert("Passing some args", a, "First argument is not as expected 'Passing some args'")
        multi_assert(true, e, "Argument e is not true!")
        multi_assert("table", type(f), "Argument f is not a table!")
        queue:push("done")
    end,"Passing some args", 1, 2, 3, true, {"Table"}).OnError(print)

    if thread.hold(function()
        return queue:pop() == "done"
    end,{sleep=1}) == nil then
        thread.kill()
    end

    print("Test 1: Ok")

    print("Test 2: Threaded Functions, arg passing, return passing, holding.")

    func = THREAD:newFunction(function(a,b,c)
        assert(a == 3, "First argument expected '3' got '".. a .."'!")
        assert(b == 2, "Second argument expected '2' got '".. a .."'!")
        assert(c == 1, "Third argument expected '1' got '".. a .."'!")
        return 1, 2, 3, {"a table"}
    end, true) -- Hold this

    a, b, c, d = func(3,2,1)

    print("Returns passed from function", a, b, c, d)

    if not a then print(b) end

    assert(a == 1, "First return was not '1'!")
    assert(b == 2, "Second return was not '2'!")
    assert(c == 3, "Third return was not '3'!")
    assert(d[1] == "a table", "Fourth return is not table, or doesn't contain 'a table'!")

    print("Test 2: Ok")

    print("Test 3: SystemThreadedTables")

    os.exit()
end).OnError(function(self, err)
    print(err)
    os.exit()
end)



multi:mainloop()