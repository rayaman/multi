package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi, thread = require("multi"):init()
a=0
func = thread:newFunction(function()
	print(thread.holdFor(3,function()
		return a==5
	end))
	print(thread.hold(function()
		return multi.NIL,"test"
	end))
end,true) -- Tell the code to wait and then return
a,b = func()
print(a,b)
multi:lightloop()