function gui:setVisiblity(val)
	self.Visible=val
	self.oV=val
	doto=self:GetAllChildren()
	if val==false then
		for i=1,#doto do
			doto[i].Visible=val
		end
	else
		for i=1,#doto do
			doto[i].Visible=doto[i].oV
		end
	end
end