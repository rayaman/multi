--[[
MIT License

Copyright (c) 2017 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
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
if table.unpack then
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
_print=print
function print(...)
	if not __SUPPRESSPRINTS then
		_print(...)
	end
end
multi = {}
multi.Version="1.8.6"
multi._VERSION="1.8.6"
multi.stage='mostly-stable'
multi.__index = multi
multi.Mainloop={}
multi.Tasks={}
multi.Tasks2={}
multi.Garbage={}
multi.ender={}
multi.Children={}
multi.Paused={}
multi.Active=true
multi.fps=60
multi.Id=-1
multi.Type='mainprocess'
multi.Rest=0
multi._type=type
multi.Jobs={}
multi.queue={}
multi.jobUS=2
multi.clock=os.clock
multi.time=os.time
multi.LinkedPath=multi
multi.isRunning=false
multi.queuefinal=function(self)
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
--Do not change these ever...Any other number will not work (Unless you are using enablePriority2() then change can be made. Just ensure that Priority_Idle is the greatest and Priority_Core is 1!)
multi.Priority_Core=1
multi.Priority_High=4
multi.Priority_Above_Normal=16
multi.Priority_Normal=64
multi.Priority_Below_Normal=256
multi.Priority_Low=1024
multi.Priority_Idle=4096
multi.PList={multi.Priority_Core,multi.Priority_High,multi.Priority_Above_Normal,multi.Priority_Normal,multi.Priority_Below_Normal,multi.Priority_Low,multi.Priority_Idle}
multi.PStep=1
--^^^^
multi.PriorityTick=1 -- Between 1 and 4 any greater and problems arise
multi.Priority=multi.Priority_Core
multi.threshold=256
multi.threstimed=.001
function multi:setThreshold(n)
	self.threshold=n or 120
end
function multi:setThrestimed(n)
	self.threstimed=n or .001
end
function multi:getLoad()
	return multi:newFunction(function(self)
		multi.scheduler:Pause()
		local sample=#multi.Mainloop
		local FFloadtest=0
		multi:benchMark(multi.threstimed):OnBench(function(_,l3) FFloadtest=l3*(1/multi.threstimed) end)
		self:hold(function() return FFloadtest~=0 end)
		local val=FFloadtest/sample
		multi.scheduler:Resume()
		if val>multi.threshold then
			return 0
		else
			return 100-((val/multi.threshold)*100)
		end
	end)()
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
		elseif s:lower()=='above' or s:lower()=='an' then
			self.Priority=self.Priority_Above_Normal
		elseif s:lower()=='normal' or s:lower()=='n' then
			self.Priority=self.Priority_Normal
		elseif s:lower()=='below' or s:lower()=='bn' then
			self.Priority=self.Priority_Below_Normal
		elseif s:lower()=='low' or s:lower()=='l' then
			self.Priority=self.Priority_Low
		elseif s:lower()=='idle' or s:lower()=='i' then
			self.Priority=self.Priority_Idle
		end
	end
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
function multi:getParentProcess()
	return self.Mainloop[self.CID]
end
multi.GetParentProcess=multi.getParentProcess
function multi:Stop()
	self.Active=false
end
function multi:condition(cond)
	if not self.CD then
		self:Pause()
		self.held=true
		self.CD=cond.condition
	elseif not(cond.condition()) then
		self.held=false
		self:Resume()
		self.CD=nil
		return false
	end
	self.Parent:Do_Order()
	return true
end
multi.Condition=multi.condition
function multi:isHeld()
	return self.held
end
multi.IsHeld=multi.isHeld
function multi.executeFunction(name,...)
	if type(_G[name])=='function' then
		_G[name](...)
	else
		print('Error: Not a function')
	end
end
function multi:waitFor(obj)
	local value=false
	self.__waiting=function()
		value=true
	end
	obj:connectFinal(self.__waiting)
	self:hold(function() return value end)
end
multi.WaitFor=multi.waitFor
function multi:reboot(r)
	local before=collectgarbage('count')
	self.Mainloop={}
	self.Tasks={}
	self.Tasks2={}
	self.Garbage={}
	self.Children={}
	self.Paused={}
	self.Active=true
	self.Id=-1
	if r then
		for i,v in pairs(_G) do
			if type(i)=='table' then
				if i.Parent and i.Id and i.Act then
					i={}
				end
			end
		end
	end
	collectgarbage()
	local after=collectgarbage('count')
	print([[Before rebooting total Ram used was ]]..before..[[Kb
After rebooting total Ram used is ]]..after..[[ Kb
A total of ]]..(before-after)..[[Kb was cleaned up]])
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
function multi:Do_Order()
	local Loop=self.Mainloop
	_G.ID=0
	for _D=#Loop,1,-1 do
		if Loop[_D] then
			if Loop[_D].Active then
				Loop[_D].Id=_D
				self.CID=_D
				Loop[_D]:Act()
			end
		end
	end
end
function multi:enablePriority()
	function self:Do_Order()
		local Loop=self.Mainloop
		_G.ID=0
		local PS=self
		for _D=#Loop,1,-1 do
			if Loop[_D] then
				if (PS.PList[PS.PStep])%Loop[_D].Priority==0 then
					if Loop[_D].Active then
						Loop[_D].Id=_D
						self.CID=_D
						Loop[_D]:Act()
					end
				end
			end
		end
		PS.PStep=PS.PStep+1
		if PS.PStep>7 then
			PS.PStep=1
		end
	end
end
function multi:enablePriority2()
	function self:Do_Order()
		local Loop=self.Mainloop
		_G.ID=0
		local PS=self
		for _D=#Loop,1,-1 do
			if Loop[_D] then
				if (PS.PStep)%Loop[_D].Priority==0 then
					if Loop[_D].Active then
						Loop[_D].Id=_D
						self.CID=_D
						Loop[_D]:Act()
					end
				end
			end
		end
		PS.PStep=PS.PStep+1
		if PS.PStep>self.Priority_Idle then
			PS.PStep=1
		end
	end
end
multi.disablePriority=multi.unProtect
function multi:fromfile(path,int)
	int=int or self
	local test2={}
	local test=bin.load(path)
	local tp=test:getBlock('s')
	if tp=='event' then
		test2=int:newEvent(test:getBlock('f'))
		local t=test:getBlock('t')
		for i=1,#t do
			test2:OnEvent(t[i])
		end
	elseif tp=='alarm' then
		test2=int:newAlarm(test:getBlock('n'))
	elseif tp=='loop' then
		test2=int:newLoop(test:getBlock('t')[1])
	elseif tp=='step' or tp=='tstep' then
		local func=test:getBlock('t')
		local funcE=test:getBlock('t')
		local funcS=test:getBlock('t')
		local tab=test:getBlock('t')
		test2=int:newStep()
		table.merge(test2,tab)
		test2.funcE=funcE
		test2.funcS=funcS
		test2.func=func
	elseif tp=='trigger' then
		test2=int:newTrigger(test:getBlock('f'))
	elseif tp=='connector' then
		test2=int:newConnection()
		test2.func=test:getBlock('t')
	elseif tp=='timer' then
		test2=int:newTimer()
		test2.count=tonumber(test:getBlock('n'))
	else
		print('Error: The file you selected is not a valid multi file object!')
		return false
	end
	return test2
end
function multi:benchMark(sec,p,pt)
	local temp=self:newLoop(function(self,t)
		if self.clock()-self.init>self.sec then
			if pt then
				print(pt.." "..self.c.." Steps in "..sec.." second(s)!")
			end
			self.tt(self.sec,self.c)
			self:Destroy()
		else
			self.c=self.c+1
		end
	end)
	temp.Priority=p or 1
	function temp:OnBench(func)
		self.tt=func
	end
	self.tt=function() end
	temp.sec=sec
	temp.init=self.clock()
	temp.c=0
	return temp
end
function multi:tofile(path)
	local items=self:getChildren()
	io.mkDir(io.getName(path))
	for i=1,#items do
		items[i]:tofile(io.getName(path)..'\\item'..item[i]..'.dat')
	end
	local int=bin.new()
	int:addBlock('process')
	int:addBlock(io.getName(path))
	int:addBlock(#self.Mainloop)
	int:addBlock(self.Active)
	int:addBlock(self.Rest)
	int:addBlock(self.Jobs)
	int:tofile()
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
function multi:IsAnActor()
	return ({watcher=true,tstep=true,step=true,updater=true,loop=true,alarm=true,event=true})[self.Type]
end
function multi:OnMainConnect(func)
	table.insert(self.func,func)
end
function multi:protect()
	function self:Do_Order()
		local Loop=self.Mainloop
		for _D=#Loop,1,-1 do
			if Loop[_D]~=nil then
				Loop[_D].Id=_D
				self.CID=_D
				local status, err=pcall(Loop[_D].Act,Loop[_D])
				if err and not(Loop[_D].error) then
					Loop[_D].error=err
					self.OnError:Fire(Loop[_D],err)
				end
			end
		end
	end
end
function multi:unProtect()
	local Loop=self.Mainloop
	_G.ID=0
	for _D=#Loop,1,-1 do
		if Loop[_D] then
			if Loop[_D].Active then
				Loop[_D].Id=_D
				self.CID=_D
				Loop[_D]:Act()
			end
		end
	end
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
	for i=#self.Jobs,1,-1 do
		if self.Jobs[i][2]==name then
			table.remove(self.Jobs,i)
		end
	end
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
		print("Warning!!! "..self.Type.." doesn't contain a Final Connection State! Use "..self.Type..":Break(function) to trigger it's final event!")
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
function multi:Sleep(n)
	self:hold(n)
end
multi.sleep=multi.Sleep
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
	return c
end
multi.ResetTime=multi.SetTime
function multi:ResolveTimer(...)
	self._timer:Pause()
	for i=1,#self.funcTMR do
		self.funcTMR[i](self,...)
	end
	self:Pause()
end
function multi:OnTimedOut(func)
	self.funcTM[#self.funcTM+1]=func
end
function multi:OnTimerResolved(func)
	self.funcTMR[#self.funcTMR+1]=func
end
-- Timer stuff done
function multi:Pause()
	if self.Type=='mainprocess' then
		print("You cannot pause the main process. Doing so will stop all methods and freeze your program! However if you still want to use multi:_Pause()")
	else
		self.Active=false
		if self.Parent.Mainloop[self.Id]~=nil then
			table.remove(self.Parent.Mainloop,self.Id)
			table.insert(self.Parent.Paused,self)
			self.PId=#self.Parent.Paused
		end
	end
end
function multi:Resume()
	if self.Type=='process' or self.Type=='mainprocess' then
		self.Active=true
		local c=self:getChildren()
		for i=1,#c do
			c[i]:Resume()
		end
	else
		if self:isPaused() then
			table.remove(self.Parent.Paused,self.PId)
			table.insert(self.Parent.Mainloop,self)
			self.Id=#self.Parent.Mainloop
			self.Active=true
		end
	end
end
function multi:resurrect()
	table.insert(self.Parent.Mainloop,self)
	self.Active=true
end
multi.Resurrect=multi.resurrect
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
				break
			end
		end
		self.Active=false
	end
end

function multi:hold(task)
	self:Pause()
	self.held=true
	if type(task)=='number' then
		local timer=multi:newTimer()
		timer:Start()
		while timer:Get()<task do
			if love then
				if love.thread then
					self.Parent:Do_Order()
				else
					self.Parent:lManager()
				end
			else
				self.Parent:Do_Order()
			end
		end
		self:Resume()
		self.held=false
	elseif type(task)=='function' then
		local env=self.Parent:newEvent(task)
		env:OnEvent(function(envt) envt:Pause() envt.Active=false end)
		while env.Active do
			if love then
				if love.graphics then
					self.Parent:lManager()
				else
					self.Parent:Do_Order()
				end
			else
				self.Parent:Do_Order()
			end
		end
		env:Destroy()
		self:Resume()
		self.held=false
	else
		print('Error Data Type!!!')
	end
end
multi.Hold=multi.hold
function multi:oneTime(func,...)
	if not(self.Type=='mainprocess' or self.Type=='process') then
		for _k=1,#self.Parent.Tasks2 do
			if self.Parent.Tasks2[_k]==func then
				return false
			end
		end
		table.insert(self.Parent.Tasks2,func)
		func(...)
		return true
	else
		for _k=1,#self.Tasks2 do
			if self.Tasks2[_k]==func then
				return false
			end
		end
		table.insert(self.Tasks2,func)
		func(...)
		return true
	end
end
function multi:Reset(n)
	self:Resume()
end
function multi:isDone()
	return self.Active~=true
end
multi.IsDone=multi.isDone
function multi:create(ref)
	multi.OnObjectCreated:Fire(ref)
end
--Constructors [CORE]
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
	c.Id=0
	c.PId=0
	c.Act=function() end
	c.Parent=self
	c.held=false
	if ins then
		table.insert(self.Mainloop,ins,c)
	else
		table.insert(self.Mainloop,c)
	end
	return c
end
function multi:newProcess(file)
	if not(self.Type=='mainprocess') then error('Can only create an interface on the multi obj') return false end
	local c = {}
	setmetatable(c, self)
	c.Parent=self
	c.Active=true
	c.func={}
	c.Id=0
	c.Type='process'
	c.Mainloop={}
	c.Tasks={}
	c.Tasks2={}
	c.Garbage={}
	c.Children={}
	c.Paused={}
	c.Active=true
	c.Id=-1
	c.Rest=0
	c.Jobs={}
	c.queue={}
	c.jobUS=2
	c.l=self:newLoop(function(self,dt) c:uManager(dt) end)
	c.l:Pause()
	function c:getController()
		return c.l
	end
	function c:Start()
		if self.l then
			self.l:Resume()
		end
	end
	function c:Resume()
		if self.l then
			self.l:Resume()
		end
	end
	function c:Pause()
		if self.l then
			self.l:Pause()
		end
	end
	function c:Remove()
		self:Destroy()
		self.l:Destroy()
	end
	if file then
		self.Cself=c
		loadstring('local process=multi.Cself '..io.open(file,'rb'):read('*all'))()
	end
	self:create(c)
	return c
end
function multi:newQueuer(file)
	local c=self:newProcess()
	c.Type='queue'
	c.last={}
	c.funcE={}
	function c:OnQueueCompleted(func)
		table.insert(self.funcE,func)
	end
	if file then
		self.Cself=c
		loadstring('local queue=multi.Cself '..io.open(file,'rb'):read('*all'))()
	end
	self:create(c)
	multi.OnObjectCreated(function(self)
		if self.Parent then
			if self.Parent.Type=="queue" then
				if self:isAnActor() then
					if self.Type=="alarm" then
						self.Active=false
					end
					self:Pause()
					self:connectFinal(multi.queuefinal)
				end
			end
		end
	end)
	function c:Start()
		self.Mainloop[#self.Mainloop]:Resume()
		self.l:Resume()
	end
	return c
end
function multi:newTimer()
	local c={}
	c.Type='timer'
	c.time=0
	c.count=0
	c.paused=false
	function c:Start()
		self.time=os.clock()
	end
	function c:Get()
		if self:isPaused() then return self.time end
		return (os.clock()-self.time)+self.count
	end
	function c:isPaused()
		return c.paused
	end
	c.Reset=c.Start
	function c:Pause()
		self.time=self:Get()
		self.paused=true
	end
	function c:Resume()
		self.paused=false
		self.time=os.clock()-self.time
	end
	function c:tofile(path)
		local m=bin.new()
		self.count=self.count+self:Get()
		m:addBlock(self.Type)
		m:addBlock(self.count)
		m:tofile(path)
	end
	self:create(c)
	return c
end
function multi:newConnection(protect)
	local c={}
	setmetatable(c,{__call=function(self,...) self:connect(...) end})
	c.Type='connector'
	c.func={}
	c.ID=0
	c.protect=protect or true
	c.connections={}
	c.fconnections={}
	c.FC=0
	function c:fConnect(func)
		local temp=self:connect(func)
		table.insert(self.fconnections,temp)
		self.FC=self.FC+1
	end
	function c:getConnection(name,ingore)
		if ingore then
			return self.connections[name] or {
				Fire=function() end -- if the connection doesn't exist lets call all of them or silently ingore
			}
		else
			return self.connections[name] or self
		end
	end
	function c:Fire(...)
		local ret={}
		for i=#self.func,1,-1 do
			if self.protect then
				local temp={pcall(self.func[i][1],...)}
				if temp[1] then
					table.remove(temp,1)
					table.insert(ret,temp)
				else
					print(temp[2])
				end
			else
				table.insert(ret,{self.func[i][1](...)})
			end
		end
		return ret
	end
	function c:Bind(t)
		self.func=t
	end
	function c:Remove()
		self.func={}
	end
	function c:connect(func,name)
		self.ID=self.ID+1
		table.insert(self.func,1,{func,self.ID})
		local temp = {
			Link=self.func,
			func=func,
			ID=self.ID,
			Parent=self,
			Fire=function(self,...)
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
			end
		}
		if name then
			self.connections[name]=temp
		end
		return temp
	end
	c.Connect=c.connect
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:tofile(path)
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
	c.Id=0
	c.PId=0
	c.Parent=self
	c.Type='job'
	c.trigfunc=func or function() end
	function c:Act()
		self:trigfunc(self)
	end
	table.insert(self.Jobs,{c,name})
	if self.JobRunner==nil then
		self.JobRunner=self:newAlarm(self.jobUS)
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
function multi:newRange()
	local selflink=self
	local temp={
		getN = function(self) selflink:Do_Order() self.n=self.n+self.c if self.n>self.b then self.Link.held=false self.Link:Resume() return nil end return self.n end,
	}
	setmetatable(temp,{
		__call=function(self,a,b,c)
			self.c=c or 1
			self.n=a-self.c
			self.a=a
			self.b=b
			self.Link=selflink--.Parent.Mainloop[selflink.CID] or
			self.Link:Pause()
			self.Link.held=true
			return function() return self:getN() end
		end
	})
	self:create(temp)
	return temp
end
multi.NewRange=multi.newRange
function multi:newCondition(func)
	local c={['condition']=func,Type="condition"}
	self:create(c)
	return c
end
multi.NewCondition=multi.newCondition
function multi:mainloop()
	if not multi.isRunning then
		multi.isRunning=true
		for i=1,#self.Tasks do
			self.Tasks[i](self)
		end
		rawset(self,'Start',self.clock())
		while self.Active do
			self:Do_Order()
		end
	else
		return "Already Running!"
	end
end
function multi:protectedMainloop()
	multi:protect()
	if not multi.isRunning then
		multi.isRunning=true
		for i=1,#self.Tasks do
			self.Tasks[i](self)
		end
		rawset(self,'Start',self.clock())
		while self.Active do
			self:Do_Order()
		end
	else
		return "Already Running!"
	end
end
function multi:unprotectedMainloop()
	multi:unProtect()
	if not multi.isRunning then
		multi.isRunning=true
		for i=1,#self.Tasks do
			self.Tasks[i](self)
		end
		rawset(self,'Start',self.clock())
		while self.Active do
			local Loop=self.Mainloop
			_G.ID=0
			for _D=#Loop,1,-1 do
				if Loop[_D] then
					if Loop[_D].Active then
						Loop[_D].Id=_D
						self.CID=_D
						Loop[_D]:Act()
					end
				end
			end
		end
	else
		return "Already Running!"
	end
end
function multi:prioritizedMainloop1()
	multi:enablePriority()
	if not multi.isRunning then
		multi.isRunning=true
		for i=1,#self.Tasks do
			self.Tasks[i](self)
		end
		rawset(self,'Start',self.clock())
		while self.Active do
			local Loop=self.Mainloop
			_G.ID=0
			local PS=self
			for _D=#Loop,1,-1 do
				if Loop[_D] then
					if (PS.PList[PS.PStep])%Loop[_D].Priority==0 then
						if Loop[_D].Active then
							Loop[_D].Id=_D
							self.CID=_D
							Loop[_D]:Act()
						end
					end
				end
			end
			PS.PStep=PS.PStep+1
			if PS.PStep>7 then
				PS.PStep=1
			end
		end
	else
		return "Already Running!"
	end
end
function multi:prioritizedMainloop2()
	multi:enablePriority2()
	if not multi.isRunning then
		multi.isRunning=true
		for i=1,#self.Tasks do
			self.Tasks[i](self)
		end
		rawset(self,'Start',self.clock())
		while self.Active do
			local Loop=self.Mainloop
			_G.ID=0
			local PS=self
			for _D=#Loop,1,-1 do
				if Loop[_D] then
					if (PS.PStep)%Loop[_D].Priority==0 then
						if Loop[_D].Active then
							Loop[_D].Id=_D
							self.CID=_D
							Loop[_D]:Act()
						end
					end
				end
			end
			PS.PStep=PS.PStep+1
			if PS.PStep>self.Priority_Idle then
				PS.PStep=1
			end
		end
	else
		return "Already Running!"
	end
end
function multi._tFunc(self,dt)
	for i=1,#self.Tasks do
		self.Tasks[i](self)
	end
	if dt then
		self.pump=true
	end
	self.pumpvar=dt
	rawset(self,'Start',self.clock())
end
function multi:uManager(dt)
	if self.Active then
		self:oneTime(self._tFunc,self,dt)
		function self:uManager(dt)
			self:Do_Order()
		end
		self:Do_Order()
	end
end
--Core Actors
function multi:newCustomObject(objRef,t)
	local c={}
	if t=='process' then
		c=self:newBase()
		if type(objRef)=='table' then
			table.merge(c,objRef)
		end
		if not c.Act then
			function c:Act()
				-- Empty function
			end
		end
	else
		c=objRef or {}
	end
	if not c.Type then
		c.Type='coustomObject'
	end
	self:create(c)
	return c
end
function multi:newEvent(task)
	local c=self:newBase()
	c.Type='event'
	c.Task=task or function() end
	function c:Act()
		if self.Task(self) then
			self:Pause()
			for _E=1,#self.func do
				self.func[_E](self)
			end
		end
	end
	function c:SetTask(func)
		self.Task=func
	end
	function c:OnEvent(func)
		table.insert(self.func,func)
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.Task)
		m:addBlock(self.func)
		m:addBlock(self.Active)
		m:tofile(path)
	end
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
	function c:setSkip(n)
		self.skip=n
	end
	c.OnUpdate=self.OnMainConnect
	self:create(c)
	return c
end
function multi:newAlarm(set)
	local c=self:newBase()
	c.Type='alarm'
	c.Priority=self.Priority_Low
	c.timer=self:newTimer()
	c.set=set or 0
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.set)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Act()
		if self.timer:Get()>=self.set then
			self:Pause()
			self.Active=false
			for i=1,#self.func do
				self.func[i](self)
			end
		end
	end
	function c:Resume()
		self.Parent.Resume(self)
		self.timer:Resume()
	end
	function c:Reset(n)
		if n then self.set=n end
		self:Resume()
		self.timer:Reset()
	end
	function c:OnRing(func)
		table.insert(self.func,func)
	end
	function c:Pause()
		self.timer:Pause()
		self.Parent.Pause(self)
	end
	self:create(c)
	return c
end
function multi:newLoop(func)
	local c=self:newBase()
	c.Type='loop'
	c.Start=self.clock()
	if func then
		c.func={func}
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Act()
		for i=1,#self.func do
			self.func[i](self,self.Parent.clock()-self.Start)
		end
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	self:create(c)
	return c
end
function multi:newFunction(func)
	local c={}
	c.func=func
	mt={
		__index=multi,
		__call=function(self,...) if self.Active then return self:func(...) end local t={...} return "PAUSED" end
	}
	c.Parent=self
	function c:Pause()
		self.Active=false
	end
	function c:Resume()
		self.Active=true
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
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.funcE)
		m:addBlock(self.funcS)
		m:addBlock({pos=self.pos,endAt=self.endAt,skip=self.skip,spos=self.spos,count=self.count,start=self.start})
		m:addBlock(self.Active)
		m:tofile(path)
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
	end
	function c:OnStep(func)
		table.insert(self.func,1,func)
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
	end
	function c:Break()
		self.Active=nil
	end
	function c:Update(start,reset,count,skip)
		self.start=start or self.start
		self.endAt=reset or self.endAt
		self.skip=skip or self.skip
		self.count=count or self.count
		self:Resume()
	end
	self:create(c)
	return c
end
function multi:newTask(func)
	table.insert(self.Tasks,func)
end
function multi:newTLoop(func,set)
	local c=self:newBase()
	c.Type='tloop'
	c.set=set or 0
	c.timer=self:newTimer()
	c.life=0
	if func then
		c.func={func}
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.Active)
		m:tofile(path)
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
	end
	function c:Pause()
		self.timer:Pause()
		self.Parent.Pause(self)
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
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
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.trigfunc)
		m:tofile(path)
	end
	self:create(c)
	return c
end
function multi:newTStep(start,reset,count,set)
	local c=self:newBase()
	think=1
	c.Type='tstep'
	c.Priority=self.Priority_Low
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
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.funcE)
		m:addBlock(self.funcS)
		m:addBlock({pos=self.pos,endAt=self.endAt,skip=self.skip,timer=self.timer,count=self.count,start=self.start,set=self.set})
		m:addBlock(self.Active)
		m:tofile(path)
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
	end
	function c:OnStep(func)
		table.insert(self.func,func)
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
	end
	function c:Break()
		self.Active=nil
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=self.clock()
		self:Resume()
	end
	self:create(c)
	return c
