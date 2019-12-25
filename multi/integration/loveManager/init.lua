if ISTHREAD then
    error("You cannot require the loveManager from within a thread!")
end
local ThreadFileData = [[
ISTHREAD = true
THREAD = require("multi.integration.loveManager.threads") -- order is important!
scratchpad = require("multi.integration.loveManager.scratchpad")
STATUS = require("multi.integration.loveManager.status")
__IMPORTS = {...}
__FUNC__=table.remove(__IMPORTS,1)
__THREADID__=table.remove(__IMPORTS,1)
__THREADNAME__=table.remove(__IMPORTS,1)
pad=table.remove(__IMPORTS,1)
globalhpad=table.remove(__IMPORTS,1)
GLOBAL = THREAD.getGlobal()
multi, thread = require("multi").init()
THREAD.loadDump(__FUNC__)(unpack(__IMPORTS))]]
local multi, thread = require("multi.compat.love2d"):init()
local THREAD = {}
__THREADID__ = 0
__THREADNAME__ = "MainThread"
multi.integration={}
multi.integration.love2d={}
multi.integration.love2d.defaultScratchpadSize = 1024
multi.integration.love2d.GlobalScratchpad = love.data.newByteData(string.rep("\0",16*multi.integration.love2d.defaultScratchpadSize))
local THREAD = require("multi.integration.loveManager.threads")
local scratchpad = require("multi.integration.loveManager.scratchpad")
local STATUS = require("multi.integration.loveManager.status")
local GLOBAL = THREAD.getGlobal()
local THREAD_ID = 1 -- The Main thread has ID of 0
local OBJECT_ID = 0
function multi:newSystemThread(name,func,...)
    local c = {}
    c.scratchpad = love.data.newByteData(string.rep("\0",multi.integration.love2d.defaultScratchpadSize))
    c.name = name
    c.ID=THREAD_ID
    c.thread=love.thread.newThread(ThreadFileData)
    c.thread:start(THREAD.dump(func),c.ID,c.name,c.scratchpad,multi.integration.love2d.GlobalScratchpad,...)
    GLOBAL["__THREAD_"..c.ID] = {ID=c.ID,Name=c.name,Thread=c.thread}
    GLOBAL["__THREAD_COUNT"] = THREAD_ID
    THREAD_ID=THREAD_ID+1
end
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
return {init=function()
    return GLOBAL,THREAD
end}