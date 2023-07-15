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
require("love.timer")
require("love.system")
require("love.data")
require("love.thread")
local serpent = require("multi.integration.loveManager.serpent")
local multi, thread = require("multi"):init()

local function ltype(data)
    local tp = type(data)
    if tp == "userdata" then
        return data:type()
    end
    return tp
end

local NIL = love.data.newByteData("\3")

-- If a non table/function is supplied we just return it
local function packValue(t)
    local tp = type(t)
    if tp == "table" then
        return love.data.newByteData("\1"..serpent.dump(t,{safe = true}))
    elseif tp == "function" then
        return love.data.newByteData("\2"..serpent.dump({t,true},{safe = true}))
    else
        return t
    end
end

-- If a non table/function is supplied we just return it
local function unpackValue(d)
    if ltype(d) == "ByteData" then
        local data = d:getString()
        if data:sub(1, 1) == "\1" then
            local status, data = serpent.load(data:sub(2,-1),{safe = false})
            if not status then
                multi.error(data)
            end
            return data
        elseif data:sub(1, 1) =="\2" then
            local status, data = serpent.load(data:sub(2,-1),{safe = false})
            if not status then
                multi.error(data)
            end
            return data[1]
        else
            return d
        end
    else
        return d
    end
end

local function createTable(n)
    if not n then
        n = "STAB"..multi.randomString(8)
    end
    local __proxy = {}
    local function set(name, val)
        local chan = love.thread.getChannel(n .. name)
        if chan:getCount() == 1 then chan:pop() end
        __proxy[name] = true
        chan:push(packValue(val))
    end
    local function get(name)
        local dat = love.thread.getChannel(n .. name):peek()
        return unpackValue(dat)
    end
    return setmetatable({},
        {
            __index = function(t, k)
                return get(k)
            end,
            __newindex = function(t, k, v)
                set(k,v)
            end
        }
    )
end

function INIT()
    local GLOBAL, THREAD = createTable("__GLOBAL__"), {}
    local status_channel, console_channel = love.thread.getChannel("__status_channel__" .. THREAD_ID), 
                                            love.thread.getChannel("__console_channel__")

    -- Non portable methods, shouldn't be used unless you know what you are doing
    THREAD.packValue = packValue
    THREAD.unpackValue = unpackValue
    THREAD.createTable = createTable

    function THREAD.set(name, val)
        GLOBAL[name] = val
    end

    function THREAD.get(name, val)
        return GLOBAL[name]
    end

    THREAD.waitFor = thread:newFunction(function(name)
        local function wait()
            math.randomseed(os.time())
            thread.yield()
        end
        repeat
            wait()
        until GLOBAL[name]
        return GLOBAL[name]
    end, true)

    function THREAD.getCores()
        return love.system.getProcessorCount()
    end

    function THREAD.getConsole()
        local c = {}
        c.queue = console_channel
        function c.print(...)
            c.queue:push(table.concat(multi.pack(...), "\t"))
        end
        function c.error(err)
            c.queue:push("Error in <"..THREAD_NAME..":" .. THREAD_ID .. ">: ".. err)
            multi.error(err)
        end
        return c
    end

    function THREAD.getThreads()
        --
    end

    function THREAD.kill() -- trigger the lane destruction
        error("Thread was killed!\1")
    end

    function THREAD.pushStatus(...)
        status_channel:push(multi.pack(...))
    end

    function THREAD.sleep(n)
        love.timer.sleep(n)
    end

    THREAD.hold = thread:newFunction(function(n)
        thread.hold(n)
    end, true)

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

    return GLOBAL, THREAD
end

return {
    init = function()
        return INIT()
    end
}