end
function multi:newWatcher(namespace,name)
	local function WatcherObj(ns,n)
		if self.Type=='queue' then
			print("Cannot create a watcher on a queue! Creating on 'multi' instead!")
			self=multi
		end
		local c=self:newBase()
		c.Type='watcher'
		c.ns=ns
		c.n=n
		c.cv=ns[n]
		function c:OnValueChanged(func)
			table.insert(self.func,func)
		end
		function c:Act()
			if self.cv~=self.ns[self.n] then
				for i=1,#self.func do
					self.func[i](self,self.cv,self.ns[self.n])
				end
				self.cv=self.ns[self.n]
			end
		end
		self:create(c)
		return c
	end
	if type(namespace)~='table' and type(namespace)=='string' then
		return WatcherObj(_G,namespace)
	elseif type(namespace)=='table' and (type(name)=='string' or 'number') then
		return WatcherObj(namespace,name)
	else
		print('Warning, invalid arguments! Nothing returned!')
	end
end
-- Threading stuff
thread={}
multi.GlobalVariables={}
if os.getOS()=="windows" then
	thread.__CORES=tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
else
	thread.__CORES=tonumber(io.popen("nproc --all"):read("*n"))
end
function thread.sleep(n)
	coroutine.yield({"_sleep_",n or 0})
