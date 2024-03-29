if ISTHREAD then
    error("You cannot require the loveManager from within a thread!")
end

local ThreadFileData = [[
ISTHREAD = true
args = {...}
THREAD_ID = args[1]
THREAD_NAME = args[2]
GLOBAL, THREAD, DEFER = require("multi.integration.loveManager.threads"):init()
__FUNC = THREAD.unpackValue(args[3])
ARGS = THREAD.unpackValue(args[4])
settings = args[5]
if ARGS == nil then ARGS = {} end
math.randomseed(THREAD_ID)
math.random()
math.random()
math.random()
stab = THREAD.createTable(THREAD_NAME .. THREAD_ID)
if GLOBAL["__env"] then
    local env = THREAD.getENV()
    for i,v in pairs(env) do
        _G[i] = v
    end
end
multi, thread = require("multi"):init{error=true, warning=true, print=true, priority=true}
multi.defaultSettings.print = true
require("multi.integration.loveManager.extensions")
require("multi.integration.sharedExtensions")
local returns = {pcall(__FUNC, multi.unpack(ARGS))}
table.remove(returns,1)
stab["returns"] = returns
for i,v in pairs(DEFER) do
    pcall(v)
end
]]

_G.THREAD_NAME = "MAIN_THREAD"
_G.THREAD_ID = 0

local multi, thread = require("multi"):init()
local GLOBAL, THREAD = require("multi.integration.loveManager.threads"):init()

multi.registerType("s_function")
multi.registerType("s_thread")

multi.integration = {}
multi.isMainThread = true
local threads = {}
local tid = 0
function multi:newSystemThread(name, func, ...)
    multi.InitSystemThreadErrorHandler()
    local name = name or multi.randomString(16)
    tid = tid + 1
    local c = {}
    c.Type = multi.STHREAD
    c.Name = name
    c.ID = tid
    c.thread = love.thread.newThread(ThreadFileData)
    c.thread:start(c.ID, c.Name, THREAD.packValue(func), THREAD.packValue({...}), multi.defaultSettings)
    c.stab = THREAD.createTable(name .. c.ID)
    c.creationTime = os.clock()
    c.OnDeath = multi:newConnection()
    c.OnError = multi:newConnection()
    c.status_channel = love.thread.getChannel("__status_channel__" .. c.ID)

    function c:getName() return c.name end

    table.insert(threads, c)

    c.OnError(multi.error)

    if self.isActor then
		self:create(c)
	else
		multi.create(multi, c)
	end

    return c
end

local started = false
local console_channel = love.thread.getChannel("__console_channel__")

function THREAD:newFunction(func, holdme)
    return thread:newFunctionBase(function(...)
        return multi:newSystemThread("SystemThreaded Function Handler", func, ...)
    end, holdme, multi.SFUNCTION)()
end

function love.threaderror(thread, errorstr)
    multi.error("Thread error! " .. errorstr)
end

function multi.InitSystemThreadErrorHandler()
	if started == true then return end
	started = true
    thread:newThread("Love System Thread Handler", function()
        while true do
            thread.yield()
            for i = #threads, 1, -1 do
                local th = threads[i]
                if th.status_channel:peek() ~= nil then
                    th.statusconnector:Fire(multi.unpack(th.status_channel:pop()))
                end
                local th_err = th.thread:getError()
                if th_err == "Thread Killed!\1" then
                    th.OnDeath:Fire("Thread Killed!")
                    table.remove(threads, i)
                elseif th_err then
                    th.OnError:Fire(th, th_err)
                    table.remove(threads, i)
                elseif th.stab.returns then
                    th.OnDeath:Fire(multi.unpack(th.stab.returns))
                    th.stab.returns = nil
                    table.remove(threads, i)
                end
            end
        end
    end)
end

THREAD.newSystemThread = function(...)
    multi:newSystemThread(...)
end

multi.integration.GLOBAL = GLOBAL
multi.integration.THREAD = THREAD
require("multi.integration.loveManager.extensions")
require("multi.integration.sharedExtensions")
multi.print("Integrated Love Threading!")

return {
    init = function()
        return GLOBAL, THREAD
    end
}
