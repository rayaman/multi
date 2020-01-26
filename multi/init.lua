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
local bin = pcall(require,"bin")
local multi = {}
local clock = os.clock
local thread = {}
if not _G["$multi"] then
	_G["$multi"] = {multi=multi,thread=thread}
end
multi.Version = "14.0.0"
multi._VERSION = "14.0.0"
multi.stage = "stable"
multi.__index = multi
multi.Name = "multi.root"
multi.Mainloop = {}
multi.Garbage = {}
multi.ender = {}
multi.Children = {}
multi.Active = true
multi.fps = 60
multi.Type = "mainprocess"
multi.Rest = 0
multi._type = type
multi.Jobs = {}
multi.queue = {}
multi.jobUS = 2
multi.clock = os.clock
multi.time = os.time
multi.LinkedPath = multi
multi.lastTime = clock()
math.randomseed(os.time())
local mainloopActive = false
local isRunning = false
local next
local ncount = 0
multi.defaultSettings = {
	priority = 0,
	protect = false,
}
--Do not change these ever...Any other number will not work (Unless you are using enablePriority2())
multi.Priority_Core = 1
multi.Priority_High = 4
multi.Priority_Above_Normal = 16
multi.Priority_Normal = 64
multi.Priority_Below_Normal = 256
multi.Priority_Low = 1024
multi.Priority_Idle = 4096
thread.Priority_Core = 3
thread.Priority_High = 2
thread.Priority_Above_Normal = 1
thread.Priority_Normal = 0
thread.Priority_Below_Normal = -1
thread.Priority_Low = -2
thread.Priority_Idle = -3
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
--^^^^
multi.PriorityTick=1 -- Between 1, 2 and 4
multi.Priority=multi.Priority_High
multi.threshold=256
multi.threstimed=.001
function multi.init()
	multi.NIL = {Type="NIL"}
	return _G["$multi"].multi,_G["$multi"].thread
