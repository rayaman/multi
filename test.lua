package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
t = multi:newThread(function()
    print("Hello!")
    os.exit()
end)
multi:lightloop()