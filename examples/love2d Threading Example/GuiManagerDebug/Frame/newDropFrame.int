function gui:newDropFrame(name,x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("DropFrame",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.WasBeingDragged=false
	c.IsBeingDragged=false
	c.Draggable=false
	c.funcD={}
	function c:GetDroppedItems()
		local t=self:getChildren()
		local tab={}
		for i=1,#t do
			if t[i].Type=="TextImageButtonFrameDrag" then
				table.insert(tab,t[i])
			end
		end
		return tab
	end
	function c:OnDropped(func)
		table.insert(self.funcD,func)
	end
	c:OnUpdate(function(self)
		if _GuiPro.DragItem then
			if _GuiPro.DragItem.Type=="TextImageButtonFrameDrag" and love.mouse.isDown(_GuiPro.DragItem.dragbut or "m")==false and self:IsHovering() then
				local t=_GuiPro.DragItem
				_GuiPro.DragItem={}
				for i=1,#t.funcD do
					t.funcD[i](self,t)
				end
				for i=1,#self.funcD do
					self.funcD[i](self,t)
				end
				_GuiPro.hasDrag=false
			end
		end
	end)
    return c
end