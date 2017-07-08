require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
require("core.GuiManager")
gui.ff.Color=Color.Black
jQueue=multi:newSystemThreadedJobQueue() -- this internally creates System threads, We told it to use a maximum of 3 cores at any given time
jQueue:registerJob("TEST_JOB",function(a,s)
	math.randomseed(s)
	print("testing...")
	-- We will push a random #
	TEST_JOB2() -- You can call other registered functions as well!
	return math.random(0,255) -- send the result to the main thread
end)
jQueue:registerJob("TEST_JOB2",function(a,s)
	print("Test Works!")
end)
jQueue:start()
tableOfOrder={}
jQueue.OnJobCompleted(function(JOBID,n)
	-- JOBID is the completed job, starts at 1 and counts up by 1.
	-- Threads finish at different times so jobids may be returned out of order! Be sure to have a way to order them
	tableOfOrder[JOBID]=n -- we order ours by putting them into a table
	if #tableOfOrder==10 then
		print("We got all of the pieces!")
	end
end)
for i=1,10 do -- Job Name of registered function, ... varargs
	jQueue:pushJob("TEST_JOB","This is a test!",math.random(1,1000000))
end
print("I pushed all of the jobs :)")
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
