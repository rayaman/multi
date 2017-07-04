require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
require("core.GuiManager")
gui.ff.Color=Color.Black
cmd=multi:newSystemThreadedExecute("C:/SystemThreadedExecuteTest.lua")
cmd.OnCMDFinished(function(code)
	print("Got Code: "..code)
end)
multi:newTLoop(function()
	print("...")
end,1)
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
