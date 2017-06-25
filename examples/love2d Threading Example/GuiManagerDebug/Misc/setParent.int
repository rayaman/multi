function gui:setParent(parent,name)-- Needs fixing!!!
	local temp=self.Parent:getChildren()
	for i=1,#temp do
		if temp[i]==self then
			table.remove(self.Parent.Children,i)
			break
		end
	end
	table.insert(parent.Children,self)
	self.Parent=parent
	if name then
		self:SetName(name)
	end
end