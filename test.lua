package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi.OnExit(function(n)
	print("Code Exited")
end)
