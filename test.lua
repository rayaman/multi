package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
--GLOBAL,THREAD = require("multi.integration.lanesManager"):init()
-- local co = 0
-- multi.OnLoad(function()
-- 	print("Code Loaded!")
-- end)
multi.OnExit(function(n)
	print("Code Exited!")
end)
-- multi:newThread(function()
-- 	t = os.clock()
-- 	while true do
-- 		thread.skip()
-- 		co = co + 1
-- 	end
-- end)
-- multi:setTimeout(function()
-- 	os.exit()
-- end,5)
multi:benchMark(1):OnBench(function(...)
	print(...)
	os.exit()
end)
multi:mainloop()