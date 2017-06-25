function gui:newScrollBar(color1,color2)
	local scrollbar=self:newFrame(-20,0,20,0,1,0,0,1)
	scrollbar.funcS={}
	scrollbar.Color=color1 or Color.saddle_brown
	scrollbar:OnClicked(function(b,self,x,y)
		love.mouse.setX(self.x+10)
		if y>=10 and y<=self.height-10 then
			self.mover:SetDualDim(0,y-10)
		end
		if y<10 then
			love.mouse.setY(10+self.y)
		end
		if y>self.height-10 then
			love.mouse.setY((self.height-10)+self.y)
		end
		for i=1,#self.funcS do
			self.funcS[i](self,self:getPosition())
		end
	end)
	scrollbar:OnEnter(function(self)
		self:addDominance()
	end)
	scrollbar:OnExit(function(self)
		self:removeDominance()
	end)
	scrollbar.mover=scrollbar:newTextButton("","",0,0,20,20)
	scrollbar.mover.Color=color2 or Color.light_brown
	function scrollbar:getPosition()
		return ((self.mover.offset.pos.y)/(self.height-20))*100
	end
	function scrollbar:setPosition(n)
		print((self.height-20),n)
		self.mover.offset.pos.y=((self.height-20)/(100/n))
		for i=1,#self.funcS do
			self.funcS[i](self,self:getPosition())
		end
	end
	function scrollbar:OnScroll(func)
		table.insert(self.funcS,func)
	end
	return scrollbar
end