multi = {}
multi.Version="4.0.1"
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
--[[function type(v)
	local t={}
	if multi._type(v)=="table" then
		t=getmetatable(v)
		if v.Type~=nil then
			if multi._type(v.Type)=="string" then
				return v.Type
			end
		end
	end
	if t.__type~=nil then
		return t.__type
	else
		return multi._type(v)
	end
end]]
-- System
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
	if self.Rest>0 then
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
--Helpers
function multi:FreeMainEvent()
	self.func={}
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
--Constructors
function multi:newEvent(task)
	local c=self:newBase()
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
	return c
end
function multi:newAlarm(set)
	local c=self:newBase()
	c.Type="alarm"
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
		self.Active=true
	end
	function c:OnRing(func)
		table.insert(self.func,func)
	end
	return c
end
function multi:newTask(func)
	table.insert(self.Tasks,func)
end
function multi:newLoop(func)
	local c=self:newBase()
	c.Type="loop"
	if func then
		c.func={func}
	end
	function c:Act()
		if self.Active==true then
			for i=1,#self.func do
				self.func[i](os.clock()-self.Parent.Start,self)
			end
		end
	end
	function c:OnLoop(func)
		table.insert(self.func,func)
	end
	function c:Break()
		self.Active=nil
	end
	return c
end
function multi:newStep(start,reset,count,skip)
	local c=self:newBase()
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
	return c
end
function multi:newTStep(start,reset,count,set)
	local c=self:newBase()
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
	return c
end
function multi:newTrigger(func)
	local c=self:newBase()
	c.Type="trigger"
	c.trigfunc=func or function() end
	function c:Fire(...)
		self:trigfunc(self,...)
	end
	return c
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
