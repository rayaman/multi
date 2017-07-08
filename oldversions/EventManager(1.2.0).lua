function dump(t,indent)
    local names = {}
    if not indent then indent = "" end
    for n,g in pairs(t) do
        table.insert(names,n)
    end
    table.sort(names)
    for i,n in pairs(names) do
        local v = t[n]
        if type(v) == "table" then
            if(v==t) then -- prevent endless loop if table contains reference to itself
                print(indent..tostring(n)..": <-")
            else
                print(indent..tostring(n)..":")
                dump(v,indent.."   ")
            end
        else
            if type(v) == "function" then
                print(indent..tostring(n).."()")
            else
                print(indent..tostring(n)..": "..tostring(v))
            end
        end
    end
end
function SetCounter()
	return os.clock()
end
----------------------------------------------------------------------------------------------------
function GetCounter(count)
	if count~=nil then
		return os.clock()-count
	else
		return 0
	end
end
----------------------------------------------------------------------------------------------------
clock=os.clock
event={
	Active=true,
	CT=false,
	tag={},
	Events={},
	Alarms={},
	EventTracker={},
	Steps={},
	TSteps={},
	CTask="",
	LoadOrder="/E/S/A/U",
	UpdateObj=
	{
		LoadOrder="",
		Resume=function(self) event.LoadOrder=self.LoadOrder end,
		Pause=function(self) self.LoadOrder=event.LoadOrder event.LoadOrder=event.LoadOrder:gsub("/U", "") end,
	},
	setLoadOrder=function(self,str) event.LoadOrder=string.upper(str) end,
	DO_Order=function() LoadOrder=event.LoadOrder LoadOrder=LoadOrder:gsub("/A", "event.RUN_ALARMS(); ") LoadOrder=LoadOrder:gsub("/E", "event.RUN_EVENTS(); ") LoadOrder=LoadOrder:gsub("/S", "event.RUN_STEPS(); ") LoadOrder=LoadOrder:gsub("/U", "event.RUN_UPDATES(); ") assert(loadstring(LoadOrder))() end,
	RUN_EVENTS=function() event.CTask="events" for d=1,#event.Events do assert(loadstring(event.Events[d]))() end end,
	RUN_STEPS=function() event.CTask="steps" for s_g=1,#event.Steps do event.Steps[s_g]:Step() end end,
	RUN_UPDATES=function() _G.__CAction__=event.UpdateObj event.CTask="updates" event.OnUpdate() end,
	RUN_ALARMS=function() for i=1,#event.Alarms do event.Alarms[i]:Tick() end end,
	--System Used Functions
	Hold=function(self,task) -- as many conditions and times that you want can be used
		local action=__CAction__
		action:Pause()
		if type(task)=="number" then
			local func=function() end
			local alarm=event:newAlarm(task,func,true)
			while alarm.active==true do
				event.CManager()
			end
			alarm:Destroy()
			action:Resume()
		elseif type(task)=="string" then
			assert(loadstring("while not("..task..") do event.CManager() end"))()
			action:Resume()
		end
	end,
	newAlarm=function(self,set,func,start)
		if not(start) then timer=0 active=false else timer=clock() active=true end
		if not(func) then func=(function() end) end
		Alarm=
		{
			active=active,
			timer=timer,
			set=set or 0,
			func=func,
			Tick=function(self) _G.__CAction__=self if self.active==true then if clock()-self.timer>=self.set then self:Pause() self:Ring() end end end,
			Pause=function(self) self.active=false end,
			Set=function(self,amt) self.set=amt self.timer=clock() self:Resume() end,
			OnRing=function(self,func) self.func=func end,
			Ring=function(self) self:func(self) end,
			Reset=function(self) self.timer=clock() self:Resume() end,
			Resume=function(self) self.active=true end,
			Destroy=function(self) for i=1,#event.Alarms do if tostring(event.Alarms[i])==tostring(self) then table.remove(event.Alarms,i) end end end,
		}
		table.insert(event.Alarms,Alarm)
		return Alarm
	end,
	setAlarm=function(self,tag,set)
		if event:eventExist("Alarm_"..tag.."(\""..tag.."\")")==false then
			event:new("Alarm_"..tag.."(\""..tag.."\")",[[GetCounter(event:getTracker("_Alarm_]]..tag..[["))>=]]..set,[[event:removeAlarm("]]..tag..[[")]])
			event:addTracker("_Alarm_"..tag,SetCounter())
			assert(loadstring("if Alarm_"..tag.."==nil then function Alarm_"..tag.."() print('No function \"Alarm_"..tag.."()\" exists make sure you created it') end end"))()
		else
			event:addTracker("_Alarm_"..tag,SetCounter())
		end
	end,
	setEvent=function(self,fname,condition,also) if not(string.find(fname,"(",1,true)) and not(string.find(fname,")",1,true)) then fname=fname.."()" end a=string.find(fname,"(",1,true) tempstr=string.sub(fname,1,a-1) event:new("Event_"..fname,condition,also) assert(loadstring("if Event_"..tempstr.."==nil then function Event_"..tempstr.."() print('No function \"Event_"..tempstr.."()\" exists make sure you created it') end end"))() end,
	removeAlarm=function(self,tag) event:destroyEvent("Alarm_"..tag) event:removeTracker("_Alarm_"..tag) end,
	updateAlarm=function(self,tag,set) event:removeAlarm(tag) event:setAlarm(tag,set) end,
	addTracker=function(self,varname,var) event.EventTracker[varname]=var end,
	getTracker=function(self,varname) return event.EventTracker[varname] end,
	listTrackers=function(self) return event.EventTracker end,
	removeTracker=function(self,var) event.EventTracker[var]=nil end,
	trackerExist=function(self,tag) return event.EventTracker[tag]~=nil end,
	updateTracker=function(self,tag,val) if event:trackerExist(tag) then event.EventTracker[tag]=val end end,
	alarmExist=function(self,tag) return (event:getTracker("_Alarm_"..tag)~=nil) end,
	new=function(self,fname,condition,also) if not(also) then also="" end table.insert(self.Events,"if "..condition.." then "..also.." "..fname.." end") table.insert(event.tag,fname) end,
	eventExist=function(self,tag) for j=1,#event.tag do if event.tag[j]==tag then return true end end return false end,
	destroyEvent=function(self,tag) for j=1,#event.tag do if event.tag[j]==tag then table.remove(event.tag,j) table.remove(event.Events,j) end end end,
	Stop=function() event.Active=false end,
	OnCreate=function() end,
	OnUpdate=function() end,
	OnClose=function() end,
	getActive=function() return event.tag end,
	Manager=function() event.OnCreate() while event.Active==true do event.DO_Order() end event.OnClose() end,
	CManager=function() if event.Active==true then event.DO_Order() end end,
	UManager=function() if event.CT==false then event.CT=true event.OnCreate() end if event.Active==true then event.DO_Order() end end,
	createStep=function(self,tag,reset,skip,endc)
		if not(endc) then
			endc=false
		end
		temp=
		{
			Name=tag,
			pos=1,
			endAt=reset or math.huge,
			active=true,
			endc=endc,
			skip=skip or 0,
			spos=0,
			Step=function(self) if self~=nil then if self.spos==0 then _G.__CAction__=self if self.active==true then assert(loadstring("Step_"..tag.."("..self.pos..",__CAction__)"))() self.pos=self.pos+1 end end if self.endAt+1<=self.pos then self:Reset() if endc==true then assert(loadstring("Step_"..self.Name.."_End(__CAction__)"))() end end end self.spos=self.spos+1 if self.spos>=self.skip then self.spos=0 end end,
			FStep=function(self) if self~=nil then if self.spos==0 then _G.__CAction__=self assert(loadstring("Step_"..tag.."("..self.pos..",__CAction__)"))() self.pos=self.pos+1 end end if self.endAt+1<=self.pos then self:Reset() if endc==true then assert(loadstring("Step_"..self.Name.."_End(__CAction__)"))() end end self.spos=self.spos+1 if self.spos>=self.skip then self.spos=0 end end,
			Remove=function(self) for as=1,#event.Steps do if event.Steps[as].Name==self.Name then table.remove(event.Steps,as) end end end,
			Reset=function(self) self.pos=1 end,
			Set=function(self,amt) self.pos=amt end,
			Pause=function(self) self.active=false end,
			Resume=function(self) self.active=true end,
			Stop=function(self) self:Reset() self:Pause() end,
			Start=function(self) self:Resume() end,
			End=function(self) _G.__CAction__=self assert(loadstring("Step_"..self.Name.."_End(__CAction__)"))() self:Reset() end,
		}
		table.insert(event.Steps,temp) return temp
	end,
	createTStep=function(self,tag,reset,timer,endc)
		if not(endc) then
			endc=false
		end
		timer=timer or 1
		temp=
		{
			Name=tag,
			pos=1,
			endAt=reset or math.huge,
			active=true,
			endc=endc,
			skip= 0,
			spos=0,
			Step=function(self) if self~=nil then if self.spos==0 then _G.__CAction__=self if self.active==true then assert(loadstring("TStep_"..tag.."("..self.pos..",__CAction__)"))() self.pos=self.pos+1 end end if self.endAt+1<=self.pos then self:Reset() if endc==true then assert(loadstring("TStep_"..self.Name.."_End(__CAction__)"))() end end end self.spos=self.spos+1 if self.spos>=self.skip then self.spos=0 end end,
			FStep=function(self) if self~=nil then if self.spos==0 then _G.__CAction__=self assert(loadstring("TStep_"..tag.."("..self.pos..",__CAction__)"))() self.pos=self.pos+1 end end if self.endAt+1<=self.pos then self:Reset() if endc==true then assert(loadstring("TStep_"..self.Name.."_End(__CAction__)"))() end end self.spos=self.spos+1 if self.spos>=self.skip then self.spos=0 end end,
			Remove=function(self) for as=1,#event.Steps do if event.Steps[as].Name==self.Name then table.remove(event.Steps,as) end end end,
			Reset=function(self) self.pos=1 end,
			Set=function(self,amt) self.pos=amt end,
			Pause=function(self) self.active=false end,
			Resume=function(self) self.active=true end,
			Stop=function(self) self:Reset() self:Pause() end,
			Start=function(self) self:Resume() end,
			End=function(self) self.pos=self.EndAt self.endc=true end,
		}
		event:setAlarm("TStep_"..tag,timer)
		event:addTracker("_TStep_"..tag,temp)
		table.insert(event.TSteps,temp)
		assert(loadstring("function Alarm_TStep_"..tag.."(alarm) event:getTracker(\"_\"..alarm):Step()  event:updateAlarm(alarm,"..timer..") end"))()
		return temp
	end,
	stepExist=function(self,tag)
		for a_s=1,#event.Steps do
			if event.Steps[a_s].Name==tag then
				return true
			end
		end
		return false
	end,
	tstepExist=function(self,tag)
		for a_s=1,#event.TSteps do
			if event.TSteps[a_s].Name==tag then
				return true
			end
		end
		return false
	end,
}
