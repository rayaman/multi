function gui:newDragItem(t,i,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("TextImageButtonFrameDrag",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.WasBeingDragged=false
	c.IsBeingDragged=false
	c.Draggable=true
	c.funcD={}
	if type(i)=="string" then
		c.Image=love.graphics.newImage(i)
		c.ImageVisibility=1
		c.ImageHeigth=c.Image:getHeight()
		c.ImageWidth=c.Image:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.ImageWidth,c.ImageHeigth)
	elseif type(i)=="image" then
		c.Image=i
		c.ImageVisibility=1
		c.ImageHeigth=c.Image:getHeight()
		c.ImageWidth=c.Image:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.ImageWidth,c.ImageHeigth)
	end
	c:OnDragStart(function(self,x,y)
		if _GuiPro.hasDrag==false then
			self:setParent(_GuiPro)
			self:SetDualDim(x,y)
			self:TopStack()
		end
	end)
	c.rotation=0
	c.Tween=0
	c.XTween=0
	c.text = t
	c.AutoScaleText=false
	c.FontHeight=_defaultfont:getHeight()
	c.Font=_defaultfont
	c.FontSize=15
	c.TextFormat="center"
	c.TextVisibility=1
    c.TextColor = {0, 0, 0}
	function c:OnDropped(func)
		table.insert(self.funcD,func)
	end
	c:OnUpdate(function(self)
		if love.mouse.isDown("m" or self.dragbut)==false and self==_GuiPro.DragItem and self.hovering==false then
			_GuiPro.DragItem={}
			for i=1,#self.func7 do
				self.func7[i](self,(love.mouse.getX())-self.width/2,(love.mouse.getY())-self.height/2)
			end
		end
	end)
    return c
end