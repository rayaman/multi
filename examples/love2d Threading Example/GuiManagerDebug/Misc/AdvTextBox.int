function gui:AdvTextBox(txt,x,y,w,h,sx,sy,sw,sh)
	name="AdvTextBox"
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("AdvTextBoxFrame",name, x, y, w, 30, sx ,sy ,sw ,sh)
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
	--local temp = c:newTextButton("X","Close",-25,5,20,20,1)
	--temp.Tween=-5
	--temp.XTween=-2
	--temp:OnReleased(function(b,self) for i=1,#self.Parent.funcX do self.Parent.funcX[i](self.Parent) end end)
	--temp.Color=Color.Red
	c.tLink=c:newTextBox("puttext","TextBox",5,h-95,-40,30,0,1,1,1)
	c.tLink.Color=Color.light_gray
	c.tLink.ClearOnFocus=true
	c.tLink:OnFocus(function(self) self.ClearOnFocus=false end)
	local temp=c:newTextButton("OK","Ok",-35,h-65,30,30,1,1)
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcO do self.Parent.funcO[i](self.Parent,self.Parent.tLink.text) end end)
	temp.Color=Color.Green
	temp.XTween=-2
	local temp=c:newTextButton("X","Cancel",-35,h-95,30,30,1,1)
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcX do self.Parent.funcX[i](self.Parent,self.Parent.tLink.text) end end)
	temp.Color=Color.Red
	temp.XTween=-2
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