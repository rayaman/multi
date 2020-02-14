package.path="?.lua;?/init.lua;?.lua;"..package.path
local multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.lanesManager"):init()
local test = multi:newSystemThreadedJobQueue(4)
local nFunc = 0
function test:newFunction(name,func,holup) -- This registers with the queue
	if type(name)=="function" then
		holup = func
		func = name
		name = "JQFunction_"..nFunc
	end
	local ref = self
	nFunc = nFunc + 1
	ref:registerFunction(name,func)
	return thread:newFunction(function(...)
		local id = ref:pushJob(name,...)
		local link
		local rets
		link = ref.OnJobCompleted(function(jid,...)
			if id==jid then
				rets = {...}
				link:Remove()
			end
		end)
		return thread.hold(function()
			if rets then
				return unpack(rets)
			end
		end)
	end,holup)
end
func = test:newFunction("test",function(a)
	test2()
	return a..a
end,true)
func2 = test:newFunction("test2",function(a)
	print("ooo")
end,true)
print(func("1"))
print(func("Hello"))
print(func("sigh"))
print(#test.OnJobCompleted.connections)
os.exit()
multi:mainloop()