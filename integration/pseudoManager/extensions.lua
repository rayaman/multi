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
	c.Type = multi.registerType("s_queue")
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
    function c:Hold(opt)
        if opt.peek then
            return thread.hold(function()
                return self:peek()
            end)
        else
            return thread.hold(function()
                return self:pop()
            end)
        end
	end
	GLOBAL[name or "_"] = c
	return c
end

function multi:newSystemThreadedTable(name)
    local c = {}
	c.Type = multi.registerType("s_table")
    function c:init()
        return self
    end
    function c:Hold(opt)
        if opt.key then
            return thread.hold(function()
                return self.tab[opt.key]
            end)
        else
            multi.error("Must provide a key to check opt.key = 'key'")
        end
    end
    GLOBAL[name or "_"] = c
	return c
end

local setfenv = multi.isolateFunction

local jqc = 1
function multi:newSystemThreadedJobQueue(n)
	local c = {}

	c.cores = n or THREAD.getCores()
	c.registerQueue = {}
	c.Type = multi.registerType("s_jobqueue")
	c.funcs = multi:newSystemThreadedTable("__JobQueue_"..jqc.."_table")
	c.queue = multi:newSystemThreadedQueue("__JobQueue_"..jqc.."_queue")
	c.queueReturn = multi:newSystemThreadedQueue("__JobQueue_"..jqc.."_queueReturn")
	c.queueAll = multi:newSystemThreadedQueue("__JobQueue_"..jqc.."_queueAll")
	c.id = 0
	c.OnJobCompleted = multi:newConnection()

	local allfunc = 0

	function c:doToAll(func)
		for i = 1, self.cores do
			self.queueAll:push({allfunc, func})
		end
		allfunc = allfunc + 1
	end
	function c:registerFunction(name, func)
		if self.funcs[name] then
			multi.error("A function by the name "..name.." has already been registered!") 
		end
		self.funcs[name] = func
	end
	function c:pushJob(name,...)
		self.id = self.id + 1
		self.queue:push{name,self.id,...}
		return self.id
	end
	function c:isEmpty()
        return queueJob:peek()==nil
    end
	local nFunc = 0
    function c:newFunction(name,func,holup) -- This registers with the queue
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
                    rets = multi.pack(...)
                end
            end)
            return thread.hold(function()
                if rets then
                    return multi.unpack(rets) or multi.NIL
                end
            end)
        end,holup),name
    end
	thread:newThread("jobManager",function()
		while true do
			thread.yield()
			local dat = c.queueReturn:pop()
			if dat then
				c.OnJobCompleted:Fire(multi.unpack(dat))
			end
		end
	end)
	for i=1,c.cores do
		multi:newSystemThread("JobQueue_"..jqc.."_worker_"..i,function(jqc)
			local multi, thread = require("multi"):init()
			local clock = os.clock
			local funcs = THREAD.waitFor("__JobQueue_"..jqc.."_table")
			local queue = THREAD.waitFor("__JobQueue_"..jqc.."_queue")
			local queueReturn = THREAD.waitFor("__JobQueue_"..jqc.."_queueReturn")
			local lastProc = clock()
			local queueAll = THREAD.waitFor("__JobQueue_"..jqc.."_queueAll")
			local registry = {}
			_G["__QR"] = queueReturn
			setmetatable(_G,{__index = funcs})
			thread:newThread("startUp",function()
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						queueAll:pop()[2]()
					end
				end
			end)
			thread:newThread("runner",function()
				thread.sleep(.1)
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						queueAll:pop()[2]()
					end
					local dat = thread.hold(queue)
					if dat then
						multi:newThread("Test",function()
							lastProc = os.clock()
							local name = table.remove(dat,1)
							local id = table.remove(dat,1)
							local tab = {multi.isolateFunction(funcs[name],_G)(multi.unpack(dat))}
							table.insert(tab,1,id)
							queueReturn:push(tab)
						end)
					end
				end
			end).OnError(multi.error)
			thread:newThread("Idler",function()
				while true do
					thread.yield()
					if clock()-lastProc> 2 then
						THREAD.sleep(.05)
					else
						THREAD.sleep(.001)
					end
				end
			end)
			multi:mainloop()
		end,jqc)
	end

    function c:Hold(opt)
        return thread.hold(self.OnJobCompleted)
    end

	jqc = jqc + 1

	self:create(c)

	return c
end

function multi:newSystemThreadedConnection(name)
	local conn = multi:newConnection()
	conn.init = function(self) return self end
	GLOBAL[name or "_"] = conn
	return conn
end
require("multi.integration.sharedExtensions")