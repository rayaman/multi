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
local multi, thread = require("multi"):init()

-- Checks if the given value is a LOVE2D object (i.e. has metatable with __index field) and if that __index field contains functions typical of LOVE2D objects
function isLoveObject(value)
    -- Check if the value has metatable
    if type(value) == "userdata" and getmetatable(value) then
        -- Check if the metatable has the __index field
        local index = getmetatable(value).__index
        if type(index) == "table" then
            -- Check if the metatable's __index table contains functions typical of LOVE2D objects
            if index.draw or index.update or index.getWidth or index.getHeight or index.getString or index.getPointer then
                return true
            end
        end
    end
    return false
end

-- Converts any function values in a table to a string with the value "\1\2:func:<function_string>" where <function_string> is the Lua stringified version of the function
function tableToFunctionString(t)
    if type(t) == "nil" then return "\1\2:nil:" end
    if type(t) == "function" then return "\1\2:func:"..string.dump(t) end
    if type(t) ~= "table" then return t end
    local newtable = {}
    for k, v in pairs(t) do
        if type(v) == "function" then
            newtable[k] = "\1\2:func:"..string.dump(v)
        elseif type(v) == "table" then
            newtable[k] = tableToFunctionString(v)
        elseif isLoveObject(v) then
            newtable[k] = v
        elseif type(v) == "userdata" then
            newtable[k] = tostring(v)
        else
            newtable[k] = v
        end
    end
    return newtable
end

-- Converts strings with the value "\1\2:func:<function_string>" back to functions
function functionStringToTable(t)
    if type(t) == "string" and t:sub(1, 8) == "\1\2:func:" then return loadstring(t:sub(9, -1)) end
    if type(t) == "string" and t:sub(1, 7) == "\1\2:nil:" then return nil end
    if type(t) ~= "table" then return t end
    for k, v in pairs(t) do
        if type(v) == "string" then
            if v:sub(1, 8) == "\1\2:func:" then
                t[k] = loadstring(v:sub(9, -1))
            else
                t[k] = v
            end
        elseif type(v) == "table" then
            t[k] = functionStringToTable(v)
        else
            t[k] = v
        end
    end
    if t.init then
        t:init()
    end
    return t
end

local function packValue(t)
    return tableToFunctionString(t)
end

local function unpackValue(t)
    return functionStringToTable(t)
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
        return unpackValue(love.thread.getChannel(n .. name):peek())
        -- if type(data) == "table" and data.init then
        --     return data:init()
        -- else
        --     return data
        -- end
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
    local GLOBAL, THREAD, DEFER = createTable("__GLOBAL__"), {}, {}
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
        until GLOBAL[name] ~= nil
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

    function THREAD.defer(func)
        table.insert(DEFER, func)
    end

    function THREAD.sync()
        -- Maybe do something...
    end

    return GLOBAL, THREAD, DEFER
end

return {
    init = function()
        return INIT()
    end
}