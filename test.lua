package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init()

local proc = multi:newProcessor("Test")
local proc2 = multi:newProcessor("Test2")
local proc3 = proc2:newProcessor("Test3")

function multi:getTaskStats()
	local stats = {
		[multi.Name] = {
			threads = multi:getThreads(),
			tasks = multi:getTasks()
		}
	}
	local procs = multi:getProcessors()
	for i = 1, #procs do
		local proc = procs[i]
		stats[proc:getFullName()] = {
			threads = proc:getThreads(),
			tasks = proc:getTasks()
		}
	end
	return stats
end

local tasks = multi:getTaskStats()

for i,v in pairs(tasks) do
	print("Process: "..i)
end

--multi:mainloop()