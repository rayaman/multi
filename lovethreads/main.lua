package.path = "../?/init.lua;../?.lua;"..package.path
local multi, thread = require("multi"):init()

GLOBAL, THREAD = require("multi.integration.loveManager"):init()

GLOBAL["Test"] = {1,2,3, function() print("HI") end}

for i,v in pairs(GLOBAL["Test"]) do
    print(i,v)
    if type(v) == "function" then v() end
end

local test = multi:newSystemThread("Test",function()
    print("THREAD_ID:",THREAD_ID)
    GLOBAL["Test2"] = "We did it!"
    eror("hahaha")
    return 1,2,3
end)

test.OnDeath(function(a,b,c)
    print("Thread finished!",a,b,c)
end)

test.OnError(function(self, err)
    print("Got Error!",err)
end)

local func = THREAD:newFunction(function(a,b,c)
    print("let's do this!",1,2,3)
    return true
end)

func(1,2,3).OnReturn(function(ret)
    print("Done",ret)
end)

thread:newThread(function()
    print("Waiting...")
    print(THREAD.waitFor("Test2"))
end)

function love.draw()
    --
end

function love.update()
    multi:uManager()
end