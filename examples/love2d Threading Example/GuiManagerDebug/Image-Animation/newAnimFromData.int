function gui:newAnimFromData(data,delay, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("ImageAnimation","FromFile", x, y, w, h, sx ,sy ,sw ,sh)
	c.Visibility=0
	c.ImageVisibility=1
	c.delay=delay or .05
	c.files=data
	c.AnimStart={}
	c.AnimEnd={}
	c:SetImage(c.files[1])
	c.step=multi:newTStep(1,#c.files,1,c.delay)
	c.step.parent=c
	c.rotation=0
	c.step:OnStart(function(step)
		for i=1,#step.parent.AnimStart do
			step.parent.AnimStart[i](step.parent)
		end
	end)
	c.step:OnStep(function(pos,step)
		step.parent:SetImage(step.parent.files[pos])
	end)
	c.step:OnEnd(function(step)
		for i=1,#step.parent.AnimEnd do
			step.parent.AnimEnd[i](step.parent)
		end
	end)
	function c:OnAnimStart(func)
		table.insert(self.AnimStart,func)
	end
	function c:OnAnimEnd(func)
		table.insert(self.AnimEnd,func)
	end
	function c:Pause()
		self.step:Pause()
	end
	function c:Resume()
		self.step:Resume()
	end
	function c:Reset()
		self.step.pos=1
	end
	function c:getFrames()
		return #self.files
	end
	function c:getFrame()
		return self.step.pos
	end
	function c:setFrame(n)
		return self:SetImage(self.files[n])
	end
	return c
end