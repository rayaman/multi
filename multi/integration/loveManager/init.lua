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
if ISTHREAD then
    error("You cannot require the loveManager from within a thread!")
end
local ThreadFileData = [[
ISTHREAD = true
THREAD = require("multi.integration.loveManager.threads") -- order is important!
sThread = THREAD
__IMPORTS = {...}
__FUNC__=table.remove(__IMPORTS,1)
__THREADID__=table.remove(__IMPORTS,1)
__THREADNAME__=table.remove(__IMPORTS,1)
stab = THREAD.createStaticTable(__THREADNAME__)
GLOBAL = THREAD.getGlobal()
multi, thread = require("multi").init()
stab["returns"] = {THREAD.loadDump(__FUNC__)(unpack(__IMPORTS))}
]]
local multi, thread = require("multi.compat.love2d"):init()
local THREAD = {}
__THREADID__ = 0
__THREADNAME__ = "MainThread"
multi.integration={}
multi.integration.love2d={}
local THREAD = require("multi.integration.loveManager.threads")
local GLOBAL = THREAD.getGlobal()
local THREAD_ID = 1
local OBJECT_ID = 0
local stf = 0
function THREAD:newFunction(func,holup)
    stf = stf + 1
	return function(...)
		local t = multi:newSystemThread("STF"..stf,func,...)
		return thread:newFunction(function()
            return thread.hold(function()
                if t.stab["returns"] then
                    local dat = t.stab.returns
                    t.stab.returns = nil
                    return unpack(dat)
                end
			end)
		end,holup)()
	end
end
function multi:newSystemThread(name,func,...)
    local c = {}
    c.name = name
    c.ID=THREAD_ID
    c.thread=love.thread.newThread(ThreadFileData)
    c.thread:start(THREAD.dump(func),c.ID,c.name,...)
    c.stab = THREAD.createStaticTable(name)
    GLOBAL["__THREAD_"..c.ID] = {ID=c.ID,Name=c.name,Thread=c.thread}
    GLOBAL["__THREAD_COUNT"] = THREAD_ID
    THREAD_ID=THREAD_ID+1
    return c
end
function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.loveManager.extensions")
return {init=function()
    return GLOBAL,THREAD
end}