package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.pesudoManager"):init()



multi:mainloop({print=true})