function gui:newProgressBar(txt,x,y,w,h,sx,sy,sw,sh)
	name="newProgressBar"
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("newProgressBarFrame",name, x, y, w, 30, sx ,sy ,sw ,sh)
	c.Draggable=true
	c.dragbut="r"
	c.BorderSize=0
	c:ApplyGradient{Color.Blue,Color.sexy_purple}
	c:newTextLabel(txt,"Holder",0,0,0,h-30,0,1,1,0).Color=Color.sexy_purple
	c.funcO={}
	c.funcX={}
	c:OnDragStart(function(self)
		self:TopStack()
	end)
	local temp = c:newTextButton("X","Close",-25,5,20,20,1)
	temp.Tween=-5
	temp.XTween=-2
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcX do self.Parent.funcX[i](self.Parent) end end)
	temp.Color=Color.Red
	c.BarBG=c:newTextButton("",5,h-65,-10,30,0,1,1)
	c.BarBG:ApplyGradient{Color.Red,Color.light_red}
	c.Bar=c.BarBG:newTextLabel("",0,0,0,0,0,0,0,1)
	c.Bar:ApplyGradient{Color.Green,Color.light_green}
	c.BarDisp=c.BarBG:newTextLabel("0%","0%",0,0,0,0,0,0,1,1)
	c.BarDisp.Visibility=0
	c.BarDisp.Link=c.Bar
	c.BarDisp:OnUpdate(function(self)
		self.text=self.Link.scale.size.x*100 .."%"
	end)
	c.Func1={}
	function c:On100(func)
		table.insert(self.Func1,func)
	end
	c:OnUpdate(function(self)
		if self.Bar.scale.size.x*100>=100 then
			for P=1,#self.Func1 do
				self.Func1[P](self)
			end
		end
	end)
	function c:SetPercentage(n)
		self.Bar:SetDualDim(0,0,0,0,0,0,n/100,1)
	end
	return c
end