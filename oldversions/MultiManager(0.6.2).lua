if not bin then
	print("Warning the 'bin' library wasn't required! multi:tofile(path) and the multi:fromfile(path,int) feature will not work!")
end
function table.merge(t1, t2)
    for k,v in pairs(t2) do
    	if type(v) == "table" then
    		if type(t1[k] or false) == "table" then
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
multi.Version={6,2,0}-- History: EventManager,EventManager+,MultiManager <-- Current
multi.stage="stable"
multi.Features=multi.Version[1].."."..multi.Version[2].."."..multi.Version[3].." "..multi.stage..[[
	Objects:
	Event
	Alarm
	Loop
	Step
	TStep
	Trigger
	Task
	Connection
	Timer
	Job
]]
multi.__index = multi
multi.Mainloop={}
multi.Tasks={}
multi.Tasks2={}
multi.Garbage={}
multi.Children={}
multi.Paused={}
multi.Active=true
multi.Id=-1
multi.Type="mainint"
multi.Rest=0
multi._type=type
multi.Jobs={}
multi.queue={}
multi.jobUS=2
multi.clock=os.clock
multi.time=os.time
multi.LinkedPath=multi
-- System
function multi:Stop()
	self.Active=false
end
function os.getOS()
	if package.config:sub(1,1)=="\\" then
		return "windows"
	else
		return "unix"
	end
end
if os.getOS()=="windows" then
	function os.sleep(n)
		if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
	end
else
	function os.sleep(n)
		os.execute("sleep " .. tonumber(n))
	end
end
function multi.executeFunction(name,...)
	if type(_G[name])=="function" then
		_G[name](...)
	else
		print("Error: Not a function")
	end
end
function multi:reboot(r)
	local before=collectgarbage("count")
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
			if type(i)=="table" then
				if i.Parent and i.Id and i.Act then
					i={}
				end
			end
		end
	end
	collectgarbage()
	local after=collectgarbage("count")
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
	for _D=#Loop,1,-1 do
		if Loop[_D]~=nil then
			if Loop[_D].Active then
				Loop[_D].Id=_D
				Loop[_D]:Act()
			end
		end
	end
	if self.Rest~=0 then
		os.sleep(self.Rest)
	end
end
function multi:fromfile(path,int)
	int=int or multi
	local test2={}
	local test=bin.load(path)
	local tp=test:getBlock("s")
	if tp=="event" then
		test2=int:newEvent(test:getBlock("f"))
		local t=test:getBlock("t")
		for i=1,#t do
			test2:OnEvent(t[i])
		end
	elseif tp=="alarm" then
		test2=int:newAlarm(test:getBlock("n"))
	elseif tp=="loop" then
		test2=int:newLoop(test:getBlock("t")[1])
	elseif tp=="step" or tp=="tstep" then
		local func=test:getBlock("t")
		local funcE=test:getBlock("t")
		local funcS=test:getBlock("t")
		local tab=test:getBlock("t")
		test2=int:newStep()
		table.merge(test2,tab)
		test2.funcE=funcE
		test2.funcS=funcS
		test2.func=func
	elseif tp=="trigger" then
		test2=int:newTrigger(test:getBlock("f"))
	elseif tp=="connector" then
		test2=int:newConnection()
		test2.func=test:getBlock("t")
	elseif tp=="timer" then
		test2=int:newTimer()
		test2.count=tonumber(test:getBlock("n"))
	else
		print("Error: The file you selected is not a valid multi file object!")
		return false
	end
	return test2
end
function multi:benchMark(sec)
	local temp=self:newLoop(function(t,self)
		if multi.clock()-self.init>self.sec then
			print(self.c.." steps in "..self.sec.." second(s)")
			self.tt(self.sec)
			self:Destroy()
		else
			self.c=self.c+1
		end
	end)
	function temp:OnBench(func)
		self.tt=func
	end
	self.tt=function() end
	temp.sec=sec
	temp.init=multi.clock()
	temp.c=0
	return temp
