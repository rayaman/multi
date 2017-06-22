package.path="?/init.lua;"..package.path
require("multi.all")
require("multi.compat.backwards[1,5,0]")
multi:newLoop(function(dt,self)
	print(dt)
end)
multi:mainloop() -- start the main runner
