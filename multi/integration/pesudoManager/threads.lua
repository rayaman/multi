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

local function INIT(thread)
	print("T",thread.sleep)
    local THREAD = {}
    local GLOBAL = {}
    THREAD.Priority_Core = 3
    THREAD.Priority_High = 2
    THREAD.Priority_Above_Normal = 1
    THREAD.Priority_Normal = 0
    THREAD.Priority_Below_Normal = -1
    THREAD.Priority_Low = -2
    THREAD.Priority_Idle = -3

    function THREAD.set(name, val)
        GLOBAL[name] = val
    end

    function THREAD.get(name)
        return GLOBAL[name]
    end

    function THREAD.waitFor(name)
        return thread.hold(function() return GLOBAL[name] end)
    end

    if getOS() == "windows" then
        THREAD.__CORES = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
    else
        THREAD.__CORES = tonumber(io.popen("nproc --all"):read("*n"))
    end

    function THREAD.getCores()
        return THREAD.__CORES
    end

    function THREAD.getConsole()
        local c = {}
        function c.print(...)
            print(...)
        end
        function c.error(err)
            error("ERROR in <"..GLOBAL["$__THREADNAME__"]..">: "..err)
        end
        return c
    end

    function THREAD.getThreads()
        return {}--GLOBAL.__THREADS__
    end

    THREAD.pushStatus = thread.pushStatus

    if os.getOS() == "windows" then
        THREAD.__CORES = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
    else
        THREAD.__CORES = tonumber(io.popen("nproc --all"):read("*n"))
    end

    function THREAD.kill()
        error("Thread was killed!")
    end

    function THREAD.getName()
        return GLOBAL["$THREAD_NAME"]
    end

    function THREAD.getID()
        return GLOBAL["$THREAD_ID"]
    end

    THREAD.sleep = thread.sleep

    THREAD.hold = thread.hold

    return GLOBAL, THREAD
end

return {init = function(thread)
    return INIT(thread)
end}