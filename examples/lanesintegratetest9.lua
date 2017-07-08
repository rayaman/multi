package.path="?/init.lua;"..package.path
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
jQueue=multi:newSystemThreadedJobQueue(n)
jQueue:registerJob("TEST_JOB",function(a,s)
	math.randomseed(s)
	TEST_JOB2()
	return math.random(0,255)
end)
jQueue:registerJob("TEST_JOB2",function()
	print("Test Works!")
end)
jQueue:start()
jQueue:doToAll(function()
	print("Doing this 6? times!")
end)
for i=1,10 do -- Job Name of registered function, ... varargs
	jQueue:pushJob("TEST_JOB","This is a test!",math.random(1,1000000))
end
tableOfOrder={}
jQueue.OnJobCompleted(function(JOBID,n)
	tableOfOrder[JOBID]=n
	if #tableOfOrder==10 then
		print("We got all of the pieces!")
	end
end)
multi:mainloop()
