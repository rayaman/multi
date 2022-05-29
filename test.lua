package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.threading"):init()



multi:mainloop()