package.path="?/init.lua;?.lua;"..package.path
local multi = require("multi")
print(multi:hasJobs())
multi:setJobSpeed(1) -- set job speed to 1 second
multi:newJob(function()
    print("A job!")
end,"test")

multi:newJob(function()
    print("Another job!")
    multi:removeJob("test") -- removes all jobs with name "test"
end,"test")

multi:newJob(function()
    print("Almost done!")
end,"test")

multi:newJob(function()
    print("Final job!")
end,"test")
print(multi:hasJobs())
print("There are "..multi:getJobs().." jobs in the queue!")
multi:mainloop()
