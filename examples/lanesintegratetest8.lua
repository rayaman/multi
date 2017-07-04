package.path="../?.lua;../?/init.lua;"..package.path
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
cmd=multi:newSystemThreadedExecute("SystemThreadedExecuteTest.lua") -- This file is important!
cmd.OnCMDFinished(function(code) -- callback function to grab the exit code... Called when the command goes through
	print("Got Code: "..code)
end)
multi:newTLoop(function()
	print("...")
end,1)
multi:mainloop()

