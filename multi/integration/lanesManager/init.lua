--[[
MIT License

Copyright (c) 2020 Ryan Ward

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
local GLOBAL,THREAD = require("multi.integration.lanesManager.threads").init(__GlobalLinda,__SleepingLinda)
local threads = {}
local count = 1
local started = false
local livingThreads = {}
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
