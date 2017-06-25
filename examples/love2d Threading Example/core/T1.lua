require("love.timer")
require("love.system")
require("love.sound")
require("love.physics")
require("love.mouse")
require("love.math")
require("love.keyboard")
require("love.joystick")
require("love.image")
require("love.font")
require("love.filesystem")
require("love.event")
require("love.audio")
require("love.graphics")
require("love.window")
_defaultfont = love.graphics.getFont()
gui = {}
function gui.getTile(i,x,y,w,h)-- returns imagedata
	if type(i)=="userdata" then
		-- do nothing
	else
		error("getTile invalid args!!! Usage: ImageElement:getTile(x,y,w,h) or gui:getTile(imagedata,x,y,w,h)")
	end
	local iw,ih=i:getDimensions()
	local id,_id=i:getData(),love.image.newImageData(w,h)
	for _x=x,w+x-1 do
		for _y=y,h+y-1 do
			_id:setPixel(_x-x,_y-y,id:getPixel(_x,_y))
		end
	end
	return love.graphics.newImage(_id)
end
multi = {}
multi.Version="4.0.0"
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
multi.Type="MainInt"
multi.Rest=0
-- System
os.sleep=love.timer.sleep
function multi:newBase(ins)
	if not(self.Type=="MainInt" or self.Type=="int") then error("Can only create an object on multi or an interface obj") return false end
	local c = {}
    if self.Type=="int" then
		setmetatable(c, self.Parent)
	else
		setmetatable(c, self)
	end
	c.Active=true
	c.func={}
	c.Id=0
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
		if self.Mainloop[_D].rem then
			table.remove(self.Mainloop,_D)
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
	if not(self.Type=="MainInt") then error("Can only create an interface on the multi obj") return false end
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
	if self.Type=="int" or self.Type=="MainInt" then
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
		if not(n) then
			self.Active=false
			if self.Parent.Mainloop[self.Id]~=nil then
				table.remove(self.Parent.Mainloop,self.Id)
				table.insert(self.Parent.Paused,self)
				self.Id=#self.Parent.Paused
			end
		else
			self:hold(n)
		end
	end
end
function multi:Resume()
	if self.Type=="int" or self.Type=="MainInt" then
		self.Active=true
		local c=self:getChildren()
		for i=1,#c do
			c[i]:Resume()
		end
	else
		if self:isPaused() then
			self.Active=true
			for i=1,#self.Parent.Paused do
				if self.Parent.Paused[i]==self then
					table.remove(self.Parent.Paused,i)
					return
				end
			end
			table.insert(self.Parent.Mainloop,self)
		end
	end
end
function multi:Destroy()
	if self.Type=="int" or self.Type=="MainInt" then
		local c=self:getChildren()
		for i=1,#c do
			c[i]:Destroy()
		end
	else
		self.rem=true
	end
end
function multi:hold(task)
	self:Pause()
	if type(task)=="number" then
		local alarm=self:newAlarm(task)
		while alarm.Active==true do
			if love then
				self.Parent.lManager()
			else
				self.Parent.Do_Order()
			end
		end
		alarm:Destroy()
		self:Resume()
	elseif type(task)=="function" then
		local env=self.Parent:newEvent(task)
		env:OnEvent(function(envt) envt:Pause() envt:Stop() end)
		while env.Active do
			if love then
				self.Parent.lManager()
			else
				self.Parent.Do_Order()
			end
		end
		env:Destroy()
		self:Resume()
	else
		print("Error Data Type!!!")
	end
end
function multi:oneTime(func,...)
	if not(self.Type=="MainInt" or self.Type=="int") then
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
	local c=self:newBase()
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
	table.insert(self.Tasks,func)
end
function multi:newLoop(func)
	local c=self:newBase()
	c.Type="Loop"
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
	return c
end
function multi:newStep(start,reset,count,skip)
	local c=self:newBase()
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
	local c=self:newBase()
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
function multi:newTrigger(func)
	local c=self:newBase()
	c.Type="Trigger"
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
	print("once!")
	if dt then
		self.pump=true
	end
	self.pumpvar=dt
	self.Start=os.clock()
end
function multi:uManager(dt)
	self:oneTime(self._tFunc,self,dt)
	self:Do_Order()
end
multi.drawF={}
function multi:dManager()
	for ii=1,#multi.drawF do
		multi.drawF[ii]()
	end
end
function multi:onDraw(func)
	table.insert(self.drawF,func)
end
function multi:lManager()
	if love.event then
		love.event.pump()
		for e,a,b,c,d in love.event.poll() do
			if e == "quit" then
				if not love.quit or not love.quit() then
					if love.audio then
						love.audio.stop()
					end
					return nil
				end
			end
			love.handlers[e](a,b,c,d)
		end
	end
	if love.timer then
		love.timer.step()
		dt = love.timer.getDelta()
	end
	if love.update then love.update(dt) end
	multi:uManager(dt)
	if love.window and love.graphics and love.window.isCreated() then
		love.graphics.clear()
		love.graphics.origin()
		if love.draw then love.draw() end
		multi.dManager()
		love.graphics.setColor(255,255,255,255)
		if multi.draw then multi.draw() end
		love.graphics.present()
	end
end
Thread={}
Thread.Name="Thread 1"
Thread.ChannelThread = love.thread.getChannel("Easy1")
Thread.ChannelMain = love.thread.getChannel("EasyMain")
Thread.Global = {}
function Thread:packTable(G)
	function escapeStr(str)
		local temp=""
		for i=1,#str do
			temp=temp.."\\"..string.byte(string.sub(str,i,i))
		end
		return temp
	end
	function ToStr(t)
		local dat="{"
		for i,v in pairs(t) do
			if type(i)=="number" then
				i="["..i.."]="
			else
				i=i.."="
			end
			if type(v)=="string" then
				dat=dat..i.."\""..v.."\","
			elseif type(v)=="number" then
				dat=dat..i..v..","
			elseif type(v)=="boolean" then
				dat=dat..i..tostring(v)..","
			elseif type(v)=="table" and not(G==v) then
				dat=dat..i..ToStr(v)..","
			--elseif type(v)=="table" and G==v then
			--	dat=dat..i.."assert(loadstring(\"return self\")),"
			elseif type(v)=="function" then
				dat=dat..i.."assert(loadstring(\""..escapeStr(string.dump(v)).."\")),"
			end
		end
		return string.sub(dat,1,-2).."}"
	end
	return "return "..ToStr(G)
end
function Thread:Send(name,var)
	arg3="1"
	if type(var)=="table" then
		var=Thread:packTable(var)
		arg3="table"
	end
	self.ChannelMain:push({name,var,arg3})
end
function Thread:UnPackChannel()
	local c=self.ChannelThread:getCount()
	for i=1,c do
		local temp=self.ChannelThread:pop()
		if temp[1] and temp[2] then
			if temp[1]=="func" and type(temp[2])=="string" then
				loadstring(temp[2])(temp[3])
			elseif temp[1]=="table" then
				_G[temp[3]]=loadstring(temp[2])()
			else
				_G[temp[1]]=temp[2]
			end
		end
	end
	if #multi:getChildren()<2 then
		os.sleep(.05)
	end
end
function Thread:boost(func,name)
	self:Send(name,string.dump(func))
end
function Thread.mainloop()
	Thread:UnPackChannel()
end
Thread.MainThread=false
multi:newLoop():OnLoop(Thread.mainloop)
multi:mainloop()
