function gui:draw()
	if _GuiPro.rotate~=0 then
		love.graphics.rotate(math.rad(_GuiPro.rotate))
	end
	if self.FormFactor:lower()=="rectangle" then
		self:drawR()
	elseif self.FormFactor:lower()=="circle" then
		self:drawC()
	else
		error("Unsupported FormFactor: "..self.FormFactor.."!")
	end
end