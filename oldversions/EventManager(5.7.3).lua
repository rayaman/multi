function readonlytable(table)
   return setmetatable({}, {
     __index = table,
     __newindex = function(table, key, value)
                    error("Attempt to modify read-only table")
                  end,
     __metatable = false
   });
end
local EventRef=
readonlytable{
	Pause=function(self)
		self.active=false
		if not(event.isPaused(self)) then
			table.insert(event.Paused,self)
			for _j=1,#event.Mainloop do
				if tostring(event.Mainloop[_j])==tostring(self) then
					table.remove(event.Mainloop,_j)
				end
			end
		end
	end,
	Resume=function(self)
		self.active=true
		if event.isPaused(self) then
			table.insert(event.Mainloop,self)
			for _j=1,#event.Paused do
				if tostring(event.Paused[_j])==tostring(self) then
					table.remove(event.Paused,_j)
				end
			end
		end
	end,
	Stop=function(self)
		self.active=nil
	end,
}

local StepRef=
readonlytable{
	Step=function(self)
		if self~=nil then
			if self.spos==0 then
				_G.__CAction__=self
					if self.active==true then
						for i=1,#self.steps do
							self.steps[i](self.pos,self)
						end
						self.pos=self.pos+self.count
					end
				end
				if self.endAt+self.count<=self.pos and self.endAt>self.start then
					self:Reset()
					for i=1,#self.funcs do
						self.funcs[i](self)
					end
				elseif self.pos<=0 then
					self:Reset()
					for i=1,#self.funcs do
						self.funcs[i](self)
					end
				end
			end
			self.spos=self.spos+1
			if self.spos>=self.skip then
				self.spos=0
			end
		end,
	FStep=function(self)
		if self~=nil then
			if self.spos==0 then
				_G.__CAction__=self
					for i=1,#self.steps do
						self.steps[i](self.pos,self)
					end
					self.pos=self.pos+self.count
				end
				if self.endAt+self.count<=self.pos and self.endAt>self.start then
					self:Reset()
					for i=1,#self.funcs do
						self.funcs[i](self)
					end
				elseif self.pos==0 then
					self:Reset()
					for i=1,#self.funcs do
						self.funcs[i](self)
					end
				end
			end
			self.spos=self.spos+1
			if self.spos>=self.skip then
				self.spos=0
			end
		end,
	Remove=function(self)
		if self~=_G.__CAction__ then
			for as=1,#event.Mainloop do
				if tostring(event.Mainloop[as])==tostring(self) then
					table.remove(event.Mainloop,as)
				end
			end
		else
			table.insert(event.garbage,self)
		end
	end,
	Reset=function(self)
		self.pos=self.start
	end,
	Set=function(self,amt)
		self.pos=amt
	end,
	Pause=EventRef.Pause,
	Resume=EventRef.Resume,
	Stop=function(self)
		self:Reset()
		self.active=nil
		for i=1,#self.funcs do
			self.funcs[i](self)
		end
	end,
	End=function(self)
		for i=1,#self.funcs do
			self.funcs[i](self)
		end
		self:Reset()
	end,
	Update=function(self,start,reset,count,skip)
		self.start=start or self.start
		self.endAt=reset or self.endAt
		self.skip=skip or self.skip
		self.count=count or self.count
		self:Resume()
	end,
	OnEnd=function(self,func)
		table.insert(self.funcs,func)
	end,
	OnStep=function(self,func)
		table.insert(self.steps,func)
	end,
	FreeConnections=function(self)
		self.funcs={}
		self.steps={}
	end,
}
--thread and run setup
if love then
	function love.run()
		if love.math then
			love.math.setRandomSeed(os.time())
		end
		if love.event then
			love.event.pump()
		end
		if love.load then love.load(arg) end
		if love.timer then love.timer.step() end
		local dt = 0
		while true do
			-- Process events.
			if love.event then
				love.event.pump()
				for e,a,b,c,d in love.event.poll() do
					if e == "quit" then
						if not love.quit or not love.quit() then
							if love.audio then
								love.audio.stop()
							end
							return
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
			event.uManager(dt)
			if love.window and love.graphics and love.window.isCreated() then
				love.graphics.clear()
				love.graphics.origin()
				if love.draw then love.draw() end
				event.dManager()
				love.graphics.setColor(255,255,255,255)
				if event.draw then event.draw() end
				love.graphics.present()
			end
		end
	end
