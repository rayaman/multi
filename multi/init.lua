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
multi.Version={1,5,0}
multi.stage='stable'
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
		local sample=#multi.Mainloop
		local FFloadtest=0
		multi:benchMark(multi.threstimed):OnBench(function(_,l3) FFloadtest=l3*(1/multi.threstimed) end)
		self:hold(function() return FFloadtest~=0 end)
		local val=FFloadtest/sample
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
function multi:isHeld()
	return self.held
end
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
	return multi.Version[1].."."..multi.Version[2].."."multi.Version[3]
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
	local temp=self:newLoop(function(t,self)
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
function multi:isAnActor()
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
					self.OnError:Fire(err,Loop[_D])
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
function multi:Sleep(n)
	self:hold(n)
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
				self.Parent:lManager()
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
				self.Parent:lManager()
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
	c.l=self:newLoop(function(dt) c:uManager(dt) end)
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
		loadstring('local interface=multi.Cself '..io.open(file,'rb'):read('*all'))()
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
function multi:newCondition(func)
	local c={['condition']=func}
	self:create(c)
	return c
end
function multi:mainloop()
	for i=1,#self.Tasks do
		self.Tasks[i](self)
	end
	rawset(self,'Start',self.clock())
	while self.Active do
		self:Do_Order()
	end
	print("Did you call multi:Stop()? This method should not be used when using multi:mainloop()! You now need to restart the multi, by using multi:reboot() and calling multi:mainloop() again or by using multi:uManager()")
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
