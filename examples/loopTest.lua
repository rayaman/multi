-- like the while loop (kinda)
require("multi")
loop=multi:newLoop(function(self,dt)
	if dt>10 then
		print("Enough time has passed!")
		self:Break() -- lets break this thing
	end
end)
multi:mainloop()
