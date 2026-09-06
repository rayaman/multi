if not bin then
	print('Warning the \'bin\' library wasn\'t required! multi:tofile(path) and the multi:fromfile(path,int) features will not work!')
end
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
multi = {}
multi.Version={'A',0,1}-- History: EventManager,EventManager+,MultiManager <-- Current After 6.3.0 Versioning scheme was altered. A.0.0
multi.help=[[
For a list of features do print(multi.Features)
For a list of changes do print(multi.changelog)
For current version do print(multi.Version)
For current stage do print(multi.stage)
For help do print(multi.help) :D
]]
multi.stage='stable'
multi.Features='Current Version: '..multi.Version[1]..'.'..multi.Version[2]..'.'..multi.Version[3]..' '..multi.stage..[[
MultiManager has 19 Objects: # indicates most commonly used 1-19 1 being the most used by me
+Events			#7
+Alarms			#2
+Loops			#3
+Steps			#4
+TSteps			#6
+Triggers		#16
+Tasks			#12
+Connections	#1  -- This is a rather new feature of this library, but has become the most useful for async handling. Knowing this is already 50% of this library
+Timers			#14 -- this was tricky because these make up both Alarms and TSteps, but in purly using this standalone is almost non existent
+Jobs			#11
+Process		#10
+Conditions		#15
+Ranges			#8
+Threads		#13
+Functions		#5
+Queuers		#17
+Updaters		#9
+Watchers		#18
+CustomObjects	#19

Constructors [Runners]
---------------------- Note: multi is the main Processor Obj It cannot be paused or destroyed (kinda)
intObj=multi:newProcess([string: FILE defualt: nil])
intObj=multi:newQueuer([string: FILE defualt: nil])

Constructors [ACTORS]
--------------------- Note: everything is a multiObj!
eventObj=multi:newEvent([function: TASK defualt: function() end])
alarmObj=multi:newAlarm([number: SET defualt: 0])
loopObj=multi:newLoop([function: FUNC])
stepObj=multi:newStep([number: START defualt: 0],[number: RESET defualt: inf],[number: COUNT defualt: 1],[number: SKIP defualt: 0])
tstepObj=multi:newTStep([number: START defualt: 0],[number: RESET defualt: inf],[number: COUNT defualt: 1],[number: SET defualt: 1])
updaterObj=multi:newUpdater([number: SKIP defualt: 0])
watcherObj=multi:newWatcher(table: NAMESPACE,string: NAME)
multiObj=multi:newCustomObject([table: OBJREF],[string: T='process'])
void=multi:newThread(string: name,function: func)

Constructors [Semi-ACTORS]
--------------------------
multi:newJob(function: func,[string: name])
multi:newRange(number: a,number: b,[number: c])
multi:newCondition(func)

Constructors [NON-ACTORS]
-------------------------
multi:newTrigger(function: func)
multi:newTask(function: func)
multi:newConnection()
multi:newTimer()
multi:newFunction(function: func)
]]
multi.changelog=[[Changelog starts at Version A.0.0
New in A.0.0
	Nothing really however a changelog will now be recorded! Feel free to remove this extra strings if space is a requriment
	version.major.minor
New in A.1.0
	Changed: multi:newConnection(protect) method
		Changed the way you are able to interact with it by adding the __call metamethod
		Old usage:

		OnUpdate=multi:newConnection()
			OnUpdate:connect(function(...)
				print("Updating",...)
			end)
		OnUpdate:Fire(1,2,3)

		New usage: notice that connect is no longer needed! Both ways still work! and always will work :)

		OnUpdate=multi:newConnection()
			OnUpdate(function(...)
				print("Updating",...)
			end)
		OnUpdate:Fire(1,2,3)
]]
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
		self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
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
	self:hold(function() return obj:isActive() end)
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
function multi:benchMark(sec,p)
	local temp=self:newLoop(function(t,self)
		if self.clock()-self.init>self.sec then
			print(self.c..' steps in '..self.sec..' second(s)')
			self.tt(self.sec)
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
		local alarm=self.Parent:newAlarm(task)
		while alarm.Active==true do
			if love then
				self.Parent:lManager()
			else
				self.Parent:Do_Order()
			end
		end
		alarm:Destroy()
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
	function c:Start()
		if self.l then
			self.l:Resume()
		else
			self.l=self.Parent:newLoop(function(dt) c:uManager(dt) end)
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
	return c
end
--Constructors [ACTORS]
function multi:newCustomObject(objRef,t)
	local c={}
	if t=='process' then
		if self.Type=='queue' then
			c=self:newBase(1)
			self.last=c
			print("This Custom Object was created on a queue! Ensure that it has a way to end! All objects have a obj:Break() method!")
		else
			c=self:newBase()
		end
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
	if self.Type=='queue' then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(multi.queuefinal)
	end
	self:create(c)
	return c
end
function multi:newEvent(task)
	local c={}
	if self.Type=='queue' then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
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
	if self.Type=='queue' then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(multi.queuefinal)
	end
	self:create(c)
	return c
end
function multi:newAlarm(set)
	local c={}
	if self.Type=='queue' then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
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
	if self.Type=='queue' then
		c:Pause()
		c:connectFinal(multi.queuefinal)
	else
		c.timer:Start()
	end
	self:create(c)
	return c
end
function multi:newLoop(func)
	local c={}
	if self.Type=='queue' then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
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
			self.func[i](self.Parent.clock()-self.Start,self)
		end
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	if self.Type=='queue' then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(multi.queuefinal)
	end
	self:create(c)
	return c
end
function multi:newUpdater(skip)
	local c={}
	if self.Type=='queue' then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
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
	if self.Type=='queue' then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(multi.queuefinal)
	end
	self:create(c)
	return c
end
function multi:newStep(start,reset,count,skip)
	local c={}
	if self.Type=='queue' then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
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
					self.func[i](self.pos,self)
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
	if self.Type=='queue' then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(multi.queuefinal)
	end
	self:create(c)
	return c
end
function multi:newTStep(start,reset,count,set)
	local c={}
	if self.Type=='queue' then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
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
				self.func[i](self.pos,self)
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
	if self.Type=='queue' then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(multi.queuefinal)
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
function multi:newThread(name,func)
	local c={}
	c.ref={}
	c.Name=name
	c.thread=coroutine.create(func)
	c.sleep=1
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
		n = tonumber(n) or 0
		ret=coroutine.yield({"_sleep_",n})
		self:syncGlobals(ret)
	end
	function c.ref:syncGlobals(v)
		self.Globals=v
	end
	table.insert(self:linkDomain("Threads"),c)
	if not multi.scheduler:isActive() then
		multi.scheduler:Resume()
	end
end
-- Constructors [SEMI-ACTORS]
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
	selflink=self
	local temp={
		getN = function(self) selflink:Do_Order() self.n=self.n+self.c if self.n>self.b then self.Link.held=false self.Link:Resume() return nil end return self.n end,
	}
	setmetatable(temp,{
		__call=function(self,a,b,c)
			self.c=c or 1
			self.n=a-self.c
			self.a=a
			self.b=b
			self.Link=selflink.Parent.Mainloop[selflink.CID]
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
-- Constructors [NON-ACTORS]
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
function multi:newTimer()
	local c={}
	c.Type='timer'
	c.time=0
	c.count=0
	function c:Start()
		self.time=os.clock()
	end
	function c:Get()
		return (os.clock()-self.time)+self.count
	end
	c.Reset=c.Start
	function c:Pause()
		self.time=self:Get()
	end
	function c:Resume()
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
function multi:newTask(func)
	table.insert(self.Tasks,func)
end
function multi:newTrigger(func)
	local c={}
	c.Type='trigger'
	c.trigfunc=func or function() end
	function c:Fire(...)
		self:trigfunc(self,...)
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
function multi:newConnection(protect)
	local c={}
	setmetatable(c,{__call=function(self,...) self:connect(...) end})
	c.Type='connector'
	c.func={}
	c.ID=0
	c.protect=protect or true
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
	function c:bind(t)
		self.func=t
	end
	function c:remove()
		self.func={}
	end
	function c:connect(func)
		self.ID=self.ID+1
		table.insert(self.func,1,{func,self.ID})
		return {
			Link=self.func,
			ID=self.ID,
			remove=function(self)
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
	end
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
--Managers
function multi:mainloop()
	for i=1,#self.Tasks do
		self.Tasks[i](self)
	end
	rawset(self,'Start',self.clock())
	while self.Active do
		self:Do_Order()
	end
	print("Did you call multi:Stop()? This method should not be used when using multi:mainloop()! You now need to restart the multiManager, by using multi:reboot() and calling multi:mainloop() again or by using multi:uManager()")
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
--Thread Setup Stuff
multi:setDomainName("Threads")
multi:setDomainName("Globals")
-- Scheduler
multi.scheduler=multi:newUpdater()
multi.scheduler.Type="scheduler"
function multi.scheduler:setStep(n)
	self.skip=tonumber(n) or 24
end
multi.scheduler.Threads=multi:linkDomain("Threads")
multi.scheduler.Globals=multi:linkDomain("Globals")
multi.scheduler:OnUpdate(function(self)
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
				elseif ret.Name then
					self.Globals[ret.Name]=ret.Value
				end
			end
		end
	end
end)
multi.scheduler:setStep()
multi.scheduler:Pause()
multi.OnError=multi:newConnection()
