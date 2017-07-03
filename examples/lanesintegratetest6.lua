-- lanes Desktop lua! NOTE: this is in lanesintergratetest6.lua in the examples folder
local GLOBAL,sThread=require("multi.integration.lanesManager").init()
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
end)
multi:mainloop()
