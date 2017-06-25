audio = {}
audio.__index = audio
function audio:new(f,t)
	local obj={}
	setmetatable(obj, audio)
	obj.source=love.audio.newSource(f,t)
	obj.f=f
	obj.t=t or "stream"
	obj.endEvent=multi:newLoop()
	obj.endEvent.Pare=obj
	obj.wasPlaying=false
	obj.func={}
	obj.func2={}
	obj.func3={}
	obj.func4={}
	obj.endEvent:OnLoop(function(time,loop)
		if not(loop.Pare:isPlaying()) and loop.Pare.wasPlaying==true and not(loop.Pare:isPaused()) then
			for i=1,#loop.Pare.func do
				loop.Pare:stop()
				loop.Pare.wasPlaying=false
				loop.Pare.endEvent:Pause()
				loop.Pare.func[i](loop.Pare)
			end
		end
	end)
	obj.endEvent:Pause()
	return obj
end
function audio:clone()
	local _temp=audio:new(self.f,self.t)
	_temp.source=self.source:clone()
	return _temp
end
--Mutators
function audio:play()
	if self:isPaused() then
		for i=1,#self.func4 do
			self.func4[i](self)
		end
		self:resume()
	else
		for i=1,#self.func3 do
			self.func3[i](self)
		end
		self.source:play()
		self.wasPlaying=true
		self.endEvent:Resume()
	end
end
function audio:stop()
	self.source:stop()
	self.wasPlaying=true
	self.endEvent:Pause()
end
function audio:pause()
	for i=1,#self.func2 do
		self.func2[i](self)
	end
	self.source:pause()
end
function audio:resume()
	self.source:resume()
end
function audio:rewind()
	self.source:rewind()
end
function audio:setAttenuationDistances(r,m)
	self.source:setAttenuationDistances(r,m)
end
function audio:setCone(innerAngle, outerAngle, outerVolume)
	self.source:setCone(innerAngle, outerAngle, outerVolume)
end
function audio:setDirection(x, y, z)
	self.source:setDirection(x, y, z)
end
function audio:setLooping(loop)
	self.source:setLooping(loop)
end
function audio:setPitch(pitch)
	self.source:setPitch(pitch)
end
function audio:setPosition(x, y, z)
	self.source:setPosition(x, y, z)
end
function audio:setRelative(enable)
	self.source:setRelative(enable)
end
function audio:setRolloff(rolloff)
	self.source:setRolloff(rolloff)
end
function audio:setVelocity(x, y, z)
	self.source:setVelocity(x, y, z)
end
function audio:setVolume(volume)
	self.source:setVolume(volume)
end
function audio:setVolumeLimits(min, max)
	self.source:setVolumeLimits(min, max)
end
function audio:seek(offset,unit)
	self.source:seek(offset,unit)
end
--Assessors
function audio:isPlaying()
	return self.source:isPlaying()
end
function audio:isPaused()
	return self.source:isPaused()
end
function audio:isStopped()
	return self.source:isStopped()
end
function audio:isLooping()
	return self.source:isLooping()
end
function audio:isStatic()
	return self.source:isStatic()
end
function audio:isRelative()
	return self.source:isRelative()
end
function audio:getAttenuationDistances()
	return self.source:getAttenuationDistances()
end
function audio:getChannels()
	return self.source:getChannels()
end
function audio:getCone()
	return self.source:getCone()
end
function audio:getDirection()
	return self.source:getDirection()
end
function audio:getPitch()
	return self.source:getPitch()
end
function audio:getPosition()
	return self.source:getPosition()
end
function audio:getRolloff()
	return self.source:getRolloff()
end
function audio:getVelocity()
	return self.source:getVelocity()
end
function audio:getVolume()
	return self.source:getVolume()
end
function audio:getVolumeLimits()
	return self.source:getVolumeLimits()
end
function audio:tell(unit)
	return self.source:tell(unit)
end
function audio:type()
	return self.source:type()
end
function audio:typeOf()
	return self.source:typeOf()
end
--Events
function audio:onResume(func)
	table.insert(self.func4,func)
end
function audio:onPlay(func)
	table.insert(self.func3,func)
end
function audio:onPause(func)
	table.insert(self.func2,func)
end
function audio:onStop(func)
	table.insert(self.func,func)
end
--[[
Object:type						|Done
Object:typeOf					|Done
Source:clone					|Done
Source:getAttenuationDistances	|Done
Source:getChannels				|Done
Source:getCone					|Done
Source:getDirection				|Done
Source:getPitch					|Done
Source:getPosition				|Done
Source:getRolloff				|Done
Source:getVelocity				|Done
Source:getVolume				|Done
Source:getVolumeLimits			|Done
Source:isLooping				|Done
Source:isPaused					|Done
Source:isPlaying				|Done
Source:isRelative				|Done
Source:isStatic					|Done
Source:isStopped				|Done
Source:pause					|Done
Source:play						|Done
Source:resume					|Done
Source:rewind					|Done
Source:seek						|Done
Source:setAttenuationDistances	|Done
Source:setCone					|Done
Source:setDirection				|Done
Source:setLooping				|Done
Source:setPitch					|Done
Source:setPosition				|Done
Source:setRelative				|Done
Source:setRolloff				|Done
Source:setVelocity				|Done
Source:setVolume				|Done
Source:setVolumeLimits			|Done
Source:stop						|Done
Source:tell						|Done
]]
