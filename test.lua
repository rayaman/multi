package.path="?/init.lua;"..package.path
require("multi.all")
process=multi:newProcess() -- this can also load a file, to keep things really organized, I will show a simple example first then show the same thing being done within another file.
process:newTLoop(function(self)
    print("Looping every second...")
end,1)
process:Start() -- starts the process
multi:mainloop() -- start the main runner
