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

local multi = {}
local mainloopActive = false
local isRunning = false
local clock = os.clock
local thread = {}
local in_proc = false
local processes = {}
local find_optimization = false

if not _G["$multi"] then
	_G["$multi"] = {multi=multi,thread=thread}
end

multi.Version = "15.3.0"
multi.Name = "root"
multi.NIL = {Type="NIL"}
local NIL = multi.NIL
multi.Mainloop = {}
multi.Children = {}
multi.Active = true
multi.Type = "rootprocess"
multi.LinkedPath = multi
multi.TIMEOUT = "TIMEOUT"
multi.TID = 0
multi.defaultSettings = {}

multi.Priority_Core = 1
multi.Priority_Very_High = 4
multi.Priority_High = 16
multi.Priority_Above_Normal = 64
multi.Priority_Normal = 256
multi.Priority_Below_Normal = 1024
multi.Priority_Low = 4096
multi.Priority_Very_Low = 16384
multi.Priority_Idle = 65536

multi.PriorityResolve = {
	[1]		=	"Core",
	[4]		=	"Very High",
	[16]	=	"High",
	[64]	=	"Above Normal",
	[256]	=	"Normal",
	[1024]	=	"Below Normal",
	[4096]	=	"Low",
	[16384]	=	"Very Low",
	[65536]	=	"Idle",
}

local PList = {multi.Priority_Core,multi.Priority_Very_High,multi.Priority_High,multi.Priority_Above_Normal,multi.Priority_Normal,multi.Priority_Below_Normal,multi.Priority_Low,multi.Priority_Very_Low,multi.Priority_Idle}
multi.PriorityTick=1
multi.Priority=multi.Priority_High
multi.threshold=256
multi.threstimed=.001

-- System
function multi.Stop()
	isRunning = false
	mainloopActive = false
end

--Processor
local priorityTable = {[false]="Disabled",[true]="Enabled"}
local ProcessName = {"SubProcessor","MainProcessor"}
local globalThreads = {}

function multi:getProcessors()
	return processes
end

function multi:getStats()
	local stats = {
		[multi.Name] = {
			threads = multi:getThreads(),
			tasks = multi:getTasks()
		}
	}
	local procs = multi:getProcessors()
	for i = 1, #procs do
		local proc = procs[i]
		stats[proc:getFullName()] = {
			threads = proc:getThreads(),
			tasks = proc:getTasks()
		}
	end
	return stats
end

--Helpers

function multi.ForEach(tab,func)
	for i=1,#tab do func(tab[i]) end
end
local CRef = {
	Fire = function() end
}

