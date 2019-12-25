local function INIT(__GlobalLinda,__SleepingLinda)
    local THREAD = {}
    function THREAD.set(name, val)
        __GlobalLinda:set(name, val)
    end
    function THREAD.get(name)
        __GlobalLinda:get(name)
    end
    function THREAD.waitFor(name)
        local function wait()
            math.randomseed(os.time())
            __SleepingLinda:receive(.001, "__non_existing_variable")
        end
        repeat
            wait()
        until __GlobalLinda:get(name)
        return __GlobalLinda:get(name)
    end
    function THREAD.testFor(name, val, sym)
        --
    end
    function THREAD.getCores()
        return THREAD.__CORES
    end
    function THREAD.getThreads()
        return GLOBAL.__THREADS__
    end
    if os.getOS() == "windows" then
        THREAD.__CORES = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
    else
        THREAD.__CORES = tonumber(io.popen("nproc --all"):read("*n"))
    end
    function THREAD.kill() -- trigger the lane destruction
        error("Thread was killed!")
    end
    function THREAD.getName()
        return THREAD_NAME
    end
    function THREAD.getID()
        return THREAD_ID
    end
    _G.THREAD_ID = 0
    function THREAD.sleep(n)
        math.randomseed(os.time())
        __SleepingLinda:receive(n, "__non_existing_variable")
    end
    function THREAD.hold(n)
        local function wait()
            math.randomseed(os.time())
            __SleepingLinda:receive(.001, "__non_existing_variable")
        end
        repeat
            wait()
        until n()
    end
    local GLOBAL = {}
    setmetatable(GLOBAL, {
		__index = function(t, k)
			return __GlobalLinda:get(k)
		end,
        __newindex = function(t, k, v)
            for i,v in pairs(__GlobalLinda) do
                print(i,v)
            end
			__GlobalLinda:set(k, v)
		end
	})
    return GLOBAL, THREAD
end
return {init = function(g,s)
    return INIT(g,s)
end}