end
function multi.queuefinal(self)
	self:Destroy()
	if self.Parent.Mainloop[#self.Parent.Mainloop] then
		if self.Parent.Mainloop[#self.Parent.Mainloop].Type=="alarm" then
			self.Parent.Mainloop[#self.Parent.Mainloop]:Reset()
			self.Parent.Mainloop[#self.Parent.Mainloop].Active=true
		else
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end
	else
		for i=1,#self.Parent.funcE do
			self.Parent.funcE[i](self)
		end
		self.Parent:Remove()
	end
end
if table.unpack and not unpack then
	unpack=table.unpack
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
function multi:setThrestimed(n)
	self.deltaTarget=n or .1
end
function multi:enableLoadDetection()
	if multi.maxSpd then return end
	-- here we are going to run a quick benchMark solo
	local temp = multi:newProcessor()
	temp:Start()
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
local MaxLoad = nil
function multi:setLoad(n)
	MaxLoad = n
end
local busy = false
local lastVal = 0
local bb = 0
function multi:getLoad()
	if not multi.maxSpd then multi:enableLoadDetection() end
	if busy then return lastVal end
	local val = nil
	if thread.isThread() then
		local bench
		multi:benchMark(.01):OnBench(function(time,steps)
			bench = steps
			bb = steps
		end)
		thread.hold(function()
			return bench
		end)
		bench = bench^1.5
		val = math.ceil((1-(bench/(multi.maxSpd/2.2)))*100)
	else
		busy = true
		local bench
		multi:benchMark(.01):OnBench(function(time,steps)
			bench = steps
			bb = steps
		end)
		while not bench do
			multi:uManager()
		end
		bench = bench^1.5
		val = math.ceil((1-(bench/(multi.maxSpd/2.2)))*100)
		busy = false
	end
	if val<0 then val = 0 end
	if val > 100 then val = 100 end
	lastVal = val
	return val,bb*100
end
function multi:setDomainName(name)
	self[name]={}
end
function multi:linkDomain(name)
	return self[name]
end
function multi:_Pause()
	self.Active=false
end
function multi:setPriority(s)
	if type(s)==number then
		self.Priority=s
	elseif type(s)=='string' then
		if s:lower()=='core' or s:lower()=='c' then
			self.Priority=self.Priority_Core
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
		elseif s:lower()=='idle' or s:lower()=='i' then
			self.Priority=self.Priority_Idle
		end
		self.solid = true
	end
	if not self.PrioritySet then
		self.defPriority = self.Priority
		self.PrioritySet = true
	end
end
function multi:ResetPriority()
	self.Priority = self.defPriority
end
-- System
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
function multi:getParentProcess()
	return self.Mainloop[self.CID]
end
multi.GetParentProcess=multi.getParentProcess
function multi.Stop()
	mainloopActive=false
end
function multi:isHeld()
	return self.held
end
multi.important={}
multi.IsHeld=multi.isHeld
function multi.executeFunction(name,...)
	if type(_G[name])=='function' then
		_G[name](...)
	else
		multi.print('Error: Not a function')
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
--Processor
function multi:getError()
	if self.error then
		return self.error
	end
end
function multi:benchMark(sec,p,pt)
	local c = 0
	local temp=self:newLoop(function(self,t)
		if t>sec then
			if pt then
				multi.print(pt.." "..c.." Steps in "..sec.." second(s)!")
			end
			self.tt(sec,c)
			self:Destroy()
		else
			c=c+1
		end
	end)
	temp:setPriority(p or 1)
	function temp:OnBench(func)
		self.tt=func
	end
	self.tt=function() end
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
function multi:endTask(TID)
	self.Mainloop[TID]:Destroy()
end
function multi.startFPSMonitior()
	if not multi.runFPS then
		multi.doFPS(s)
		multi.runFPS=true
	end
end
function multi.doFPS(s)
	multi:benchMark(1):OnBench(doFPS)
	if s then
		multi.fps=s
	end
end
--Helpers
function multi.timer(func,...)
	local timer=multi:newTimer()
	timer:Start()
	args={func(...)}
	local t = timer:Get()
	timer = nil
	return t,unpack(args)
end
function multi:IsAnActor()
	return self.Act~=nil
end
function multi:OnMainConnect(func)
	table.insert(self.func,func)
	return self
end
function multi:reallocate(o,n)
	n=n or #o.Mainloop+1
	local int=self.Parent
	self:Destroy()
	self.Parent=o
	table.insert(o.Mainloop,n,self)
	self.Active=true
end
multi.Reallocate=multi.Reallocate
function multi:setJobSpeed(n)
	self.jobUS=n
end
function multi:hasJobs()
	return #self.Jobs>0,#self.Jobs
end
function multi:getJobs()
	return #self.Jobs
end
function multi:removeJob(name)
	local count = 0
	for i=#self.Jobs,1,-1 do
		if self.Jobs[i][2]==name then
			table.remove(self.Jobs,i)
			count = count + 1
		end
	end
	return count
end
function multi:FreeMainEvent()
	self.func={}
end
function multi:connectFinal(func)
	if self.Type=='event' then
		self:OnEvent(func)
	elseif self.Type=='alarm' then
		self:OnRing(func)
	elseif self.Type=='step' or self.Type=='tstep' then
		self:OnEnd(func)
	else
		multi.print("Warning!!! "..self.Type.." doesn't contain a Final Connection State! Use "..self.Type..":Break(func) to trigger it's final event!")
		self:OnBreak(func)
	end
end
multi.ConnectFinal=multi.connectFinal
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
multi.IsPaused=multi.isPaused
function multi:isActive()
	return self.Active
end
multi.IsActive=multi.isActive
function multi:getType()
	return self.Type
end
multi.GetType=multi.getType
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
multi.ResetTime=multi.SetTime
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
		self.Active=false
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
multi.IsDone=multi.isDone
function multi:create(ref)
	multi.OnObjectCreated:Fire(ref,self)
end
function multi:setName(name)
	self.Name = name
	return self
end
multi.SetName = multi.setName
--Constructors [CORE]
local _tid = 0
function multi:newBase(ins)
	if not(self.Type=='mainprocess' or self.Type=='process' or self.Type=='queue') then error('Can only create an object on multi or an interface obj') return false end
	local c = {}
    if self.Type=='process' or self.Type=='queue' then
		setmetatable(c, self.Parent)
	else
		setmetatable(c, self)
	end
	c.Active=true
	c.func={}
	c.funcTM={}
	c.funcTMR={}
	c.ender={}
	c.TID = _tid
	c.important={}
	c.Act=function() end
	c.Parent=self
	c.held=false
	c.creationTime = os.clock()
	if ins then
		table.insert(self.Mainloop,ins,c)
	else
		table.insert(self.Mainloop,c)
	end
	_tid = _tid + 1
	return c
end
function multi:newProcessor(file)
	if not(self.Type=='mainprocess') then error('Can only create an interface on the multi obj') return false end
	local c = {}
	setmetatable(c, self)
	c.Parent=self
	c.Active=true
	c.func={}
	c.Type='process'
	c.Mainloop={}
	c.Garbage={}
	c.Children={}
	c.Active=false
	c.Rest=0
	c.Jobs={}
	c.queue={}
	c.jobUS=2
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
	-- c.__Destroy = self.Destroy
	-- c.Destroy = c.Remove
	self:create(c)
--~ 	c:IngoreObject()
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
	function c:tofile(path)
		local m=bin.new()
		count=count+self:Get()
		m:addBlock(self.Type)
		m:addBlock(count)
		m:tofile(path)
		return self
	end
	self:create(c)
	return c
end
function multi:newConnector()
	local c = {Type = "connector"}
	return c
end
local CRef = {
	Fire = function() end
}
function multi:newConnection(protect,func)
	local c={}
	c.callback = func
	c.Parent=self
	c.lock = false
	setmetatable(c,{__call=function(self,...)
		local t = ...
		if type(t)=="table" and t.Type ~= nil then
			return self:Fire(args,select(2,...))
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
			ID=self.ID,
			Parent=self,
			Fire=function(self,...)
				if self.Parent.lock then return end
--~ 				if self.Parent.FC>0 then
--~ 					for i=1,#self.Parent.FC do
--~ 						self.Parent.FC[i]:Fire(...)
--~ 					end
--~ 				end
				if self.Parent.protect then
					local t=pcall(self.func,...)
					if t then
						return t
					end
				else
					return self.func(...)
				end
			end,
			Remove=function(self)
				for i=1,#self.Link do
					if self.Link[i][2]~=nil then
						if self.Link[i][2]==self.ID then
							table.remove(self.Link,i)
							self.remove=function() end
							self.Link=nil
							self.ID=nil
							return true
						end
					end
				end
			end,
		}
		temp.Destroy=temp.Remove
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
			conn_helper(self,tab[1],tab[2],tab[3])
		end
	end
	c.Connect=c.connect
	c.GetConnection=c.getConnection
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:tofile(path)
		return self
	end
	return c
end
multi.OnObjectCreated=multi:newConnection()
multi.OnObjectDestroyed=multi:newConnection()
function multi:newJob(func,name)
	if not(self.Type=='mainprocess' or self.Type=='process') then error('Can only create an object on multi or an interface obj') return false end
	local c = {}
    if self.Type=='process' then
		setmetatable(c, self.Parent)
	else
		setmetatable(c, self)
	end
	c.Active=true
	c.func={}
	c.Parent=self
	c.Type='job'
	c.trigfunc=func or function() end
	function c:Act()
		self:trigfunc(self)
	end
	table.insert(self.Jobs,{c,name})
	if self.JobRunner==nil then
		self.JobRunner=self:newAlarm(self.jobUS):setName("multi.jobHandler")
		self.JobRunner:OnRing(function(self)
			if #self.Parent.Jobs>0 then
				if self.Parent.Jobs[1] then
					self.Parent.Jobs[1][1]:Act()
					table.remove(self.Parent.Jobs,1)
				end
			end
			self:Reset(self.Parent.jobUS)
		end)
	end
end
function multi.nextStep(func)
	ncount = ncount+1
	if not next then
		next = {func}
	else
		next[#next+1] = func
	end
end
multi.OnPreLoad=multi:newConnection()
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
	local start=self.clock()
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
function multi:newTrigger(func)
	local c={}
	c.Type='trigger'
	c.trigfunc=func or function() end
	function c:Fire(...)
		self:trigfunc(...)
		return self
	end
	self:create(c)
	return c
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
	c.timer=self.clock()
	c.set=set or 1
	c.funcS={}
	function c:Update(start,reset,count,set)
		self.start=start or self.start
		self.pos=self.start
		self.endAt=reset or self.endAt
		self.set=set or self.set
		self.count=count or self.count or 1
		self.timer=self.clock()
		self:Resume()
		return self
	end
	function c:Act()
		if self.clock()-self.timer>=self.set then
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
		self.timer=self.clock()
		self:Resume()
		return self
	end
	self:create(c)
	return c
end
function multi:newTimeStamper()
	local c=self:newUpdater(self.Priority_Idle)
	c:OnUpdate(function()
		c:Run()
	end)
	local feb = 28
	local leap = tonumber(os.date("%Y"))%4==0 and (tonumber(os.date("%Y"))%100~=0 or tonumber(os.date("%Y"))%400==0)
	if leap then
		feb = 29
	end
	local dInM = {
		["01"] = 31,
		["02"] = feb,
		["03"] = 31,
		["04"] = 30,
		["05"] = 31,
		["06"] = 30,
		["07"] = 31, -- This is dumb, why do we still follow this double 31 days!?
		["08"] = 31,
		["09"] = 30,
		["10"] = 31,
		["11"] = 30,
		["12"] = 31,
	}
	c.Type='timestamper'
	c:setPriority("Idle")
	c.hour = {}
	c.minute = {}
	c.second = {}
	c.time = {}
	c.day = {}
	c.month = {}
	c.year = {}
	function c:Run()
		for i=1,#self.hour do
			if self.hour[i][1]==os.date("%H") and self.hour[i][3] then
				self.hour[i][2](self)
				self.hour[i][3]=false
			elseif self.hour[i][1]~=os.date("%H") and not self.hour[i][3] then
				self.hour[i][3]=true
			end
		end
		for i=1,#self.minute do
			if self.minute[i][1]==os.date("%M") and self.minute[i][3] then
				self.minute[i][2](self)
				self.minute[i][3]=false
			elseif self.minute[i][1]~=os.date("%M") and not self.minute[i][3] then
				self.minute[i][3]=true
			end
		end
		for i=1,#self.second do
			if self.second[i][1]==os.date("%S") and self.second[i][3] then
				self.second[i][2](self)
				self.second[i][3]=false
			elseif self.second[i][1]~=os.date("%S") and not self.second[i][3] then
				self.second[i][3]=true
			end
		end
		for i=1,#self.day do
			if type(self.day[i][1])=="string" then
				if self.day[i][1]==os.date("%a") and self.day[i][3] then
					self.day[i][2](self)
					self.day[i][3]=false
				elseif self.day[i][1]~=os.date("%a") and not self.day[i][3] then
					self.day[i][3]=true
				end
			else
				local dday = self.day[i][1]
				if dday < 0 then
					dday = dInM[os.date("%m")]+(dday+1)
				end
				if string.format("%02d",dday)==os.date("%d") and self.day[i][3] then
					self.day[i][2](self)
					self.day[i][3]=false
				elseif string.format("%02d",dday)~=os.date("%d") and not self.day[i][3] then
					self.day[i][3]=true
				end
			end
		end
		for i=1,#self.month do
			if self.month[i][1]==os.date("%m") and self.month[i][3] then
				self.month[i][2](self)
				self.month[i][3]=false
			elseif self.month[i][1]~=os.date("%m") and not self.month[i][3] then
				self.month[i][3]=true
			end
		end
		for i=1,#self.time do
			if self.time[i][1]==os.date("%X") and self.time[i][3] then
				self.time[i][2](self)
				self.time[i][3]=false
			elseif self.time[i][1]~=os.date("%X") and not self.time[i][3] then
				self.time[i][3]=true
			end
		end
		for i=1,#self.year do
			if self.year[i][1]==os.date("%y") and self.year[i][3] then
				self.year[i][2](self)
				self.year[i][3]=false
			elseif self.year[i][1]~=os.date("%y") and not self.year[i][3] then
				self.year[i][3]=true
			end
		end
	end
	function c:OnTime(hour,minute,second,func)
		if type(hour)=="number" then
			self.time[#self.time+1]={string.format("%02d:%02d:%02d",hour,minute,second),func,true}
		else
			self.time[#self.time+1]={hour,minute,true}
		end
		return self
	end
	function c:OnHour(hour,func)
		self.hour[#self.hour+1]={string.format("%02d",hour),func,true}
		return self
	end
	function c:OnMinute(minute,func)
		self.minute[#self.minute+1]={string.format("%02d",minute),func,true}
		return self
	end
	function c:OnSecond(second,func)
		self.second[#self.second+1]={string.format("%02d",second),func,true}
		return self
	end
	function c:OnDay(day,func)
		self.day[#self.day+1]={day,func,true}
		return self
	end
	function c:OnMonth(month,func)
		self.month[#self.month+1]={string.format("%02d",month),func,true}
		return self
	end
	function c:OnYear(year,func)
		self.year[#self.year+1]={string.format("%02d",year),func,true}
		return self
	end
	self:create(c)
	return c
end
-- Threading stuff
multi.GlobalVariables={}
if os.getOS()=="windows" then
	thread.__CORES=tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
else
	thread.__CORES=tonumber(io.popen("nproc --all"):read("*n"))
end
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
	coroutine.yield({"_sleep_",n or 0})
end
function thread.hold(n)
	thread._Requests()
	return coroutine.yield({"_hold_",n or function() return true end})
end
function thread.holdFor(sec,n)
	thread._Requests()
	return coroutine.yield({"_holdF_", sec, n or function() return true end})
end
function thread.holdWithin(skip,n)
	thread._Requests()
	return coroutine.yield({"_holdW_", skip, n or function() return true end})
end
function thread.skip(n)
	thread._Requests()
	if not n then n = 1 elseif n<1 then n = 1 end
	coroutine.yield({"_skip_",n})
end
function thread.kill()
	coroutine.yield({"_kill_",":)"})
end
function thread.yield()
	thread._Requests()
	coroutine.yield({"_sleep_",0})
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
function multi.hold(func)
	if thread.isThread() then
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
function thread:newFunction(func)
    local c = {Type = "tfunc"}
    c.__call = function(self,...)
		local rets, err
		local function wait() 
			if thread.isThread() then
				return thread.hold(function()
					if err then
						return multi.NIL, err
					elseif rets then
						return unpack(rets) 
					end
				end)
			else
				while not rets do
					multi.scheduler:Act()
				end
				return unpack(rets)
			end
		end
		local t = multi:newThread("TempThread",func,...)
		t.OnDeath(function(self,status,...) rets = {...}  end)
		t.OnError(function(self,e) err = e end)
		return  {
			isTFunc = true,
			wait = wait,
			connect = function(f) 
				t.OnDeath(function(self,status,...) f(...) end) 
				t.OnError(function(self,err) f(self, err) end) 
			end
		}
    end
    setmetatable(c,c)
    return c
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
	c.OnError = multi:newConnection()
	c.OnDeath = multi:newConnection()
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
		err=coroutine.yield({"_kill_"})
		if err then
			error("Failed to kill a thread! Exiting...")
		end
	end
	function c.ref:sleep(n)
		if type(n)=="function" then
			ret=coroutine.yield({"_hold_",n})
		elseif type(n)=="number" then
			n = tonumber(n) or 0
			ret=coroutine.yield({"_sleep_",n})
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
	local function helper(i)
		if type(ret)=="table" then
			if ret[1]=="_kill_" then
				threads[i].OnDeath:Fire(threads[i],"killed",ret,r1,r2,r3,r4,r5,r6)
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
		end
	end
	multi.scheduler:OnLoop(function(self)
		for i=#threads,1,-1 do
			if not threads[i].__started then
				_,ret,r1,r2,r3,r4,r5,r6=coroutine.resume(threads[i].thread,unpack(threads[i].startArgs))
				threads[i].__started = true
				helper(i)
			end
			if not _ then
				threads[i].OnError:Fire(threads[i],ret)
			end
			if threads[i] and coroutine.status(threads[i].thread)=="dead" then
				threads[i].OnDeath:Fire(threads[i],"ended",ret,r1,r2,r3,r4,r5,r6)
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
				_,ret,r1,r2,r3,r4,r5,r6=coroutine.resume(threads[i].thread,t0,t1,t2,t3,t4,t5,t6)
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
multi.OnError=multi:newConnection()
function multi:newThreadedProcess(name)
	local c = {}
	local holding = false
	local kill = false
	setmetatable(c, multi)
	function c:newBase(ins)
		local ct = {}
		ct.Active=true
		ct.func={}
		ct.ender={}
		ct.Act=function() end
		ct.Parent=self
		ct.held=false
		ct.ref=self.ref
		table.insert(self.Mainloop,ct)
		return ct
	end
	c.Parent=self
	c.Active=true
	c.func={}
	c.Type='threadedprocess'
	c.Mainloop={}
	c.Garbage={}
	c.Children={}
	c.Active=true
	c.Rest=0
	c.updaterate=.01
	c.restRate=.1
	c.Jobs={}
	c.queue={}
	c.jobUS=2
	c.rest=false
	function c:getController()
		return nil
	end
	function c:Start()
		self.rest=false
		return self
	end
	function c:Resume()
		self.rest=false
		return self
	end
	function c:Pause()
		self.rest=true
		return self
	end
	function c:Remove()
		self.ref:kill()
		return self
	end
	function c:Kill()
		kill = true
		return self
	end
	function c:Sleep(n)
		holding = true
		if type(n)=="number" then
			multi:newAlarm(n):OnRing(function(a)
				holding = false
				a:Destroy()
			end):setName("multi.TPSleep")
		elseif type(n)=="function" then
			multi:newEvent(n):OnEvent(function(e)
				holding = false
				e:Destroy()
			end):setName("multi.TPHold")
		end
		return self
	end
	c.Hold=c.Sleep
	multi:newThread(name,function(ref)
		while true do
			thread.hold(function()
				return not(holding)
			end)
			c:uManager()
		end
	end)
	return c
end
function multi:newHyperThreadedProcess(name)
	if not name then error("All threads must have a name!") end
	local c = {}
	setmetatable(c, multi)
	local ind = 0
	local holding = true
	local kill = false
	function c:newBase(ins)
		local ct = {}
		ct.Active=true
		ct.func={}
		ct.ender={}
		ct.Act=function() end
		ct.Parent=self
		ct.held=false
		ct.ref=self.ref
		ind = ind + 1
		multi:newThread("Proc <"..name.."> #"..ind,function()
			while true do
				thread.hold(function()
					return not(holding)
				end)
				if kill then
					err=coroutine.yield({"_kill_"})
					if err then
						error("Failed to kill a thread! Exiting...")
					end
				end
				ct:Act()
			end
		end)
		return ct
	end
	c.Parent=self
	c.Active=true
	c.func={}
	c.Type='hyperthreadedprocess'
	c.Mainloop={}
	c.Garbage={}
	c.Children={}
	c.Active=true
	c.Rest=0
	c.updaterate=.01
	c.restRate=.1
	c.Jobs={}
	c.queue={}
	c.jobUS=2
	c.rest=false
	function c:getController()
		return nil
	end
	function c:Start()
		holding = false
		return self
	end
	function c:Resume()
		holding = false
		return self
	end
	function c:Pause()
		holding = true
		return self
	end
	function c:Remove()
		self.ref:kill()
		return self
	end
	function c:Kill()
		kill = true
		return self
	end
	function c:Sleep(b)
		holding = true
		if type(b)=="number" then
			local t = os.clock()
			multi:newAlarm(b):OnRing(function(a)
				holding = false
				a:Destroy()
			end):setName("multi.HTPSleep")
		elseif type(b)=="function" then
			multi:newEvent(b):OnEvent(function(e)
				holding = false
				e:Destroy()
			end):setName("multi.HTPHold")
		end
		return self
	end
	c.Hold=c.Sleep
	return c
end
-- Multi runners
function multi:mainloop(settings)
	multi.defaultSettings = settings or multi.defaultSettings
	self.uManager=self.uManagerRef
	multi.OnPreLoad:Fire()
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
		while mainloopActive do
			if next then
				local DD = table.remove(next,1)
				while DD do
					DD()
					DD = table.remove(next,1)
				end
			end
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
	self.uManager=self.uManagerRef
end
function multi:uManagerRef(settings)
	if self.Active then
		if next then
			local DD = table.remove(next,1)
			while DD do
				DD()
				DD = table.remove(next,1)
			end
		end
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
-- State Saving Stuff
function multi:IngoreObject()
	self.Ingore=true
	return self
end
function multi:ToString()
	if self.Ingore then return end
	local t=self.Type
	local data;
	multi.print(t)
	if t:sub(-6)=="Thread" then
		data={
			Type=t,
			rest=self.rest,
			updaterate=self.updaterest,
			restrate=self.restrate,
			name=self.name,
			func=self.func,
			important=self.important,
			Active=self.Active,
			ender=self.ender,
			held=self.held,
		}
	else
		data={
			Type=t,
			func=self.func,
			funcTM=self.funcTM,
			funcTMR=self.funcTMR,
			important=self.important,
			ender=self.ender,
			held=self.held,
		}
	end
	if t=="eventThread" or t=="event" then
		table.merge(data,{
			Task=self.Task,
		})
	elseif t=="loopThread" or t=="loop" then
		table.merge(data,{
			Start=self.Start,
		})
	elseif t=="stepThread" or t=="step" then
		table.merge(data,{
			funcE=self.funcE,
			funcS=self.funcS,
			pos=self.pos,
			endAt=self.endAt,
			start=self.start,
			spos=self.spos,
			skip=self.skip,
			count=self.count,
		})
	elseif t=="tloopThread" then
		table.merge(data,{
			restN=self.restN,
		})
	elseif t=="tloop" then
		table.merge(data,{
			set=self.set,
			life=self.life,
		})
	elseif t=="tstepThread" or t=="tstep" then
		table.merge(data,{
			funcE=self.funcE,
			funcS=self.funcS,
			pos=self.pos,
			endAt=self.endAt,
			start=self.start,
			spos=self.spos,
			skip=self.skip,
			count=self.count,
			timer=self.timer,
			set=self.set,
			reset=self.reset,
		})
	elseif t=="updaterThread" or t=="updater" then
		table.merge(data,{
			pos=self.pos,
			skip=self.skip,
		})
	elseif t=="alarmThread" or t=="alarm" then
		table.merge(data,{
			set=self.set,
		})
	elseif t=="timemaster" then
		-- Weird stuff is going on here!
		-- Need to do some testing
		table.merge(data,{
			timer=self.timer,
			_timer=self._timer,
			set=self.set,
			link=self.link,
		})
	elseif t=="process" or t=="mainprocess" then
		local loop=self.Mainloop
		local dat={}
		for i=1,#loop do
			local ins=loop[i]:ToString()
			if ins~=nil then
				table.insert(dat,ins)
			end
		end
		local str=bin.new()
		str:addBlock({Type=t})
		str:addBlock(#dat,4,"n")
		for i=1,#dat do
			str:addBlock(#dat[i],4,"n")
			str:addBlock(dat[i])
		end
		return str.data
	end
	for i,v in pairs(self.important) do
		data[v]=self[v]
	end
	local str=bin.new()
	str:addBlock(data)
	return str.data
end
function multi:newFromString(str)
	if type(str)=="table" then
		if str.Type=="bin" then
			str=str.data
		end
	end
	local handle=bin.new(str)
	local data=handle:getBlock("t")
	local t=data.Type
	if t=="mainprocess" then
		local objs=handle:getBlock("n",4)
		for i=1,objs do
			self:newFromString(handle:getBlock("s",(handle:getBlock("n",4))))
		end
		return self
	elseif  t=="process" then
		local temp=multi:newProcessor()
		local objs=handle:getBlock("n",4)
		for i=1,objs do
			temp:newFromString(handle:getBlock("s",(handle:getBlock("n",4))))
		end
		return temp
	elseif t=="step" then -- GOOD
		local item=self:newStep()
		table.merge(item,data)
		return item
	elseif t=="tstep" then -- GOOD
		local item=self:newTStep()
		table.merge(item,data)
		return item
	elseif t=="tloop" then -- GOOD
		local item=self:newTLoop()
		table.merge(item,data)
		return item
	elseif t=="event" then -- GOOD
		local item=self:newEvent(data.task)
		table.merge(item,data)
		return item
	elseif t=="alarm" then -- GOOD
		local item=self:newAlarm()
		table.merge(item,data)
		return item
	elseif t=="updater" then -- GOOD
		local item=self:newUpdater()
		table.merge(item,data)
		return item
	elseif t=="loop" then -- GOOD
		local item=self:newLoop()
		table.merge(item,data)
		return item
	end
end
function multi:Important(varname)
	table.insert(important,varname)
end
function multi:ToFile(path)
	bin.new(self:ToString()):tofile(path)
end
function multi:fromFile(path)
	self:newFromString(bin.load(path))
end
function multi:SetStateFlag(opt)
	--
end
function multi:quickStateSave(b)
	--
end
function multi:saveState(path,opt)
	--
end
function multi:loadState(path)
	--
end
function multi:setDefualtStateFlag(opt)
	--
end
return multi
