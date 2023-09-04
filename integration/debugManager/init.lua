local multi, thread = require("multi"):init()

multi.defaultSettings.debugging = true

local dbg = {}

local creation_hook

creation_hook = function(obj, process)
    print("Created: ",obj.Type, "in", process.Type, process:getFullName())
    if obj.Type == multi.PROCESS then
        obj.OnObjectCreated(creation_hook)
    end
end

local debug_stats = {}

local tmulti = multi:getThreadManagerProcess()
multi.OnObjectCreated(creation_hook)
tmulti.OnObjectCreated(creation_hook)

--[[
    multi.ROOTPROCESS		= "rootprocess"
    multi.CONNECTOR			= "connector"
    multi.TIMEMASTER		= "timemaster"
    multi.PROCESS			= "process"
    multi.TIMER				= "timer"
    multi.EVENT				= "event"
    multi.UPDATER			= "updater"
    multi.ALARM				= "alarm"
    multi.LOOP				= "loop"
    multi.TLOOP				= "tloop"
    multi.STEP				= "step"
    multi.TSTEP				= "tstep"
    multi.THREAD			= "thread"
    multi.SERVICE			= "service"
    multi.PROXY 			= "proxy"
    multi.THREADEDFUNCTION	= "threaded_function"
]]