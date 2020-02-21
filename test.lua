package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
--local sterilizer = require("multi.integration.sterilization")
local multi,thread = require("multi"):init()
local test = multi:newThread(function()
    while true do
        thread.sleep(1)
        print("Hello!")
    end
end)
local alarm = multi:newAlarm(4):OnRing(function(a)
    print(a.Type)
    a:Destroy()
    print(a.Type)
    test:Destroy()
end)
multi:lightloop()
-- function pushJobs()
-- 	multi.Jobs:newJob(function()
-- 		print("job called")
-- 	end) -- No name job
-- 	multi.Jobs:newJob(function()
--         print("job called2")
--         os.exit() -- This is the last thing callec. I link to end the loop when doing examples
-- 	end,"test")
-- 	multi.Jobs:newJob(function()
-- 		print("job called3")
-- 	end,"test2")
-- end
-- pushJobs()
-- pushJobs()
-- multi:newThread(function()

-- end)
-- local jobs = multi.Jobs:getJobs() -- gets all jobs
-- local jobsn = multi.Jobs:getJobs("test") -- gets all jobs names 'test'
-- jobsn[1]:removeJob() -- Select a job and remove it
-- multi.Jobs:removeJobs("test2") -- Remove all jobs names 'test2'
-- multi.Jobs.SetScheme(1) -- Jobs are internally a service, so setting scheme and priority
-- multi.Jobs.SetPriority(multi.Priority_Core)
-- multi:lightloop()