package.path = "../?/init.lua;../?.lua;"..package.path
multi, thread = require("multi"):init{print=true,findopt=true}

local conn1, conn2 = multi:newConnection(), multi:newConnection():fastMode()
conn3 = conn1 + conn2

conn1(function()
	print("Hi 1")
end)

conn2(function()
	print("Hi 2")
end)

conn3(function()
	print("Hi 3")
end)

function test(a,b,c)
	print("I run before all and control if things go!")
	return a>b
end

conn4 = test .. conn1

conn5 = conn2 .. function() print("I run after it all!") end

conn4:Fire(3,2,3)

conn5(function()
	print("Test 1")
end)

conn5(function()
	print("Test 2")
end)

conn5(function()
	print("Test 3")
end)

conn5:Fire()