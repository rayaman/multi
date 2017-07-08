--[[
MIT License

Copyright (c) 2017 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
function os.getOS()
	if package.config:sub(1,1)=='\\' then
		return 'windows'
	else
		return 'unix'
	end
end
-- Step 1 get lanes
lanes=require("lanes").configure()
--~ package.path="lua/?/init.lua;lua/?.lua;"..package.path
require("multi") -- get it all and have it on all lanes
function multi:canSystemThread()
	return true
end
local multi=multi
-- Step 2 set up the linda objects
local __GlobalLinda = lanes.linda() -- handles global stuff
local __SleepingLinda = lanes.linda() -- handles sleeping stuff
-- For convience a GLOBAL table will be constructed to handle requests
local GLOBAL={}
setmetatable(GLOBAL,{
	__index=function(t,k)
		return __GlobalLinda:get(k)
	end,
	__newindex=function(t,k,v)
		__GlobalLinda:set(k,v)
	end,
})
-- Step 3 rewrite the thread methods to use lindas
local THREAD={}
function THREAD.set(name,val)
	__GlobalLinda:set(name,val)
end
function THREAD.get(name)
	__GlobalLinda:get(name)
end
local function randomString(n)
	local str = ''
	local strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		str = str..''..strings[math.random(1,#strings)]
	end
	return str
end
function THREAD.waitFor(name)
	local function wait()
		math.randomseed(os.time())
		__SleepingLinda:receive(.001,randomString(12))
	end
	repeat wait() until __GlobalLinda:get(name)
	return __GlobalLinda:get(name)
end
function THREAD.testFor(name,val,sym)
	--
end
function THREAD.getCores()
	return THREAD.__CORES
end
if os.getOS()=="windows" then
	THREAD.__CORES=tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
else
	THREAD.__CORES=tonumber(io.popen("nproc --all"):read("*n"))
end
function THREAD.kill() -- trigger the lane destruction
	-- coroutine.yield({"_kill_",":)"})
end
--[[ Step 4 We need to get sleeping working to handle timing... We want idle wait, not busy wait
Idle wait keeps the CPU running better where busy wait wastes CPU cycles... Lanes does not have a sleep method
however, a linda recieve will in fact be a idle wait! So we use that and wrap it in a nice package]]
function THREAD.sleep(n)
	math.randomseed(os.time())
	__SleepingLinda:receive(n,randomString(12))
end
function THREAD.hold(n)
	local function wait()
		math.randomseed(os.time())
		__SleepingLinda:receive(.001,randomString(12))
	end
	repeat wait() until n()
end
-- Step 5 Basic Threads!
function multi:newSystemThread(name,func)
    local c={}
    local __self=c
    c.name=name
	c.Type="sthread"
    c.thread=lanes.gen("*", func)()
	function c:kill()
		--self.status:Destroy()
		self.thread:cancel()
		print("Thread: '"..self.name.."' has been stopped!")
	end
	c.status=multi:newUpdater(multi.Priority_IDLE)
	c.status.link=c
	c.status:OnUpdate(function(self)
		local v,err,t=self.link.thread:join(.001)
		if err then
			multi.OnError:Fire(self.link,err)
			print("Error in systemThread: '"..self.link.name.."' <"..err..">")
			self:Destroy()
		end
	end)
    return c
end
print("Integrated Lanes!")
multi.integration={} -- for module creators
multi.integration.GLOBAL=GLOBAL
multi.integration.THREAD=THREAD
require("multi.integration.shared")
return {init=function() return GLOBAL,THREAD end}
