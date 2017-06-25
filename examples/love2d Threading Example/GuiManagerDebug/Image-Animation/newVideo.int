function gui:newVideo(name,i,x,y,w,h,sx,sy,sw,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("Video",name, x, y, w, h, sx ,sy ,sw ,sh)
	if type(i)=="string" then
		c.Video=love.graphics.newVideo(i)
	else
		c.Video=i
	end
	c.Visibility=0
	c.VideoVisibility=1
	c.rotation=0
	if c.Video~=nil then
		c.VideoHeigth=c.Video:getHeight()
		c.VideoWidth=c.Video:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.VideoWidth,c.VideoHeigth)
	end
	c.funcV={}
	function c:Play()
		self.handStart=true
		self.Video:play()
	end
    function c:Pause()
		self.Video:pause()
	end
	c.Resume=c.Play
	function c:Stop()
		self.handStart=false
		self:Pause()
		self:Rewind()
		for i=1,# self.funcV do
			self.funcV[i](self)
		end
	end
	function c:OnVideoStopped(func)
		table.insert(self.funcV,func)
	end
    function c:Rewind()
		self.Video:rewind()
	end
	function c:Restart()
		self:Rewind()
		self:Play()
	end
    function c:Seek(o)
		self.Video:seek(o)
	end
    function c:Tell()
		self.Video:tell()
	end
    function c:SetFilter(min, mag, anisotropy)
		self.Video:setFilter(min, mag, anisotropy)
	end
	function c:IsPlaying()
		return self.Video:isPlaying()
	end
	c:OnUpdate(function(self)
		if self.Video:isPlaying()==false and self.handStart == true then
			self:Stop()
		end
	end)
    return c
end