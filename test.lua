package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
local multi,thread = require("multi"):init()

-- Testing destroying and fixed connections
c = multi:newConnection()
c1 = c(function()
    print("called 1")
end)
c2 = c(function()
    print("called 2")
end)
c3 = c(function()
    print("called 3")
end)

print(c1,c2.Type,c3)
c:Fire()
c2:Destroy()
print(c1,c2.Type,c3)
c:Fire()
c1:Destroy()
print(c1,c2.Type,c3)
c:Fire()

-- Destroying alarms and threads
local test = multi:newThread(function()
    while true do
        thread.sleep(1)
        print("Hello!")
    end
end)

test.OnDeath(function()
    os.exit() -- This is the last thing called.
end)

local alarm = multi:newAlarm(4):OnRing(function(a)
    print(a.Type)
    a:Destroy()
    print(a.Type)
    test:Destroy()
    print("TEST: ",test)
end)
multi:lightloop()