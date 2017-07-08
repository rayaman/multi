IsEvent=true
event={
Active=true,
CT=false,
tag={},
Events={},
EventTracker={},
Steps={},
setAlarm=function(self,tag,set) event:new("Alarm_"..tag.."(\""..tag.."\")",[[GetCounter(event:getTracker("_Alarm_]]..tag..[["))>=]]..set,[[event:removeAlarm("]]..tag..[[")]]) event:addTracker("_Alarm_"..tag,SetCounter()) end,
setEvent=function(self,fname,condition,also) if not(string.find(fname,"(",1,true)) and not(string.find(fname,")",1,true)) then fname=fname.."()" end event:new("Event_"..fname,condition,also) end,
removeAlarm=function(self,tag) event:destroy("Alarm_"..tag) event:removeTracker("_Alarm_"..tag) end,
updateAlarm=function(self,tag,set) event:removeAlarm(tag) event:setAlarm(tag,set) end,
addTracker=function(self,varname,var) event.EventTracker[varname]=var end,
getTracker=function(self,var) return event.EventTracker[var] end,
removeTracker=function(self,var) event.EventTracker[var]=nil end,
trackerExist=function(self,tag) return event.EventTracker[tag]~=nil end,
updateTracker=function(self,tag,val) if event:trackerExist(tag) then event.EventTracker[tag]=val end end,
alarmExist=function(self,tag) return (event:getTracker("_Alarm_"..tag)~=nil) end,
new=function(self,fname,condition,also) if not(also) then also="" end table.insert(self.Events,"if "..condition.." then "..also.." "..fname.." end") table.insert(event.tag,fname) end,
eventExist=function(self,tag) for j=1,#event.tag do if event.tag[j]==tag then return true end end return false end,
destroy=function(self,tag) for j=1,#event.tag do if event.tag[j]==tag then table.remove(event.tag,j) table.remove(event.Events,j) end end end,
Stop=function() event.Active=false end,
OnCreate=function() end,
OnUpdate=function() end,
OnClose=function() end,
getActive=function() return event.tag end,
Manager=function() event.OnCreate() while event.Active==true do for d=1,#event.Events do if event.Active==true then loadstring(event.Events[d])() end end for s_g=1,#event.Steps do event.Steps[s_g]:Step() end event.OnUpdate() end event.OnClose() end,
CManager=function() for d=1,#event.Events do if event.Active==true then loadstring(event.Events[d])() end end for s_g=1,#event.Steps do event.Steps[s_g]:Step() end event.OnUpdate() end,
UManager=function() if event.CT==false then event.CT=true event.OnCreate() end for d=1,#event.Events do if event.Active==true then loadstring(event.Events[d])() end end for s_g=1,#event.Steps do event.Steps[s_g]:Step() end event.OnUpdate() end,
createStep=function(self,tag,reset,endc)
if not(endc) then endc=false end
if not(reset) then reset=0 end
temp={Name=tag,pos=1,endAt=reset,active=true,endc=endc,
Step=function(self) if self~=nil then _G.__CStep__=self if self.active==true then loadstring("Step_"..tag.."("..self.pos..",__CStep__)")() self.pos=self.pos+1 end end if self.endAt+1<=self.pos then self:Reset() if endc==true then loadstring("Step_"..self.Name.."_End(__CStep__)")() end end end,
Remove=function(self) for as=1,#event.Steps do if event.Steps[as].Name==self.Name then table.remove(event.Steps,as) end end end,
Reset=function(self) self.pos=1 end,
Set=function(self,amt) self.pos=amt end,
Pause=function(self) self.active=false end,
Resume=function(self) self.active=true end,
Stop=function(self) self:Reset() self:Pause() end,
Start=function(self) self:Resume() end,
End=function(self) self.pos=self.EndAt self.endc=true end,
}
table.insert(event.Steps,temp) return temp end,
stepExist=function(self,tag)
for a_s=1,#event.Steps do
if event.Steps[a_s].Name==tag then
return true
end
end
return false
end,
}