end
eThreads={
	send=function() end,




}
function RunTasks()
	for i=1,#event.DoTasks do
		event.DoTasks[i]()
	end
end
event={
	VERSION="1.0.0 (Build Version: 5.7.3)",
	Priority_Core=1,
	Priority_High=2,
	Priority_Above_Normal=4,
	Priority_Normal=16,
	Priority_Low=256,
	Priority_Idle=65536,
	Start=0,
	Active=true,
	CT=false,
	Tasks={},
	DoTasks={},
	garbage={},
	Paused={},
	last={},
	func={},
	drawF={},
	pump=false,
	pumpvar=0,
	Mainloop={},
	PEnabled=true,
	PCount=1,
	Triggers={},
	oneTimeObj=
	{
		last={},
		Resume=function(self) end,
		Pause=function(self) end,
	},
	RemoveAll=function()
		event.Mainloop={}
	end,
	GarbageObj=
	{
		Resume=function() end,
		Pause=function() end
	},
	isPaused=function(obj)
		for _j=1,#event.Paused do
			if tostring(event.Paused[_j])==tostring(obj) then
				return true
			end
		end
		return false
	end,
	DO_Order=function()
		event.oneTime(RunTasks)
		event.PCount=event.PCount+1
		for i=1,#event.Mainloop do
			if event.Mainloop[i]~=nil then
				local obj = event.Mainloop[i]
				if event.PCount%obj.Priority==0 and event.PEnabled then
					obj:Act()
				elseif event.PEnabled==false then
					obj:Act()
				end
				if event.PCount>event.Priority_Idle then
					event.PCount=event.Priority_Core
				end
			end
		end
		event.MANAGE_GARBAGE()
	end,
	MANAGE_GARBAGE=function()
		_G.__CAction__=event.GarbageObj
		for _i=1,#event.garbage do
			event.garbage[_i]:Remove()
			table.remove(event.garbage,_i)
		end
	end,
	oneTime=function(func)
		event.oneTimeObj.last=_G.__CAction__
		_G.__CAction__=event.oneTimeObj
		for _k=1,#event.Tasks do
			if event.Tasks[_k]==func then
				_G.__CAction__=event.oneTimeObj.last
				return false
			end
		end
		table.insert(event.Tasks,func)
		func()
		_G.__CAction__=event.oneTimeObj.last
		return true
	end,
	oneETime=function(func)
		for _k=1,#event.Tasks do
			if event.Tasks[_k]==string.dump(func) then
				return false
			end
		end
		table.insert(event.Tasks,string.dump(func))
		func()
		return true
	end,
	hold=function(task) -- as many conditions and times that you want can be used
		local action=__CAction__
		action:Pause()
		if type(task)=="number" then
			local alarm=event.newAlarm(task,function() end,true)
			while alarm.active==true do
				if love then
					event.lManager()
				else
					event.cManager()
				end
			end
			alarm:Remove()
			action:Resume()
		elseif type(task)=="function" then
			local env=event.newEvent(task,function(envt) envt:Pause() envt:Stop() end)
			while env.active do
				if love then
					event.lManager()
				else
					event.cManager()
				end
			end
			env:Remove()
			action:Resume()
		else
			print("Error Data Type!!!")
		end
	end,
	waitFor=function(obj)
		local obj=obj
		event.hold(function() return not(obj.active) end)
	end,
	getType=function(obj)
		if obj.Type~=nil then
			return obj.Type
		end
	end,
	newEvent=function(test,task)
		temp=
		{
			Priority=event.Priority_Normal,
			_Priority=0,
			Parent=event.Events,
			Type="Event",
			active=true,
			test=test or (function() end),
			task={task} or {},
			Act=function(self)
				_G.__CAction__=self
				if self:test(self)==true then
					self:Pause()
					self:Stop()
					for i=1,#self.task do
						self.task[i](self)
					end
				end
			end,
			Reset=function(self) self:Resume() end,
			Stop=EventRef.Stop,
			Pause=EventRef.Pause,
			Resume=EventRef.Resume,
			OnEvent=function(self,func)
				table.insert(self.task,func)
			end,
			FreeConnections=function(self)
				self.task={}
			end,
			Remove=function(self)
				if self~=_G.__CAction__ then
					for i=1,#event.Mainloop do
						if tostring(event.Mainloop[i])==tostring(self) then
							table.remove(event.Mainloop,i)
						end
					end
				else
					table.insert(event.garbage,self)
				end
			end,
		}
		table.insert(event.Mainloop,temp)
		event.last=temp
		return temp
	end,
	newAlarm=function(set,func,start)
		if not(start) then
			timer=0
			active=false
		else
			timer=os.clock()
			active=true
		end
		if not(func) then
			func=(function() end)
		end
		Alarm=
		{
			Priority=event.Priority_Normal,
			_Priority=0,
			Parent=event.Alarms,
			Type="Alarm",
			active=active,
			timer=timer,
			set=set or 0,
			func={func},
			Act=function(self)
				_G.__CAction__=self
				if self.active==true then
					if os.clock()-self.timer>=self.set then
						self:Pause()
						self:Stop()
						self:Ring()
					end
				end
			end,
			FreeConnections=function(self)
				self.func={}
			end,
			Stop=EventRef.Stop,
			Pause=EventRef.Pause,
			Set=function(self,amt)
				self.set=amt
				self.timer=os.clock()
				self:Resume()
			end,
			OnRing=function(self,func)
				table.insert(self.func,func)
			end,
			Ring=function(self)
				for i=1,#self.func do
					self.func[i](self)
				end
			end,
			Reset=function(self)
				self.timer=os.clock()
				self:Resume()
			end,
			Resume=EventRef.Resume,
			Remove=function(self)
				if self~=_G.__CAction__ then
					for i=1,#event.Mainloop do
						if tostring(event.Mainloop[i])==tostring(self) then
							table.remove(event.Mainloop,i)
						end
					end
				else
					table.insert(event.garbage,self)
				end
			end,
		}
		table.insert(event.Mainloop,Alarm)
		event.last=temp
		return Alarm
	end,
	newTask=function(func)
		table.insert(event.DoTasks,func)
	end,
	createLoop=function()
		temp=
		{
			Priority=event.Priority_Normal,
			_Priority=0,
			Parent=event.Loops,
			Type="Loop",
			active=true,
			func={},
			OnLoop=function(self,func)
				table.insert(self.func,func)
			end,
			Stop=EventRef.Stop,
			Pause=EventRef.Pause,
			Resume=EventRef.Resume,
			Act=function(self)
				_G.__CAction__=self
				for i=1,#self.func do
					self.func[i](os.clock()-event.Start,self)
				end
			end,
			Remove=function(self)
				if self~=_G.__CAction__ then
					for i=1,#event.Mainloop do
						if tostring(event.Mainloop[i])==tostring(self) then
							table.remove(event.Mainloop,i)
						end
					end
				else
					table.insert(event.garbage,self)
				end
			end,
			FreeConnections=function(self)
				self.func={}
			end,
		}
		table.insert(event.Mainloop,temp)
		event.last=temp
		return temp
	end,
	createStep=function(start,reset,count,skip)
		think=1
		if start~=nil and reset~=nil then
			if start>reset then
				think=-1
			end
		end
		if not(endc) then
			endc=false
		end
		temp=
		{
			Priority=event.Priority_Normal,
			_Priority=0,
			start=start or 1,
			Parent=event.Steps,
			Type="Step",
			pos=start or 1,
			endAt=reset or math.huge,
			active=true,
			skip=skip or 0,
			spos=0,
			count=count or 1*think,
			funcs={},
			steps={},
			Act=StepRef.Step,
			FAct=StepRef.FStep,
			Remove=StepRef.Remove,
			Reset=StepRef.Reset,
			Set=StepRef.Set,
			Pause=StepRef.Pause,
			Resume=StepRef.Resume,
			Stop=StepRef.Stop,
			End=StepRef.End,
			Update=StepRef.Update,
			OnEnd=StepRef.OnEnd,
			OnStep=StepRef.OnStep,
			FreeConnections=StepRef.FreeConnections
		}
		table.insert(event.Mainloop,temp)
		event.last=temp
		return temp
	end,
	createTStep=function(start,reset,timer,count)
		think=1
		if start~=nil and reset~=nil then
			if start>reset then
				think=-1
			end
		end
		if not(endc) then
			endc=false
		end
		timer=timer or 1
		local _alarm=event.newAlarm(timer,function(alarm) alarm.Link:Act() alarm:Reset() end,true)
		temp=
		{
			Priority=event.Priority_Normal,
			_Priority=0,
			start=start or 1,
			Parent=event.TSteps,
			Type="TStep",
			pos=start or 1,
			endAt=reset or math.huge,
			active=true,
			skip= 0,
			spos=0,
			count=count or 1*think,
			funcs={},
			steps={},
			alarm=_alarm,
			Act=StepRef.Step,
			FAct=StepRef.FStep,
			Remove=function(self)
				if self~=_G.__CAction__ then
					for as=1,#event.Mainloop do
						if tostring(event.Mainloop[as])==tostring(self) then
							table.remove(event.Mainloop,as)
						end
					end
					self.alarm:Remove()
				else
					table.insert(event.garbage,self)
				end
			end,
			Reset=StepRef.Reset,
			Set=StepRef.Set,
			Pause=StepRef.Pause,
			Resume=StepRef.Resume,
			Stop=StepRef.Stop,
			End=StepRef.End,
			Update=function(self,start,reset,timer,count)
				if start~=nil and reset~=nil then
					if start>reset then
						if not(count<0) then
							print("less")
							count=-count
						end
					end
				end
				self.start=start or self.start
				self.endAt=reset or self.endAt
				if timer~=nil then
					self.alarm:Set(timer)
				end
				self.count=count or self.count
				self.pos=self.start
				self:Resume()
			end,
			OnEnd=StepRef.OnEnd,
			OnStep=StepRef.OnStep,
			FreeConnections=StepRef.FreeConnections
		}
		_alarm.Link=temp
		event.last=temp
		return temp
	end,
	createTrigger=function(func)
		temp={
			active=true,
			trigfunc=func,
			Remove=function(self)
				for i=1,#event.Triggers do
					if event.Triggers[i]==self then
						table.remove(event.Triggers,i)
					end
				end
			end,
			Pause=function(self) self.active=false end,
			Resume=function(self) self.active=true end,
			Fire=function(self,...)
				if self.active==true then
					local tempA=__CAction__
					__CAction__=self
					self:trigfunc(...)
					__CAction__=tempA
				end
			end,
		}
		table.insert(event.Triggers,temp)
		return temp
	end,
	stop=function()
		event.Active=false
	end,
	onStart=function() end,
	onUpdate=function(func)
		local temp=event.createLoop()
		temp:OnLoop(func)
		temp.Priority=1
	end,
	onDraw=function(func)
		table.insert(event.drawF,func)
	end,
	onClose=function() end,
	manager=function()
		if not(love) then
			event.onStart()
			event.Start=os.clock()
			while event.Active==true do
				event.DO_Order()
			end
			event.onClose()
			return os.clock()-event.Start
		else
			return false
		end
	end,
	cManager=function()
		if event.Active==true then
			event.DO_Order()
		end
	end,
	uManager=function(dt)
		if event.CT==false then
			if dt then
				event.pump=true
			end
			event.CT=true
			event.onStart()
			event.Start=os.clock()
		end
		event.pumpvar=dt
		if event.Active==true then
			event.DO_Order()
		end
	end,
	dManager=function()
		for ii=1,#event.drawF do
			event.drawF[ii]()
		end
	end,
	lManager=function()
		if love.event then
			love.event.pump()
			for e,a,b,c,d in love.event.poll() do
				if e == "quit" then
					if not love.quit or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
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
		event.uManager(dt)
		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			event.dManager()
			love.graphics.present()
		end
	end,
	benchMark=function(sec,p)
		p=p or event.Priority_Normal
		local temp=event.createStep(10)
		temp.CC=0
		temp:OnStep(function(pos,step) step.CC=step.CC+1 end)
		local Loud=event.newAlarm(sec,nil,true)
		Loud.Link=temp
		Loud:OnRing(function(alarm) print((alarm.Link.CC).." steps in "..alarm.set.." second(s)") end)
		temp.Priority=p
		Loud.Priority=p
		return Loud
	end,
}
