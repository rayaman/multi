package.path = "../?/init.lua;../?.lua;"..package.path
multi, thread = require("multi"):init{print=true,findopt=true}

local conn1 = multi:newConnection()
local conn2 = function(a,b,c) return a*2, b*2, c*2 end % conn1
conn2(function(a,b,c)
	print("Conn2",a,b,c)
end)
conn1(function(a,b,c)
	print("Conn1",a,b,c)
end)
conn1:Fire(1,2,3)
conn2:Fire(1,2,3)