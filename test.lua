package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.threading"):init()

test = thread:newFunction(function() 
	return 1,2
end)

ref = test()
ref.OnError(function(...)
	print("Got Error",...)
end)

ref.OnReturn(function(...)
	print("Got Returns",...)
end)

multi:mainloop()