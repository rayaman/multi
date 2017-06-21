package.path="?/init.lua;"..package.path
require("multi.all")
multi:benchMark(3,nil,"Results: ")
multi:mainloop() -- start the main runner
