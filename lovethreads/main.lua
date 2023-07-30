package.path = "../?/init.lua;../?.lua;"..package.path
local multi, thread = require("multi"):init{print=true, warning = true, error=true}
local flat = require("flatten")

local people = {
    {
       name = "Fred",
       address = "16 Long Street",
       phone = "123456"
    },
    {
       name = "Wilma",
       address = "16 Long Street",
       phone = "123456",
       func = function()
           print("Hi")
       end
    },
    {
       name = "Barney",
       address = "17 Long Street",
       phone = "123457",
       important = love.data.newByteData("TEST")
    }
 }

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local fpeople = flat.flatten(people)

print("Flatten", dump(fpeople))

local people = flat.unflatten(fpeople)

print("Unflatten", dump(people))
 
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