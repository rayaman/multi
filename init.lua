--[[
MIT License

Copyright (c) 2023 Ryan Ward

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
local processes = {}
local find_optimization = false
local threadManager
local __CurrentConnectionThread

multi.unpack = table.unpack or unpack
multi.pack = table.pack or function(...) return {...} end

if table.unpack then unpack = table.unpack end

-- Types

multi.DestroyedObj = {
	Type = "DESTROYED",
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

multi.DESTROYED	= multi.DestroyedObj

-- I don't like modifying the global namespace, so I prepend a "$"
if not _G["$multi"] then
	_G["$multi"] = {multi = multi, thread = thread}
end

local types = {}
function multi.registerType(typ, p)
	if multi["$"..typ:upper():gsub("_","")] then return typ end
	multi["$"..typ:upper():gsub("_","")] = typ
	table.insert(types, {typ, p or typ})
	return typ
end

function multi.hasType(typ)
	if multi["$"..typ:upper():gsub("_","")] then 
		return multi["$"..typ:upper():gsub("_","")] 
	end
end

function multi.getTypes()
	return types
end

multi.Version = "16.0.1"
multi.Name = "root"
multi.NIL = {Type="NIL"}
local NIL = multi.NIL
multi.Mainloop = {}
multi.Children = {}
multi.Active = true
multi.Type = multi.registerType("rootprocess")
multi.LinkedPath = multi
multi.TIMEOUT = multi.registerType("TIMEOUT", "timeouts")
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

local pack = multi.pack

--Processor
local priorityTable = {[false]="Disabled",[true]="Enabled"}
local ProcessName = {"SubProcessor","MainProcessor"}
local globalThreads = {}

function multi:getProcessors()
	return processes
end

function multi:isType(type)
	return self.Type == type
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

function multi.setClock(c)
	clock = c
end

function multi.ForEach(tab,func)
	for i=1,#tab do func(tab[i]) end
end

function multi.randomString(n)
	local str = ''
	local strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		str = str..''..strings[math.random(1,#strings)]
	end
	return str
end

function multi.isMulitObj(obj)
	if type(obj)=="table" then
		if obj.Type ~= nil then
			return multi.hasType(obj.Type) ~= nil
		end
	end
	return false
end

function multi.forwardConnection(src, dest)
	if multi.isMulitObj(src) and multi.isMulitObj(dest) then
		src(function(...)
			dest:Fire(...)
		end)
	else
		multi.error("Cannot forward non-connection objects")
	end
end

local optimization_stats = {}
local ignoreconn = true
local empty_func = function() end
function multi:newConnection(protect,func,kill)
	local processor = self
	local c={}
	local lock = false
	local fast = {}
	c.__connectionAdded = function() end
	c.rawadd = false
	c.Parent = self

	setmetatable(c,{
		__call=function(self,...)
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
	__unm = function(obj) -- -obj Reverses the order of connected events
		local conns = obj:Bind({})
		for i = #conns, 1, -1 do
			obj.rawadd = true
			obj(conns[i])
			obj.rawadd = false
		end
		return obj
	end,
	__mod = function(obj1, obj2) -- %
		local cn = self:newConnection()
		if type(obj1) == "function" and type(obj2) == "table" then
			obj2(function(...)
				cn:Fire(obj1(...))
			end)
		elseif type(obj1) == "table" and type(obj2) == "function" then
			local conns = obj1:Bind({})
			for i = 1,#conns do
				obj1(function(...)
					conns[i](obj2(...))
				end)
			end
			obj1.__connectionAdded = function(conn, func)
				obj1:Unconnect(conn)
				obj1.rawadd = true
				obj1:Connect(function(...)
					func(obj2(...))
				end)
				obj1.rawadd = false
			end
			return obj1
		else
			error("Invalid mod!", type(obj1), type(obj2),"Expected function, connection(table)")
		end
		return cn
	end,
	__div = function(obj1, obj2) -- /
		local cn = self:newConnection()
		local ref
		if type(obj1) == "function" and type(obj2) == "table" then
			obj2(function(...)
				local args = {obj1(...)}
				if args[1] then
					cn:Fire(multi.unpack(args))
				end
			end)
		else
			multi.error("Invalid divide!", type(obj1), type(obj2),"Expected function/connection(table)")
		end
		return cn
	end,
	__concat = function(obj1, obj2) -- ..
		local cn = self:newConnection()
		local ref
		if type(obj1) == "function" and type(obj2) == "table" then
			cn(function(...)
				if obj1(...) then
					obj2:Fire(...)
				end
			end)
			cn.__connectionAdded = function(conn, func)
				cn:Unconnect(conn)
				obj2:Connect(func)
			end
		elseif type(obj1) == "table" and type(obj2) == "function" then
			ref = cn(function(...)
				obj1:Fire(...)
				obj2(...)
			end)
			cn.__connectionAdded = function()
				cn.rawadd = true
				cn:Unconnect(ref)
				ref = cn(function(...)
					if obj2(...) then
						obj1:Fire(...)
					end
				end)
			end
			return obj1
		elseif type(obj1) == "table" and type(obj2) == "table" then
			-- 
		else
			error("Invalid concat!", type(obj1), type(obj2),"Expected function/connection(table), connection(table)/function")
		end
		return cn
	end,
	__add = function(c1,c2) -- Or
		local cn = self:newConnection()
		c1(function(...)
			cn:Fire(...)
		end)
		c2(function(...)
			cn:Fire(...)
		end)
		return cn
	end,
	__mul = function(c1,c2) -- And
		local cn = self:newConnection()
		local ref1, ref2
		if c1.__hasInstances == nil then
			cn.__hasInstances = {2}
			cn.__count = {0}
		else
			cn.__hasInstances = c1.__hasInstances
			cn.__hasInstances[1] = cn.__hasInstances[1] + 1
			cn.__count = c1.__count
		end

		ref1 = c1(function(...)
			cn.__count[1] = cn.__count[1] + 1
			c1:Lock(ref1)
			if cn.__count[1] == cn.__hasInstances[1] then
				cn:Fire(...)
				cn.__count[1] = 0
				c1:Unlock(ref1)
				c2:Unlock(ref2)
			end
		end)

		ref2 = c2(function(...)
			cn.__count[1] = cn.__count[1] + 1
			c2:Lock(ref2)
			if cn.__count[1] == cn.__hasInstances[1] then
				cn:Fire(...)
				cn.__count[1] = 0
				c1:Unlock(ref1)
				c2:Unlock(ref2)
			end
		end)
		return cn
	end})

	c.Type=multi.registerType("connector", "connections")
	c.func={}
	c.ID=0
	local protect=protect or false
	local connections={}
	c.FC=0

	function c:hasConnections()
		return #fast~=0
	end

	function c:Lock(conn)
		if conn and not conn.lock then
			conn.lock = function() end
			for i = 1, #fast do
				if fast[conn.ref] == fast[i] then
					fast[i] = conn.lock
					return self
				end
			end
			return self
		end
		lock = true
		return self
	end

	function c:Unlock(conn)
		if conn and conn.lock then
			for i = 1, #fast do
				if conn.lock == fast[i] then
					fast[i] = fast[conn.ref]
					return self
				end
			end
			return self
		end
		lock = false
		return self
	end

	if protect then
		function c:Fire(...)
			if lock then return end
			local kills = {}
			for i=1,#fast do
				local suc, err = pcall(fast[i], ...)
				if not suc then
					multi.error(err)
				end
				if kill then
					table.insert(kills,i)
					processor:newTask(function()
						for _, k in pairs(kills) do
                            table.remove(kills, _)
							table.remove(fast, k)
						end
					end)
				end
			end
		end
	end

	function c:getConnections()
		return fast
	end

	function c:getConnection(name, ignore)
		return fast[name] or function() multi:warning("") end
	end

	function c:Unconnect(conn)
		for i = 1, #fast do
			if fast[conn.ref] == fast[i] then
				table.remove(self)
				return table.remove(fast, i), i
			end
		end
	end

	function c:fastMode() return self end
	
	if kill then
		local kills = {}
		function c:Fire(...)
			if lock then return end
			for i=1,#fast do
				fast[i](...)
				if kill then
					table.insert(kills,i)
					processor:newTask(function()
						for _, k in pairs(kills) do
                            table.remove(kills, _)
							table.remove(fast, k)
						end
					end)
				end
			end
		end
	else
		function c:Fire(...)
			if lock then return end
			for i=1,#fast do
				fast[i](...)
			end
		end
	end

	function c:Connect(func, name)
		local th 
		if thread.getRunningThread then
			th = thread.getRunningThread()
		end
		if th then
			local fref = func
			func = function(...)
				__CurrentConnectionThread = th
				fref(...)
				__CurrentConnectionThread = nil
			end
		end
		table.insert(fast, func)
		if name then 
			fast[name] = func 
		else 
			fast["Conn_"..multi.randomString(12)] = func
		end
		local temp = {fast = true}
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
		temp.ref = multi.randomString(24)
		fast[temp.ref] = func
		temp.name = name
		if self.rawadd then
			self.rawadd = false
		else
			table.insert(self,true)
			self.__connectionAdded(temp, func)
		end
		return temp
	end

	function c:Bind(t)
		local temp = fast
		fast=t
		return temp
	end

	function c:Get()
		return fast
	end

	function c:Remove()
		local temp = fast
		fast={}
		return temp
	end

	function c:Hold()
		local rets = {multi.hold(self)}
		return unpack(rets)
	end

	c.connect=c.Connect
	c.GetConnection=c.getConnection
	c.HasConnections = c.hasConnections
	c.GetConnection = c.getConnection

	if func then
		c = c .. func
	end

	if not(ignoreconn) then
		if not self then return c end
		self:create(c)
	end

	return c
end

-- Used with ISO Threads
local function isolateFunction(func, env)
    if setfenv then
        return setfenv(func, env)
    else
        local env = env or {}
        local dmp = string.dump(func)
        return load(dmp,"IsolatedThread_PesudoThreading", "bt", env)
    end
end

multi.isolateFunction = isolateFunction

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
	c.Type=multi.registerType("timemaster")
	c.timer=self:newTimer()
	c.timer:Start()
	c.set=n
	c.link=self
	c.OnTimedOut = self:newConnection()
	c.OnTimerResolved = self:newConnection()
	self._timer=c.timer
	function c:Act()
		if self.timer:Get()>=self.set then
			self.link:Pause()
			self.OnTimedOut:Fire(self.link)
			self:Destroy()
			return true
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
	if self.Type==multi.registerType("rootprocess") then
		multi.print("You cannot pause the main process. Doing so will stop all methods and freeze your program! However if you still want to use multi:_Pause()")
	else
		self.Active=false
		self._Act = self.Act
		self.Act = empty_func
	end
	return self
end

function multi:Resume()
	if self.Type==multi.registerType("process", "processes") or self.Type==multi.registerType("rootprocess") then
		self.Active=true
		local c=self:getChildren()
		for i=1,#c do
			c[i]:Resume()
		end
	else
		if self.Active==false then
			self.Act = self._Act
			self.Active=true
		end
	end
	return self
end

function multi:Destroy()
	if self.Type==multi.registerType("process", "processes") or self.Type==multi.registerType("rootprocess") then
		local c=self:getChildren()
		for i=1,#c do
			self.OnObjectDestroyed:Fire(c[i], self)
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
				self.Parent.OnObjectDestroyed:Fire(self, self.Parent)
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
	ref.UID = "U"..multi.randomString(12)
	self.OnObjectCreated:Fire(ref, self)
	return self
end

function multi:setName(name)
	self.Name = name
	return self
end

--Constructors [CORE]
local _tid = 0
function multi:newBase(ins)
	if not(self.Type==multi.registerType("rootprocess") or self.Type==multi.registerType("process", "processes")) then multi.error('Can only create an object on multi or an interface obj') return false end
	local c = {}
	if self.Type==multi.registerType("process", "processes") then
		setmetatable(c, {__index = multi})
	else
		setmetatable(c, {__index = multi})
	end
	c.Active=true
	c.func={}
	c.funcTM={}
	c.funcTMR={}
	c.OnBreak = self:newConnection()
	c.OnPriorityChanged = self:newConnection()
	c.TID = _tid
	c.Act=function() end
	c.Parent=self
	c.creationTime = clock()

	function c:Pause()
		c.Parent.Pause(self)
		return self
	end

	function c:Resume()
		c.Parent.Resume(self)
		return self
	end
	
	if ins then
		table.insert(self.Mainloop,ins,c)
	else
		table.insert(self.Mainloop,c)
	end
	_tid = _tid + 1
	return c
end

function multi:newTimeout(timeout)
	local c={}
	c.Type = multi.registerType(multi.TIMEOUT, "timeouts")
	return function(self) self:Destroy() return c end % self:newAlarm(timeout).OnRing
end

function multi:newTimer()
	local c={}
	c.Type=multi.registerType("timer", "timers")
	local time=0
	local count=0
	local paused=false
	function c:Start()
		time=clock()
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
		time=clock()-time
		return self
	end
	self:create(c)
	return c
end

--Core Actors
function multi:newEvent(task, func)
	local c=self:newBase()
	c.Type=multi.registerType("event", "events")
	local task = task or function() end
	function c:Act()
		local t = task(self)
		if t then
			self:Pause()
			self.returns = t
			self.OnEvent:Fire(self)
			return true
		end
	end
	function c:SetTask(func)
		task=func
		return self
	end
	c.OnEvent = self:newConnection()
	if func then
		c.OnEvent(func)
	end
	self:setPriority("core")
	c:setName(c.Type)
	self:create(c)
	return c
end

function multi:newUpdater(skip, func)
	local c=self:newBase()
	c.Type=multi.registerType("updater", "updaters")
	local pos = 1
	local skip = skip or 1
	function c:Act()
		if pos >= skip then
			pos = 0
			self.OnUpdate:Fire(self)
			return true
		end
		pos = pos+1
	end
	function c:SetSkip(n)
		skip=n
		return self
	end
	c.OnUpdate = self:newConnection()
	c:setName(c.Type)
	if func then
		c.OnUpdate(func)
	end
	self:create(c)
	return c
end

function multi:newAlarm(set, func)
	local c=self:newBase()
	c.Type=multi.registerType("alarm", "alarms")
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
			return true
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
	c.OnRing = self:newConnection()
	function c:Pause()
		count = clock()
		self.Parent.Pause(self)
		return self
	end
	if func then
		c.OnRing(func)
	end
	c:setName(c.Type)
	self:create(c)
	return c
end

function multi:newLoop(func, notime)
	local c=self:newBase()
	c.Type = multi.registerType("loop", "loops")
	local start=clock()
	if notime then
		function c:Act()
			self.OnLoop:Fire(self)
			return true
		end
	else
		function c:Act()
			self.OnLoop:Fire(self,clock()-start)
			return true
		end
	end
	
	c.OnLoop = self:newConnection()

	if func then
		c.OnLoop(func)
	end
	
	self:create(c)
	c:setName(c.Type)
	return c
end

function multi:newStep(start,reset,count,skip)
	local c=self:newBase()
	think=1
	c.Type=multi.registerType("step", "steps")
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
		return true
	end
	c.Reset=c.Resume
	c.OnStart = self:newConnection()
	c.OnStep = self:newConnection()
	c.OnEnd = self:newConnection()
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
	c:setName(c.Type)
	self:create(c)
	return c
end

function multi:newTLoop(func, set)
	local c=self:newBase()
	c.Type=multi.registerType("tloop", "tloops")
	c.set=set or 0
	c.timer=self:newTimer()
	c.life=0
	c:setPriority("Low")

	function c:Act()
		if self.timer:Get() >= self.set then
			self.life=self.life+1
			self.timer:Reset()
			self.OnLoop:Fire(self, self.life)
			return true
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

	c.OnLoop = self:newConnection()

	if func then
		c.OnLoop(func)
	end

	c:setName(c.Type)

	self:create(c)

	return c
end

function multi:setTimeout(func, t)
	thread:newThread("TimeoutThread", function() thread.sleep(t) func() end)
end

function multi:newTStep(start,reset,count,set)
	local c=self:newStep(start,reset,count)
	c.Type=multi.registerType("tstep", "tsteps")
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
			return true
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
	c:setName(c.Type)
	self:create(c)
	return c
end

multi.tasks = {}

function multi:newTask(func)
	self.tasks[#self.tasks + 1] = func
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

function multi:setCurrentProcess()
	__CurrentProcess = self
end

function multi:setCurrentTask()
	__CurrentTask = self
end

function multi:getName()
	return self.Name
end

function multi:getFullName()
	return self.Name
end

local sandcount = 1

function multi:newProcessor(name, nothread, priority)
	local c = {}
	setmetatable(c,{__index = multi})
	local name = name or "Processor_" .. sandcount
	sandcount = sandcount + 1
	c.Mainloop = {}
	c.Type = multi.registerType("process", "processes")
	local Active =  nothread or false
	local task_delay = 0
	c.Name = name or ""
	c.tasks = {}
	c.threads = {}
	c.startme = {}
	c.parent = self
	c.OnObjectCreated = self:newConnection()

	local boost = 1
	local handler

	if priority then
		handler = c:createPriorityHandler(c)
	else
		handler = c:createHandler(c)
	end

	if not nothread then -- Don't create a loop if we are triggering this manually
		c.process = self:newLoop(function()
			if Active then
				c:uManager(true)
				handler()
			end
		end)
		c.process.__ignore = true
		c.process.isProcessThread = true
		c.process.PID = sandcount
		c.OnError = c.process.OnError
	else
		c.OnError = self:newConnection()
	end

	c.OnError(multi.error)

	function c:getHandler()
		return handler
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

	function c:newThread(name, func,...)
		return thread.newThread(c, name, func, ...)
	end

	function c:newFunction(func, holdme)
		return thread:newFunctionBase(function(...)
			return c:newThread("Process Threaded Function Handler", func, ...)
		end, holdme)()
	end

	function c:boost(count)
		boost = count or 1
		if boost > 1 then
			self.run = function()
				if not Active then return end
				for i=1,boost do
					c:uManager(true)
					handler()
				end
				return c
			end
		else
			self.run = function()
				if not Active then return end
				c:uManager(true)
				handler()
				return c
			end
		end
	end

	function c.run()
		if not Active then return end
		c:uManager(true)
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

	function c:setTaskDelay(delay)
		if type(delay) == "function" then
			task_delay = delay
		else
			task_delay = tonumber(delay) or 0
		end
	end

	c:newThread("Task Handler", function()
		local self = multi:getCurrentProcess()
		local function task_holder()
			return #self.tasks > 0
		end
		while true do
			if #self.tasks > 0 then
				table.remove(self.tasks,1)()
			else
				thread.hold(task_holder)
			end
			if task_delay~=0 then
				thread.hold(task_delay)
			end
		end
	end).OnError(multi.error)
	
	table.insert(processes,c)
	self:create(c)
	return c
end

function multi.hold(func,opt)
	if thread.isThread() then return thread.hold(func, opt) end
	local proc = multi.getCurrentTask()
	if proc then
		proc:Pause()
	end
	local rets
	thread:newThread("Hold_func",function()
		rets = {thread.hold(func,opt)}
	end)
	while rets == nil do
		multi:uManager()
	end
	if proc then
		proc:Resume()
	end
	return multi.unpack(rets)
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

function multi:getRunners()
	local tasks = {}
	for i,v in pairs(self.Mainloop) do
		if not v.__ignore then
			tasks[#tasks+1] = v
		end
	end
	return tasks
end

function thread.request(t,cmd,...)
	thread.requests[t.thread] = {cmd, multi.pack(...)}
end

function thread.defer(func)
	local th = thread.getRunningThread()
	local conn = (th.OnError + th.OnDeath)
	conn(function()
		func(th)
	end)
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
		thread[cmd](multi.unpack(args))
	end
end

function thread.exec(func)
	func()
end

function thread.sleep(n)
	thread._Requests()
	thread.getRunningThread().lastSleep = clock()
	return yield(CMD, t_sleep, n or 1)
end

local function conn_test(conn)
	local ready = false
	local args
	local func = function(...)
		ready = true
		args = multi.pack(...)
	end

	local ref = conn(func)
	return function()
		if ready then
			conn:Unconnect(ref)
			if #args==0 then
				return multi.NIL
			else
				return multi.unpack(args)
			end
		end
	end
end

function thread.chain(...)
	local args = select("#",...)
	for i=1,args do
		thread.hold(select(i,...))
	end
end

function thread.hold(n, opt)
	thread._Requests()
	local opt = opt or {}
	if type(opt)=="table" and type(n) == "function" then
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
	elseif type(n) == "table" and n.Type == multi.registerType("connector", "connections") then
		return yield(CMD, t_hold, conn_test(n), nil, interval)
	elseif type(n) == "table" and n.Hold ~= nil then
		return n:Hold(opt)
	elseif type(n) == "function" then
		return yield(CMD, t_hold, n, nil, interval)
	else
		multi.error("Invalid argument passed to thread.hold(...) ".. type(n) .. "!")
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
	multi.error("thread killed!")
end

function thread.yield()
	thread._Requests()
	return yield(CMD, t_yield)
end

function thread.isThread()
	local a,b = running()
	if b then
		-- We are dealing with luajit compat or 5.2+
		return not(b)
	else
		return a~=nil
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
	local returns = multi.pack(...)
	local rets = {}
	local ind = 0
	for i=#returns,1,-1 do
		if returns[i] then
			ind = i
			break
		end
	end
	return multi.unpack(returns,1,ind)
end

function thread.pushStatus(...)
	local t = __CurrentConnectionThread or thread.getRunningThread()
	t.statusconnector:Fire(...)
end

function thread:newFunctionBase(generator, holdme, TYPE)
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
						local g = rets
						rets = nil
						return cleanReturns((g[1] or multi.NIL),g[2],g[3],g[4],g[5],g[6],g[7],g[8],g[9],g[10],g[11],g[12],g[13],g[14],g[15],g[16])
					end
				end)
			else
				while not rets and not err do
					multi:uManager()
				end
				local g = rets
				rets = nil
				if err then
					return nil,err
				end
				return cleanReturns(g[1],g[2],g[3],g[4],g[5],g[6],g[7],g[8],g[9],g[10],g[11],g[12],g[13],g[14],g[15],g[16])
			end
		end
		tfunc.__call = function(th,...)
			if th.Active == false then 
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
			t.OnDeath(function(...) rets = multi.pack(...) end)
			t.OnError(function(self,e) err = e end)
			if holdme then
				return wait()
			end
			local temp = {
				OnStatus = multi:getCurrentProcess():newConnection(true),
				OnError = multi:getCurrentProcess():newConnection(true),
				OnReturn = multi:getCurrentProcess():newConnection(true),
				isTFunc = true,
				wait = wait,
				getReturns = function()
					return multi.unpack(rets)
				end,
				connect = function(f)
					local tempConn = multi:getCurrentProcess():newConnection(true)
					t.OnDeath(function(...) if f then f(...) else tempConn:Fire(...) end end) 
					t.OnError(function(self,err) if f then f(nil,err) else tempConn:Fire(nil,err) end end)
					return tempConn
				end
			}
			t.OnDeath(function(...) temp.OnReturn:Fire(...) end) 
			t.OnError(function(self,err) temp.OnError:Fire(err) temp.OnError(multi.error) end)
			t.linkedFunction = temp
			t.statusconnector = temp.OnStatus
			return temp
		end
		setmetatable(tfunc, tfunc)
		tfunc.Type = TYPE or multi.registerType("function", "functions")
		return tfunc
	end
end

function thread:newFunction(func, holdme)
	return thread:newFunctionBase(function(...)
		return thread:newThread("Free Threaded Function Handler", func, ...)
	end, holdme)()
end

function thread:newProcessor(name, nothread, priority)
	-- Inactive proxy proc
	local process = multi:getCurrentProcess()
	local proc = process:newProcessor(name, true)
	local thread_proc = process:newProcessor(name).Start()
	local Active = true

	local handler
	if priority then
		handler = thread_proc:createPriorityHandler(c)
	else
		handler = thread_proc:createHandler(c)
	end
	
	function proc:getThreads()
		return thread_proc.threads
	end

	function proc:getFullName()
		return thread_proc.parent:getFullName() .. "." .. self.Name
	end

	function proc:getName()
		return thread_proc.Name
	end

	function proc:isActive()
		return Active
	end

	function proc:newThread(name, func, ...)
		return thread.newThread(thread_proc, name, func, ...)
	end

	function proc:newFunction(func, holdme)
		return thread:newFunctionBase(function(...)
			return thread_proc:newThread("TProc Threaded Function Handler", func, ...)
		end, holdme)()
	end

	function proc.Start()
		Active = true
		return proc
	end

	function proc.Stop()
		Active = false
		return proc
	end

	function proc:Destroy()
		Active = false
		thread_proc:Destroy()
	end
	
	proc.OnObjectCreated(function(obj)
		if not obj.Act then return end
		multi.print("Converting "..obj.Type.." to thread!")
		thread_proc:newThread(function()
			obj.reallocate = empty_func
			while true do
				thread.hold(function() return Active end)
				obj:Act()
			end
		end)
	end)

	process:create(proc)
	
	return proc
end

-- A cross version way to set enviroments, not the same as fenv though
function multi.setEnv(func,env)
	local f = string.dump(func)
	local chunk = load(f, "env", "bt", env)
	return chunk
end

function thread:newThread(name, func, ...)
	multi.OnLoad:Fire() -- This was done incase a threaded function was called before mainloop/uManager was called
	if type(name) == "function" then
		func = name
		name = "UnnamedThread_"..multi.randomString(16)
	end
	local c={nil,nil,nil,nil,nil,nil,nil}
	c.TempRets = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}
	c.startArgs = multi.pack(...)
	c.ref={}
	c.Name=name
	c.thread=create(func)
	c.sleep=1
	c.Type = multi.registerType("thread", "threads")
	c.TID = threadid
	c.firstRunDone=false
	c._isPaused = false
	c.returns = {}
	c.isError = false

	if self.Type == multi.registerType("process", "processes") then
		c.OnError = self:newConnection(true,nil,true)
		c.OnDeath = self:newConnection(true,nil,true)
	else
		c.OnError = threadManager:newConnection(true,nil,true)
		c.OnDeath = threadManager:newConnection(true,nil,true)
	end

	c.OnError(multi.error)

	function c:getName()
		return c.Name
	end

	function c:isPaused()
		return self._isPaused
	end

	local resumed = false
	function c:Pause()
		if not self._isPaused then
			thread.request(self, "exec", function()
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
		thread.request(self, "kill")
		return self
	end

	function c:Sleep(n)
		thread.request(self, "exec", function()
			thread.sleep(n)
			resumed = false
		end)
		return self
	end
	
	function c:Hold(n,opt)
		thread.request(self, "exec", function()
			thread.hold(n, opt)
			resumed = false
		end)
		return self
	end

	c.Destroy = c.Kill
	if thread.isThread() then
		if self.Type == multi.registerType("process", "processes") then
			table.insert(self.startme, c)
		else
			table.insert(threadManager.startme, c)
		end
	else
		if self.Type == multi.registerType("process", "processes") then
			table.insert(self.startme, c)
		else
			table.insert(threadManager.startme, c)
		end
	end
	
	globalThreads[c] = multi
	threadid = threadid + 1
	if self.Type == multi.registerType("process", "processes") then
		self:create(c)
	else
		threadManager:create(c)
	end
	c.creationTime = clock()
	return c
end

function thread:newISOThread(name, func, env, ...)
	local func = func or name
	local env = env or {}
	if not env.thread then
		env.thread = thread
	end
	if not env.multi then
		env.multi = multi
	end
	if type(name) == "function" then
		name = "Thread#"..threadCount
	end
	local func = isolateFunction(func, env)
	return thread:newThread(name, func, ...)
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
	["normal"] = function(thd,ref) end,
	["running"] = function(thd,ref) end,
	["dead"] = function(thd,ref,task,i,th)
		if ref.__processed then table.remove(th,i) return end
		if _ then
			ref.OnDeath:Fire(ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16)
		else
			ref.OnError:Fire(ref,ret,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16)
			multi.error(ref, ret)
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
		_=nil r1=nil r2=nil r3=nil r4=nil r5=nil r6=nil r7=nil r8=nil r9=nil r10=nil r11=nil r12=nil r13=nil r14=nil r15=nil r16=nil
		ref.__processed = true
	end,
}

function multi:createHandler()
	local threads, startme = self.threads, self.startme
	return coroutine.wrap(function()
		local temp_start
		while true do
			while #startme>0 do
				temp_start = table.remove(startme)
				_, ret, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16 = resume(temp_start.thread, multi.unpack(temp_start.startArgs))
				co_status[status(temp_start.thread)](temp_start.thread, temp_start, t_none, nil, threads)
				table.insert(threads, temp_start)
				yield()
			end
			for i=#threads,1,-1 do
				ref = threads[i]
				if ref then
					task = ref.task
					thd = ref.thread
					ready = ref.__ready
					co_status[status(thd)](thd, ref, task, i, threads)
				end
				yield()
			end
			yield()
		end
	end)
end

function multi:createPriorityHandler()
	local threads, startme = self.threads, self.startme
	return coroutine.wrap(function()
		local temp_start
		while true do
			while #startme>0 do
				temp_start = table.remove(startme)
				_, ret, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16 = resume(temp_start.thread, multi.unpack(temp_start.startArgs))
				co_status[status(temp_start.thread)](temp_start.thread, temp_start, t_none, nil, threads)
				table.insert(threads, temp_start)
			end
			for i=#threads,1,-1 do
				ref = threads[i]
				if ref then
					task = ref.task
					thd = ref.thread
					ready = ref.__ready
					co_status[status(thd)](thd, ref, task, i, threads)
				end
			end
			yield()
		end
	end)
end

function multi:newService(func) -- Priority managed threads
	local c = {}
	c.Type = multi.registerType("service", "services")
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
			c:OnStarted(c, Service_Data)
		end
		return c
	end

	local function process()
		thread.hold(function()
			return active
		end)
		func(c, Service_Data)
		task(ap)
		return c
	end

	local th = thread:newThread("Service_Handler",function()
		while true do
			process()
		end
	end)

	th.OnError = c.OnError -- use the threads onerror as our own
	th.OnError(multi.error)
	
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

	self:create(c)

	return c
end

-- Multi runners
function multi:mainloopRef()
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
				if ctask then ctask:Act() end
				__CurrentProcess = self
			end
		end
	else
		return nil, "Already Running!"
	end
end

multi.mainloop = multi.mainloopRef

function multi:p_mainloop()
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
		end
	else
		return nil, "Already Running!"
	end
end

local function doOpt()
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
		elseif type(n) == "table" and n.Type == multi.registerType("connector", "connections") then
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
			multi.error("Invalid argument passed to thread.hold(...)!")
		end
	end
end

local init = false
multi.settingsHook = multi:newConnection()
function multi.init(settings, realsettings)
	if settings == multi then settings = realsettings end
	
	if type(settings)=="table" then

		multi.defaultSettings = settings

		if settings.priority then
			multi.mainloop = multi.p_mainloop
		else
			multi.mainloop = multi.mainloopRef
		end

		if not init then
			
			if settings.findopt then
				find_optimization = true
				doOpt()
				multi.enableOptimization:Fire(multi, thread)
			end

			if settings.debugging then
				require("multi.integration.debugManager")
			end

			multi.settingsHook:Fire(settings)
		end
	end
	init = true
	return _G["$multi"].multi,_G["$multi"].thread
end

function multi:uManager()
	if self.Active then
		__CurrentProcess = self
		multi.OnPreLoad:Fire()
		self.uManager=self.uManagerRef
		multi.OnLoad:Fire()
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
	end
end

--------
-- UTILS
--------

function multi.isTimeout(res)
	if type(res) == "table" then
		return res.Type == multi.TIMEOUT
	end
	return res == multi.TIMEOUT
end

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

math.randomseed(os.time())

function multi:enableLoadDetection()
	if multi.maxSpd then return end
	-- here we are going to run a quick benchMark solo
	local temp = self:newProcessor()
	local t = clock()
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
	if not self:IsAnActor() or self.Type == multi.registerType("process", "processes") then return end
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
		self.OnPriorityChanged:Fire(self, self.Priority)
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
	temp.OnBench = self:newConnection()
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

function multi:reallocate(processor, index)
	index=index or #processor.Mainloop+1
	local int=self.Parent
	self.Parent=processor
	if index then
		table.insert(processor.Mainloop, index, self)
	else
		table.insert(processor.Mainloop, self)
	end
	self.Active=true
	return self
end

function multi.timer(func,...)
	local timer=multi:newTimer()
	timer:Start()
	args={func(...)}
	local t = timer:Get()
	timer = nil
	return t,multi.unpack(args)
end

if os.getOS()=="windows" then
	thread.__CORES=tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
else
	thread.__CORES=tonumber(io.popen("nproc --all"):read("*n"))
end

function multi.print(...)
	if multi.defaultSettings.print then
		local t = {}
		for i,v in ipairs(multi.pack(...)) do t[#t+1] = tostring(v) end
		io.write("\x1b[94mINFO:\x1b[0m " .. table.concat(t," ") .. "\n")
	end
end

function multi.warn(...)
	if multi.defaultSettings.warn then
		local t = {}
		for i,v in ipairs(multi.pack(...)) do t[#t+1] = tostring(v) end
		io.write("\x1b[93mWARNING:\x1b[0m " .. table.concat(t," ") .. "\n")
	end
end

function multi.debug(...)
	if multi.defaultSettings.debugging then
		local t = {}
		for i,v in ipairs(multi.pack(...)) do t[#t+1] = tostring(v) end
		io.write("\x1b[97mDEBUG:\x1b[0m " .. table.concat(t," ") 
		.. "\n" .. multi:getCurrentProcess():getFullName() 
		.. " " .. (multi:getCurrentTask() and multi:getCurrentTask().Type or "Unknown Type") .. "\n" .. 
		((coroutine.running()) and debug.traceback((coroutine.running())) or debug.traceback()) .. "\n")
	end
end

function multi.error(self, err)
	if type(err) == "bool" then crash = err end
	if type(self) == "string" then err = self end
	local name = debug.getinfo(2).name
	if name then
		io.write("\x1b[91mERROR:\x1b[0m " .. err .. " " .. name .."\n")
	else
		io.write("\x1b[91mERROR:\x1b[0m " .. err .. " ?\n")
	end
	if multi.defaultSettings.error then
		error("^^^ " .. multi:getCurrentProcess():getFullName() .. " " .. multi:getCurrentTask().Type .. "\n" .. 
		((coroutine.running()) and debug.traceback((coroutine.running())) or debug.traceback()) .. "\n")
		os.exit(1)
	end
end

function multi.success(...)
	local t = {}
	for i,v in ipairs(multi.pack(...)) do t[#t+1] = tostring(v) end
	io.write("\x1b[92mSUCCESS:\x1b[0m " .. table.concat(t," ") .. "\n")
end

-- Old things for compatability
multi.GetType		=	multi.getType
multi.IsPaused		=	multi.isPaused
multi.IsActive		=	multi.isActive
multi.Reallocate	=	multi.reallocate
multi.ConnectFinal	=	multi.connectFinal
multi.ResetTime		=	multi.SetTime
multi.setTime		=	multi.SetTime
multi.IsDone		=	multi.isDone
multi.SetName		=	multi.setName

-- Special Events
local _os = os.exit

function os.exit(n)
	multi.OnExit:Fire(n or 0)
	_os(n)
end

multi.OnObjectCreated=multi:newConnection()
ignoreconn = false
multi.OnObjectDestroyed=multi:newConnection()
multi.OnLoad = multi:newConnection(nil,nil,true)

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

multi.OnError=multi:newConnection()
multi.OnPreLoad = multi:newConnection()
multi.OnExit = multi:newConnection(nil,nil,true)
multi.m = {onexit = function() os.exit() end}

if _VERSION >= "Lua 5.2" or jit then
	setmetatable(multi.m, {__gc = multi.m.onexit})
else
	multi.m.sentinel = newproxy(true)
	getmetatable(multi.m.sentinel).__gc = multi.m.onexit
end

threadManager = multi:newProcessor("Global_Thread_Manager", nil, true).Start()
threadManager.tasks = multi.tasks -- The main multi interface is a bit different.

function multi:setTaskDelay(delay)
	threadManager:setTaskDelay(delay)
end

function multi:getThreadManagerProcess()
	return threadManager
end

function multi:getHandler()
	return threadManager:getHandler()
end

return multi