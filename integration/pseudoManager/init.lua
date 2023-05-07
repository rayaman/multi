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
local multi, thread = require("multi"):init()

if multi.integration then
	return {
		init = function()
			return multi.integration.GLOBAL, multi.integration.THREAD
		end
	}
end

local GLOBAL, THREAD = require("multi.integration.pseudoManager.threads").init(thread)

function multi:canSystemThread() -- We are emulating system threading
	return true
end

function multi:getPlatform()
	return "pesudo"
end

local function split(str)
	local tab = {}
	for word in string.gmatch(str, '([^,]+)') do
		table.insert(tab,word)
	end
	return tab
end

local tab = [[_VERSION,io,os,require,load,debug,assert,collectgarbage,error,getfenv,getmetatable,ipairs,loadstring,module,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,xpcall,math,coroutine,string,table]]
tab = split(tab)

local id = 0
function multi:newSystemThread(name,func,...)
	GLOBAL["$THREAD_NAME"] = name
	GLOBAL["$__THREADNAME__"] = name
	GLOBAL["$THREAD_ID"] = id
	GLOBAL["$thread"] = thread

	local env = {
		GLOBAL = GLOBAL,
		THREAD = THREAD,
		THREAD_NAME = name,
		__THREADNAME__ = name,
		THREAD_ID = id,
		thread = thread,
	}

	if GLOBAL["__env"] then
		for i,v in pairs(GLOBAL["__env"]) do
			env[i] = v
		end
	end
	
	for i = 1,#tab do
		env[tab[i]] = _G[tab[i]]
	end

	local th = thread:newISOThread(name,func,env,...)
	
	id = id + 1

	return th
end

THREAD.newSystemThread = multi.newSystemThread
-- System threads as implemented here cannot share memory, but use a message passing system.
-- An isolated thread allows us to mimic that behavior so if access data from the "main" thread happens things will not work. This behavior is in line with how the system threading works

function THREAD:newFunction(func,holdme)
	return thread:newFunctionBase(function(...)
		return multi:newSystemThread("TempSystemThread",func,...)
	end,holdme)()
end

multi.print("Integrated Pesudo Threading!")
multi.integration = {} -- for module creators
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.pseudoManager.extensions")
return {
	init = function()
		return GLOBAL, THREAD
	end
}
