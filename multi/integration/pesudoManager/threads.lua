--[[
MIT License

Copyright (c) 2020 Ryan Ward

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
local function INIT()
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
    function THREAD.getCores()
        return THREAD.__CORES
    end
    function THREAD.getConsole()
        local c = {}
        c.print = print
        function c.error(err)
            error("ERROR in <"..__THREADNAME__..">: "..err)
        end
        return c
    end
    function THREAD.getThreads()
        return {} --GLOBAL.__THREADS__
    end
    THREAD.__CORES = thread.__CORES
    function THREAD.getName()
        local t = thread.getRunningThread()
        return t.Name
    end
    function THREAD.getID()
        local t = thread.getRunningThread()
        return t.TID
    end
    _G.THREAD_ID = 0
    THREAD.kill = thread.kill
    THREAD.sleep = thread.sleep
    THREAD.hold = thread.hold
    return GLOBAL, THREAD
end
return {init = function()
    return INIT()
end}