function gui:toString() -- oh boy this is gonna be painful lol
	multi:newThread("saving data: ",function()
		local dat=bin.stream("test.dat",false)
		function GetAllChildren2(Object)
			local Stuff = {}
			function Seek(Items)
				for i=1,#Items do
					--table.insert(Stuff,Items[i])
					for a,v in pairs(Items[i]) do
						-- dat:tackE(a.."|"..tostring(v))
						print(a.."|"..tostring(v))
						-- dat.workingfile:flush()
					end
					thread.skip()
					local NItems = Items[i]:getChildren()
					if NItems ~= nil then
						Seek(NItems)
					end
				end
			end
			local Objs = Object:getChildren()
			for i=1,#Objs do
				-- table.insert(Stuff,Objs[i])
				for a,v in pairs(Objs[i]) do
					-- dat:tackE(a.."|"..tostring(v))
					print(Objs[i].Type..":"..a.."|"..tostring(v))
					-- dat.workingfile:flush()
				end
				thread.skip()
				local Items = Objs[i]:getChildren()
				if Items ~= nil then
					Seek(Items)
				end
			end
			-- dat:tofile("test.dat")
			return Stuff
		end
		GetAllChildren2(self)
	end)
end