end
function thread.hold(n)
	coroutine.yield({"_hold_",n or function() return true end})
end
function thread.skip(n)
	coroutine.yield({"_skip_",n or 0})
end
function thread.kill()
	coroutine.yield({"_kill_",":)"})
end
function thread.yeild()
	coroutine.yield({"_sleep_",0})
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
function thread.testFor(name,val,sym)
	thread.hold(function() return thread.get(name)~=nil end)
	return thread.get(name)
end
function multi:newTBase(ins)
	local c = {}
	c.Active=true
	c.func={}
	c.ender={}
	c.Id=0
	c.PId=0
	c.Parent=self
	c.held=false
	return c
end
function multi:newThread(name,func)
	local c={}
	c.ref={}
	c.Name=name
	c.thread=coroutine.create(func)
	c.sleep=1
	c.Type="thread"
	c.firstRunDone=false
	c.timer=multi.scheduler:newTimer()
	c.ref.Globals=self:linkDomain("Globals")
	function c.ref:send(name,val)
		ret=coroutine.yield({Name=name,Value=val})
		self:syncGlobals(ret)
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
			self:syncGlobals(ret)
		elseif type(n)=="number" then
			n = tonumber(n) or 0
			ret=coroutine.yield({"_sleep_",n})
			self:syncGlobals(ret)
		else
			error("Invalid Type for sleep!")
		end
	end
	function c.ref:syncGlobals(v)
		self.Globals=v
	end
	table.insert(self:linkDomain("Threads"),c)
	if not multi.scheduler:isActive() then
		multi.scheduler:Resume()
	end
