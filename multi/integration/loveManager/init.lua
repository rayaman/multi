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
local multi, thread = require("multi"):init()
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

function multi:newSystemThread(name,func,...)
    local c = {}
    c.name = name
    c.ID=THREAD_ID
    c.thread=love.thread.newThread(ThreadFileData)
    c.thread:start(THREAD.dump(func),c.ID,c.name,...)
    c.stab = THREAD.createStaticTable(name)
	c.OnDeath = multi:newConnection()
	c.OnError = multi:newConnection()
    GLOBAL["__THREAD_"..c.ID] = {ID=c.ID, Name=c.name, Thread=c.thread}
    GLOBAL["__THREAD_COUNT"] = THREAD_ID
    THREAD_ID=THREAD_ID + 1
    thread:newThread(function()
        while true do
            thread.yield()
            if c.stab["returns"] then
                c.OnDeath:Fire(c,unpack(t.stab.returns))
                t.stab.returns = nil
                thread.kill()
            end
            local error = c.thread:getError()
            if error then
                if error:find("Thread Killed!\1") then
                    c.OnDeath:Fire(c, "Thread Killed!")
                    thread.kill()
                else
                    c.OnError:Fire(c, error)
                    thread.kill()
                end
            end
        end
    end)
    return c
end

function THREAD:newFunction(func)
	return thread:newFunctionBase(function(...)
		return multi:newSystemThread("TempSystemThread",func,...)
	end)()
end

THREAD.newSystemThread = multi.newSystemThread
function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.loveManager.extensions")
print("Integrated Love Threading!")
return {init=function()
    return GLOBAL,THREAD
end}