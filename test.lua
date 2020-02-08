package.path="?/init.lua;?.lua;"..package.path
multi,thread = require("multi"):init()
multi.OnLoad(function()
	print("Code Loaded!")
end)
multi:setTimeout(function()
	print("here we are!")
end,2)
local t
co = 0
multi.OnExit(function(n)
	print("Code Exited: ".. os.clock()-t .." Count: ".. co)
end)
test = thread:newFunction(function()
	thread.sleep(1)
	return 1,math.random(2,100)
end)
multi:newThread(function()
	while true do
		thread.sleep(.1)
		print("!")
	end
end)
multi:newThread(function()
	t = os.clock()
	while true do
		thread.skip()
		co = co + 1
	end
end)
example = {}
setmetatable(example,{
	__newindex = function(t,k,v)
		print("Inside metamethod",t,k,v)
		local a,b = test().wait()
		print("We did it!",a,b)
		rawset(t,k,v)
	end,
	__index = thread:newFunction(function(t,k,v)
		thread.sleep(1)
		return "You got a string"
	end,true)
})
example["test"] = "We set a variable!"
print(example["test"])
print(example.hi)
c,d = test().wait()
print(c,d)
a,b = 6,7
multi:newThread(function()
	a,b = test()
	print("Waited:",a,b)
	test().connect(function(a,b)
		print("Connected:",a,b)
		os.exit()
	end)
end)
multi:mainloop()