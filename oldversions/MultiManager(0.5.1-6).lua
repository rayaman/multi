multi = {}
multi.Version="5.1.6"
multi.__index = multi
multi.Mainloop={}
multi.Tasks={}
multi.Tasks2={}
multi.Garbage={}
multi.Children={}
multi.Paused={}
multi.MasterId=0
multi.Active=true
multi.Id=-1
multi.Type="mainint"
multi.Rest=0
multi._type=type
multi.Jobs={}
multi.queue={}
multi.jobUS=2
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
	self.MasterId=self.MasterId+1
	return c
end
function multi:reboot(r)
	self.Mainloop={}
	self.Tasks={}
	self.Tasks2={}
	self.Garbage={}
	self.Children={}
	self.Paused={}
	self.MasterId=0
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
	for _D=#self.Mainloop,1,-1 do
		if self.Mainloop[_D]~=nil then
			self.Mainloop[_D].Id=_D
			self.Mainloop[_D]:Act()
		end
		if self.Mainloop[_D]~=nil then
			if self.Mainloop[_D].rem~=nil then
				table.remove(self.Mainloop,_D)
			end
		end
	end
	if self.Rest~=0 then
		os.sleep(self.Rest)
	end
end
function multi:benchMark(sec)
	local temp=self:newLoop(function(t,self)
		if os.clock()-self.init>self.sec then
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
	temp.init=os.clock()
	temp.c=0
	return temp
end
function multi:newInterface()
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
	c.MasterId=0
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
	return c
end
function multi:newStack(file)
	local c=self:newInterface()
	c.Type="stack"
	stack=c
	c.last={}
	c.funcE={}
	if file then
		dofile(file)
	end
	function c:OnStackCompleted(func)
		table.insert(self.funcE,func)
	end
	return c
end
--Helpers
function multi:protect()
	function self:Do_Order()
		for _D=#self.Mainloop,1,-1 do
			if self.Mainloop[_D]~=nil then
				self.Mainloop[_D].Id=_D
				local status, err=pcall(self.Mainloop[_D].Act,self.Mainloop[_D])
				if err and not(self.Mainloop[_D].error) then
					self.Mainloop[_D].error=err
					print(err..": Ingoring error continuing...")
				end
			end
			if self.Mainloop[_D]~=nil then
				if self.Mainloop[_D].rem~=nil then
					table.remove(self.Mainloop,_D)
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
		for _D=#self.Mainloop,1,-1 do
			if self.Mainloop[_D]~=nil then
				self.Mainloop[_D].Id=_D
				self.Mainloop[_D]:Act()
			end
			if self.Mainloop[_D]~=nil then
				if self.Mainloop[_D].rem~=nil then
					table.remove(self.Mainloop,_D)
				end
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
	elseif self.Type=="loop" then
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
function multi:Destroy()
	if self.Type=="int" or self.Type=="mainint" then
		local c=self:getChildren()
		for i=1,#c do
			c[i]:Destroy()
		end
	else
		self.rem=true
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
--Constructors
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
		if self.Task(self) and self.Active==true then
			self:Pause()
			for _E=1,#self.func do
				self.func[_E](self)
			end
		end
	end
	function c:OnEvent(func)
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
function multi:newAlarm(set)
	local c={}
	if self.Type=="stack" then
		c=self:newBase(1)
		self.last=c
	else
		c=self:newBase()
	end
	c.Type="alarm"
	c.timer=os.clock()
	c.set=set or 0
	function c:Act()
		if self.Active==true then
			if os.clock()-self.timer>=self.set then
				self:Pause()
				self.Active=false
				for i=1,#self.func do
					self.func[i](self)
				end
			end
		end
	end
	function c:Resume()
		self.Parent.Resume(self)
		self.timer=os.clock()
		self.Active=true
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=os.clock()
		self:Resume()
		self.Active=true
	end
	function c:OnRing(func)
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
			table.remove(self.Parent.Mainloop,#self.Parent.Mainloop)
			self.Parent.Mainloop[#self.Parent.Mainloop]:Resume()
		end)
	end
	return c
end
function multi:newTask(func)
	table.insert(self.Tasks,func)
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
	c.Start=os.clock()
	if func then
		c.func={func}
	end
	function c:Act()
		if self.Active==true then
			for i=1,#self.func do
				self.func[i](os.clock()-self.Start,self)
			end
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
	function c:Act()
		if self~=nil then
			if self.spos==0 then
				if self.Active==true then
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
		end
		self.spos=self.spos+1
		if self.spos>=self.skip then
			self.spos=0
		end
	end
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
	c.timer=os.clock()
	c.set=set or 1
	c.funcS={}
	function c:Update(start,reset,count,set)
		self.start=start or self.start
		self.pos=start
		self.endAt=reset or self.endAt
		self.set=set or self.set
		self.count=count or self.count or 1
		self.timer=os.clock()
		self:Resume()
	end
	function c:Act()
		if self.Active then
			if os.clock()-self.timer>=self.set then
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
function multi:newTrigger(func)
	local c={}
	c.Type="trigger"
	c.trigfunc=func or function() end
	function c:Fire(...)
		self:trigfunc(self,...)
	end
	return c
end
function multi:newConnection()
	local c={}
	c.Type="connector"
	c.func={}
	function c:Fire(...)
		for i=1,#self.func do
			t,e=pcall(self.func[i],...)
			if not(t) then
				print(e)
			end
		end
	end
	function c:bind(t)
		self.func=t
	end
	function c:connect(func)
		table.insert(self.func,func)
	end
	return c
end
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
--Managers
function multi:mainloop()
	for i=1,#self.Tasks do
		self.Tasks[i](self)
	end
	self.Start=os.clock()
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
	self.Start=os.clock()
end
function multi:uManager(dt)
	if self.Active then
		self:oneTime(self._tFunc,self,dt)
		self:Do_Order()
	end
end
