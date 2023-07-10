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

_G.THREAD_NAME = "MAIN_THREAD"
_G.THREAD_ID = 0

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

function THREAD:newFunction(func, holdme)
	return thread:newFunctionBase(function(...)
		return multi:newSystemThread("TempSystemThread",func,...)
	end, holdme, multi.SFUNCTION)()
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
	c.Type = multi.STHREAD
	c.creationTime = os.clock()
	c.alive = true
	c.priority = THREAD.Priority_Normal
	local multi_settings = multi.defaultSettings
	local globe = {
		THREAD_NAME = name,
		THREAD_ID = count,
		THREAD = THREAD,
		GLOBAL = GLOBAL,
		_Console = __ConsoleLinda
	}
	if GLOBAL["__env"] then
		for i,v in pairs(GLOBAL["__env"]) do
			globe[i] = v
		end
	end
	c.thread = lanes.gen("*",
	{
		globals = globe,
		priority = c.priority
	},function(...)
		local profi

		if multi_settings.debug then
			profi = require("proFI")
			profi:start()
		end

		multi, thread = require("multi"):init(multi_settings)
		require("multi.integration.lanesManager.extensions")
		require("multi.integration.sharedExtensions")
		local has_error = true
		returns = {pcall(func, ...)}
		return_linda:set("returns", returns)
		has_error = false
		if profi then
			multi.OnExit(function(...)
				profi:stop()
				profi:writeReport("Profiling Report [".. THREAD_NAME .."].txt")
			end)
		end
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

	if self.isActor then
		self:create(c)
	else
		multi.create(multi, c)
	end

	return c
end

THREAD.newSystemThread = function(...)
    multi:newSystemThread(...)
end

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
			if data then
				--print(data[1])
			end
			for i = #threads, 1, -1 do
				temp = threads[i]
				status = temp.thread.status
				push = __StatusLinda:get(temp.Id)
				if push then
					temp.statusconnector:Fire(multi.unpack(({__StatusLinda:receive(nil, temp.Id)})[2]))
				end
				if status == "done" or temp.returns:get("returns") then
					returns = ({temp.returns:receive(0, "returns")})[2]
					livingThreads[temp.Id] = {false, temp.Name}
					temp.alive = false
					if returns[1] == false then
						temp.OnError:Fire(temp, returns[2])
					else
						table.remove(returns,1)
						temp.OnDeath:Fire(multi.unpack(returns))
					end
					GLOBAL["__THREADS__"] = livingThreads
					table.remove(threads, i)
				elseif status == "running" then
					--
				elseif status == "waiting" then
					--
				elseif status == "error" then
					-- The thread never really errors, we handle this through our linda object
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
	end).OnError(multi.error)
end

multi.print("Integrated Lanes Threading!")
multi.integration = {} -- for module creators
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.lanesManager.extensions")
return {
	init = function()
		return GLOBAL, THREAD
	end
}
