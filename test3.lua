package.path = "./?.lua"
require("jitpaths")
--require("luapaths")
local multi,thread = require("multi"):init()
--local GLOBAL,THREAD = require("multi.integration.lanesManager"):init()

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


-- multi:benchMark(1):OnBench(function(sec,steps)
-- 	print("Steps:",steps)
-- 	os.exit()
-- end)
print("Running benchmarks! ",_VERSION)
local sleep_for = 1
local a = 0
local c = 1
local function bench(t,step)
	a = a + step
	c = c + 1
	if c == 9 then
		print("Total: "..a)
		os.exit()
	end
end
multi:benchMark(sleep_for,multi.Priority_Idle,"Idle:"):OnBench(bench)
multi:benchMark(sleep_for,multi.Priority_Very_Low,"Very Low:"):OnBench(bench)
multi:benchMark(sleep_for,multi.Priority_Low,"Low:"):OnBench()
multi:benchMark(sleep_for,multi.Priority_Below_Normal,"Below Normal:"):OnBench(bench)
multi:benchMark(sleep_for,multi.Priority_Normal,"Normal:"):OnBench(bench)
multi:benchMark(sleep_for,multi.Priority_Above_Normal,"Above Normal:"):OnBench(bench)
multi:benchMark(sleep_for,multi.Priority_High,"High:"):OnBench(bench)
multi:benchMark(sleep_for,multi.Priority_Very_High,"Very High:"):OnBench(bench)
multi:benchMark(sleep_for,multi.Priority_Core,"Core:"):OnBench(bench)
multi.OnExit(function()
	print("Total: ".. a)
end)
multi:mainloop{print=true,priority=3}
--multi:lightloop()