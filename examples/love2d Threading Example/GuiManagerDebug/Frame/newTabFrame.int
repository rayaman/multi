function gui:newTabFrame(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=gui:newFrame(name, x, y, w, h, sx ,sy ,sw ,sh)
	c.tabheight=20
	c.Holder=c:newFrame("Holder",0,c.tabheight,0,0,0,0,1,1)
	c.TabHolder=c:newFrame("TabHolder",0,0,0,c.tabheight,0,0,1)
	function c:setTabHeight(n)
		self.tabheight=n
		self.Holder:SetDualDim(0,-self.tabheight,0,0,0,0,1,1)
	end
	function c:addTab(name,colorT,colorH)
		if colorT and not(colorH) then
			colorH=colorT
		end
		local tab=self.TabHolder:newTextButton(name,name,0,0,0,0,0,0,0,1)
		tab.Tween=-3
		if colorT then
			tab.Color=colorT
		end
		local holder=self.Holder:newFrame(name,0,0,0,0,0,0,1,1)
		if colorH then
			holder.Color=colorH
		end
		tab.frame=holder
		tab:OnReleased(function(b,self)
			if b=="l" then
				local tt=self.Parent:getChildren()
				local th=self.Parent.Parent.Holder:getChildren()
				for i=1,#th do
					th[i].Visible=false
				end
				for i=1,#tt do
					tt[i].frame.Visible=false
					tt[i].BorderSize=1
				end
				self.BorderSize=0
				self.frame.Visible=true
			end
		end)
		local tt=self.TabHolder:getChildren()
		for i=1,#tt do
			tt[i].frame.Visible=false
			tt[i].BorderSize=1
		end
		tab.frame.Visible=true
		tab.BorderSize=0
		return tab,holder
	end
	c:OnUpdate(function(self)
		local th=self.TabHolder:getChildren()
		local l=self.width/#th
		for i=1,#th do
			th[i]:SetDualDim(l*(i-1),0,l)
		end
		if #th==0 then
			self:Destroy()
		end
	end)
	return c
end