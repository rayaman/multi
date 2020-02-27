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
local multi = {}
local mainloopActive = false
local isRunning = false
local clock = os.clock
local thread = {}
if not _G["$multi"] then
	_G["$multi"] = {multi=multi,thread=thread}
end

multi.Version = "14.2.0"
multi.stage = "stable"
--multi.__index = multi
multi.Name = "multi.root"
multi.Mainloop = {}
multi.Garbage = {}
multi.ender = {}
multi.Children = {}
multi.Active = true
multi.Type = "mainprocess"
multi.Rest = 0
multi._type = type
multi.queue = {}
multi.clock = os.clock
multi.time = os.time
multi.LinkedPath = multi
multi.lastTime = clock()

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
	[1]="Core",
	[4]="High",
	[16]="Above Normal",
	[64]="Normal",
	[256]="Below Normal",
	[1024]="Low",
	[4096]="Idle",
}

multi.PStep = 1
multi.PList = {multi.Priority_Core,multi.Priority_High,multi.Priority_Above_Normal,multi.Priority_Normal,multi.Priority_Below_Normal,multi.Priority_Low,multi.Priority_Idle}
multi.PriorityTick=1
multi.Priority=multi.Priority_High
multi.threshold=256
multi.threstimed=.001
	
function multi.init()
	multi.NIL = {Type="NIL"}
	return _G["$multi"].multi,_G["$multi"].thread
end

-- System
function multi.Stop()
	mainloopActive=false
end

--Processor
local priorityTable = {[0]="Round-Robin",[1]="Just-Right",[2]="Top-heavy",[3]="Timed-Based-Balancer"}
local ProcessName = {[true]="SubProcessor",[false]="MainProcessor"}
function multi:getTasksDetails(t)
	if t == "string" or not t then
		str = {
			{"Type <Identifier>","Uptime","Priority","TID"}
		}
		local count = 0
		for i,v in pairs(self.Mainloop) do
			local name = v.Name or ""
			if name~="" then
				name = " <"..name..">"
			end
			count = count + 1
			table.insert(str,{v.Type:sub(1,1):upper()..v.Type:sub(2,-1)..name,multi.Round(os.clock()-v.creationTime,3),self.PriorityResolve[v.Priority],v.TID})
		end
		for v,i in pairs(multi.PausedObjects) do
			local name = v.Name or ""
			if name~="" then
				name = " <"..name..">"
			end
			count = count + 1
			table.insert(str,{v.Type:sub(1,1):upper()..v.Type:sub(2,-1)..name,multi.Round(os.clock()-v.creationTime,3),self.PriorityResolve[v.Priority],v.TID})
		end
		if count == 0 then
			table.insert(str,{"Currently no processes running!","","",""})
		end
		local s = multi.AlignTable(str)
		dat = ""
		dat2 = ""
		if multi.SystemThreads then
			for i = 1,#multi.SystemThreads do
				dat2 = dat2.."<SystemThread: "..multi.SystemThreads[i].Name.." | "..os.clock()-multi.SystemThreads[i].creationTime..">\n"
			end
		end
		local load, steps = multi:getLoad()
		if thread.__threads then
			for i=1,#thread.__threads do
				dat = dat .. "<THREAD: "..thread.__threads[i].Name.." | "..os.clock()-thread.__threads[i].creationTime..">\n"
			end
			return "Load on "..ProcessName[self.Type=="process"].."<"..(self.Name or "Unnamed")..">"..": "..multi.Round(load,2).."%\nCycles Per Second Per Task: "..steps.."\nMemory Usage: "..math.ceil(collectgarbage("count")).." KB\nThreads Running: "..#thread.__threads.."\nSystemThreads Running: "..#(multi.SystemThreads or {}).."\nPriority Scheme: "..priorityTable[multi.defaultSettings.priority or 0].."\n\n"..s.."\n\n"..dat..dat2
		else
			return "Load on "..ProcessName[self.Type=="process"].."<"..(self.Name or "Unnamed")..">"..": "..multi.Round(load,2).."%\nCycles Per Second Per Task: "..steps.."\n\nMemory Usage: "..math.ceil(collectgarbage("count")).." KB\nThreads Running: 0\nPriority Scheme: "..priorityTable[multi.defaultSettings.priority or 0].."\n\n"..s..dat2
		end
	elseif t == "t" or t == "table" then
		local load,steps = multi:getLoad()
		str = {
			ProcessName = (self.Name or "Unnamed"),
			ThreadCount = #thread.__threads,
			MemoryUsage = math.ceil(collectgarbage("count")),
			PriorityScheme = priorityTable[multi.defaultSettings.priority or 0],
			SystemLoad = multi.Round(load,2),
			CyclesPerSecondPerTask = steps,
			SystemThreadCount = multi.SystemThreads and #multi.SystemThreads or 0
		}
		str.Tasks = {}
		str.PausedTasks = {}
		str.Threads = {}
		str.Systemthreads = {}
		for i,v in pairs(self.Mainloop) do
			table.insert(str.Tasks,{Link = v, Type=v.Type,Name=v.Name,Uptime=os.clock()-v.creationTime,Priority=self.PriorityResolve[v.Priority],TID = v.TID})
		end
		for v,i in pairs(multi.PausedObjects) do
			table.insert(str.Tasks,{Link = v, Type=v.Type,Name=v.Name,Uptime=os.clock()-v.creationTime,Priority=self.PriorityResolve[v.Priority],TID = v.TID})
		end
		for i=1,#thread.__threads do
			table.insert(str.Threads,{Uptime = os.clock()-thread.__threads[i].creationTime,Name = thread.__threads[i].Name,Link = thread.__threads[i],TID = thread.__threads[i].TID})
		end
		if multi.SystemThreads then
			for i=1,#multi.SystemThreads do
				table.insert(str.Systemthreads,{Uptime = os.clock()-multi.SystemThreads[i].creationTime,Name = multi.SystemThreads[i].Name,Link = multi.SystemThreads[i],TID = multi.SystemThreads[i].count})
			end
		end
		return str
	end
