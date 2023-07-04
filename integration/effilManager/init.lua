local multi, thread = require("multi"):init{error=true}
multi.error("Currntly not supported!")
os.exit(1)
local effil = require("effil")

-- I like some of the things that this library offers.
-- Current limitations prevent me from being able to use effil, 
--	but I might fork and work on it myself.

-- Configs
effil.allow_table_upvalues(false)

local GLOBAL,THREAD = require("multi.integration.effilManager.threads").init()
local count = 1
local started = false
local livingThreads = {}

function multi:newSystemThread(name, func, ...)
    local name = name or multi.randomString(16)
	local rand = math.random(1, 10000000)
    c = {}
	c.name = name
	c.Name = name
	c.Id = count
end

function THREAD:newFunction(func, holdme)
	return thread:newFunctionBase(function(...)
		return multi:newSystemThread("TempSystemThread",func,...)
	end, holdme, multi.SFUNCTION)()
end

THREAD.newSystemThread = function(...)
    multi:newSystemThread(...)
end

multi.print("Integrated Effil Threading!")
multi.integration = {} -- for module creators
multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.effilManager.extensions")
return {
	init = function()
		return GLOBAL, THREAD
	end
}