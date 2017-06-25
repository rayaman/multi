function gui:TopStack()
	childs=self.Parent:getChildren()
	for i=1,#childs do
		if childs[i]==self then
			table.remove(self.Parent.Children,i)
			table.insert(self.Parent.Children,self)
			break
		end
	end
end