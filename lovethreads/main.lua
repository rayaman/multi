package.path = "../?/init.lua;../?.lua;"..package.path
local multi, thread = require("multi"):init()

local GLOBAL, THREAD = require("multi.integration.loveManager"):init()

GLOBAL["Test"] = {1,2,3, function() print("HI") end}

for i,v in pairs(GLOBAL["Test"]) do
    print(i,v)
    if type(v) == "function" then v() end
end

multi:newAlarm(3):OnRing(function()
    GLOBAL["Test2"] = "We got a value!"
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