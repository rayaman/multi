package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi, thread = require("multi"):init()
a=0
func = thread:newFunction(function()
	return thread.holdFor(3,function()
		return a==5
	end)
end,true) -- Tell the code to wait and then return
print(func())
multi:lightloop()