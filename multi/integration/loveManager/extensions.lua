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
local multi, thread = require("multi").init()
local pad = require("multi.integration.loveManager.scratchpad")
GLOBAL = multi.integration.GLOBAL
THREAD = multi.integration.THREAD
function multi:newSystemThreadedQueue(name)
	local c = {}
	c.Name = name
	local fRef = {"func",nil}
	function c:init()
		local q = {}
		q.chan = love.thread.getChannel(self.Name)
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
	c.queue = love.thread.getChannel("__JobQueue_"..jqc.."_queue")
	c.queueReturn = love.thread.getChannel("__JobQueue_"..jqc.."_queueReturn")
	c.queueAll = love.thread.getChannel("__JobQueue_"..jqc.."_queueAll")
	c.id = 0
	c.OnJobCompleted = multi:newConnection()
	c._bytedata = love.data.newByteData(string.rep(status.BUSY,c.cores))
	c.bytedata = pad:new(c._bytedata)
	local allfunc = 0
	function c:doToAll(func)
		self.bytedata:write(string.rep(status.BUSY,c.cores)) -- set all variables to busy
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
		self.bytedata:write(string.rep(status.BUSY,c.cores)) -- set all variables to busy
		self.funcs[name] = func
	end
	function c:pushJob(name,...)
		self.id = self.id + 1
		self.queue:push{name,self.id,...}
		return self.id
	end
	multi:newThread("jobManager",function()
		while true do
			thread.yield()
			local dat = c.queueReturn:pop()
			if dat then
				print(dat)
				c.OnJobCompleted:Fire(unpack(dat))
			end
		end
	end)
	for i=1,c.cores do
		multi:newSystemThread("JobQueue_"..jqc.."_worker_"..i,function(jqc)
			local multi, thread = require("multi"):init()
			local function atomic(channel)
				return channel:pop()
			end
			require("love.timer")
			local clock = os.clock
			local pad = require("multi.integration.loveManager.scratchpad")
			local status = require("multi.integration.loveManager.status")
			local funcs = THREAD.createStaticTable("__JobQueue_"..jqc.."_table")
			local queue = love.thread.getChannel("__JobQueue_"..jqc.."_queue")
			local queueReturn = love.thread.getChannel("__JobQueue_"..jqc.."_queueReturn")
			local lastProc = clock()
			local queueAll = love.thread.getChannel("__JobQueue_"..jqc.."_queueAll")
			local registry = {}
			setmetatable(_G,{__index = funcs})
			multi:newThread("startUp",function()
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						THREAD.loadDump(queueAll:pop()[2])()
					end
				end
			end)
			multi:newThread("runner",function()
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
						local tab = {funcs[name](unpack(dat))}
						table.insert(tab,1,id)
						queueReturn:push(tab)
					end
				end
			end):OnError(function(...)
				error(...)
			end)
			multi:newThread("Idler",function()
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