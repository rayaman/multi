multi = {}
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
-- System
function multi:newBase(ins)
	local c = {}
    setmetatable(c, multi)
	c.Parent=self
	c.Active=true
	c.func={}
	c.Id=0
	c.Act=function() end
	if ins then
		table.insert(multi.Mainloop,ins,c)
	else
		table.insert(multi.Mainloop,c)
	end
	multi.MasterId=multi.MasterId+1
	return c
end
function multi:reboot(r)
	multi.Mainloop={}
	multi.Tasks={}
	multi.Tasks2={}
	multi.Garbage={}
	multi.Children={}
	multi.Paused={}
	multi.MasterId=0
	multi.Active=true
	multi.Id=-1
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
--Processor
function multi.Do_Order()
	for _D=#multi.Mainloop,1,-1 do
		if multi.Mainloop[_D]~=nil then
			multi.Mainloop[_D].Id=_D
			multi.Mainloop[_D]:Act()
		end
	end
end
function multi:benchMark(sec)
	local temp=multi:newStep(2)
	temp.CC=0
	temp:OnStep(function(pos,step) step.CC=step.CC+1 end)
	local Loud=multi:newAlarm(sec)
	Loud.Link=temp
	Loud:OnRing(function(alarm) alarm.Link.CC=alarm.Link.CC print((alarm.Link.CC).." steps in "..alarm.set.." second(s)") alarm.bench=alarm.Link.CC alarm.Link:Destroy() alarm:Destroy() end)
	return Loud
end
--Helpers
function multi:FreeMainEvent()
	self.func={}
end
function multi:isPaused()
	return not(self.Active)
end
function multi:Pause(n)
	if not(n) then
		self.Active=false
		table.remove(multi.Mainloop,self.Id)
		table.insert(multi.Paused,self)
	else
		self:hold(n)
	end
end
function multi:Resume()
	if self:isPaused() then
		self.Active=true
		table.remove(multi.Paused,self.Id)
		table.insert(multi.Mainloop,self)
	end
end
function multi:Remove()
	self:Pause()
	self:Destroy()
end
function multi:Destroy()
	self:Pause()
	if self:isPaused() then
		for i=1,#multi.Paused do
			if multi.Paused[i]==self then
				table.remove(multi.Paused,i)
				return
			end
		end
	else
		table.remove(multi.Mainloop,self.Id)
	end
	self.Act=function() end
end
function multi:hold(task)
	self:Pause()
	if type(task)=="number" then
		local alarm=multi:newAlarm(task)
		while alarm.Active==true do
			if love then
				multi.lManager()
			else
				multi.Do_Order()
			end
		end
		alarm:Destroy()
		self:Resume()
	elseif type(task)=="function" then
		local env=multi:newEvent(task)
		env:OnEvent(function(envt) envt:Pause() envt:Stop() end)
		while env.Active do
			if love then
				multi.lManager()
			else
				multi.Do_Order()
			end
		end
		env:Destroy()
		self:Resume()
	else
		print("Error Data Type!!!")
	end
end
function multi:oneTime(func,...)
		for _k=1,#multi.Tasks2 do
			if multi.Tasks2[_k]==func then
				return false
			end
		end
		table.insert(multi.Tasks2,func)
		func(...)
		return true
end
--Constructors
function multi:newEvent(task)
	local c=multi:newBase()
	c.Type="Event"
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
	return c
end
function multi:newAlarm(set)
	local c=multi:newBase()
	c.Type="Alarm"
	c.timer=os.clock()
	c.set=set or 0
	function c:Act()
		if self.Active==true then
			if os.clock()-self.timer>=self.set then
				self:Pause()
				for i=1,#self.func do
					self.func[i](self)
				end
			end
		end
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=os.clock()
		self:Resume()
	end
	function c:OnRing(func)
		table.insert(self.func,func)
	end
	return c
end
function multi:newTask(func)
	table.insert(multi.Tasks,func)
end
function multi:newLoop()
	local c=multi:newBase()
	c.Type="Loop"
	function c:Act()
		if self.Active==true then
			for i=1,#self.func do
				self.func[i](os.clock()-multi.Start,self)
			end
		end
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	return c
end
function multi:newStep(start,reset,count,skip)
	local c=multi:newBase()
	think=1
	c.Type="Step"
	c.pos=start or 1
	c.endAt=reset or math.huge
	c.skip=skip or 0
	c.spos=0
	c.count=count or 1*think
	c.funcE={}
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
					for i=1,#self.func do
						self.func[i](self.pos,self)
					end
					self.pos=self.pos+self.count
				end
			end
		end
		self.spos=self.spos+1
		if self.spos>=self.skip then
			self.spos=0
		end
	end
	function c:OnStep(func)
		table.insert(self.func,1,func)
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
	end
	function c:Update(start,reset,count,skip)
		self.start=start or self.start
		self.endAt=reset or self.endAt
		self.skip=skip or self.skip
		self.count=count or self.count
		self:Resume()
	end
	c:OnStep(function(p,s)
		if s.count>0 and s.endAt==p then
			for fe=1,#s.funcE do
				s.funcE[fe](s)
			end
			s.pos=s.start-1
		elseif s.count<0 and s.endAt==p then
			for fe=1,#s.funcE do
				s.funcE[fe](s)
			end
			s.pos=s.start-1
		end
	end)
	return c
end
function multi:newTStep(start,reset,count,set)
	local c=multi:newBase()
	think=1
	c.Type="TStep"
	c.start=start or 1
	local reset = reset or math.huge
	c.endAt=reset
	c.pos=start or 1
	c.skip=skip or 0
	c.count=count or 1*think
	c.funcE={}
	c.timer=os.clock()
	c.set=set or 1
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
				for i=1,#self.func do
					self.func[i](self.pos,self)
				end
				if self.endAt==self.pos then
					for fe=1,#self.funcE do
						self.funcE[fe](self)
					end
					self.pos=self.start-1
				end
				self.pos=self.pos+self.count
			end
		end
	end
	function c:OnEnd(func)
		table.insert(self.funcE,func)
	end
	function c:Reset(n)
		if n then self.set=n end
		self.timer=os.clock()
		self:Resume()
	end
	function c:OnStep(func)
		table.insert(self.func,func)
	end
	return c
end

function multi:inQueue(func)
	if self.Id==-1 then
		print("Error: Can't queue the multi object")
		return
	end
	local c=multi:newBase(self.Id)
	self.Id=self.Id-1
	c.Type="Queue"
	c.Task=func
	c.Link=self
	function c:Act()
		self.Task(self.Link)
		self:Destroy()
	end
end
function multi:newTrigger(func)
	local c=multi:newBase()
	c.Type="Trigger"
	c.trigfunc=func or function() end
	function c:Fire(...)
		self:trigfunc(self,...)
	end
	return c
end
--Managers
function multi:mainloop()
	for i=1,#multi.Tasks do
		multi.Tasks[i]()
	end
	multi.Start=os.clock()
	while self.Active do
		multi.Do_Order()
	end
end
function multi._tFunc(dt)
	if dt then
		multi.pump=true
	end
	multi.pumpvar=dt
	multi.Start=os.clock()
end
function multi:uManager(dt)
	multi:oneTime(multi._tFunc,dt)
	multi.Do_Order()
end