local optimization_stats = {}
local ignoreconn = true
function multi:newConnection(protect,func,kill)
	local c={}
	local call_funcs = {}
	local lock = false
	c.callback = func
	c.Parent=self

	setmetatable(c,{__call=function(self,...)
		local t = ...
		if type(t)=="table" then
			for i,v in pairs(t) do
				if v==self then
					local ref = self:Connect(select(2,...))
					if ref then
						ref.root_link = select(1,...)
						return ref
					end
					return self
				end
			end
			return self:Connect(...)
		else
			return self:Connect(...)
		end
	end,
	__add = function(c1,c2) -- Or
		local cn = multi:newConnection()
		c1(function(...)
			cn:Fire(...)
		end)
		c2(function(...)
			cn:Fire(...)
		end)
		return cn
	end,
	__mul = function(c1,c2) -- And
		local cn = multi:newConnection()
		if not c1.__hasInstances then
			cn.__hasInstances = 2
			cn.__count = 0
		else
			cn.__hasInstances = c1.__hasInstances + 1
			cn.__count = c1.__count
		end
		c1(function(...)
			cn.__count = cn.__count + 1
			if cn.__count == cn.__hasInstances then
				cn:Fire(...)
				cn.__count = 0
			end
		end)
		c2(function(...)
			cn.__count = cn.__count + 1
			if cn.__count == cn.__hasInstances then
				cn:Fire(...)
				cn.__count = 0
			end
		end)
		return cn
	end})

	c.Type='connector'
	c.func={}
	c.ID=0
	local protect=protect or false
	local connections={}
	c.FC=0

	function c:hasConnections()
		return #call_funcs~=0
	end

	function c:getConnection(name,ignore)
		if ignore then
			return connections[name] or CRef
		else
			return connections[name] or self
		end
	end

	function c:Lock()
		lock = true
		return self
	end

	function c:Unlock()
		lock = false
		return self
	end

	if protect then
		function c:Fire(...)
			if lock then return end
			for i=#call_funcs,1,-1 do
				if not call_funcs[i] then return end
				local suc, err = pcall(call_funcs[i],...)
				if not suc then
					print(err)
				end
				if kill then
					table.remove(call_funcs,i)
				end
			end
		end
	else
		function c:Fire(...)
			if lock then return end
			for i=#call_funcs,1,-1 do
				call_funcs[i](...)
				if kill then
					table.remove(call_funcs,i)
				end
			end
		end
	end

	local fast = {}
	function c:getConnections()
		return call_funcs
	end

	function c:fastMode()
		if find_optimization then return self end
		function self:Fire(...)
			for i=1,#fast do
				fast[i](...)
			end
		end
		function self:Connect(func)
			table.insert(fast,func)
		end
		return self
	end

	function c:Bind(t)
		local temp = call_funcs
		call_funcs=t
		return temp
	end

	function c:Remove()
		local temp = call_funcs
		call_funcs={}
		return temp
	end

	local function conn_helper(self,func,name,num)
		self.ID=self.ID+1

		if num then
			table.insert(call_funcs,num,func)
		else
			table.insert(call_funcs,1,func)
		end

		local temp = {
			func=func,
			Type="connector_link",
			Parent=self,
			connect = function(s,...)
				return self:Connect(...)
			end
		}

		setmetatable(temp,{
			__call=function(s,...)
				return self:Connect(...)
			end,
			__index = function(t,k)
				if rawget(t,"root_link") then
					return t["root_link"][k]
				end
				return nil
			end,
			__newindex = function(t,k,v)
				if rawget(t,"root_link") then
					t["root_link"][k] = v
				end
				rawset(t,k,v)
			end,
		})

		function temp:Fire(...)
			return call_funcs(...)
		end

		function temp:Destroy()
			for i=#call_funcs,1,-1 do
				if call_funcs[i]~=nil then
					if call_funcs[i]==self.func then
						table.remove(call_funcs,i)
						self.remove=function() end
						multi.setType(temp,multi.DestroyedObj)
					end
				end
			end
		end

		if name then
			connections[name]=temp
		end

		if self.callback then
			self.callback(temp)
		end

		return temp
	end

	function c:Connect(...)--func,name,num
		local tab = {...}
		local funcs={}
		for i=1,#tab do
			if type(tab[i])=="function" then
				funcs[#funcs+1] = tab[i]
			end
		end
		if #funcs>1 then
			local ret = {}
			for i=1,#funcs do
				table.insert(ret,conn_helper(self,funcs[i]))
			end
			return ret
		else
			return conn_helper(self,tab[1],tab[2],tab[3])
		end
	end

	function c:SetHelper(func)
		conn_helper = func
		return self
	end

	if find_optimization then
		--
	end

	c.connect=c.Connect
	c.GetConnection=c.getConnection
	c.HasConnections = c.hasConnections
	c.GetConnection = c.getConnection

	if not(ignoreconn) then
		multi:create(c)
	end
	return c
end

multi.enableOptimization = multi:newConnection()
multi.optConn = multi:newConnection(true)
multi.optConn(function(msg)
	table.insert(optimization_stats, msg)
end)

function multi:getOptimizationConnection()
	return multi.optConn
end

function multi:getOptimizationStats()
	return optimization_stats
end

function multi:isFindingOptimizing()
	return find_optimization
end

-- Used with ISO Threads
local function isolateFunction(func,env)
	local dmp = string.dump(func)
	local env = env or {}
	if setfenv then
		local f = loadstring(dmp,"IsolatedThread_PesudoThreading")
		setfenv(f,env)
		return f
	else
		return load(dmp,"IsolatedThread_PesudoThreading","bt",env)
	end
end

function multi:Break()
	self:Pause()
	self.Active=nil
	self.OnBreak:Fire(self)
end

function multi:isPaused()
	return not(self.Active)
end

function multi:isActive()
	return self.Active
end

function multi:getType()
	return self.Type
end

-- Advance Timer stuff
function multi:SetTime(n)
	if not n then n=3 end
	local c=self:newBase()
	c.Type='timemaster'
	c.timer=self:newTimer()
	c.timer:Start()
	c.set=n
	c.link=self
	c.OnTimedOut = multi:newConnection()
	c.OnTimerResolved = multi:newConnection()
	self._timer=c.timer
	function c:Act()
		if self.timer:Get()>=self.set then
			self.link:Pause()
			self.OnTimedOut:Fire(self.link)
			self:Destroy()
		end
	end
	return self
end

function multi:ResolveTimer(...)
	self._timer:Pause()
	self.OnTimerResolved:Fire(self,...)
	self:Pause()
	return self
end

-- Timer stuff done
multi.PausedObjects = {}
function multi:Pause()
	if self.Type=='rootprocess' then
		multi.print("You cannot pause the main process. Doing so will stop all methods and freeze your program! However if you still want to use multi:_Pause()")
	else
		self.Active=false
		local loop = self.Parent.Mainloop
		for i=1,#loop do
			if loop[i] == self then
				multi.PausedObjects[self] = true
				table.remove(loop,i)
				break
			end
		end
	end
	return self
end

function multi:Resume()
	if self.Type=='process' or self.Type=='rootprocess' then
		self.Active=true
		local c=self:getChildren()
		for i=1,#c do
			c[i]:Resume()
		end
	else
		if self.Active==false then
			table.insert(self.Parent.Mainloop,self)
			multi.PausedObjects[self] = nil
			self.Active=true
		end
	end
	return self
end

function multi:Destroy()
	if self.Type=='process' or self.Type=='rootprocess' then
		local c=self:getChildren()
		for i=1,#c do
			self.OnObjectDestroyed:Fire(c[i])
			c[i]:Destroy()
		end
		local new = {}
		for th,proc in pairs(globalThreads) do
			if proc == self then
				th:Destroy()
				table.remove(globalThreads,th)
			else
				new[th]=proc
			end
		end
		globalThreads = new
		multi.setType(self,multi.DestroyedObj)
	else
		for i=#self.Parent.Mainloop,1,-1 do
			if self.Parent.Mainloop[i]==self then
				self.Parent.OnObjectDestroyed:Fire(self)
				table.remove(self.Parent.Mainloop,i)
				self.Destroyed = true
				break
			end
		end
		self.Act = function() end
	end
	return self
end

function multi:Reset(n)
	self:Resume()
	return self
end

function multi:isDone()
	return self.Active~=true
end

function multi:create(ref)
	self.OnObjectCreated:Fire(ref,self)
	return self
end

function multi:setName(name)
	self.Name = name
	return self
end

--Constructors [CORE]
local _tid = 0
function multi:newBase(ins)
	if not(self.Type=='rootprocess' or self.Type=='process') then error('Can only create an object on multi or an interface obj') return false end
	local c = {}
	if self.Type=='process' then
		setmetatable(c, {__index = multi})
	else
		setmetatable(c, {__index = multi})
	end
	c.Active=true
	c.func={}
	c.funcTM={}
	c.funcTMR={}
	c.OnBreak = multi:newConnection()
	c.TID = _tid
	c.Act=function() end
	c.Parent=self
	c.creationTime = os.clock()
	if ins then
		table.insert(self.Mainloop,ins,c)
	else
		table.insert(self.Mainloop,c)
	end
	_tid = _tid + 1
	return c
end

function multi:newConnector()
	local c = {Type = "connector"}
	return c
end

multi.OnObjectCreated=multi:newConnection()
multi.OnObjectDestroyed=multi:newConnection()
multi.OnLoad = multi:newConnection(nil,nil,true)
ignoreconn = false
function multi:newTimer()
	local c={}
	c.Type='timer'
	local time=0
	local count=0
	local paused=false
	function c:Start()
		time=os.clock()
		return self
	end
	function c:Get()
		if self:isPaused() then return time end
		return (clock()-time)+count
	end
	function c:isPaused()
		return paused
	end
	c.Reset=c.Start
	function c:Pause()
		time=self:Get()
		paused=true
		return self
	end
	function c:Resume()
		paused=false
		time=os.clock()-time
		return self
	end
	multi:create(c)
	return c
end

--Core Actors
function multi:newEvent(task)
	local c=self:newBase()
	c.Type='event'
	local task = task or function() end
	function c:Act()
		local t = task(self)
		if t then
			self:Pause()
			self.returns = t
			c.OnEvent:Fire(self)
		end
	end
	function c:SetTask(func)
		task=func
		return self
	end
	c.OnEvent = self:newConnection():fastMode()
	self:setPriority("core")
	c:SetName(c.Type)
	multi:create(c)
	return c
end

function multi:newUpdater(skip)
	local c=self:newBase()
	c.Type='updater'
	local pos = 1
	local skip = skip or 1
	function c:Act()
		if pos >= skip then
			pos = 0
			self.OnUpdate:Fire(self)
		end
		pos = pos+1
	end
	function c:SetSkip(n)
		skip=n
		return self
	end
	c.OnUpdate = self:newConnection():fastMode()
	c:SetName(c.Type)
	multi:create(c)
	return c
end

function multi:newAlarm(set)
	local c=self:newBase()
	c.Type='alarm'
	c:setPriority("Low")
	c.set=set or 0
	local count = 0
	local t = clock()
	function c:Act()
		if clock()-t>=self.set then
			self:Pause()
			self.Active=false
			self.OnRing:Fire(self)
			t = clock()
		end
	end
	function c:Resume()
		self.Parent.Resume(self)
		t = count + t
		return self
	end
	function c:Reset(n)
		if n then self.set=n end
		self:Resume()
		t = clock()
		return self
	end
	c.OnRing = self:newConnection():fastMode()
	function c:Pause()
		count = clock()
		self.Parent.Pause(self)
		return self
	end
	c:SetName(c.Type)
	multi:create(c)
	return c
end

function multi:newLoop(func,notime)
	local c=self:newBase()
	c.Type='loop'
	local start=clock()
	if notime then
		function c:Act()
			self.OnLoop:Fire(self)
		end
	else
		function c:Act()
			self.OnLoop:Fire(self,clock()-start)
		end
	end
	c.OnLoop = self:newConnection():fastMode()

	if func then
		c.OnLoop(func)
	end
	
	multi:create(c)
	c:SetName(c.Type)
	return c
end

function multi:newStep(start,reset,count,skip)
	local c=self:newBase()
	think=1
	c.Type='step'
	c.pos=start or 1
	c.endAt=reset or math.huge
	c.skip=skip or 0
	c.spos=0
	c.count=count or 1*think
	c.start=start or 1
	if start~=nil and reset~=nil then
		if start>reset then
			think=-1
		end
	end
	function c:Act()
		if self~=nil then
			if self.spos==0 then
				if self.pos==self.start then
					self.OnStart:Fire(self)
				end
				self.OnStep:Fire(self,self.pos)
				self.pos=self.pos+self.count
				if self.pos-self.count==self.endAt then
					self:Pause()
					self.OnEnd:Fire(self)
					self.pos=self.start
				end
			end
		end
		self.spos=self.spos+1
		if self.spos>=self.skip then
			self.spos=0
		end
	end
	c.Reset=c.Resume
	c.OnStart = self:newConnection():fastMode()
	c.OnStep = self:newConnection():fastMode()
	c.OnEnd = self:newConnection():fastMode()
	function c:Break()
		self.Active=nil
		return self
	end
	function c:Count(count)
		self.count = count
	end
	function c:Update(start,reset,count,skip)
		self.start=start or self.start
		self.endAt=reset or self.endAt
		self.skip=skip or self.skip
		self.count=count or self.count
		self:Resume()
		return self
	end
	c:SetName(c.Type)
	multi:create(c)
	return c
end

function multi:newTLoop(func,set)
	local c=self:newBase()
	c.Type='tloop'
	c.set=set or 0
	c.timer=self:newTimer()
	c.life=0
	c:setPriority("Low")
	function c:Act()
		if self.timer:Get()>=self.set then
			self.life=self.life+1
			self.timer:Reset()
			self.OnLoop:Fire(self,self.life)
		end
	end
	function c:Set(set)
		self.set = set
	end
	function c:Resume()
		self.Parent.Resume(self)
		self.timer:Resume()
		return self
	end
	function c:Pause()
		self.timer:Pause()
		self.Parent.Pause(self)
		return self
	end
	c.OnLoop = self:newConnection():fastMode()
	if func then
		c.OnLoop(func)
	end
	c:SetName(c.Type)
	multi:create(c)
	return c
end

function multi:setTimeout(func,t)
	thread:newThread(function() thread.sleep(t) func() end)
end

function multi:newTStep(start,reset,count,set)
	local c=self:newStep(start,reset,count)
	c.Type='tstep'
	c:setPriority("Low")
	local reset = reset or math.huge
	c.timer=clock()
	c.set=set or 1
	function c:Update(start,reset,count,set)
		self.start=start or self.start
		self.pos=self.start
		self.endAt=reset or self.endAt
		self.set=set or self.set
		self.count=count or self.count or 1
		self.timer=clock()
		self:Resume()
		return self
	end
	function c:Act()
		if clock()-self.timer>=self.set then
			self:Reset()
			if self.pos==self.start then
				self.OnStart:Fire(self)
			end
			self.OnStep:Fire(self,self.pos)
			self.pos=self.pos+self.count
			if self.pos-self.count==self.endAt then
				self:Pause()
				self.OnEnd:Fire(self)
				self.pos=self.start
			end
		end
	end
	function c:Set(set)
		self.set = set
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=clock()
		self:Resume()
		return self
	end
	c:SetName(c.Type)
	multi:create(c)
	return c
end

local scheduledjobs = {}
local sthread

function multi:scheduleJob(time,func)
	if not sthread then
		sthread = thread:newThread("JobScheduler",function()
			local time = os.date("*t", os.time())
			local ready = false
			while true do
				thread.sleep(1) -- Every second we do some tests
				time = os.date("*t", os.time())
				for j,job in pairs(scheduledjobs) do
					ready = true
					for k,v in pairs(job[1]) do
						if not (v == time[k]) then
							ready = false
						end
					end
					if ready and not job[3] then
						job[2]()
						job[3] = true
					elseif not ready and job[3] then
						job[3] = false
					end
				end
			end
		end)
	end
	table.insert(scheduledjobs,{time, func,false})
end

local __CurrentProcess = multi
local __CurrentTask

function multi.getCurrentProcess()
	return __CurrentProcess
end

function multi.getCurrentTask()
	return __CurrentTask
end

function multi:getName()
	return self.Name
end

function multi:getFullName()
	return self.Name
end

local sandcount = 1

function multi:newProcessor(name,nothread)
	local c = {}
	setmetatable(c,{__index = multi})
	local name = name or "Processor_"..sandcount
	sandcount = sandcount + 1
	c.Mainloop = {}
	c.Type = "process"
	local Active =  nothread or false
	c.Name = name or ""
	c.threads = {}
	c.startme = {}
	c.parent = self

	local handler = c:createHandler(c.threads,c.startme)

	if not nothread then -- Don't create a loop if we are triggering this manually
		c.process = self:newLoop(function()
			if Active then
				c:uManager()
				handler()
			end
		end)
		c.process.__ignore = true
		c.process.isProcessThread = true
		c.process.PID = sandcount
		c.OnError = c.process.OnError
	else
		c.OnError = multi:newConnection()
	end
	
	

	function c:getThreads()
		return c.threads
	end

	function c:getFullName()
		return c.parent:getFullName() .. "." .. c.Name
	end

	function c:getName()
		return self.Name
	end

	function c:newThread(name,func,...)
		in_proc = c
		local t = thread.newThread(c,name,func,...)
		in_proc = false
		return t
	end

	function c:newFunction(func,holdme)
		return thread:newFunctionBase(function(...)
			return c:newThread("TempThread",func,...)
		end,holdme)()
	end

	function c.run()
		if not Active then return end
		c:uManager()
		handler()
		return c
	end

	function c.isActive()
		return Active
	end

	function c.Start()
		Active = true
		return c
	end

	function c.Stop()
		Active = false
		return c
	end

	function c:Destroy()
		Active = false
		c.process:Destroy()
	end
	
	table.insert(processes,c)
	return c
end

function multi.hold(func,opt)
	if thread.isThread() then
		if type(func) == "function" or type(func) == "table" then
			return thread.hold(func,opt)
		end
		return thread.sleep(func)
	end
	local death = false
	local proc = multi.getCurrentTask()
	proc:Pause()
	if type(func)=="number" then
		thread:newThread("Hold_func",function()
			thread.hold(func)
			death = true
		end)
		while not death do
			multi:uManager()
		end
		proc:Resume()
	else
		local rets
		thread:newThread("Hold_func",function()
			rets = {thread.hold(func,opt)}
			death = true
		end)
		while not death do
			multi:uManager()
		end
		proc:Resume()
		return unpack(rets)
	end
end

-- Threading stuff
local threadCount = 0
local threadid = 0
thread.__threads = {}
local threads = thread.__threads
multi.GlobalVariables={}
local dFunc = function() return true end
thread.requests = {}
local CMD = {} -- We will compare this special local
local interval
local resume, status, create, yield, running = coroutine.resume, coroutine.status, coroutine.create, coroutine.yield, coroutine.running

local t_hold, t_sleep, t_holdF, t_skip, t_holdW, t_yield, t_none = 1, 2, 3, 4, 5, 6, 7

function multi:getThreads()
	return threads
end

function multi:getTasks()
	local tasks = {}
	for i,v in pairs(self.Mainloop) do
		if not v.__ignore then
			tasks[#tasks+1] = v
		end
	end
	return tasks
end

function thread.request(t,cmd,...)
	thread.requests[t.thread] = {cmd,{...}}
end

function thread.getRunningThread()
	local threads = globalThreads
	local t = coroutine.running()
	if t then
		for th,process in pairs(threads) do
			if t==th.thread then
				return th
			end
		end
	end
end

function thread._Requests()
	local t = thread.requests[running()]
	if t then
		thread.requests[running()] = nil
		local cmd,args = t[1],t[2]
		thread[cmd](unpack(args))
	end
end

function thread.sleep(n)
	thread._Requests()
	thread.getRunningThread().lastSleep = clock()
	return yield(CMD, t_sleep, n or 1)
end

function thread.hold(n,opt)
	thread._Requests()
	local opt = opt or {}
	if type(opt)=="table" then
		interval = opt.interval
		if opt.cycles then
			return yield(CMD, t_holdW, opt.cycles or 1, n or dFunc, interval)
		elseif opt.sleep then
			return yield(CMD, t_holdF, opt.sleep, n or dFunc, interval)
		elseif opt.skip then
			return yield(CMD, t_skip, opt.skip or 1, nil, interval)
		end
	end
	
	if type(n) == "number" then
		thread.getRunningThread().lastSleep = clock()
		return yield(CMD, t_sleep, n or 0, nil, interval)
	elseif type(n) == "table" and n.Type == "connector" then
		local rdy = function()
			return false
		end
		n(function(a1,a2,a3,a4,a5,a6)
			rdy = function()
				if a1==nil then
					return NIL,a2,a3,a4,a5,a6
				end
				return a1,a2,a3,a4,a5,a6
			end
		end)
		return yield(CMD, t_hold, function()
			return rdy()
		end, nil, interval)
	elseif type(n) == "function" then
		return yield(CMD, t_hold, n or dFunc, nil, interval)
	else
		error("Invalid argument passed to thread.hold(...)!")
	end
end

function thread.hold(n,opt)
	thread._Requests()
	local opt = opt or {}
	if type(opt)=="table" then
		interval = opt.interval
		if opt.cycles then
			return yield(CMD, t_holdW, opt.cycles or 1, n or dFunc, interval)
		elseif opt.sleep then
			return yield(CMD, t_holdF, opt.sleep, n or dFunc, interval)
		elseif opt.skip then
			return yield(CMD, t_skip, opt.skip or 1, nil, interval)
		end
	end
	
	if type(n) == "number" then
		thread.getRunningThread().lastSleep = clock()
		return yield(CMD, t_sleep, n or 0, nil, interval)
	elseif type(n) == "table" and n.Type == "connector" then
		local rdy = function()
			return false
		end
		n(function(a1,a2,a3,a4,a5,a6)
			rdy = function()
				if a1==nil then
					return NIL,a2,a3,a4,a5,a6
				end
				return a1,a2,a3,a4,a5,a6
			end
		end)
		return yield(CMD, t_hold, function()
			return rdy()
		end, nil, interval)
	elseif type(n) == "function" then
		if find_optimization then
			local cache = string.dump(n)
			local f_str = tostring(n)
			local good = true
			for i=1,#func_cache do
				if func_cache[i][1] == cache and func_cache[i][2] ~= f_str then
					if not func_cache[i][3] then
						multi.optConn:Fire("It's better to store a function to a variable than to use an anonymous function within the hold method!\n" .. debug.traceback())
						func_cache[i][3] = true
					end
					good = false
				end
			end
			if good then
				table.insert(func_cache, {cache, f_str})
			end
		end
		return yield(CMD, t_hold, n or dFunc, nil, interval)
	else
		error("Invalid argument passed to thread.hold(...)!")
	end
end

function thread.holdFor(sec,n)
	thread._Requests()
	return yield(CMD, t_holdF, sec, n or dFunc)
end

function thread.holdWithin(skip,n)
	thread._Requests()
	return yield(CMD, t_holdW, skip or 1, n or dFunc)
end

function thread.skip(n)
	thread._Requests()
	return yield(CMD, t_skip, n or 1)
end

function thread.kill()
	error("thread killed!")
end

function thread.yield()
	thread._Requests()
	return yield(CMD, t_yield)
end

function thread.isThread()
	if _VERSION~="Lua 5.1" then
		local a,b = running()
		return not(b)
	else
		return running()~=nil
	end
end

function thread.getCores()
	return thread.__CORES
end

function thread.set(name,val)
	multi.GlobalVariables[name]=val
	return true
end

function thread.get(name)
	return multi.GlobalVariables[name]
end

function thread.waitFor(name)
	thread.hold(function() return thread.get(name)~=nil end)
	return thread.get(name)
end

local function cleanReturns(...)
	local returns = {...}
	local rets = {}
	local ind = 0
	for i=#returns,1,-1 do
		if returns[i] then
			ind = i
			break
		end
	end
	return unpack(returns,1,ind)
end

function thread.pushStatus(...)
	local t = thread.getRunningThread()
	t.statusconnector:Fire(...)
end

local handler

function thread:newFunctionBase(generator,holdme)
	return function()
		local tfunc = {}
		tfunc.Active = true
		function tfunc:Pause()
			self.Active = false
		end
		function tfunc:Resume()
			self.Active = true
		end
		function tfunc:holdMe(b)
			holdme = b
		end
		local function noWait()
			return nil, "Function is paused"
		end
		local rets, err
		local function wait()
			if thread.isThread() then
				return thread.hold(function()
					if err then
						return multi.NIL, err
					elseif rets then
						return cleanReturns((rets[1] or multi.NIL),rets[2],rets[3],rets[4],rets[5],rets[6],rets[7],rets[8],rets[9],rets[10],rets[11],rets[12],rets[13],rets[14],rets[15],rets[16])
					end
				end)
			else
				while not rets and not err do
					handler()
				end
				if err then
					return nil,err
				end
				return cleanReturns(rets[1],rets[2],rets[3],rets[4],rets[5],rets[6],rets[7],rets[8],rets[9],rets[10],rets[11],rets[12],rets[13],rets[14],rets[15],rets[16])
			end
		end
		tfunc.__call = function(t,...)
			if t.Active == false then 
				if holdme then
					return nil, "Function is paused"
				end
				return {
					isTFunc = true,
					wait = noWait,
					connect = function(f)
						f(nil,"Function is paused")
					end
				}
			end 
			local t = generator(...)
			t.OnDeath(function(...) rets = {...}  end)
			t.OnError(function(self,e) err = e end)
			if holdme then
				return wait()
			end
			local temp = {
				OnStatus = multi:newConnection(true),
				OnError = multi:newConnection(true),
				OnReturn = multi:newConnection(true),
				isTFunc = true,
				wait = wait,
				getReturns = function()
					return unpack(rets)
				end,
				connect = function(f)
					local tempConn = multi:newConnection(true)
					t.OnDeath(function(...) if f then f(...) else tempConn:Fire(...) end end) 
					t.OnError(function(self,err) if f then f(nil,err) else tempConn:Fire(nil,err) end end)
					return tempConn
				end
			}
			t.OnDeath(function(...) temp.OnReturn:Fire(...) end) 
			t.OnError(function(self,err) temp.OnError:Fire(err) end)
			t.linkedFunction = temp
			t.statusconnector = temp.OnStatus
			return temp
		end
		setmetatable(tfunc,tfunc)
		return tfunc
	end
end

function thread:newFunction(func,holdme)
	return thread:newFunctionBase(function(...)
		return thread:newThread("TempThread",func,...)
	end,holdme)()
end

-- A cross version way to set enviroments, not the same as fenv though
function multi.setEnv(func,env)
	local f = string.dump(func)
	local chunk = load(f,"env","bt",env)
	return chunk
end

local threads = {}
local startme = {}
local startme_len = 0
function thread:newThread(name,func,...)
	multi.OnLoad:Fire() -- This was done incase a threaded function was called before mainloop/uManager was called
	local func = func or name
	if func == name then
		name = name or multi.randomString(16)
	end
	local c={nil,nil,nil,nil,nil,nil,nil}
	local env = {self=c}
	c.TempRets = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}
	c.startArgs = {...}
	c.ref={}
	c.Name=name
	c.thread=create(func)
	c.sleep=1
	c.Type="thread"
	c.TID = threadid
	c.firstRunDone=false
	c._isPaused = false
	c.returns = {}
	c.isError = false 
	c.OnError = multi:newConnection(true,nil,true)
	c.OnDeath = multi:newConnection(true,nil,true)

	function c:getName()
		return c.Name
	end

	function c:isPaused()
		return self._isPaused
	end

	local resumed = false
	function c:Pause()
		if not self._isPaused then
			thread.request(self,"exec",function()
				thread.hold(function()
					return resumed
				end)
				resumed = false
				self._isPaused = false
			end)
			self._isPaused = true
		end
		return self
	end

	function c:Resume()
		resumed = true
		return self
	end

	function c:Kill()
		thread.request(self,"kill")
		return self
	end

	function c:Sleep(n)
		thread.request(self,"exec",function()
			thread.sleep(n)
			resumed = false
		end)
		return self
	end
	
	function c:Hold(n,opt)
		thread.request(self,"exec",function()
			thread.hold(n,opt)
			resumed = false
		end)
		return self
	end

	c.Destroy = c.Kill

	if self.Type=="process" then
		table.insert(self.startme,c)
	else
		table.insert(startme,c)
	end

	startme_len = #startme
	globalThreads[c] = multi
	threadid = threadid + 1
	multi:create(c)
	c.creationTime = os.clock()
	return c
end

function thread:newISOThread(name,func,_env,...)
	local func = func or name
	local env = _env or {}
	if not env.thread then
		env.thread = thread
	end
	if not env.multi then
		env.multi = multi
	end
	if type(name) == "function" then
		name = "Thread#"..threadCount
	end
	local func = isolateFunction(func,env)
	return thread:newThread(name,func,...)
end

multi.newThread = thread.newThread
multi.newISOThread = thread.newISOThread

local t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15
local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16
local ret,_
local task, thd, ref, ready
local switch = {
	function(th,co)--hold
		if clock() - th.intervalR>=th.interval then
			t0,t1,t2,t3,t4,t5,t6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16 = th.func()
			if t0 then
				if t0==NIL then t0 = nil end
				th.task = t_none
				_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
			end
			th.intervalR = clock()
		end
	end,
	function(th,co)--sleep
		if clock() - th.time>=th.sec then
			th.task = t_none
			_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
		end
	end,
	function(th,co)--holdf
		if clock() - th.intervalR>=th.interval then
			t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15 = th.func()
			if t0 then
				if t0 then
					if t0==NIL then t0 = nil end
					th.task = t_none
				end
				th.task = t_none
				_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
			elseif clock() - th.time>=th.sec then
				th.task = t_none
				t0 = nil
				t1 = multi.TIMEOUT
				_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
			end
			th.intervalR = clock()
		end
	end,
	function(th,co)--skip
		th.pos = th.pos + 1
		if th.count==th.pos then
			th.task = t_none
			_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
		end
	end,
	function(th,co)--holdw
		if clock() - th.intervalR>=th.interval then
			th.pos = th.pos + 1
			t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15 = th.func()
			if t0 then
				if t0 then
					if t0==NIL then t0 = nil end
					th.task = t_none
				end
				th.task = ""
				_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
			elseif th.count==th.pos then
				th.task = t_none
				t0 = nil
				t1 = multi.TIMEOUT
				_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
			end
			th.intervalR = clock()
		end
	end,
	function(th,co)--yield
		_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16=resume(co,t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15)
	end,
	function() end--none
}

setmetatable(switch,{__index=function() return function() end end})

local cmds = {-- ipart: t_hold, t_sleep, t_holdF, t_skip, t_holdW, t_yield, t_none <-- Order
	function(th,arg1,arg2,arg3)
		th.func = arg1
		th.task = t_hold
		th.interval = arg3 or 0
		th.intervalR = clock()
	end,
	function(th,arg1,arg2,arg3)
		th.sec = arg1
		th.time = clock()
		th.task = t_sleep
	end,
	function(th,arg1,arg2,arg3)
		th.sec = arg1
		th.func = arg2
		th.task = t_holdF
		th.time = clock()
		th.interval = arg3 or 0
		th.intervalR = clock()
	end,
	function(th,arg1,arg2,arg3)
		th.count = arg1
		th.pos = 0
		th.task = t_skip
	end,
	function(th,arg1,arg2,arg3)
		th.count = arg1
		th.pos = 0
		th.func = arg2
		th.task = t_holdW
		th.time = clock()
		th.interval = arg3 or 0
		th.intervalR = clock()
	end,
	function(th,arg1,arg2,arg3)
		th.task = t_yield
	end,
	function() end
}
setmetatable(cmds,{__index=function() return function() end end})
local co_status
co_status = {
	["suspended"] = function(thd,ref,task,i,th)
		switch[task](ref,thd)
		cmds[r1](ref,r2,r3,r4,r5)
		if ret ~= CMD and _ ~= nil then -- The rework makes this necessary
			co_status["dead"](thd,ref,task,i,th)
		end
		r1=nil r2=nil r3=nil r4=nil r5=nil
	end,
	["normal"] = function(thd,ref)  end,
	["running"] = function(thd,ref)  end,
	["dead"] = function(thd,ref,task,i,th)
		if ref.__processed then return end
		if _ then
			ref.OnDeath:Fire(ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16)
		else
			ref.OnError:Fire(ref,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16)
		end
		if i then
			table.remove(th,i)
		else
			for i,v in pairs(th) do
				if v.thread==thd then
					table.remove(th,i)
					break
				end
			end
		end
		_=nil r1=nil r2=nil r3=nil r4=nil r5=nil
		ref.__processed = true
	end,
}
handler = coroutine.wrap(function(self)
	local temp_start
	while true do
		for start = #startme, 1, -1 do
			temp_start = startme[start]
			table.remove(startme)
			_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16 = resume(temp_start.thread,unpack(temp_start.startArgs))
			co_status[status(temp_start.thread)](temp_start.thread,temp_start,t_none,nil,threads) -- Make sure there was no error
			table.insert(threads,temp_start)
			yield()
		end
		for i=#threads,1,-1 do
			ref = threads[i]
			if ref then
				task = ref.task
				thd = ref.thread
				ready = ref.__ready
				co_status[status(thd)](thd,ref,task,i,threads)
			end
			yield()
		end
		yield()
	end
end)

function multi:createHandler(threads,startme)
	return coroutine.wrap(function(self)
		local temp_start
		while true do
			for start = #startme, 1, -1 do
				temp_start = startme[start]
				table.remove(startme)
				_,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16 = resume(temp_start.thread,unpack(temp_start.startArgs))
				co_status[status(temp_start.thread)](temp_start.thread,temp_start,t_none,nil,threads) -- Make sure there was no error
				table.insert(threads,temp_start)
				yield()
			end
			for i=#threads,1,-1 do
				ref = threads[i]
				if ref then
					task = ref.task
					thd = ref.thread
					ready = ref.__ready
					co_status[status(thd)](thd,ref,task,i,threads)
				end
				yield()
			end
			yield()
		end
	end)
end

function multi:newService(func) -- Priority managed threads
	local c = {}
	c.Type = "service"
	c.OnStopped = self:newConnection()
	c.OnStarted = self:newConnection()
	local Service_Data = {}
	local active
	local time
	local p = multi.Priority_Normal
	local ap
	local task = thread.sleep
	local scheme = 1

	function c.Start()
		if not active then
			time = self:newTimer()
			time:Start()
			active = true
			c:OnStarted(c,Service_Data)
		end
		return c
	end

	local function process()
		thread.hold(function()
			return active
		end)
		func(c,Service_Data)
		task(ap)
		return c
	end

	local th = thread:newThread(function()
		while true do
			process()
		end
	end)

	th.OnError = c.OnError -- use the threads onerror as our own
	
	function c.Destroy()
		th:kill()
		c.Stop()
		multi.setType(c,multi.DestroyedObj)
		return c
	end

	function c:SetScheme(n)
		if type(self)=="number" then n = self end
		scheme = n
		if math.abs(n)==1 then
			ap = (p^(1/3))/10
			if ap==.1 then task = thread.yield end
			task = thread.sleep
		elseif math.abs(n)==2 then
			ap = math.abs(p-1)*32+1
			task = thread.skip
		elseif math.abs(n)==3 then
			-- This is a time based pirority manager. Things that take long to run get
		end
		return c
	end

	function c.Stop()
		if active then
			c:OnStopped(c)
			Service_Data = {}
			time:Reset()
			time:Pause()
			time = nil
			active = false
		end
		return c
	end

	function c.Pause()
		if active then
			time:Pause()
			active = false
		end
		return c
	end

	function c.Resume()
		if not active then
			time:Resume()
			active = true
		end
		return c
	end

	function c.GetUpTime()
		return time:Get()
	end

	function c:SetPriority(pri)
		if type(self)=="number" then pri = self end
		p = pri
		c.SetScheme(scheme)
		return c
	end

	multi.create(multi,c)

	return c
end

-- Multi runners
local function mainloop(self)
	__CurrentProcess = self
	multi.OnPreLoad:Fire()
	self.uManager = self.uManagerRef
	if not isRunning then
		isRunning = true
		mainloopActive = true
		local Loop=self.Mainloop
		local ctask
		multi.OnLoad:Fire()
		while mainloopActive do
			for _D=#Loop,1,-1 do
				__CurrentTask = Loop[_D]
				ctask = __CurrentTask
				ctask:Act()
				__CurrentProcess = self
			end
			handler()
		end
	else
		return nil, "Already Running!"
	end
end

multi.mainloop = mainloop

local function p_mainloop(self)
	__CurrentProcess = self
	multi.OnPreLoad:Fire()
	self.uManager = self.uManagerRefP1
	if not isRunning then
		isRunning=true
		mainloopActive = true
		local Loop = self.Mainloop
		local ctask
		multi.OnLoad:Fire()
		while mainloopActive do
			for task=#Loop,1,-1 do
				__CurrentTask = Loop[task]
				ctask = __CurrentTask
				for i=1,9 do
					if PList[i]%ctask.Priority == 0 then
						ctask:Act()
						__CurrentProcess = self
					end
				end
			end
			handler()
		end
	else
		return nil, "Already Running!"
	end
end

local init = false
function multi.init(settings, realsettings)
	if settings == multi then settings = realsettings end
	if init then return _G["$multi"].multi,_G["$multi"].thread end
	init = true
	if type(settings)=="table" then
		multi.defaultSettings = settings
		if settings.priority then
			multi.mainloop = p_mainloop
		else
			multi.mainloop = mainloop
		end
		if settings.findopt then
			find_optimization = true
			multi.enableOptimization:Fire(multi, thread)
		end
	end
	return _G["$multi"].multi,_G["$multi"].thread
end

function multi:uManager()
	if self.Active then
		__CurrentProcess = self
		multi.OnPreLoad:Fire()
		self.uManager=self.uManagerRef
		multi.OnLoad:Fire()
		handler()
	end
end

function multi:uManagerRefP1()
	if self.Active then
		__CurrentProcess = self
		local Loop=self.Mainloop
		for _D=#Loop,1,-1 do
			__CurrentTask = Loop[_D]
			for P=1,9 do
				if PList[P]%__CurrentTask.Priority==0 then
					__CurrentTask:Act()
					__CurrentProcess = self
				end
			end
		end
		handler()
	end
end

function multi:uManagerRef()
	if self.Active then
		__CurrentProcess = self
		local Loop=self.Mainloop
		for _D=#Loop,1,-1 do
			__CurrentTask = Loop[_D]
			__CurrentTask:Act()
			__CurrentProcess = self
		end
		handler()
	end
end

--------
-- UTILS
--------

function table.merge(t1, t2)
	for k,v in pairs(t2) do
		if type(v) == 'table' then
			if type(t1[k] or false) == 'table' then
				table.merge(t1[k] or {}, t2[k] or {})
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end

if table.unpack and not unpack then
	unpack=table.unpack
end

multi.DestroyedObj = {
	Type = "destroyed",
}

local function uni()
	return multi.DestroyedObj
end

local function uniN() end
function multi.setType(obj,t)
	if t == multi.DestroyedObj then
		for i,v in pairs(obj) do
			obj[i] = nil
		end
		setmetatable(obj, {
			__index = function(t,k)
				return setmetatable({},{__index = uni,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni})
			end,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni
		})
	end
end
setmetatable(multi.DestroyedObj, {
	__index = function(t,k)
		return setmetatable({},{__index = uni,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni})
	end,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni
})
math.randomseed(os.time())

function multi:enableLoadDetection()
	if multi.maxSpd then return end
	-- here we are going to run a quick benchMark solo
	local temp = self:newProcessor()
	local t = os.clock()
	local stop = false
	temp:benchMark(.01):OnBench(function(time,steps)
		stop = steps
	end)
	while not stop do
		temp:uManager()
	end
	temp:Destroy()
	multi.maxSpd = stop
end

local lastVal = 0
local last_step = 0

function multi:getLoad()
	if not multi.maxSpd then multi:enableLoadDetection() end
	local val = nil
	local bench
	local bb
	self:benchMark(.01).OnBench(function(time,steps)
		bench = steps
		bb = steps
	end)
	_,timeout = multi.hold(function()
		return bench
	end,{sleep=.012})
	if timeout or not bench then
		bench = 0
		bb = 0
	end
	bench = bench^1.5
	val = math.ceil((1-(bench/(multi.maxSpd/2.2)))*100)
	if val<0 then val = 0 end
	if val > 100 then val = 100 end
	lastVal = val
	last_step = bb*100
	return val,last_step
end

function multi:setPriority(s)
	if type(s)=="number" then
		self.Priority=s
	elseif type(s)=='string' then
		if s:lower()=='core' or s:lower()=='c' then
			self.Priority=self.Priority_Core
		elseif s:lower()=="very high" or s:lower()=="vh" then
			self.Priority=self.Priority_Very_High
		elseif s:lower()=='high' or s:lower()=='h' then
			self.Priority=self.Priority_High
		elseif s:lower()=='above' or s:lower()=='a' then
			self.Priority=self.Priority_Above_Normal
		elseif s:lower()=='normal' or s:lower()=='n' then
			self.Priority=self.Priority_Normal
		elseif s:lower()=='below' or s:lower()=='b' then
			self.Priority=self.Priority_Below_Normal
		elseif s:lower()=='low' or s:lower()=='l' then
			self.Priority=self.Priority_Low
		elseif s:lower()=="very low" or s:lower()=="vl" then
			self.Priority=self.Priority_Very_Low
		elseif s:lower()=='idle' or s:lower()=='i' then
			self.Priority=self.Priority_Idle
		end
	end
	if not self.PrioritySet then
		self.defPriority = self.Priority
		self.PrioritySet = true
	end
	return self
end

function multi:ResetPriority()
	self.Priority = self.defPriority
	return self
end

function os.getOS()
	if package.config:sub(1,1)=='\\' then
		return 'windows'
	else
		return 'unix'
	end
end

if os.getOS()=='windows' then
	function os.sleep(n)
		if n > 0 then os.execute('ping -n ' .. tonumber(n+1) .. ' localhost > NUL') end
	end
else
	function os.sleep(n)
		os.execute('sleep ' .. tonumber(n))
	end
end

function multi.randomString(n)
	local str = ''
	local strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		str = str..''..strings[math.random(1,#strings)]
	end
	return str
end

function multi:getChildren()
	return self.Mainloop
end

function multi:getVersion()
	return multi.Version
end

function multi:getPlatform()
	if love then
		if love.thread then
			return "love2d"
		end
	else
		return "lanes"
	end
end

function multi:canSystemThread()
	return false
end

function multi:benchMark(sec,p,pt)
	local c = 0
	local temp=self:newLoop(function(self,t)
		if t>sec then
			if pt then
				multi.print(pt.." "..c.." Steps in "..sec.." second(s)!")
			end
			self.OnBench:Fire(sec,c)
			self:Destroy()
		else
			c=c+1
		end
	end)
	temp.OnBench = multi:newConnection()
	temp:setPriority(p or 1)
	return temp
end

function multi.Round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end
  
function multi.AlignTable(tab)
	local longest = {}
	local columns = #tab[1]
	local rows = #tab
	for i=1, columns do
		longest[i] = -math.huge
	end
	for i = 1,rows do
		for j = 1,columns do
			tab[i][j] = tostring(tab[i][j])
			if #tab[i][j]>longest[j] then
				longest[j] = #tab[i][j]
			end
		end
	end
	for i = 1,rows do
		for j = 1,columns do
			if tab[i][j]~=nil and #tab[i][j]<longest[j] then
				tab[i][j]=tab[i][j]..string.rep(" ",longest[j]-#tab[i][j])
			end
		end
	end
	local str = {}
	for i = 1,rows do
		str[#str+1] = table.concat(tab[i]," ")
	end
	return table.concat(str,"\n")
end

function multi:endTask(TID)
	for i=#self.Mainloop,1,-1 do
		if self.Mainloop[i].TID == TID then
			self.Mainloop[TID]:Destroy()
			return self
		end
	end
	return self
end

function multi:IsAnActor()
	return self.Act~=nil
end

function multi:reallocate(o,n)
	n=n or #o.Mainloop+1
	local int=self.Parent
	self:Destroy()
	self.Parent=o
	table.insert(o.Mainloop,n,self)
	self.Active=true
	return self
end

function multi.timer(func,...)
	local timer=multi:newTimer()
	timer:Start()
	args={func(...)}
	local t = timer:Get()
	timer = nil
	return t,unpack(args)
end

if os.getOS()=="windows" then
	thread.__CORES=tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
else
	thread.__CORES=tonumber(io.popen("nproc --all"):read("*n"))
end

function multi.print(...)
	if multi.defaultSettings.print then
		print(...)
	end
end

multi.GetType		=	multi.getType
multi.IsPaused		=	multi.isPaused
multi.IsActive		=	multi.isActive
multi.Reallocate	=	multi.Reallocate
multi.ConnectFinal	=	multi.connectFinal
multi.ResetTime		=	multi.SetTime
multi.IsDone		=	multi.isDone
multi.SetName		=	multi.setName

-- Special Events
local _os = os.exit

function os.exit(n)
	multi.OnExit:Fire(n or 0)
	_os(n)
end

multi.OnError=multi:newConnection()
multi.OnPreLoad = multi:newConnection()
multi.OnExit = multi:newConnection(nil,nil,true)
multi.m = {onexit = function() multi.OnExit:Fire() end}

if _VERSION >= "Lua 5.2" or jit then
	setmetatable(multi.m, {__gc = multi.m.onexit})
else
	multi.m.sentinel = newproxy(true)
	getmetatable(multi.m.sentinel).__gc = multi.m.onexit
end
local func_cache = {}
multi:newThread(function()
	thread.skip()
	if find_optimization then
		
		function thread.hold(n,opt)
			thread._Requests()
			local opt = opt or {}
			if type(opt)=="table" then
				interval = opt.interval
				if opt.cycles then
					return yield(CMD, t_holdW, opt.cycles or 1, n or dFunc, interval)
				elseif opt.sleep then
					return yield(CMD, t_holdF, opt.sleep, n or dFunc, interval)
				elseif opt.skip then
					return yield(CMD, t_skip, opt.skip or 1, nil, interval)
				end
			end
			
			if type(n) == "number" then
				thread.getRunningThread().lastSleep = clock()
				return yield(CMD, t_sleep, n or 0, nil, interval)
			elseif type(n) == "table" and n.Type == "connector" then
				local rdy = function()
					return false
				end
				n(function(a1,a2,a3,a4,a5,a6)
					rdy = function()
						if a1==nil then
							return NIL,a2,a3,a4,a5,a6
						end
						return a1,a2,a3,a4,a5,a6
					end
				end)
				return yield(CMD, t_hold, function()
					return rdy()
				end, nil, interval)
			elseif type(n) == "function" then
				local cache = string.dump(n)
				local f_str = tostring(n)
				local good = true
				for i=1,#func_cache do
					if func_cache[i][1] == cache and func_cache[i][2] ~= f_str and not func_cache[i][3] then
						multi:getOptimizationConnection():Fire("It's better to store a function to a variable than to use an anonymous function within the hold method!\n" .. debug.traceback())
						func_cache[i][3] = true
						good = false
					end
				end
				if good then
					table.insert(func_cache, {cache, f_str})
				end
				return yield(CMD, t_hold, n or dFunc, nil, interval)
			else
				error("Invalid argument passed to thread.hold(...)!")
			end
		end
		-- Add more Overrides
	end
end).OnError(print)

return multi