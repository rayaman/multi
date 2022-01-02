package.path = "./?/init.lua;"..package.path
local multi,thread = require("multi"):init()
local GLOBAL,THREAD = require("multi.integration.threading"):init()

function sleep(n)
	if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end

func = THREAD:newFunction(function(a,b,c)
	print("Hello Thread!",a,b,c)
	return 1,2,3	
end)

multi:newThread("Test thread",function()
	handler = func(4,5,6)
	thread.hold(handler.OnReturn)
	print("Function Done",handler.getReturns())
end)
multi:mainloop()