package.path = "../?/init.lua;../?.lua;"..package.path
multi, thread = require("multi"):init{print=true,findopt=true}
require("multi.integration.priorityManager")

multi:mainloop()