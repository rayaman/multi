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
local multi, thread = require("multi").init()
GLOBAL = multi.integration.GLOBAL
THREAD = multi.integration.THREAD
function multi:newSystemThreadedQueue(name)
	local c = {}
	c.Name = name
	local fRef = {"func",nil}
	function c:init()
		local q = {}
		q.chan = lovr.thread.getChannel(self.Name)
		function q:push(dat)
			if type(dat) == "function" then
				fRef[2] = THREAD.dump(dat)
				self.chan:push(fRef)
				return
			else
				self.chan:push(dat)
			end
		end
		function q:pop()
			local dat = self.chan:pop()
			if type(dat)=="table" and dat[1]=="func" then
				return THREAD.loadDump(dat[2])
			else
				return dat
			end
		end
		function q:peek()
			local dat = self.chan:peek()
			if type(dat)=="table" and dat[1]=="func" then
				return THREAD.loadDump(dat[2])
			else
				return dat
			end
		end
		return q
	end
	THREAD.package(name,c)
	return c
end
function multi:newSystemThreadedTable(name)
    local c = {}
    c.name = name
    function c:init()
        return THREAD.createTable(self.name)
    end
    THREAD.package(name,c)
	return c
end
local jqc = 1
function multi:newSystemThreadedJobQueue(n)
	local c = {}
	c.cores = n or THREAD.getCores()
	c.registerQueue = {}
	c.funcs = THREAD.createStaticTable("__JobQueue_"..jqc.."_table")
	c.queue = lovr.thread.getChannel("__JobQueue_"..jqc.."_queue")
	c.queueReturn = lovr.thread.getChannel("__JobQueue_"..jqc.."_queueReturn")
	c.queueAll = lovr.thread.getChannel("__JobQueue_"..jqc.."_queueAll")
	c.id = 0
	c.OnJobCompleted = multi:newConnection()
	local allfunc = 0
	function c:doToAll(func)
		local f = THREAD.dump(func)
		for i = 1, self.cores do
			self.queueAll:push({allfunc,f})
		end
		allfunc = allfunc + 1
	end
	function c:registerFunction(name,func)
		if self.funcs[name] then
			error("A function by the name "..name.." has already been registered!") 
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
                    link:Destroy()
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
			require("lovr.timer")
			local function atomic(channel)
				return channel:pop()
			end
			local clock = os.clock
			local funcs = THREAD.createStaticTable("__JobQueue_"..jqc.."_table")
			local queue = lovr.thread.getChannel("__JobQueue_"..jqc.."_queue")
			local queueReturn = lovr.thread.getChannel("__JobQueue_"..jqc.."_queueReturn")
			local lastProc = clock()
			local queueAll = lovr.thread.getChannel("__JobQueue_"..jqc.."_queueAll")
			local registry = {}
			_G["__QR"] = queueReturn
			setmetatable(_G,{__index = funcs})
			thread:newThread("startUp",function()
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						THREAD.loadDump(queueAll:pop()[2])()
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
						THREAD.loadDump(queueAll:pop()[2])()
					end
					local dat = queue:performAtomic(atomic)
					if dat then
						lastProc = os.clock()
						local name = table.remove(dat,1)
						local id = table.remove(dat,1)
						local tab = {funcs[name](multi.unpack(dat))}
						table.insert(tab,1,id)
						queueReturn:push(tab)
					end
				end
			end):OnError(function(...)
				error(...)
			end)
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
	jqc = jqc + 1
	return c
end