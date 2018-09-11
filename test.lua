package.path="?/init.lua;?.lua;"..package.path
--~ package.cpath="./?.dll;"..package.cpath
--~ time = require("time")
--~ local d1 = time.date(2012, 4, 30)
--~ a=time.nowlocal()
--~ while true do
--~ 	print(time.nowlocal():ticks())
--~ end
multi = require("multi")
--~ multi:newTLoop(function(self)
--~ 	a = 0
--~ end,.001)
--~ multi:benchMark(1,nil,"Steps/s:"):OnBench(function()
--~ 	os.exit()
--~ end)
function multi:ResetPriority()
	self.solid = false
end
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end
local a=0
local b=0
local c=0
multi:benchMark(1,multi.Priority_Core,"Regular Bench:"):OnBench(function() -- the onbench() allows us to do each bench after each other!
	print("AutoP\n---------------")
		multi:newLoop(function()
		a=a+1
	end)
	t=multi:newLoop(function()
		c=c+1
		sleep(.001)
	end)
	multi:newLoop(function()
		b=b+1
	end)
	multi:benchMark(1,multi.Priority_Core,"Hmm:"):OnBench(function()
		multi.nextStep(function()
			print(a,b,c)
--~ 			os.exit()
		end)
	end)
end)
settings = {
--~ 	priority = 3, -- this is overwritten while auto_priority is being used! You can also use -1 for this setting as well
	auto_priority = true,
	auto_stretch = 1000,
	auto_lowerbound = multi.Priority_Idle
}
while true do
	multi:uManager(settings)
end
