--[[
MIT License

Copyright (c) 2019 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
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
package.path = "?/init.lua;?.lua;" .. package.path
multi, thread = require("multi").init() -- get it all and have it on all lanes
if multi.integration then -- This allows us to call the lanes manager from supporting modules without a hassel
	return {
		init = function()
			return multi.integration.GLOBAL, multi.integration.THREAD
		end
	}
end
function os.getOS()
	if package.config:sub(1, 1) == "\\" then
		return "windows"
	else
		return "unix"
	end
end
-- Step 1 get lanes
lanes = require("lanes").configure()
multi.SystemThreads = {}
multi.isMainThread = true
function multi:canSystemThread()
	return true
end
function multi:getPlatform()
	return "lanes"
end
-- Step 2 set up the Linda objects
local __GlobalLinda = lanes.linda() -- handles global stuff
local __SleepingLinda = lanes.linda() -- handles sleeping stuff
-- For convenience a GLOBAL table will be constructed to handle requests
local GLOBAL = {}
setmetatable(
	GLOBAL,
	{
		__index = function(t, k)
			return __GlobalLinda:get(k)
		end,
		__newindex = function(t, k, v)
			__GlobalLinda:set(k, v)
		end
	}
)
-- Step 3 rewrite the thread methods to use Lindas
local THREAD = {}
function THREAD.set(name, val)
	__GlobalLinda:set(name, val)
end
function THREAD.get(name)
	__GlobalLinda:get(name)
end
local function randomString(n)
	local str = ""
	local strings = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","1","2","3","4","5","6","7","8","9","0","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
	for i = 1, n do
		str = str .. "" .. strings[math.random(1, #strings)]
	end
	return str
end
function THREAD.waitFor(name)
	local function wait()
		math.randomseed(os.time())
		__SleepingLinda:receive(.001, randomString(12))
	end
	repeat
		wait()
	until __GlobalLinda:get(name)
	return __GlobalLinda:get(name)
end
function THREAD.testFor(name, val, sym)
	--
end
function THREAD.getCores()
	return THREAD.__CORES
end
function THREAD.getThreads()
	return GLOBAL.__THREADS__
end
if os.getOS() == "windows" then
	THREAD.__CORES = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
else
	THREAD.__CORES = tonumber(io.popen("nproc --all"):read("*n"))
end
function THREAD.kill() -- trigger the lane destruction
	error("Thread was killed!")
end
function THREAD.getName()
	return THREAD_NAME
end
function THREAD.getID()
	return THREAD_ID
end
_G.THREAD_ID = 0
--[[ Step 4 We need to get sleeping working to handle timing... We want idle wait, not busy wait
Idle wait keeps the CPU running better where busy wait wastes CPU cycles... Lanes does not have a sleep method
however, a linda recieve will in fact be a idle wait! So we use that and wrap it in a nice package]]
function THREAD.sleep(n)
	math.randomseed(os.time())
	__SleepingLinda:receive(n, randomString(12))
end
function THREAD.hold(n)
	local function wait()
		math.randomseed(os.time())
		__SleepingLinda:receive(.001, randomString(12))
	end
	repeat
		wait()
	until n()
end
local rand = math.random(1, 10000000)
-- Step 5 Basic Threads!
local threads = {}
local count = 1
local started = false
local livingThreads = {}
function multi.removeUpvalues(func)
	if not debug then return end
	local count=1
	local dat = true
	while dat do
		dat = debug.setupvalue(func, count, nil)
		count = count+1
	end
end
function multi.getUpvalues(func)
	local count=1
	local tab = {}
	local dat = true
	while dat do
		dat = debug.getupvalue(func, count)
		if dat then
			table.insert(tab,dat)
			print(dat)
		end
		count = count+1
	end
	return tab
end
function multi:newSystemThread(name, func, ...)
	multi.InitSystemThreadErrorHandler()
	rand = math.random(1, 10000000)
	local c = {}
	local __self = c
	c.name = name
	c.Name = name
	c.Id = count
	c.loadString = {"base","package","os,math","table","string","coroutine"}
	livingThreads[count] = {true, name}
	c.Type = "sthread"
	c.creationTime = os.clock()
	c.alive = true
	c.priority = thread.Priority_Normal
	local args = {...}
	multi.nextStep(function()
		c.thread = lanes.gen(table.concat(c.loadString,","),{globals={
			THREAD_NAME=name,
			THREAD_ID=count
		},priority=c.priority}, func)(unpack(args))
	end)
	count = count + 1
	function c:kill()
		self.thread:cancel()
		multi.print("Thread: '" .. self.name .. "' has been stopped!")
		self.alive = false
	end
	table.insert(multi.SystemThreads, c)
	c.OnError = multi:newConnection()
	GLOBAL["__THREADS__"] = livingThreads
	return c
end
multi.OnSystemThreadDied = multi:newConnection()
function multi.InitSystemThreadErrorHandler()
	if started == true then
		return
	end
	started = true
	multi:newThread(
"ThreadErrorHandler",
		function()
			local threads = multi.SystemThreads
			while true do
				thread.sleep(.5) -- switching states often takes a huge hit on performance. half a second to tell me there is an error is good enough.
				for i = #threads, 1, -1 do
					local v, err, t = threads[i].thread:join(.001)
					if err then
						if err:find("Thread was killed!") then
							print(err)
							livingThreads[threads[i].Id] = {false, threads[i].Name}
							threads[i].alive = false
							multi.OnSystemThreadDied:Fire(threads[i].Id)
							GLOBAL["__THREADS__"] = livingThreads
							table.remove(threads, i)
						elseif err:find("stack traceback") then
							print(err)
							threads[i].OnError:Fire(threads[i], err, "Error in systemThread: '" .. threads[i].name .. "' <" .. err .. ">")
							threads[i].alive = false
							livingThreads[threads[i].Id] = {false, threads[i].Name}
							multi.OnSystemThreadDied:Fire(threads[i].Id)
							GLOBAL["__THREADS__"] = livingThreads
							table.remove(threads, i)
						end
					end
				end
			end
		end
	)
end
multi.print("Integrated Lanes!")
multi.integration = {} -- for module creators
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.lanesManager.extensions")
return {
	init = function()
		return GLOBAL, THREAD
	end
}
