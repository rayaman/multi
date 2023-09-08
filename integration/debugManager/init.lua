local multi, thread = require("multi"):init()

multi.defaultSettings.debugging = true

local dbg = {}
dbg.__index = dbg
dbg.processors = {}

-- Hooks to all on object created events!
local c_cache = {}
local d_cache = {}

local proc = multi:newProcessor("Debug_Processor").Start()

dbg.OnObjectCreated = function(obj, process)
    if c_cache[obj] then
        return false
    else
        c_cache[obj] = true
        proc:newTask(function()
            c_cache[obj] = false
        end)
        return true
    end
end .. multi:newConnection()

dbg.OnObjectDestroyed = function(obj, process)
    if d_cache[obj] then
        return false
    else
        d_cache[obj] = true
        proc:newTask(function()
            d_cache[obj] = false
        end)
        return true
    end
end .. multi:newConnection()

local creation_hook, destruction_hook
local types
local processes = {}

creation_hook = function(obj, process)
    types = multi:getTypes()
    if obj.Type == multi.PROCESS and not dbg.processors[obj] then
        obj.OnObjectCreated(creation_hook)
        obj.OnObjectDestroyed(destruction_hook)
        dbg.processors[obj] = {}
    end
    dbg.OnObjectCreated:Fire(obj, process)
end

destruction_hook = function(obj, process)
    dbg.OnObjectDestroyed:Fire(obj, process)
end

local debug_stats = {}

local tmulti = multi:getThreadManagerProcess()
multi.OnObjectCreated(creation_hook)
tmulti.OnObjectCreated(creation_hook)
multi.OnObjectDestroyed(destroction_hook)
tmulti.OnObjectDestroyed(destroction_hook)

-- We write to a debug interface in the multi namespace
multi.debugging = dbg