end
multi:setDomainName("Threads")
multi:setDomainName("Globals")
multi.scheduler=multi:newLoop()
multi.scheduler.Type="scheduler"
function multi.scheduler:setStep(n)
	self.skip=tonumber(n) or 24
end
multi.scheduler.skip=0
multi.scheduler.counter=0
multi.scheduler.Threads=multi:linkDomain("Threads")
multi.scheduler.Globals=multi:linkDomain("Globals")
multi.scheduler:OnLoop(function(self)
	self.counter=self.counter+1
	for i=#self.Threads,1,-1 do
		ret={}
		if coroutine.status(self.Threads[i].thread)=="dead" then
			table.remove(self.Threads,i)
		else
			if self.Threads[i].timer:Get()>=self.Threads[i].sleep then
				if self.Threads[i].firstRunDone==false then
					self.Threads[i].firstRunDone=true
					self.Threads[i].timer:Start()
					_,ret=coroutine.resume(self.Threads[i].thread,self.Threads[i].ref)
				else
					_,ret=coroutine.resume(self.Threads[i].thread,self.Globals)
				end
				if _==false then
					self.Parent.OnError:Fire(self.Threads[i],ret)
					print("Error in thread: <"..self.Threads[i].Name.."> "..ret)
				end
				if ret==true or ret==false then
					print("Thread Ended!!!")
					ret={}
				end
			end
			if ret then
				if ret[1]=="_kill_" then
					table.remove(self.Threads,i)
				elseif ret[1]=="_sleep_" then
					self.Threads[i].timer:Reset()
					self.Threads[i].sleep=ret[2]
				elseif ret[1]=="_skip_" then
					self.Threads[i].timer:Reset()
					self.Threads[i].sleep=math.huge
					local event=multi:newEvent(function(evnt) return multi.scheduler.counter>=evnt.counter end)
					event.link=self.Threads[i]
					event.counter=self.counter+ret[2]
					event:OnEvent(function(evnt)
						evnt.link.sleep=0
					end)
				elseif ret[1]=="_hold_" then
					self.Threads[i].timer:Reset()
					self.Threads[i].sleep=math.huge
					local event=multi:newEvent(ret[2])
					event.link=self.Threads[i]
					event:OnEvent(function(evnt)
						evnt.link.sleep=0
					end)
				elseif ret.Name then
					self.Globals[ret.Name]=ret.Value
				end
			end
		end
	end
end)
multi.scheduler:Pause()
multi.OnError=multi:newConnection()
function multi:newThreadedAlarm(name,set)
	local c=self:newTBase()
	c.Type='alarmThread'
	c.timer=self:newTimer()
	c.set=set or 0
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.set)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
		self.timer:Resume()
	end
	function c:Reset(n)
		if n then self.set=n end
		self.rest=false
		self.timer:Reset(n)
	end
	function c:OnRing(func)
		table.insert(self.func,func)
	end
	function c:Pause()
		self.timer:Pause()
		self.rest=true
	end
	c.rest=false
	c.updaterate=multi.Priority_Low -- skips
	c.restRate=0 -- secs
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if c.timer:Get()>=c.set then
					c:Pause()
					for i=1,#c.func do
						c.func[i](c)
					end
				end
				thread.skip(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
function multi:newThreadedUpdater(name,skip)
	local c=self:newTBase()
	c.Type='updaterThread'
	c.pos=1
	c.skip=skip or 1
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	c.OnUpdate=self.OnMainConnect
	c.rest=false
	c.updaterate=0
	c.restRate=.75
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				for i=1,#c.func do
					c.func[i](c)
				end
				c.pos=c.pos+1
				thread.skip(c.skip)
			end
		end
	end)
	self:create(c)
	return c
