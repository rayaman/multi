package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init()
GLOBAL, THREAD = require("multi.integration.pesudoManager"):init()

func = THREAD:newFunction(function(count)
	print("Starting Status test: ",count)
	local a = 0
	while true do
		a = a + 1
		THREAD.sleep(.1)
		THREAD.pushStatus(a,count)
		if a == count then break end
	end
	return "Done"
end)

local ret = func(10)
local ret2 = func(15)
local ret3 = func(20)
local s1,s2,s3 = 0,0,0
ret.OnError(function(...)
	print("Error:",...)
end)
ret2.OnError(function(...)
	print("Error:",...)
end)
ret3.OnError(function(...)
	print("Error:",...)
end)
ret.OnStatus(function(part,whole)
	s1 = math.ceil((part/whole)*1000)/10
	print(s1)
end)
ret2.OnStatus(function(part,whole)
	s2 = math.ceil((part/whole)*1000)/10
	print(s2)
end)
ret3.OnStatus(function(part,whole)
	s3 = math.ceil((part/whole)*1000)/10
	print(s3)
end)

-- local proc = multi:newProcessor("Test")
-- local proc2 = multi:newProcessor("Test2")
-- local proc3 = proc2:newProcessor("Test3")

-- function multi:getTaskStats()
-- 	local stats = {
-- 		[multi.Name] = {
-- 			threads = multi:getThreads(),
-- 			tasks = multi:getTasks()
-- 		}
-- 	}
-- 	local procs = multi:getProcessors()
-- 	for i = 1, #procs do
-- 		local proc = procs[i]
-- 		stats[proc:getFullName()] = {
-- 			threads = proc:getThreads(),
-- 			tasks = proc:getTasks()
-- 		}
-- 	end
-- 	return stats
-- end

-- local tasks = multi:getTaskStats()

-- for i,v in pairs(tasks) do
-- 	print("Process: "..i)
-- end

multi:mainloop()