end
function multi:tofile(path)
	local items=self:getChildren()
	io.mkDir(io.getName(path))
	for i=1,#items do
		items[i]:tofile(io.getName(path).."\\item"..item[i]..".dat")
	end
	local int=bin.new()
	int:addBlock("int")
	int:addBlock(io.getName(path))
	int:addBlock(#self.Mainloop)
	int:addBlock(self.Active)
	int:addBlock(self.Rest)
	int:addBlock(self.Jobs)
	int:tofile()
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
				local status, err=pcall(Loop[_D].Act,Loop[_D])
				if err and not(Loop[_D].error) then
					Loop[_D].error=err
					print(err..": Ingoring error continuing...")
				end
			end
		end
		if self.Rest~=0 then
			os.sleep(self.Rest)
		end
	end
end
function multi:unProtect()
	function self:Do_Order()
		for _D=#Loop,1,-1 do
			if Loop[_D]~=nil then
				Loop[_D].Id=_D
				Loop[_D]:Act()
			end
		end
		if self.Rest~=0 then
			os.sleep(self.Rest)
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
	if self.Type=="event" then
		self:OnEvent(func)
	elseif self.Type=="alarm" then
		self:OnRing(func)
	elseif self.Type=="step" or self.Type=="tstep" then
		self:OnEnd(func)
	elseif self.Type=="loop" or self.Type=="updater" then
		self:OnBreak(func)
	else
		error("No final event exists for: "..self.Type)
	end
end
function multi:Break()
	self:Pause()
	self.Active=nil
	for i=1,#self.ender do
		self.ender[i](self)
	end
end
function multi:OnBreak(func)
	table.insert(self.ender,func)
end
function multi:isPaused()
	return not(self.Active)
end
function multi:Pause(n)
	if self.Type=="int" or self.Type=="mainint" then
		self.Active=false
		if not(n) then
			local c=self:getChildren()
			for i=1,#c do
				c[i]:Pause()
			end
		else
			self:hold(n)
		end
	else
		if n==nil then
			self.Active=false
			if self.Parent.Mainloop[self.Id]~=nil then
				table.remove(self.Parent.Mainloop,self.Id)
				table.insert(self.Parent.Paused,self)
				self.PId=#self.Parent.Paused
			end
		else
			self:hold(n)
		end
	end
end
function multi:Resume()
	if self.Type=="int" or self.Type=="mainint" then
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
	if self.Type=="int" or self.Type=="mainint" then
		local c=self:getChildren()
		for i=1,#c do
			c[i]:Destroy()
		end
	else
		for i=1,#self.Parent.Mainloop do
			if self.Parent.Mainloop[i]==self then
				table.remove(self.Parent.Mainloop,i)
				break
			end
		end
		self.Active=false
	end
end
function multi:hold(task)
	self:Pause()
	if type(task)=="number" then
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
	elseif type(task)=="function" then
		local env=self.Parent:newEvent(task)
		env:OnEvent(function(envt) envt:Pause() envt:Stop() end)
		while env.Active do
			if love then
				self.Parent:lManager()
			else
				self.Parent:Do_Order()
			end
		end
		env:Destroy()
		self:Resume()
	else
		print("Error Data Type!!!")
	end
end
function multi:oneTime(func,...)
	if not(self.Type=="mainint" or self.Type=="int") then
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
--Constructors [CORE]
function multi:newBase(ins)
	if not(self.Type=="mainint" or self.Type=="int" or self.Type=="stack") then error("Can only create an object on multi or an interface obj") return false end
	local c = {}
    if self.Type=="int" or self.Type=="stack" then
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
	if ins then
		table.insert(self.Mainloop,ins,c)
	else
		table.insert(self.Mainloop,c)
	end
	return c
end
function multi:newInterface(file)
	if not(self.Type=="mainint") then error("Can only create an interface on the multi obj") return false end
	local c = {}
    setmetatable(c, self)
	c.Parent=self
	c.Active=true
	c.func={}
	c.Id=0
	c.Type="int"
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
	function c:Stop()
		if self.l then
			self.l:Pause()
		end
	end
	function c:Remove()
		self:Destroy()
		self.l:Destroy()
	end
	if file then
		multi.Cself=c
		loadstring("interface=multi.Cself "..io.open(file,"rb"):read("*all"))()
	end
	return c
end
function multi:newStack(file)
	local c=self:newInterface()
	c.Type="stack"
	c.last={}
	c.funcE={}
	if file then
		multi.Cself=c
		loadstring("stack=multi.Cself "..io.open(file,"rb"):read("*all"))()
	end
	function c:OnStackCompleted(func)
		table.insert(self.funcE,func)
	end
	return c
end
--Constructors [ACTORS]
function multi:coustomObject(objRef,t)
	local c={}
	if t=="process" then
		c=self:newBase()
		if type(objRef)=="table" then
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
		c.Type="coustomObject"
	end
end
function multi:newEvent(task)
	local c={}
	if self.Type=="stack" then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
	c.Type="event"
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
	if self.Type=="stack" then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(function(self)
			if self.Parent.last==self then
				for i=1,#self.Parent.funcE do
					self.Parent.funcE[i](self)
				end
				self.Parent:Remove()
			end
			self:Destroy()
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end)
	end
	return c
end
function multi:newAlarm(set)
	local c={}
	if self.Type=="stack" then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
	c.Type="alarm"
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
	if self.Type=="stack" then
		c:Pause()
		c:connectFinal(function(self)
			if self.Parent.last==self then
				for i=1,#self.Parent.funcE do
					self.Parent.funcE[i](self)
				end
				self.Parent:Remove()
			end
			table.remove(self.Parent.Mainloop,#self.Parent.Mainloop)
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end)
	else
		c.timer:Start()
	end
	return c
end
function multi:newLoop(func)
	local c={}
	if self.Type=="stack" then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
	c.Type="loop"
	c.Start=multi.clock()
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
			self.func[i](multi.clock()-self.Start,self)
		end
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	if self.Type=="stack" then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(function(self)
			if self.Parent.last==self then
				for i=1,#self.Parent.funcE do
					self.Parent.funcE[i](self)
				end
				self.Parent:Remove()
			end
			self:Destroy()
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end)
	end
	return c
end
function multi:newUpdater(skip)
	local c={}
	if self.Type=="stack" then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
	c.Type="updater"
	c.pos=1
	c.skip=skip or 1
	function c:Act()
		if self.pos>=skip then
			self.pos=0
			for i=1,#self.func do
				self.func[i](self)
			end
		end
		self.pos=self.pos+1
	end
	c.OnUpdate=multi.OnMainConnect
	if self.Type=="stack" then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(function(self)
			if self.Parent.last==self then
				for i=1,#self.Parent.funcE do
					self.Parent.funcE[i](self)
				end
				self.Parent:Remove()
			end
			self:Destroy()
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end)
	end
	return c
end
function multi:newStep(start,reset,count,skip)
	local c={}
	if self.Type=="stack" then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
	think=1
	c.Type="step"
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
	if self.Type=="stack" then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(function(self)
			if self.Parent.last==self then
				for i=1,#self.Parent.funcE do
					self.Parent.funcE[i](self)
				end
				self.Parent:Remove()
			end
			self:Destroy()
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end)
	end
	return c
end
function multi:newTStep(start,reset,count,set)
	local c={}
	if self.Type=="stack" then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
	think=1
	c.Type="tstep"
	c.start=start or 1
	local reset = reset or math.huge
	c.endAt=reset
	c.pos=start or 1
	c.skip=skip or 0
	c.count=count or 1*think
	c.funcE={}
	c.timer=multi.clock()
	c.set=set or 1
	c.funcS={}
	c.Reset=c.Resume
	function c:Update(start,reset,count,set)
		self.start=start or self.start
		self.pos=start
		self.endAt=reset or self.endAt
		self.set=set or self.set
		self.count=count or self.count or 1
		self.timer=multi.clock()
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
		if multi.clock()-self.timer>=self.set then
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
		self.timer=multi.clock()
		self:Resume()
	end
	if self.Type=="stack" then
		if #self.Mainloop>1 then
			c:Pause()
		end
		c:connectFinal(function(self)
			if self.Parent.last==self then
				for i=1,#self.Parent.funcE do
					self.Parent.funcE[i](self)
				end
				self.Parent:Remove()
			end
			self:Destroy()
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end)
	end
	return c
end
-- Constructors [SEMI-ACTORS]
function multi:newJob(func,name)
	if not(self.Type=="mainint" or self.Type=="int") then error("Can only create an object on multi or an interface obj") return false end
	local c = {}
    if self.Type=="int" then
		setmetatable(c, self.Parent)
	else
		setmetatable(c, self)
	end
	c.Active=true
	c.func={}
	c.Id=0
	c.PId=0
	c.Parent=self
	c.Type="job"
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
-- Constructors [NON-ACTORS]
function multi:newWatcher(namespace,name)
	local function WatcherObj(ns,n)
		local c=multi:newBase()
		c.Type="watcher"
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
		return c
	end
	if type(namespace)~="table" and type(namespace)=="string" then
		return WatcherObj(_G,namespace)
	elseif type(namespace)=="table" and (type(name)=="string" or "number") then
		return WatcherObj(namespace,name)
	else
		print("Warning, invalid arguments! Nothing returned!")
	end
end
function multi:newTimer()
	local c={}
	c.Type="timer"
	c.time=0
	c.count=0
	function c:Start()
		self.time=multi.clock()
	end
	function c:Get()
		return (multi.clock()-self.time)+self.count
	end
	c.Reset=c.Start
	function c:Pause()
		self.time=self:Get()
	end
	function c:Resume()
		self.time=multi.clock()-self.time
	end
	function c:tofile(path)
		local m=bin.new()
		self.count=self.count+self:Get()
		m:addBlock(self.Type)
		m:addBlock(self.count)
		m:tofile(path)
	end
	return c
end
function multi:newTask(func)
	table.insert(self.Tasks,func)
end
function multi:newTrigger(func)
	local c={}
	c.Type="trigger"
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
	return c
end
function multi:newConnection()
	local c={}
	c.Type="connector"
	c.func={}
	c.ID=0
	function c:Fire(...)
		for i=#self.func,1,-1 do
			t,e=pcall(self.func[i][1],...)
			if not(t) then
				print(e)
			end
		end
	end
	function c:bind(t)
		self.func=t
	end
	function c:remove()
		self.func={}
	end
	function c:connect(func)
		self.ID=self.ID+1
		table.insert(self.func,{func,self.ID})
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
--Managers
function multi:mainloop()
	for i=1,#self.Tasks do
		self.Tasks[i](self)
	end
	rawset(self,"Start",multi.clock())
	while self.Active do
		self:Do_Order()
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
	rawset(self,"Start",multi.clock())
end
function multi:uManager(dt)
	if self.Active then
		self:oneTime(self._tFunc,self,dt)
		self:Do_Order()
	end
end
