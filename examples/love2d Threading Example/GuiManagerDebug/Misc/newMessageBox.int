function gui:newMessageBox(txt,x,y,w,h,sx,sy,sw,sh)
	name="MessageBox"
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("MessageBoxFrame",name, x, y, w, 30, sx ,sy ,sw ,sh)
	c.Draggable=true
	c.dragbut="r"
	c:ApplyGradient{Color.Blue,Color.sexy_purple}
	c.BorderSize=0
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
	local temp=c:newTextButton("OK","Ok",0,h-65,0,30,.25,1,.5)
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcO do self.Parent.funcO[i](self.Parent) end end)
	temp.Color=Color.Green
	function c:Close()
		self.Visible=false
	end
	function c:Open()
		self.Visible=true
	end
	function c:OnOk(func)
		table.insert(self.funcO,func)
	end
	function c:OnX(func)
		table.insert(self.funcX,func)
	end
	return c
end