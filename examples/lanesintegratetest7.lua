-- Creating the object using lanes manager to show case this. Examples has the file for love2d
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
jQueue=multi:newSystemThreadedJobQueue(n) -- this internally creates System threads. By defualt it will use the # of processors on your system You can set this number though.
-- Only create 1 jobqueue! For now making more than 1 is buggy. You only really need one though. Just register new functions if you want 1 queue to do more. The one reason though is keeping track of jobIDs. I have an idea that I will roll out in the next update.
jQueue:registerJob("TEST_JOB",function(a,s)
	math.randomseed(s)
	-- We will push a random #
	TEST_JOB2() -- You can call other registered functions as well!
	return math.random(0,255) -- send the result to the main thread
end)
jQueue:registerJob("TEST_JOB2",function()
	print("Test Works!") -- this is called from the job since it is registered on the same queue
end)
jQueue:start()
tableOfOrder={} -- This is how we will keep order of our completed jobs. There is no guarantee that the order will be correct
jQueue.OnJobCompleted(function(JOBID,n) -- whenever a job is completed you hook to the event that is called. This passes the JOBID folled by the returns of the job
	-- JOBID is the completed job, starts at 1 and counts up by 1.
	-- Threads finish at different times so jobids may be passed out of order! Be sure to have a way to order them
	tableOfOrder[JOBID]=n -- we order ours by putting them into a table
	if #tableOfOrder==10 then
		print("We got all of the pieces!")
	end
end)
-- LEts push the jobs now
for i=1,10 do -- Job Name of registered function, ... varargs
	jQueue:pushJob("TEST_JOB","This is a test!",math.random(1,1000000))
end
print("I pushed all of the jobs :)")
multi:mainloop() -- Start the main loop :D
