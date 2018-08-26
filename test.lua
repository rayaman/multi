package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local a = 0
multi:newThread("test",function()
	print("lets go")
	b,c = thread.hold(function()
		return b,"We did it!"
	end)
	print(b,c)
end)
multi:newTLoop(function()
	a=a+1
	if a == 5 then
		b = "Hello"
	end
end,1)
multi:mainloop()
