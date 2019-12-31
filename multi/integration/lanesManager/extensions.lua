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
local multi, thread = require("multi"):init()
local GLOBAL, THREAD = multi.integration.GLOBAL,multi.integration.THREAD
function multi:newSystemThreadedQueue(name)
	local c = {}
	c.linda = lanes.linda()
	function c:push(v)
		self.linda:send("Q", v)
	end
	function c:pop()
		return ({self.linda:receive(0, "Q")})[2]
	end
	function c:peek()
		return self.linda:get("Q")
	end
	function c:init()
		return self
	end
	GLOBAL[name or "_"] = c
	return c
end
function multi:newSystemThreadedTable(name)
    local c = {}
    c.link = lanes.linda()
    setmetatable(c,{
        __index = function(t,k)
            return c.link:get(k)
        end,
        __newindex = function(t,k,v)
            c.link:set(k,v)
        end
    })
    function c:init()
        return self
    end
    GLOBAL[name or "_"] = c
	return c
end
function multi:newSystemThreadedJobQueue(n)
    local c = {}
    c.cores = n or THREAD.getCores()*2
    c.OnJobCompleted = multi:newConnection()
    local funcs = multi:newSystemThreadedTable()
    local queueJob = multi:newSystemThreadedQueue()
    local queueReturn = multi:newSystemThreadedQueue()
    local doAll = multi:newSystemThreadedQueue()
    local ID=1
    local jid = 1
    function c:doToAll(func)
        for i=1,c.cores do
            doAll:push{ID,func}
        end
        ID = ID + 1
    end
    function c:registerFunction(name,func)
        funcs[name]=func
    end
    function c:pushJob(name,...)
        queueJob:push{name,jid,{...}}
        jid = jid + 1
    end
    multi:newThread("JobQueueManager",function()
        while true do
            local job = thread.hold(function()
                return queueReturn:pop()
            end)
            local id = table.remove(job,1)
            c.OnJobCompleted:Fire(id,unpack(job))
        end
    end)
    for i=1,c.cores do
        multi:newSystemThread("SystemThreadedJobQueue",function(queue)
            local multi,thread = require("multi"):init()
            local idle = os.clock()
            local clock = os.clock
            local ref = 0
            setmetatable(_G,{__index = funcs})
            multi:newThread("JobHandler",function()
                while true do
                    local dat = thread.hold(function()
                        return queueJob:pop()
                    end)
                    idle = clock()
                    local name = table.remove(dat,1)
                    local jid = table.remove(dat,1)
                    local args = table.remove(dat,1)
                    queueReturn:push{jid, funcs[name](unpack(args)),queue}
                end
            end)
            multi:newThread("DoAllHandler",function()
                while true do
                    local dat = thread.hold(function()
                        return doAll:peek()
                    end)
                    if dat then
                        if dat[1]>ref then
                            idle = clock()
                            ref = dat[1]
                            dat[2]()
                            doAll:pop()
                        end
                    end
                end
            end)
            multi:newThread("IdleHandler",function()
                while true do
                    thread.hold(function()
                        return clock()-idle>3
                    end)
                    THREAD.sleep(.01)
                end
            end)
            multi:mainloop()
        end,i).priority = thread.Priority_Core
    end
    return c
end 