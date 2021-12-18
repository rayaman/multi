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
multi:newLoop(function()
	local _,data = __ConsoleLinda:receive(0, "Q")
	if data then
		print(unpack(data))
	end
end)
local GLOBAL,THREAD = require("multi.integration.lanesManager.threads").init(__GlobalLinda,__SleepingLinda)
local threads = {}
local count = 1
local started = false
local livingThreads = {}

function THREAD:newFunction(func,holdme)
    local tfunc = {}
	tfunc.Active = true
	function tfunc:Pause()
		self.Active = false
	end
	function tfunc:Resume()
		self.Active = true
	end
	function tfunc:holdMe(b)
		holdme = b
	end
	local function noWait()
		return nil, "Function is paused"
	end
    local rets, err
	local function wait(no) 
		if thread.isThread() and not (no) then
			return multi.hold(function()
				if err then
					return nil, err
				elseif rets then
					return unpack(rets)
				end
			end)
		else
			while not rets and not err do
				multi.scheduler:Act()
			end
			if err then
				return nil,err
			end
			return unpack(rets)
		end
	end
    tfunc.__call = function(t,...)
		if not t.Active then 
			if holdme then
				return nil, "Function is paused"
			end
			return {
				isTFunc = true,
				wait = noWait,
				connect = function(f)
					f(nil,"Function is paused")
				end
			}
		end 
        local t = multi:newSystemThread("SystemThreadedFunction",func,...)
		t.OnDeath(function(self,...) rets = {...}  end)
		t.OnError(function(self,e) err = e end)
		if holdme then
			return wait()
		end
		local temp = {
			OnStatus = multi:newConnection(),
			OnError = multi:newConnection(),
			OnReturn = multi:newConnection(),
			isTFunc = true,
			wait = wait,
			connect = function(f)
				local tempConn = multi:newConnection()
				t.OnDeath(function(self,...) if f then f(...) else tempConn:Fire(...) end end) 
				t.OnError(function(self,err) if f then f(nil,err) else tempConn:Fire(nil,err) end end)
				return tempConn
			end
		}
		t.OnDeath(function(self,...) temp.OnReturn:Fire(...) end) 
		t.OnError(function(self,err) temp.OnError:Fire(err) end)
		t.linkedFunction = temp
		t.statusconnector = temp.OnStatus
		return temp
	end
	setmetatable(tfunc,tfunc)
    return tfunc
end

function multi:newSystemThread(name, func, ...)
	multi.InitSystemThreadErrorHandler()
	rand = math.random(1, 10000000)
	local c = {}
	local __self = c
	c.name = name
	c.Name = name
	c.Id = count
	c.loadString = {"base","package","os","io","math","table","string","coroutine"}
	livingThreads[count] = {true, name}
	c.Type = "sthread"
	c.creationTime = os.clock()
	c.alive = true
	c.priority = THREAD.Priority_Normal
	local args = {...}
	multi:newThread(function()
		c.thread = lanes.gen(table.concat(c.loadString,","),
		{
			globals={ -- Set up some globals
				THREAD_NAME=name,
				THREAD_ID=count,
				THREAD = THREAD,
				GLOBAL = GLOBAL,
				_Console = __ConsoleLinda
			},
			priority=c.priority
		},func)(unpack(args))
		thread.kill()
	end)
	count = count + 1
	function c:kill()
		self.thread:cancel()
		multi.print("Thread: '" .. self.name .. "' has been stopped!")
		self.alive = false
	end
	table.insert(multi.SystemThreads, c)
	c.OnDeath = multi:newConnection()
	c.OnError = multi:newConnection()
	GLOBAL["__THREADS__"] = livingThreads
	return c
end

local function detectLuaError(str)
	return type(str)=="string" and str:match("%.lua:%d*:")
end

local function tableLen(tab)
	local len = 0
	for i,v in pairs(tab) do
		len = len + 1
	end
	return len
end

function multi.InitSystemThreadErrorHandler()
	if started == true then
		return
	end
	started = true
	multi:newThread("ThreadErrorHandler",function()
		local threads = multi.SystemThreads
		while true do
			thread.sleep(.1) -- switching states often takes a huge hit on performance. half a second to tell me there is an error is good enough.
			for i = #threads, 1, -1 do
				local _,data = pcall(function()
					return {threads[i].thread:join(1)}
				end)
				local v, err, t = data[1],data[2],data[3]
				if detectLuaError(err) then
					if err:find("Thread was killed!\1") then
						livingThreads[threads[i].Id] = {false, threads[i].Name}
						threads[i].alive = false
						threads[i].OnDeath:Fire(threads[i],nil,"Thread was killed!")
						GLOBAL["__THREADS__"] = livingThreads
						table.remove(threads, i)
					else
						threads[i].OnError:Fire(threads[i], err, "Error in systemThread: '" .. threads[i].name .. "' <" .. err .. ">")
						threads[i].alive = false
						livingThreads[threads[i].Id] = {false, threads[i].Name}
						GLOBAL["__THREADS__"] = livingThreads
						table.remove(threads, i)
					end
				elseif tableLen(data)>0 then
					livingThreads[threads[i].Id] = {false, threads[i].Name}
					threads[i].alive = false
					threads[i].OnDeath:Fire(threads[i],unpack(data))
					GLOBAL["__THREADS__"] = livingThreads
					table.remove(threads, i)
				end
			end
		end
	end).OnError(function(...)
		print("Error!",...)
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
