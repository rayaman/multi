--[[
MIT License

Copyright (c) 2022 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local function getOS()
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	else
		return "unix"
	end
end

local function INIT(__GlobalLinda, __SleepingLinda, __StatusLinda, __Console)
    local THREAD = {}
    THREAD.Priority_Core = 3
    THREAD.Priority_High = 2
    THREAD.Priority_Above_Normal = 1
    THREAD.Priority_Normal = 0
    THREAD.Priority_Below_Normal = -1
    THREAD.Priority_Low = -2
    THREAD.Priority_Idle = -3

    function THREAD.set(name, val)
        __GlobalLinda:set(name, val)
    end

    function THREAD.get(name)
        return __GlobalLinda:get(name)
    end

    function THREAD.waitFor(name)
        local multi, thread = require("multi"):init()
        return multi.hold(function()
            math.randomseed(os.time())
            __SleepingLinda:receive(.001, "__non_existing_variable")
            return __GlobalLinda:get(name)
        end)
    end

    function THREAD.getCores()
        return THREAD.__CORES
    end

    function THREAD.getConsole()
        local c = {}
        c.queue = __Console
        function c.print(...)
            c.queue:push("Q", table.concat(multi.pack(...), "\t"))
        end
        function c.error(err)
            c.queue:push("Q", "Error in <"..THREAD_NAME..":" .. THREAD_ID .. ">: ".. err)
            multi.error(err)
        end
        return c
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
        error("Thread was killed!\1")
    end

    function THREAD.sync()
        -- Maybe do something...
    end
	
    function THREAD.pushStatus(...)
        local args = multi.pack(...)
        __StatusLinda:send(nil,THREAD_ID, args)
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
			__GlobalLinda:set(k, v)
		end
	})

    function THREAD.setENV(env, name)
        GLOBAL[name or "__env"] = env
    end

    function THREAD.getENV(name)
        return GLOBAL[name or "__env"]
    end

    function THREAD.exposeENV(name)
        name = name or "__env"
        local env = THREAD.getENV(name)
        for i,v in pairs(env) do
            _G[i] = v
        end
    end

    function THREAD.defer(func)
        table.insert(_DEFER, func)
    end

    return GLOBAL, THREAD
end

return {init = function(g,s,st,c,onexit)
    return INIT(g,s,st,c,onexit)
end}