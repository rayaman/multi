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

-- This module probably will not be maintained any longer!
package.path = "?/init.lua;?.lua;" .. package.path
local function _INIT(luvitThread, timer)
	-- lots of this stuff should be able to stay the same
	function os.getOS()
		if package.config:sub(1, 1) == "\\" then
			return "windows"
		else
			return "unix"
		end
	end
	-- Step 1 get setup threads on luvit... Sigh how do i even...
	local multi, thread = require("multi").init()
	isMainThread = true
	function multi:canSystemThread()
		return true
	end
	function multi:getPlatform()
		return "luvit"
	end
	local multi = multi
	-- Step 2 set up the Global table... is this possible?
	local GLOBAL = {}
	setmetatable(
		GLOBAL,
		{
			__index = function(t, k)
				--print("No Global table when using luvit integration!")
				return nil
			end,
			__newindex = function(t, k, v)
				--print("No Global table when using luvit integration!")
			end
		}
	)
	local THREAD = {}
	function THREAD.set(name, val)
		--print("No Global table when using luvit integration!")
	end
	function THREAD.get(name)
		--print("No Global table when using luvit integration!")
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
		--print("No Global table when using luvit integration!")
	end
	function THREAD.testFor(name, val, sym)
		--print("No Global table when using luvit integration!")
	end
	function THREAD.getCores()
		return THREAD.__CORES
	end
	if os.getOS() == "windows" then
		THREAD.__CORES = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
	else
		THREAD.__CORES = tonumber(io.popen("nproc --all"):read("*n"))
	end
	function THREAD.kill() -- trigger the thread destruction
		error("Thread was Killed!")
	end
	-- hmmm if im cleaver I can get this to work... but since data passing isn't going to be a thing its probably not important
	function THREAD.sleep(n)
		--print("No Global table when using luvit integration!")
	end
	function THREAD.hold(n)
		--print("No Global table when using luvit integration!")
	end
	-- Step 5 Basic Threads!
	local function entry(path, name, func, ...)
		local timer = require "timer"
		local luvitThread = require "thread"
		package.path = path
		loadstring(func)(...)
	end
	function multi:newSystemThread(name, func, ...)
		local c = {}
		local __self = c
		c.name = name
		c.Type = "sthread"
		c.thread = {}
		c.func = string.dump(func)
		function c:kill()
			-- print("No Global table when using luvit integration!")
		end
		luvitThread.start(entry, package.path, name, c.func, ...)
		return c
	end
	multi.print("Integrated Luvit!")
	multi.integration = {} -- for module creators
	multi.integration.GLOBAL = GLOBAL
	multi.integration.THREAD = THREAD
	require("multi.integration.shared")
	-- Start the main mainloop... This allows you to process your multi objects, but the engine on the main thread will be limited to .001 or 1 millisecond sigh...
	local interval =
		timer.setInterval(
		1,
		function()
			multi:uManager()
		end
	)
	return multi
end
return {init = function(threadHandle, timerHandle)
	local multi = _INIT(threadHandle, timerHandle)
	return GLOBAL, THREAD
end}
