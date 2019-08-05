package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local a=0
multi:newThread("Test",function()
	while true do
		thread.hold(function()
			return a%4000000==0 and a~=0
		end)
		print(thread.getCores(),a)
	end
end)
multi:newThread("Test2",function()
	while true do
		thread.yield()
		a=a+1
	end
end)
multi.OnError(function(...)
	print(...)
end)
multi:threadloop()
