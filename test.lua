package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL,THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
function table.print(tbl, indent)
	if type(tbl)~="table" then return end
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		formatting = string.rep('  ', indent) .. k .. ': '
		if type(v) == 'table' then
			print(formatting)
			table.print(v, indent+1)
		else
			print(formatting .. tostring(v))
		end
	end
end
print(#multi.SystemThreads)
multi:newThread("Detail Updater",function()
	while true do
		thread.sleep(1)
		print(multi:getTasksDetails())
		print("-----")
		table.print(multi:getTasksDetails("t"))
		io.read()
	end
end)
multi.OnSystemThreadDied(function(...)
	print("why you say dead?",...)
end)
multi.OnError(function(...)
	print(...)
end)
multi:newSystemThread("TestSystem",function()
	while true do
		THREAD.sleep(1)
		print("I'm alive")
	end
end)
print(#multi.SystemThreads)
multi:mainloop{
	protect = false,
	print = true
}
