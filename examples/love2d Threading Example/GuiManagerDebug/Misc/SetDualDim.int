function gui:SetDualDim(x, y, w, h, sx ,sy ,sw ,sh)
	if _GuiPro.DPI_ENABLED then
		if x then
			x=self.DPI*x
		end
		if y then
			y=self.DPI*y
		end
		if w then
			w=self.DPI*w
		end
		if h then
			h=self.DPI*h
		end
	end
	if sx then
		self.scale.pos.x=sx
	end
	if sy then
		self.scale.pos.y=sy
	end
	if x then
		self.offset.pos.x=x
	end
	if y then
		self.offset.pos.y=y
	end
	if sw then
		self.scale.size.x=sw
	end
	if sh then
		self.scale.size.y=sh
	end
	if w then
		self.offset.size.x=w
	end
	if h then
		self.offset.size.y=h
	end
	if self.Image then
		self:SetImage(self.Image)
	end
end
function gui:setDualDim(...)
  self:SetDualDim(...)
end