require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
require("core.GuiManager")
gui.ff.Color=Color.Black
test=multi:newSystemThreadedTable("YO"):init()
test["test1"]="lol"
multi:newSystemThread("test",function()
	tab=sThread.waitFor("YO"):init()
	print(tab["test1"])
	sThread.sleep(3)
	tab["test2"]="Whats so funny?"
end)
multi:newThread("test2",function()
	print(test:waitFor("test2"))
	t.text="DONE!"
end)
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