end

--Helpers
function multi:Break()
	self:Pause()
	self.Active=nil
	for i=1,#self.ender do
		if self.ender[i] then
			self.ender[i](self)
		end
	end
end

function multi:OnBreak(func)
	table.insert(self.ender,func)
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
	local c=multi:newBase()
	c.Type='timemaster'
	c.timer=multi:newTimer()
	c.timer:Start()
	c.set=n
	c.link=self
	self._timer=c.timer
	function c:Act()
		if self.timer:Get()>=self.set then
			self.link:Pause()
			for i=1,#self.link.funcTM do
				self.link.funcTM[i](self.link)
			end
			
			self:Destroy()
		end
	end
	return self
end

function multi:ResolveTimer(...)
	self._timer:Pause()
	for i=1,#self.funcTMR do
		self.funcTMR[i](self,...)
	end
	self:Pause()
	return self
end

function multi:OnTimedOut(func)
	self.funcTM[#self.funcTM+1]=func
	return self
end

function multi:OnTimerResolved(func)
	self.funcTMR[#self.funcTMR+1]=func
	return self
end

-- Timer stuff done
multi.PausedObjects = {}
function multi:Pause()
	if self.Type=='mainprocess' then
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
	if self.Type=='process' or self.Type=='mainprocess' then
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
	if self.Type=='process' or self.Type=='mainprocess' then
		local c=self:getChildren()
		for i=1,#c do
			self.OnObjectDestroyed:Fire(c[i])
			c[i]:Destroy()
		end
	else
		for i=1,#self.Parent.Mainloop do
			if self.Parent.Mainloop[i]==self then
				self.Parent.OnObjectDestroyed:Fire(self)
				table.remove(self.Parent.Mainloop,i)
				self.Destroyed = true
				break
			end
		end
		multi.setType(self,multi.DestroyedObj)
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
	multi.OnObjectCreated:Fire(ref,self)
end

function multi:setName(name)
	self.Name = name
	return self
end

--Constructors [CORE]
local _tid = 0
function multi:newBase(ins)
	if not(self.Type=='mainprocess' or self.Type=='process' or self.Type=='queue') then error('Can only create an object on multi or an interface obj') return false end
	local c = {}
    if self.Type=='process' or self.Type=='queue' then
		setmetatable(c, {__index = multi}) -- setmetatable(c, {__index = multi})
	else
		setmetatable(c, {__index = multi})
	end
	c.Active=true
	c.func={}
	c.funcTM={}
	c.funcTMR={}
	c.ender={}
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
local CRef = {
	Fire = function() end
}
local ignoreconn = true
function multi:newConnection(protect,func,kill)
	local c={}
	c.callback = func
	c.Parent=self
	c.lock = false
	setmetatable(c,{__call=function(self,...)
		local t = ...
		if type(t)=="table" then
			for i,v in pairs(t) do
				if v==self then
					return self:Fire(select(2,...))
				end
			end
			return self:connect(...)
		else
			return self:connect(...)
		end
	end})
	c.Type='connector'
	c.func={}
	c.ID=0
	c.protect=protect or true
	c.connections={}
	c.fconnections={}
	c.FC=0
	function c:holdUT(n)
		local n=n or 0
		self.waiting=true
		local count=0
		local id=self:connect(function()
			count = count + 1
			if n<=count then
				self.waiting=false
			end
		end)
		repeat
			self.Parent:uManager(multi.defaultSettings)
		until self.waiting==false
		id:Destroy()
		return self
	end
	c.HoldUT=c.holdUT
	function c:fConnect(func)
		local temp=self:connect(func)
		table.insert(self.fconnections,temp)
		self.FC=self.FC+1
		return self
	end
	c.FConnect=c.fConnect
	function c:getConnection(name,ignore)
		if ignore then
			return self.connections[name] or CRef
		else
			return self.connections[name] or self
		end
	end
	function c:Lock()
		c.lock = true
	end
	function c:Unlock()
		c.lock = false
	end
	function c:Fire(...)
		local ret={}
		if self.lock then return end
		for i=#self.func,1,-1 do
			if self.protect then
				if not self.func[i] then return end
				local temp={pcall(self.func[i][1],...)}
				if temp[1] then
					table.remove(temp,1)
					table.insert(ret,temp)
				else
					multi.print(temp[2])
				end
			else
				if not self.func[i] then return end
				table.insert(ret,{self.func[i][1](...)})
			end
			if kill then
				table.remove(self.func,i)
			end
		end
		return ret
	end
	function c:Bind(t)
		self.func=t
		return self
	end
	function c:Remove()
		self.func={}
		return self
	end
	local function conn_helper(self,func,name,num)
		self.ID=self.ID+1
		if num then
			table.insert(self.func,num,{func,self.ID})
		else
			table.insert(self.func,1,{func,self.ID})
		end
		local temp = {
			Link=self.func,
			func=func,
			Type="connector_link",
			ID=self.ID,
			Parent=self,
			connect = function(s,...)
				return self:connect(...)
			end
		}
		setmetatable(temp,{__call=function(s,...)
			return self:connect(...)
		end})
		function temp:Fire(...)
			if self.Parent.lock then return end
			if self.Parent.protect then
				local t=pcall(self.func,...)
				if t then
					return t
				end
			else
				return self.func(...)
			end
		end
		function temp:Destroy()
			for i=1,#self.Link do
				if self.Link[i][2]~=nil then
					if self.Link[i][2]==self.ID then
						table.remove(self.Link,i)
						self.remove=function() end
						self.Link=nil
						self.ID=nil
						multi.setType(temp,multi.DestroyedObj)
					end
				end
			end
		end
		if name then
			self.connections[name]=temp
		end
		if self.callback then
			self.callback(temp)
		end
		return temp
	end
	function c:connect(...)--func,name,num
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
	c.Connect=c.connect
	c.GetConnection=c.getConnection
	if not(ignoreconn) then
		multi:create(c)
	end
	return c
end
multi.OnObjectCreated=multi:newConnection()
multi.OnObjectDestroyed=multi:newConnection()
multi.OnLoad = multi:newConnection(nil,nil,true)
ignoreconn = false
function multi:newProcessor(file)
	if not(self.Type=='mainprocess') then error('Can only create an interface on the multi obj') return false end
	local c = {}
	setmetatable(c, {__index = multi})
	c.Parent=self
	c.Active=true
	c.func={}
	c.Type='process'
	c.Mainloop={}
	c.Garbage={}
	c.Children={}
	c.Active=false
	c.Rest=0
	c.queue={}
	c.l=self:newLoop(function(self,dt)
		if self.link.Active then
			c:uManager()
		end
	end)
	c.l.link = c
	c.l.Type = "processor"
	function c:getController()
		return c.l
	end
	function c:Start()
		self.Active = true
		return self
	end
	function c:Resume()
		self.Active = false
		return self
	end
	function c:setName(name)
		c.l.Name = name
		return self
	end
	function c:Pause()
		if self.l then
			self.l:Pause()
		end
		return self
	end
	function c:Remove()
		if self.Type == "process" then
			self:__Destroy()
			self.l:Destroy()
		else
			self:__Destroy()
		end
	end
	function c:Destroy()
		if self == c then
			self.l:Destroy()
		else
			for i = #c.Mainloop,1,-1 do
				if c.Mainloop[i] == self then
					table.remove(c.Mainloop,i)
					break
				end
			end
		end
	end
	if file then
		self.Cself=c
		loadstring('local process=multi.Cself '..io.open(file,'rb'):read('*all'))()
	end
	self:create(c)
	return c
end
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
	self:create(c)
	return c
end

--Core Actors
function multi:newEvent(task)
	local c=self:newBase()
	c.Type='event'
	c.Task=task or function() end
	function c:Act()
		local t = {self.Task(self)}
		if t[1] then
			self:Pause()
			self.returns = t
			for _E=1,#self.func do
				self.func[_E](self)
			end
		end
	end
	function c:SetTask(func)
		self.Task=func
		return self
	end
	function c:OnEvent(func)
		table.insert(self.func,func)
		return self
	end
	self:setPriority("core")
	self:create(c)
	return c
end
function multi:newUpdater(skip)
	local c=self:newBase()
	c.Type='updater'
	c.pos=1
	c.skip=skip or 1
	function c:Act()
		if self.pos>=self.skip then
			self.pos=0
			for i=1,#self.func do
				self.func[i](self)
			end
		end
		self.pos=self.pos+1
	end
	function c:SetSkip(n)
		self.skip=n
		return self
	end
	c.OnUpdate=self.OnMainConnect
	self:create(c)
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
			for i=1,#self.func do
				self.func[i](self)
			end
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
	function c:OnRing(func)
		table.insert(self.func,func)
		return self
	end
	function c:Pause()
		count = clock()
		self.Parent.Pause(self)
		return self
	end
	self:create(c)
	return c
end
function multi:newLoop(func)
	local c=self:newBase()
	c.Type='loop'
	local start=clock()
	local funcs = {}
	if func then
		funcs={func}
	end
	function c:Act()
		for i=1,#funcs do
			funcs[i](self,clock()-start)
		end
	end
	function c:OnLoop(func)
		table.insert(funcs,func)
		return self
	end
	self:create(c)
	return c
end
function multi:newFunction(func)
	local c={}
	c.func=func
	c.Type = "mfunc"
	mt={
		__index=multi,
		__call=function(self,...)
			if self.Active then
				return self:func(...)
			end
			return nil,true
		end
	}
	c.Parent=self
	function c:Pause()
		self.Active=false
		return self
	end
	function c:Resume()
		self.Active=true
		return self
	end
	setmetatable(c,mt)
	self:create(c)
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
	c.funcE={}
	c.funcS={}
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
					for fe=1,#self.funcS do
						self.funcS[fe](self)
					end
				end
				for i=1,#self.func do
					self.func[i](self,self.pos)
				end
				self.pos=self.pos+self.count
				if self.pos-self.count==self.endAt then
					self:Pause()
					for fe=1,#self.funcE do
						self.funcE[fe](self)
					end
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
	function c:OnStart(func)
		table.insert(self.funcS,func)
		return self
	end
	function c:OnStep(func)
		table.insert(self.func,1,func)
		return self
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
		return self
	end
	function c:Break()
		self.Active=nil
		return self
	end
	function c:Update(start,reset,count,skip)
		self.start=start or self.start
		self.endAt=reset or self.endAt
		self.skip=skip or self.skip
		self.count=count or self.count
		self:Resume()
		return self
	end
	self:create(c)
	return c
end
function multi:newTLoop(func,set)
	local c=self:newBase()
	c.Type='tloop'
	c.set=set or 0
	c.timer=self:newTimer()
	c.life=0
	c:setPriority("Low")
	if func then
		c.func={func}
	end
	function c:Act()
		if self.timer:Get()>=self.set then
			self.life=self.life+1
			for i=1,#self.func do
				self.func[i](self,self.life)
			end
			self.timer:Reset()
		end
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
	function c:OnLoop(func)
		table.insert(self.func,func)
		return self
	end
	self:create(c)
	return c
end
function multi:setTimeout(func,t)
	multi:newThread(function() thread.sleep(t) func() end)
end
function multi:newTStep(start,reset,count,set)
	local c=self:newBase()
	think=1
	c.Type='tstep'
	c:setPriority("Low")
	c.start=start or 1
	local reset = reset or math.huge
	c.endAt=reset
	c.pos=start or 1
	c.skip=skip or 0
	c.count=count or 1*think
	c.funcE={}
	c.timer=clock()
	c.set=set or 1
	c.funcS={}
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
				for fe=1,#self.funcS do
					self.funcS[fe](self)
				end
			end
			for i=1,#self.func do
				self.func[i](self,self.pos)
			end
			self.pos=self.pos+self.count
			if self.pos-self.count==self.endAt then
				self:Pause()
				for fe=1,#self.funcE do
					self.funcE[fe](self)
				end
				self.pos=self.start
			end
		end
	end
	function c:OnStart(func)
		table.insert(self.funcS,func)
		return self
	end
	function c:OnStep(func)
		table.insert(self.func,func)
		return self
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
		return self
	end
	function c:Break()
		self.Active=nil
		return self
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=clock()
		self:Resume()
		return self
	end
	self:create(c)
	return c
end
local scheduledjobs = {}
local sthread
function multi:scheduleJob(time,func)
	if not sthread then
		sthread = multi:newThread("JobScheduler",function()
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

-- Threading stuff
multi.GlobalVariables={}
local dFunc = function() return true end
local dRef = {nil,nil,nil}
thread.requests = {}
function thread.request(t,cmd,...)
	thread.requests[t.thread] = {cmd,{...}}
end
function thread._Requests()
	local t = thread.requests[coroutine.running()]
	thread.requests[coroutine.running()] = nil
	if t then
		local cmd,args = t[1],t[2]
		thread[cmd](unpack(args))
	end
end
function thread.exec(func)
	func()
end
function thread.sleep(n)
	thread._Requests()
	dRef[1] = "_sleep_"
	dRef[2] = n or 0
	return coroutine.yield(dRef)
end
function thread.hold(n)
	thread._Requests()
	dRef[1] = "_hold_"
	dRef[2] = n or dFunc
	return coroutine.yield(dRef)
end
function thread.holdFor(sec,n)
	thread._Requests()
	dRef[1] = "_holdF_"
	dRef[2] = sec
	dRef[3] = n or dFunc
	return coroutine.yield(dRef)
end
function thread.holdWithin(skip,n)
	thread._Requests()
	dRef[1] = "_holdW_"
	dRef[2] = skip or 1
	dRef[3] = n or dFunc
	return coroutine.yield(dRef)
end
function thread.skip(n)
	thread._Requests()
	dRef[1] = "_skip_"
	dRef[2] = n or 1
	return coroutine.yield(dRef)
end
function thread.kill()
	dRef[1] = "_kill_"
	dRef[2] = "T_T"
	return coroutine.yield(dRef)
end
function thread.yield()
	thread._Requests()
	return thread.sleep(0)
end
function thread.isThread()
	return coroutine.running()~=nil
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
function multi.hold(func,no)
	if thread.isThread() and not(no) then
		if type(func) == "function" or type(func) == "table" then
			return thread.hold(func)
		end
		return thread.sleep(func)
	end
	local death = false
	if type(func)=="number" then
		multi:newThread("Hold_func",function()
			thread.sleep(func)
			death = true
		end)
		while not death do
			multi.scheduler:Act()
		end
	else
		local rets
		multi:newThread("Hold_func",function()
			rets = {thread.hold(func)}
			death = true
		end)
		while not death do
			multi.scheduler:Act()
		end
		return unpack(rets)
	end
end
function multi.holdFor(n,func)
	local temp
	multi:newThread(function()
		thread.sleep(n)
		temp = true
	end)
	return multi.hold(function()
		if func() then
			return func()
		elseif temp then
			return multi.NIL, "TIMEOUT"
		end
	end)
end
function thread:newFunction(func,holdme)
    return function(...)
		local rets, err
		local function wait(no) 
			if thread.isThread() and not (no) then
				return multi.hold(function()
					if err then
						return multi.NIL, err
					elseif rets then
						return unpack(rets) 
					end
				end)
			else
				while not rets and not err do
					multi.scheduler:Act()
				end
				if err then
					return nil,err
				end
				return unpack(rets)
			end
		end
		local t = multi:newThread("TempThread",func,...)
		t.OnDeath(function(self,status,...) rets = {...}  end)
		t.OnError(function(self,e) err = e end)
		if holdme then
			return wait()
		end
		local temp = {
			isTFunc = true,
			wait = wait,
			connect = function(f)
				t.OnDeath(function(self,status,...) f(...)  end) 
				t.OnError(function(self,err) f(err) end) 
			end
		}
		return temp
    end
end
function thread.run(func)
	local threaddata,t2,t3,t4,t5,t6
	local t = multi:newThread("Temp_Thread",func)
	t.OnDeath(function(self,status, r1,r2,r3,r4,r5,r6)
		threaddata,t2,t3,t4,t5,t6 = r1,r2,r3,r4,r5,r6
	end)
	return thread.hold(function()
		return threaddata,t2,t3,t4,t5,t6
	end)
end
function thread.testFor(name,_val,sym)
	thread.hold(function()
		local val = thread.get(name)~=nil
		if val then
			if sym == "==" or sym == "=" then
				return _val==val
			elseif sym == ">" then
				return _val>val
			elseif sym == "<" then
				return _val<val
			elseif sym == "<=" then
				return _val<=val
			elseif sym == ">=" then
				return _val>=val
			end
		end
	end)
	return thread.get(name)
end
function multi.print(...)
	if multi.defaultSettings.print then
		print(...)
	end
end
local initT = false
local threadCount = 0
local threadid = 0
thread.__threads = {}
local threads = thread.__threads
local Gref = _G
function multi:newThread(name,func,...)
	multi.OnLoad:Fire()
	local func = func or name
	if type(name) == "function" then
		name = "Thread#"..threadCount
	end
	local env = {}
	setmetatable(env,{
		__index = Gref,
		__newindex = function(t,k,v)
			if type(v)=="function" then
				rawset(t,k,thread:newFunction(v))
			else
				Gref[k]=v
			end
		end
	})
	setfenv(func,env)
	local c={}
	c.TempRets = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}
	c.startArgs = {...}
	c.ref={}
	c.Name=name
	c.thread=coroutine.create(func)
	c.sleep=1
	c.Type="thread"
	c.TID = threadid
	c.firstRunDone=false
	c.timer=multi:newTimer()
	c._isPaused = false
	c.returns = {}
	c.OnError = multi:newConnection(true,nil,true)
	c.OnDeath = multi:newConnection(true,nil,true)
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
	end
	function c:Resume()
		resumed = true
	end
	function c:Kill()
		thread.request(self,"kill")
	end
	c.Destroy = c.Kill
	function c.ref:send(name,val)
		ret=coroutine.yield({Name=name,Value=val})
	end
	function c.ref:get(name)
		return self.Globals[name]
	end
	function c.ref:kill()
		dRef[1] = "_kill_"
		dRef[2] = "I Was killed by You!"
		err = coroutine.yield(dRef)
		if err then
			error("Failed to kill a thread! Exiting...")
		end
	end
	function c.ref:sleep(n)
		if type(n)=="function" then
			ret=thread.hold(n)
		elseif type(n)=="number" then
			ret=thread.sleep(tonumber(n) or 0)
		else
			error("Invalid Type for sleep!")
		end
	end
	function c.ref:syncGlobals(v)
		self.Globals=v
	end
	table.insert(threads,c)
	if initT==false then
		multi.initThreads()
	end
	c.creationTime = os.clock()
	threadid = threadid + 1
	self:create(c)
	return c
end
function multi.initThreads(justThreads)
	initT = true
	multi.scheduler=multi:newLoop():setName("multi.thread")
	multi.scheduler.Type="scheduler"
	function multi.scheduler:setStep(n)
		self.skip=tonumber(n) or 24
	end
	multi.scheduler.skip=0
	local t0,t1,t2,t3,t4,t5,t6
	local r1,r2,r3,r4,r5,r6
	local ret,_
	local function CheckRets(i)
		if ret~=nil and not(threads[i].isError) then
			if not threads[i] then return end
			if not _ then
				threads[i].isError = true
				threads[i].TempRets[1] = ret
				return
			end
			threads[i].TempRets[1] = ret
			threads[i].TempRets[2] = r1
			threads[i].TempRets[3] = r2
			threads[i].TempRets[4] = r3
			threads[i].TempRets[5] = r4
			threads[i].TempRets[6] = r5
			threads[i].TempRets[7] = r6
		end
	end
	local function helper(i)
		if type(ret)=="table" then
			if ret[1]=="_kill_" then
				threads[i].OnDeath:Fire(threads[i],"killed",ret,r1,r2,r3,r4,r5,r6)
				multi.setType(threads[i],multi.DestroyedObj)
				table.remove(threads,i)
				ret = nil
			elseif ret[1]=="_sleep_" then
				threads[i].sec = ret[2]
				threads[i].time = clock()
				threads[i].task = "sleep"
				threads[i].__ready = false
				ret = nil
			elseif ret[1]=="_skip_" then
				threads[i].count = ret[2]
				threads[i].pos = 0
				threads[i].task = "skip"
				threads[i].__ready = false
				ret = nil
			elseif ret[1]=="_hold_" then
				if type(ret[2])=="table" and ret[2].Type=='connector' then
					local letsgo
					ret[2](function(...) letsgo = {...} end)
					ret[2] = function()
						if letsgo then
							return unpack(letsgo)
						end
					end
				end
				threads[i].func = ret[2]
				threads[i].task = "hold"
				threads[i].__ready = false
				ret = nil
			elseif ret[1]=="_holdF_" then
				threads[i].sec = ret[2]
				threads[i].func = ret[3]
				threads[i].task = "holdF"
				threads[i].time = clock()
				threads[i].__ready = false
				ret = nil
			elseif ret[1]=="_holdW_" then
				threads[i].count = ret[2]
				threads[i].pos = 0
				threads[i].func = ret[3]
				threads[i].task = "holdW"
				threads[i].time = clock()
				threads[i].__ready = false
				ret = nil
			end
			CheckRets(i)
		end
	end
	multi.scheduler:OnLoop(function(self)
		for i=#threads,1,-1 do
			if threads[i].isError then
				threads[i].OnError:Fire(threads[i],unpack(threads[i].TempRets))
				multi.setType(threads[i],multi.DestroyedObj)
				table.remove(threads,i)
			end
			if threads[i] and not threads[i].__started then
				if coroutine.running() ~= threads[i].thread then
					_,ret,r1,r2,r3,r4,r5,r6=coroutine.resume(threads[i].thread,unpack(threads[i].startArgs))
				end
				threads[i].__started = true
				helper(i)
			end
			if threads[i] and not _ then
				threads[i].OnError:Fire(threads[i],unpack(threads[i].TempRets))
				threads[i].isError = true
			end
			if threads[i] and coroutine.status(threads[i].thread)=="dead" then
				threads[i].OnDeath:Fire(threads[i],"ended",unpack(threads[i].TempRets or {}))
				multi.setType(threads[i],multi.DestroyedObj)
				table.remove(threads,i)
			elseif threads[i] and threads[i].task == "skip" then
				threads[i].pos = threads[i].pos + 1
				if threads[i].count==threads[i].pos then
					threads[i].task = ""
					threads[i].__ready = true
				end
			elseif threads[i] and threads[i].task == "hold" then --GOHERE
				t0,t1,t2,t3,t4,t5,t6 = threads[i].func()
				if t0 then
					if t0==multi.NIL then
						t0 = nil
					end
					threads[i].task = ""
					threads[i].__ready = true
				end
			elseif threads[i] and threads[i].task == "sleep" then
				if clock() - threads[i].time>=threads[i].sec then
					threads[i].task = ""
					threads[i].__ready = true
				end
			elseif threads[i] and threads[i].task == "holdF" then
				t0,t1,t2,t3,t4,t5,t6 = threads[i].func()
				if t0 then
					threads[i].task = ""
					threads[i].__ready = true
				elseif clock() - threads[i].time>=threads[i].sec then
					threads[i].task = ""
					threads[i].__ready = true
					t0 = nil
					t1 = "TIMEOUT"
				end
			elseif threads[i] and threads[i].task == "holdW" then
				threads[i].pos = threads[i].pos + 1
				t0,t1,t2,t3,t4,t5,t6 = threads[i].func()
				if t0 then
					threads[i].task = ""
					threads[i].__ready = true
				elseif threads[i].count==threads[i].pos then
					threads[i].task = ""
					threads[i].__ready = true
					t0 = nil
					t1 = "TIMEOUT"
				end
			end
			if threads[i] and threads[i].__ready then
				threads[i].__ready = false
				if coroutine.running() ~= threads[i].thread then
					_,ret,r1,r2,r3,r4,r5,r6=coroutine.resume(threads[i].thread,t0,t1,t2,t3,t4,t5,t6)
					CheckRets(i)
				end
			end
			helper(i)
		end
	end)
	if justThreads then
		while true do
			multi.scheduler:Act()
		end
	end
end
function multi:threadloop()
	multi.initThreads(true)
end
function multi:newService(func) -- Priority managed threads
	local c = {}
	c.Type = "service"
	c.OnError = multi:newConnection()
	c.OnStopped = multi:newConnection()
	c.OnStarted = multi:newConnection()
	local Service_Data = {}
	local active
	local time
	local p = multi.Priority_Normal
	local ap
	local task = thread.sleep
	local scheme = 1
	function c.Start()
		time = multi:newTimer()
		time:Start()
		active = true
		c:OnStarted(c,Service_Data)
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
	local th = multi:newThread(function()
		while true do
			process()
		end
	end)
	th.OnError = c.OnError -- use the threads onerror as our own
	function c.Destroy()
		th:kill()
		multi.setType(c,multi.DestroyedObj)
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
		end
		return c
	end
	function c.Stop()
		c:OnStopped(c)
		Service_Data = {}
		time:Reset()
		time:Pause()
		time = nil
		active = false
		return c
	end
	function c.Pause()
		time:Pause()
		active = false
		return c
	end
	function c.Resume()
		time:Resume()
		active = true
		return c
	end
	function c.GetUpTime()
		return time:Get()
	end
	function c:SetPriority(pri)
		if type(self)=="number" then pri = self end
		p = pri
		c.SetScheme(scheme)
	end
	multi.create(multi,c)
	return c
end
multi.Jobs = multi:newService(function(self,jobs)
	local job = table.remove(jobs,1)
	if job and job.removed==nil then
		job.func()
	end
end)
multi.Jobs.OnStarted(function(self,jobs)
	function self:newJob(func,name)
		table.insert(jobs,{
			func = func,
			name = name,
			removeJob = function(self) self.removed = true end
		})
	end
	function self:getJobs(name)
		local tab = {}
		if not name then return jobs end
		for i=1,#jobs do
			if name == jobs[i].name then
				table.insert(tab,jobs[i])
			end
		end
		return tab
	end
	function self:removeJobs(name)
		for i=1,#jobs do
			if name ~= nil and name == jobs[i].name then
				jobs[i]:removeJob()
			elseif name == nil then
				jobs[i]:removeJob()
			end
		end
	end
end)
multi.Jobs.SetPriority(multi.Priority_Normal)
multi.Jobs.Start()
-- Multi runners
function multi:lightloop()
	if not isRunning then
		local Loop=self.Mainloop
		while true do
			for _D=#Loop,1,-1 do
				if Loop[_D].Active then
					self.CID=_D
					if not protect then
						Loop[_D]:Act()
					end
				end
			end
		end
	end
end
function multi:mainloop(settings)
	multi.OnPreLoad:Fire()
	multi.defaultSettings = settings or multi.defaultSettings
	self.uManager=self.uManagerRef
	local p_c,p_h,p_an,p_n,p_bn,p_l,p_i = self.Priority_Core,self.Priority_High,self.Priority_Above_Normal,self.Priority_Normal,self.Priority_Below_Normal,self.Priority_Low,self.Priority_Idle
	local P_LB = p_i
	if not isRunning then
		local protect = false
		local priority = false
		local stopOnError = true
		local delay = 3
		if settings then
			priority = settings.priority
			if settings.auto_priority then
				priority = -1
			end
			if settings.preLoop then
				settings.preLoop(self)
			end
			if settings.stopOnError then
				stopOnError = settings.stopOnError
			end
			if settings.auto_stretch then
				p_i = p_i * settings.auto_stretch
			end
			if settings.auto_delay then
				delay = settings.auto_delay
			end
			if settings.auto_lowerbound then
				P_LB = settings.auto_lowerbound
			end
			protect = settings.protect
		end
		local t,tt = clock(),0
		isRunning=true
		local lastTime = clock()
		rawset(self,'Start',clock())
		mainloopActive = true
		local Loop=self.Mainloop
		local PS=self
		local PStep = 1
		local autoP = 0
		local solid,sRef
		local cc=0
		multi.OnLoad:Fire()
		while mainloopActive do
			if priority == 1 then
				for _D=#Loop,1,-1 do
					for P=1,7 do
						if Loop[_D] then
							if (PS.PList[P])%Loop[_D].Priority==0 then
								if Loop[_D].Active then
									self.CID=_D
									if not protect then
										Loop[_D]:Act()
									else
										local status, err=pcall(Loop[_D].Act,Loop[_D])
										if err then
											Loop[_D].error=err
											self.OnError:Fire(Loop[_D],err)
											if stopOnError then
												Loop[_D]:Destroy()
											end
										end
									end
								end
							end
						end
					end
				end
			elseif priority == 2 then
				for _D=#Loop,1,-1 do
					if Loop[_D] then
						if (PStep)%Loop[_D].Priority==0 then
							if Loop[_D].Active then
								self.CID=_D
								if not protect then
									Loop[_D]:Act()
								else
									local status, err=pcall(Loop[_D].Act,Loop[_D])
									if err then
										Loop[_D].error=err
										self.OnError:Fire(Loop[_D],err)
										if stopOnError then
											Loop[_D]:Destroy()
										end
									end
								end
							end
						end
					end
				end
				PStep=PStep+1
				if PStep==p_i then
					PStep=0
				end
			elseif priority == 3 then
				cc=cc+1
				if cc == 1000 then
					tt = clock()-t
					t = clock()
					cc=0
				end
				for _D=#Loop,1,-1 do
					if Loop[_D] then
						if Loop[_D].Priority == p_c or (Loop[_D].Priority == p_h and tt<.5) or (Loop[_D].Priority == p_an and tt<.125) or (Loop[_D].Priority == p_n and tt<.063) or (Loop[_D].Priority == p_bn and tt<.016) or (Loop[_D].Priority == p_l and tt<.003) or (Loop[_D].Priority == p_i and tt<.001) then
							if Loop[_D].Active then
								self.CID=_D
								if not protect then
									Loop[_D]:Act()
								else
									local status, err=pcall(Loop[_D].Act,Loop[_D])
									if err then
										Loop[_D].error=err
										self.OnError:Fire(Loop[_D],err)
										if stopOnError then
											Loop[_D]:Destroy()
										end
									end
								end
							end
						end
					end
				end
			elseif priority == -1 then
				for _D=#Loop,1,-1 do
					sRef = Loop[_D]
					if Loop[_D] then
						if (sRef.Priority == p_c) or PStep==0 then
							if sRef.Active then
								self.CID=_D
								if not protect then
									if sRef.solid then
										sRef:Act()
										solid = true
									else
										time = multi.timer(sRef.Act,sRef)
										sRef.solid = true
										solid = false
									end
									if Loop[_D] and not solid then
										if time == 0 then
											Loop[_D].Priority = p_c
										else
											Loop[_D].Priority = P_LB
										end
									end
								else
									if Loop[_D].solid then
										Loop[_D]:Act()
										solid = true
									else
										time, status, err=multi.timer(pcall,Loop[_D].Act,Loop[_D])
										Loop[_D].solid = true
										solid = false
									end
									if Loop[_D] and not solid then
										if time == 0 then
											Loop[_D].Priority = p_c
										else
											Loop[_D].Priority = P_LB
										end
									end
									if err then
										Loop[_D].error=err
										self.OnError:Fire(Loop[_D],err)
										if stopOnError then
											Loop[_D]:Destroy()
										end
									end
								end
							end
						end
					end
				end
				PStep=PStep+1
				if PStep>p_i then
					PStep=0
					if clock()-lastTime>delay then
						lastTime = clock()
						for i = 1,#Loop do
							Loop[i]:ResetPriority()
						end
					end
				end
			else
				for _D=#Loop,1,-1 do
					if Loop[_D] then
						if Loop[_D].Active then
							self.CID=_D
							if not protect then
								Loop[_D]:Act()
							else
								local status, err=pcall(Loop[_D].Act,Loop[_D])
								if err then
									Loop[_D].error=err
									self.OnError:Fire(Loop[_D],err)
									if stopOnError then
										Loop[_D]:Destroy()
									end
								end
							end
						end
					end
				end
			end
		end
	else
		return "Already Running!"
	end
end
function multi:uManager(settings)
	multi.OnPreLoad:Fire()
	multi.defaultSettings = settings or multi.defaultSettings
	self.t,self.tt = clock(),0
	if settings then
		priority = settings.priority
		if settings.auto_priority then
			priority = -1
		end
		if settings.preLoop then
			settings.preLoop(self)
		end
		if settings.stopOnError then
			stopOnError = settings.stopOnError
		end
		multi.defaultSettings.p_i = self.Priority_Idle
		if settings.auto_stretch then
			multi.defaultSettings.p_i = settings.auto_stretch*self.Priority_Idle
		end
		multi.defaultSettings.delay = settings.auto_delay or 3
		multi.defaultSettings.auto_lowerbound = settings.auto_lowerbound or self.Priority_Idle
		protect = settings.protect
	end
	multi.OnLoad:Fire()
	self.uManager=self.uManagerRef
end
function multi:uManagerRef(settings)
	if self.Active then
		local Loop=self.Mainloop
		local PS=self
		if multi.defaultSettings.priority==1 then
			for _D=#Loop,1,-1 do
				for P=1,7 do
					if Loop[_D] then
						if (PS.PList[P])%Loop[_D].Priority==0 then
							if Loop[_D].Active then
								self.CID=_D
								if not multi.defaultSettings.protect then
									Loop[_D]:Act()
								else
									local status, err=pcall(Loop[_D].Act,Loop[_D])
									if err then
										Loop[_D].error=err
										self.OnError:Fire(Loop[_D],err)
										if multi.defaultSettings.stopOnError then
											Loop[_D]:Destroy()
										end
									end
								end
							end
						end
					end
				end
			end
		elseif multi.defaultSettings.priority==2 then
			for _D=#Loop,1,-1 do
				if Loop[_D] then
					if (PS.PStep)%Loop[_D].Priority==0 then
						if Loop[_D].Active then
							self.CID=_D
							if not multi.defaultSettings.protect then
								Loop[_D]:Act()
							else
								local status, err=pcall(Loop[_D].Act,Loop[_D])
								if err then
									Loop[_D].error=err
									self.OnError:Fire(Loop[_D],err)
									if multi.defaultSettings.stopOnError then
										Loop[_D]:Destroy()
									end
								end
							end
						end
					end
				end
			end
			PS.PStep=PS.PStep+1
			if PS.PStep>self.Priority_Idle then
				PS.PStep=0
			end
		elseif priority == 3 then
			self.tt = clock()-self.t
			self.t = clock()
			for _D=#Loop,1,-1 do
				if Loop[_D] then
					if Loop[_D].Priority == self.Priority_Core or (Loop[_D].Priority == self.Priority_High and tt<.5) or (Loop[_D].Priority == self.Priority_Above_Normal and tt<.125) or (Loop[_D].Priority == self.Priority_Normal and tt<.063) or (Loop[_D].Priority == self.Priority_Below_Normal and tt<.016) or (Loop[_D].Priority == self.Priority_Low and tt<.003) or (Loop[_D].Priority == self.Priority_Idle and tt<.001) then
						if Loop[_D].Active then
							self.CID=_D
							if not protect then
								Loop[_D]:Act()
							else
								local status, err=pcall(Loop[_D].Act,Loop[_D])
								if err then
									Loop[_D].error=err
									self.OnError:Fire(Loop[_D],err)
									if multi.defaultSettings.stopOnError then
										Loop[_D]:Destroy()
									end
								end
							end
						end
					end
				end
			end
		elseif priority == -1 then
			for _D=#Loop,1,-1 do
				local sRef = Loop[_D]
				if Loop[_D] then
					if (sRef.Priority == self.Priority_Core) or PStep==0 then
						if sRef.Active then
							self.CID=_D
							if not protect then
								if sRef.solid then
									sRef:Act()
									solid = true
								else
									time = multi.timer(sRef.Act,sRef)
									sRef.solid = true
									solid = false
								end
								if Loop[_D] and not solid then
									if time == 0 then
										Loop[_D].Priority = self.Priority_Core
									else
										Loop[_D].Priority = multi.defaultSettings.auto_lowerbound
									end
								end
							else
								if Loop[_D].solid then
									Loop[_D]:Act()
									solid = true
								else
									time, status, err=multi.timer(pcall,Loop[_D].Act,Loop[_D])
									Loop[_D].solid = true
									solid = false
								end
								if Loop[_D] and not solid then
									if time == 0 then
										Loop[_D].Priority = self.Priority_Core
									else
										Loop[_D].Priority = multi.defaultSettings.auto_lowerbound
									end
								end
								if err then
									Loop[_D].error=err
									self.OnError:Fire(Loop[_D],err)
									if multi.defaultSettings.stopOnError then
										Loop[_D]:Destroy()
									end
								end
							end
						end
					end
				end
			end
			self.PStep=self.PStep+1
			if self.PStep>multi.defaultSettings.p_i then
				self.PStep=0
				if clock()-self.lastTime>multi.defaultSettings.delay then
					self.lastTime = clock()
					for i = 1,#Loop do
						Loop[i]:ResetPriority()
					end
				end
			end
		else
			for _D=#Loop,1,-1 do
				if Loop[_D] then
					if Loop[_D].Active then
						self.CID=_D
						if not multi.defaultSettings.protect then
							Loop[_D]:Act()
						else
							local status, err=pcall(Loop[_D].Act,Loop[_D])
							if err then
								Loop[_D].error=err
								self.OnError:Fire(Loop[_D],err)
							end
						end
					end
				end
			end
		end
	end
end
require("multi.utils").init(multi,thread)
return multi
