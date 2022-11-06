--[[
MIT License

Copyright (c) 2022 Ryan Ward

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
multi, thread = require("multi"):init() -- get it all and have it on all lanes
if multi.integration then -- This allows us to call the lanes manager from supporting modules without a hassle
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
local __ConsoleLinda = lanes.linda() -- handles console stuff
local __StatusLinda = lanes.linda() -- handles pushstatus for stfunctions

local GLOBAL,THREAD = require("multi.integration.lanesManager.threads").init(__GlobalLinda, __SleepingLinda, __StatusLinda, __ConsoleLinda)
local count = 1
local started = false
local livingThreads = {}

function THREAD:newFunction(func,holdme)
	return thread:newFunctionBase(function(...)
		return multi:newSystemThread("TempSystemThread",func,...)
	end,holdme)()
end

function multi:newSystemThread(name, func, ...)
	local name = name or multi.randomString(16)
	multi.InitSystemThreadErrorHandler()
	local rand = math.random(1, 10000000)
	local return_linda = lanes.linda()
	c = {}
	c.name = name
	c.Name = name
	c.Id = count
	c.loadString = {"base","package","os","io","math","table","string","coroutine"}
	livingThreads[count] = {true, name}
	c.returns = return_linda
	c.Type = "sthread"
	c.creationTime = os.clock()
	c.alive = true
	c.priority = THREAD.Priority_Normal
	local multi_settings = multi.defaultSettings
	for i,v in pairs(multi_settings) do
		print(i,v)
	end
	c.thread = lanes.gen("*",
	{
		globals={ -- Set up some globals
			THREAD_NAME = name,
			THREAD_ID = count,
			THREAD = THREAD,
			GLOBAL = GLOBAL,
			_Console = __ConsoleLinda
		},
		priority=c.priority
	},function(...)
		require("multi"):init(multi_settings)
		require("multi.integration.lanesManager.extensions")
		local has_error = true
		return_linda:set("returns",{func(...)})
		has_error = false
	end)(...)
	count = count + 1
	function c:getName()
		return c.Name
	end
	function c:kill()
		self.thread:cancel()
		self.alive = false
	end
	table.insert(multi.SystemThreads, c)
	c.OnDeath = multi:newConnection()
	c.OnError = multi:newConnection()
	GLOBAL["__THREADS__"] = livingThreads
	return c
end

THREAD.newSystemThread = multi.newSystemThread

function multi.InitSystemThreadErrorHandler()
	if started == true then
		return
	end
	started = true
	thread:newThread("SystemThreadScheduler",function()
		local threads = multi.SystemThreads
		local _,data,status,push,temp
		while true do
			thread.yield()
			_,data = __ConsoleLinda:receive(0, "Q")
			if data then print(unpack(data)) end
			for i = #threads, 1, -1 do
				temp = threads[i]
				status = temp.thread.status
				push = __StatusLinda:get(temp.Id)
				if push then
					temp.statusconnector:Fire(unpack(({__StatusLinda:receive(nil, temp.Id)})[2]))
				end
				if status == "done" or temp.returns:get("returns") then
					livingThreads[temp.Id] = {false, temp.Name}
					temp.alive = false
					temp.OnDeath:Fire(unpack(({temp.returns:receive(0, "returns")})[2]))
					GLOBAL["__THREADS__"] = livingThreads
					table.remove(threads, i)
				elseif status == "running" then
					--
				elseif status == "waiting" then
					--
				elseif status == "error" then
					livingThreads[temp.Id] = {false, temp.Name}
					temp.alive = false
					temp.OnError:Fire(temp,unpack(temp.returns:receive(0,"returns") or {"Thread Killed!"}))
					GLOBAL["__THREADS__"] = livingThreads
					table.remove(threads, i)
				elseif status == "cancelled" then
					livingThreads[temp.Id] = {false, temp.Name}
					temp.alive = false
					temp.OnError:Fire(temp,"thread_cancelled")
					GLOBAL["__THREADS__"] = livingThreads
					table.remove(threads, i)
				elseif status == "killed" then
					livingThreads[temp.Id] = {false, temp.Name}
					temp.alive = false
					temp.OnError:Fire(temp,"thread_killed")
					GLOBAL["__THREADS__"] = livingThreads
					table.remove(threads, i)
				end
			end
		end
	end)
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
