function GetAllChildren(Object)
	local Stuff = {}
	function Seek(Items)
		for i=1,#Items do
			if Items[i].Visible==true then
				table.insert(Stuff,Items[i])
				local NItems = Items[i]:getChildren()
				if NItems ~= nil then
					Seek(NItems)
				end
			end
		end
	end
	local Objs = Object:getChildren()
	for i=1,#Objs do
		if Objs[i].Visible==true then
			table.insert(Stuff,Objs[i])
			local Items = Objs[i]:getChildren()
			if Items ~= nil then
				Seek(Items)
			end
		end
	end
	return Stuff
end