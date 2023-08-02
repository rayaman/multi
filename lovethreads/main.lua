package.path = "../?/init.lua;../?.lua;"..package.path
local multi, thread = require("multi"):init{print=true, warning = true, error=true}
local utils = require("multi.integration.loveManager.utils")

local people = {1,2,3}

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. '('..type(v):sub(1,1)..'),'
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local fpeople = utils.pack(people)

print("Pack:", dump(fpeople))

local people = utils.unpack(fpeople)

print("Unpack:", dump(people))
print(type(people[3]))
 
-- GLOBAL, THREAD = require("multi.integration.loveManager"):init()

-- local queue = multi:newSystemThreadedQueue("TestQueue")
-- local tab = multi:newSystemThreadedTable("TestTable")

-- local test = multi:newSystemThread("Test",function()
--     local queue = THREAD.waitFor("TestQueue")
--     local tab = THREAD.waitFor("TestTable")
--     print("THREAD_ID:",THREAD_ID)
--     queue:push("Did it work?")
--     tab["Test"] = true
--     return 1,2,3
-- end)

-- multi:newThread("QueueTest", function()
--     print(thread.hold(queue))
--     print(thread.hold(tab, {key="Test"}))
--     print("Done!")
-- end)

-- local jq = multi:newSystemThreadedJobQueue(n)

-- jq:registerFunction("test2",function()
--     print("This works!")
-- end)

-- jq:registerFunction("test",function(a, b, c)
--     print(a, b+c)
--     test2()
--     return a+b+c
-- end)

-- print("Job:",jq:pushJob("test",1,2,3))
-- print("Job:",jq:pushJob("test",2,3,4))
-- print("Job:",jq:pushJob("test",5,6,7))

-- jq.OnJobCompleted(function(...)
--     print("Job Completed!", ...)
-- end)

-- function love.draw()
--     --
-- end

-- function love.update()
--     multi:uManager()
-- end