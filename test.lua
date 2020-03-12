package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi, thread = require("multi"):init()
func = thread:newFunction(function(a)
	return thread.holdFor(3,function()
		return a==5 and "This is returned" -- Condition being tested!
	end)
end,true)
print(func(5))
print(func(0))
-- You actually do not need the light/mainloop or any runner for threaded functions to work
--multi:lightloop()