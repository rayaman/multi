package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi, thread = require("multi"):init()


multi:lightloop()