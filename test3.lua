package.path = "./?/init.lua;"..package.path
local multi,thread = require("multi"):init()
local GLOBAL,THREAD = require("multi.integration.lanesManager"):init()

-- func = THREAD:newFunction(function(a,b,c)
-- 	print("Hello Thread!",a,b,c)
-- 	return 1,2,3	
-- end)

-- func2 = THREAD:newFunction(function(a,b,c)
-- 	print("Hello Thread2!",a,b,c)
-- 	THREAD.sleep(1)
-- 	return 10,11,12	
-- end)

-- multi:newThread("Test thread",function()
-- 	handler = func(4,5,6)
-- 	handler2 = func2(7,8,9)
-- 	thread.hold(handler.OnReturn + handler2.OnReturn)
-- 	print("Function Done",handler.getReturns())
-- 	print("Function Done",handler2.getReturns())
-- end)
multi:benchMark(1):OnBench(function(sec,steps)
	print("Steps:",steps)
	os.exit()
end)

multi:mainloop()