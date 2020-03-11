package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi, thread = require("multi"):init()
a=0
local function cleanReturns(...)
	local n = select("#", ...)
	print(n)
	local returns = {...}
	local rets = {}
	local ind = 0
	for i=n,1,-1 do
		if returns[i] then
			ind=i
		end
	end
	return unpack(returns,1,ind)
end
func = thread:newFunction(function()
	return thread.holdFor(3,function()
		return a==5 -- Condition being tested!
	end)
end,true)
print(func())
--multi:lightloop()