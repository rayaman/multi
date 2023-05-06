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
local threads = {}

function threads.loadDump(d)
    return loadstring(d:getString())
end

function threads.dump(func)
    return love.data.newByteData(string.dump(func))
end

local fRef = {"func",nil}
local function manage(channel, value)
    channel:clear()
    if type(value) == "function" then
        fRef[2] = THREAD.dump(value)
        channel:push(fRef)
        return
    else
        channel:push(value)
    end
end

local GNAME = "__GLOBAL_"
local proxy = {}
function threads.set(name,val)
    if not proxy[name] then proxy[name] = love.thread.getChannel(GNAME..name) end
    proxy[name]:performAtomic(manage, val) 
end

function threads.get(name)
    if not proxy[name] then proxy[name] = love.thread.getChannel(GNAME..name) end
    local dat = proxy[name]:peek()
    if type(dat)=="table" and dat[1]=="func" then
        return THREAD.loadDump(dat[2])
    else
        return dat
    end
end

function threads.waitFor(name)
    if thread.isThread() then
        return thread.hold(function()
            return threads.get(name)
        end)
    end
    while threads.get(name)==nil do
        love.timer.sleep(.001)
    end
    local dat = threads.get(name)
    if type(dat) == "table" and dat.init then
        dat.init = threads.loadDump(dat.init)
    end
    return dat
end

function threads.package(name,val)
    local init = val.init
    val.init=threads.dump(val.init)
    GLOBAL[name]=val
    val.init=init
end

function threads.getCores()
    return love.system.getProcessorCount()
end

function threads.kill()
    error("Thread Killed!\1")
end

function threads.pushStatus(...)
    local status_channel = love.thread.getChannel("STATCHAN_" ..__THREADID__)
    local args = {...}
    status_channel:push(args)
end

function threads.getThreads()
    local t = {}
    for i=1,GLOBAL["__THREAD_COUNT"] do
        t[#t+1]=GLOBAL["__THREAD_"..i]
    end
    return t
end

function threads.getThread(n)
    return GLOBAL["__THREAD_"..n]
end

function threads.getName()
    return __THREADNAME__
end

function threads.getID()
    return __THREADID__
end

function threads.sleep(n)
    love.timer.sleep(n)
end

function threads.getGlobal()
    return setmetatable({},
        {
            __index = function(t, k)
                return THREAD.get(k)
            end,
            __newindex = function(t, k, v)
                THREAD.set(k,v)
            end
        }
    )
end

function threads.packENV(env)
    local e = {}
    for i,v in pairs(env) do
        if type(v) == "function" then
            e["$f"..i] = string.dump(v)
        elseif type(v) == "table" then
            e["$t"..i] = threads.packENV(v)
        else
            e[i] = v
        end
    end
    return e
end

function threads.unpackENV(env)
    local e = {}
    for i,v in pairs(env) do
        if type(i) == "string" and i:sub(1,2) == "$f" then
            e[i:sub(3,-1)] = loadstring(v)
        elseif type(i) == "string" and i:sub(1,2) == "$t" then
            e[i:sub(3,-1)] = threads.unpackENV(v)
        else
            e[i] = v
        end
    end
    return e
end


function threads.setENV(env, name)
    name = name or "__env"
    (threads.getGlobal())[name] = threads.packENV(env)
end

function threads.getENV(name)
    name = name or "__env"
    return threads.unpackENV((threads.getGlobal())[name])
end

function threads.exposeENV(name)
    name = name or "__env"
    local env = threads.getENV(name)
    for i,v in pairs(env) do
        _G[i] = v
    end
end

function threads.createTable(n)
    local _proxy = {}
    local function set(name,val)
        if not _proxy[name] then _proxy[name] = love.thread.getChannel(n..name) end
        _proxy[name]:performAtomic(manage, val) 
    end
    local function get(name)
        if not _proxy[name] then _proxy[name] = love.thread.getChannel(n..name) end
        local dat = _proxy[name]:peek()
        if type(dat)=="table" and dat[1]=="func" then
            return THREAD.loadDump(dat[2])
        else
            return dat
        end
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

function threads.getConsole()
    local c = {}
    c.queue = love.thread.getChannel("__CONSOLE__")
    function c.print(...)
        c.queue:push{...}
    end
    function c.error(err)
        c.queue:push{"ERROR in <"..__THREADNAME__..">: "..err,__THREADID__}
        error(err)
    end
    return c
end

if not ISTHREAD then
    local queue = love.thread.getChannel("__CONSOLE__")
    multi:newLoop(function(loop)
        dat = queue:pop()
        if dat then
            print(unpack(dat))
        end
    end)
end

function threads.createStaticTable(n)
    local __proxy = {}
    local function set(name,val)
        if __proxy[name] then return end
        local chan = love.thread.getChannel(n..name)
        if chan:getCount()>0 then return end
        chan:performAtomic(manage, val)
        __proxy[name] = val
    end
    local function get(name)
        if __proxy[name] then return __proxy[name] end
        local dat = love.thread.getChannel(n..name):peek()
        if type(dat)=="table" and dat[1]=="func" then
            __proxy[name] = THREAD.loadDump(dat[2])
            return __proxy[name]
        else
            __proxy[name] = dat
            return __proxy[name]
        end
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

function threads.hold(n)
    local dat
    while not(dat) do
        dat = n()
    end
end

return threads