end
function multi:newThreadedTStep(name,start,reset,count,set)
	local c=self:newTBase()
	local think=1
	c.Type='tstepThread'
	c.Priority=self.Priority_Low
	c.start=start or 1
	local reset = reset or math.huge
	c.endAt=reset
	c.pos=start or 1
	c.skip=skip or 0
	c.count=count or 1*think
	c.funcE={}
	c.timer=os.clock()
	c.set=set or 1
	c.funcS={}
	function c:Update(start,reset,count,set)
		self.start=start or self.start
		self.pos=self.start
		self.endAt=reset or self.endAt
		self.set=set or self.set
		self.count=count or self.count or 1
		self.timer=os.clock()
		self:Resume()
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.funcE)
		m:addBlock(self.funcS)
		m:addBlock({pos=self.pos,endAt=self.endAt,skip=self.skip,timer=self.timer,count=self.count,start=self.start,set=self.set})
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	function c:OnStart(func)
		table.insert(self.funcS,func)
	end
	function c:OnStep(func)
		table.insert(self.func,func)
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
	end
	function c:Break()
		self.Active=nil
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=os.clock()
		self:Resume()
	end
	c.updaterate=0--multi.Priority_Low -- skips
	c.restRate=0
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if os.clock()-c.timer>=c.set then
					c:Reset()
					if c.pos==c.start then
						for fe=1,#c.funcS do
							c.funcS[fe](c)
						end
					end
					for i=1,#c.func do
						c.func[i](c.pos,c)
					end
					c.pos=c.pos+c.count
					if c.pos-c.count==c.endAt then
						c:Pause()
						for fe=1,#c.funcE do
							c.funcE[fe](c)
						end
						c.pos=c.start
					end
				end
				thread.skip(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
function multi:newThreadedTLoop(name,func,n)
	local c=self:newTBase()
	c.Type='tloopThread'
	c.restN=n or 1
	if func then
		c.func={func}
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	c.rest=false
	c.updaterate=0
	c.restRate=.75
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				for i=1,#c.func do
					c.func[i](c)
				end
				thread.sleep(c.restN) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
function multi:newThreadedStep(name,start,reset,count,skip)
	local c=self:newTBase()
	local think=1
	c.Type='stepThread'
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
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.funcE)
		m:addBlock(self.funcS)
		m:addBlock({pos=self.pos,endAt=self.endAt,skip=self.skip,spos=self.spos,count=self.count,start=self.start})
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	c.Reset=c.Resume
	function c:OnStart(func)
		table.insert(self.funcS,func)
	end
	function c:OnStep(func)
		table.insert(self.func,1,func)
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
	end
	function c:Break()
		self.rest=true
	end
	function c:Update(start,reset,count,skip)
		self.start=start or self.start
		self.endAt=reset or self.endAt
		self.skip=skip or self.skip
		self.count=count or self.count
		self:Resume()
	end
	c.updaterate=0
	c.restRate=.1
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				ref:sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if c~=nil then
					if c.spos==0 then
						if c.pos==c.start then
							for fe=1,#c.funcS do
								c.funcS[fe](c)
							end
						end
						for i=1,#c.func do
							c.func[i](c.pos,c)
						end
						c.pos=c.pos+c.count
						if c.pos-c.count==c.endAt then
							c:Pause()
							for fe=1,#c.funcE do
								c.funcE[fe](c)
							end
							c.pos=c.start
						end
					end
				end
				c.spos=c.spos+1
				if c.spos>=c.skip then
					c.spos=0
				end
				ref:sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
