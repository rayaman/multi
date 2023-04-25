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
local multi, thread = require("multi"):init()
local GLOBAL, THREAD = multi.integration.GLOBAL,multi.integration.THREAD

local function stripUpValues(func)
    local dmp = string.dump(func)
    if setfenv then
        return loadstring(dmp,"IsolatedThread_PesudoThreading")
    else
        return load(dmp,"IsolatedThread_PesudoThreading","bt")
    end
end

function multi:newSystemThreadedQueue(name)
	local c = {}
	function c:push(v)
		table.insert(self,v)
	end
	function c:pop()
		return table.remove(self,1)
	end
	function c:peek()
		return self[1]
	end
	function c:init()
		return self
	end
	GLOBAL[name or "_"] = c
	return c
end
function multi:newSystemThreadedTable(name)
    local c = {}
    function c:init()
        return self
    end
    GLOBAL[name or "_"] = c
	return c
end
local setfenv = setfenv
if not setfenv then
    if not debug then
        multi.print("Unable to implement setfenv in lua 5.2+ the debug module is not available!")
    else
        setfenv = function(f, env)
            return load(string.dump(f), nil, nil, env)
        end
    end
end
function multi:newSystemThreadedJobQueue(n)
    local c = {}
    c.cores = n or THREAD.getCores()*2
    c.OnJobCompleted = multi:newConnection()
    local jobs = {}
    local ID=1
    local jid = 1
    local env = {}
    setmetatable(env,{
        __index = _G
    })
    local funcs = {}
    function c:doToAll(func)
        setfenv(func,env)()
        return self
    end
    function c:registerFunction(name,func)
        funcs[name] = setfenv(func,env)
        return self
    end
    function c:pushJob(name,...)
        table.insert(jobs,{name,jid,{...}})
        jid = jid + 1
        return jid-1
    end
    function c:isEmpty()
        return #jobs == 0
    end
    local nFunc = 0
    function c:newFunction(name,func,holup) -- This registers with the queue
        local func = stripUpValues(func)
        if type(name)=="function" then
            holup = func
            func = name
            name = "JQ_Function_"..nFunc
        end
        nFunc = nFunc + 1
        c:registerFunction(name,func)
        return thread:newFunction(function(...)
            local id = c:pushJob(name,...)
            local link
            local rets
            link = c.OnJobCompleted(function(jid,...)
                if id==jid then
                    rets = {...}
                end
            end)
            return thread.hold(function()
                if rets then
                    return unpack(rets) or multi.NIL
                end
            end)
        end,holup),name
    end
    for i=1,c.cores do
        thread:newThread("PesudoThreadedJobQueue_"..i,function()
            while true do
                thread.yield()
                if #jobs>0 then
                    local j = table.remove(jobs,1)
                    c.OnJobCompleted:Fire(j[2],funcs[j[1]](unpack(j[3])))
                else
                    thread.sleep(.05)
                end
            end
        end).OnError(print)
    end
    return c
end

function multi:newSystemThreadedConnection(name)
	local conn = multi.newConnection()
	conn.init = function(self) return self end
	GLOBAL[name or "_"] = conn
	return conn
end