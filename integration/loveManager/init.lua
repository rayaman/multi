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
THREAD = require("multi.integration.loveManager.threads")
sThread = THREAD
__IMPORTS = {...}
__FUNC__=table.remove(__IMPORTS,1)
THREAD_ID=table.remove(__IMPORTS,1)
THREAD_NAME=table.remove(__IMPORTS,1)
math.randomseed(THREAD_ID)
math.random()
math.random()
math.random()
stab = THREAD.createStaticTable(THREAD_NAME .. THREAD_ID)
GLOBAL = THREAD.getGlobal()
if GLOBAL["__env"] then
    local env = THREAD.unpackENV(GLOBAL["__env"])
    for i,v in pairs(env) do
        _G[i] = v
    end
end
multi, thread = require("multi").init()
multi.integration={}
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
pcall(require,"multi.integration.loveManager.extensions")
pcall(require,"multi.integration.sharedExtensions")
stab["returns"] = {THREAD.loadDump(__FUNC__)(multi.unpack(__IMPORTS))}
]]

local multi, thread = require("multi"):init()

local THREAD = {}
_G.THREAD_NAME = "MAIN_THREAD"
_G.THREAD_ID = 0
multi.integration = {}
local THREAD = require("multi.integration.loveManager.threads")
local GLOBAL = THREAD.getGlobal()
multi.isMainThread = true

function multi:newSystemThread(name, func, ...)
    THREAD_ID = THREAD_ID + 1
    local c = {}
    c.name = name
    c.ID = THREAD_ID
    c.thread = love.thread.newThread(ThreadFileData)
    c.thread:start(THREAD.dump(func), c.ID, c.name, ...)
    c.stab = THREAD.createStaticTable(name .. c.ID)
    c.OnDeath = multi:newConnection()
    c.OnError = multi:newConnection()
    GLOBAL["__THREAD_" .. c.ID] = {ID = c.ID, Name = c.name, Thread = c.thread}
    GLOBAL["__THREAD_COUNT"] = THREAD_ID
    
    function c:getName() return c.name end
    thread:newThread(name .. "_System_Thread_Handler",function()
        if name == "SystemThreaded Function Handler" then
            local status_channel = love.thread.getChannel("STATCHAN_" .. c.ID)
            thread.hold(function()
                -- While the thread is running we might as well do something in the loop
                if status_channel:peek() ~= nil then
                    c.statusconnector:Fire(multi.unpack(status_channel:pop()))
                end
                return not c.thread:isRunning()
            end)
        else
            thread.hold(function() return not c.thread:isRunning() end)
        end
        -- If the thread is not running let's handle that.
        local thread_err = c.thread:getError()
        if thread_err == "Thread Killed!\1" then
            c.OnDeath:Fire("Thread Killed!")
        elseif thread_err then
            c.OnError:Fire(c, thread_err)
        elseif c.stab.returns then
            c.OnDeath:Fire(multi.unpack(c.stab.returns))
            c.stab.returns = nil
        end
    end)
    	
	if self.isActor then
		self:create(c)
	else
		multi.create(multi, c)
	end

    return c
end

function THREAD:newFunction(func, holdme)
    return thread:newFunctionBase(function(...)
        return multi:newSystemThread("SystemThreaded Function Handler", func, ...)
    end, holdme)()
end

THREAD.newSystemThread = multi.newSystemThread

function love.threaderror(thread, errorstr)
    multi.print("Thread error!\n" .. errorstr)
end

multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.loveManager.extensions")
require("multi.integration.sharedExtensions")
multi.print("Integrated Love Threading!")
return {init = function() return GLOBAL, THREAD end}