function multi:newThreadedProcess(name)
	local c = {}
	setmetatable(c, multi)
	function c:newBase(ins)
		local ct = {}
		setmetatable(ct, self.Parent)
		ct.Active=true
		ct.func={}
		ct.ender={}
		ct.Id=0
		ct.PId=0
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
	c.Id=0
	c.Type='process'
	c.Mainloop={}
	c.Tasks={}
	c.Tasks2={}
	c.Garbage={}
	c.Children={}
	c.Paused={}
	c.Active=true
	c.Id=-1
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
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	function c:Remove()
		self.ref:kill()
	end
	function c:kill()
		err=coroutine.yield({"_kill_"})
		if err then
			error("Failed to kill a thread! Exiting...")
		end
	end
	function c:sleep(n)
		if type(n)=="function" then
			ret=coroutine.yield({"_hold_",n})
		elseif type(n)=="number" then
			n = tonumber(n) or 0
			ret=coroutine.yield({"_sleep_",n})
		else
			error("Invalid Type for sleep!")
		end
	end
	c.hold=c.sleep
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				ref:Sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				c:uManager()
				ref:sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	return c
end
function multi:newThreadedLoop(name,func)
	local c=self:newTBase()
	c.Type='loopThread'
	c.Start=os.clock()
	if func then
		c.func={func}
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.func)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	c.rest=false
	c.updaterate=0
	c.restRate=.75
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				thread.sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				for i=1,#c.func do
					c.func[i](os.clock()-self.Start,c)
				end
				thread.sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
function multi:newThreadedEvent(name,task)
	local c=self:newTBase()
	c.Type='eventThread'
	c.Task=task or function() end
	function c:OnEvent(func)
		table.insert(self.func,func)
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.Task)
		m:addBlock(self.func)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	c.rest=false
	c.updaterate=0
	c.restRate=1
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				ref:sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if c.Task(self) then
					for _E=1,#c.func do
						c.func[_E](c)
					end
					c:Pause()
				end
				ref:sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
