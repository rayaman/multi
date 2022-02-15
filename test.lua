package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init()

func = thread:newFunction(function(count)
    local a = 0
    while true do
        a = a + 1
        thread.sleep(.1)
        thread.pushStatus(a,count)
        if a == count then break end
    end
    return "Done", 1, 2, 3
end)

thread:newThread("test",function()
    local ret = func(10)
    ret.OnStatus(function(part,whole)
        print("Ret1: ",math.ceil((part/whole)*1000)/10 .."%")
    end)
    print("Status:",thread.hold(ret.OnReturn))
    print("Function Done!")
    os.exit()
end).OnError(function(...)
    print("Error:",...)
end)

multi:mainloop()