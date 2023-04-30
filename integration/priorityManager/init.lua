-- Advanced process management. Mutates the multi namespace
local multi, thread = require("multi"):init()
local ok, chronos = pcall(require, "chronos") -- hpc

if not ok then chronos = nil end

-- This is an integration, we cannot directly access locals that are in the main file.

local PList = {
	multi.Priority_Core,
	multi.Priority_Very_High,
	multi.Priority_High,
	multi.Priority_Above_Normal,
	multi.Priority_Normal,
	multi.Priority_Below_Normal,
	multi.Priority_Low,
	multi.Priority_Very_Low,
	multi.Priority_Idle
}

-- Restructered these functions since they rely on local variables from the core library

local mainloop = multi.mainloopRef
local mainloop_p = multi.mainloop_p
local uManagerRef = multi.uManagerRef
local uManagerRefP = multi.uManagerRefP1

-- self:setCurrentProcess() a bit slower than using the local var, but there isn't another option

-- function multi:uManagerRef()
-- 	if self.Active then
-- 		self:setCurrentProcess()
-- 		local Loop=self.Mainloop
-- 		for _D=#Loop,1,-1 do
-- 			__CurrentTask = Loop[_D]
-- 			__CurrentTask:Act()
-- 			self:setCurrentProcess()
-- 		end
-- 	end
-- end

local function init()
	local RR, PB, TB = 0, 1, 2

    multi.priorityScheme = {
        RoundRobin = 0,
        PriorityBased = 1,
        TimedBased = 2
    }

    function multi:setPriorityScheme(scheme)
        if not self.Type == multi.PROCESS or not self.Type == multi.ROOTPROCESS then
			multi.warn("You should only invoke setPriorityScheme on a processor object!")
		end
        if scheme == RR then
			multi.mainloop = mainloop
			multi.uManager = uManagerRef
		elseif scheme == PB then
			multi.mainloop = mainloop_p
			multi.uManager = uManagerRefP
		elseif scheme == TB then
			--
		else
			multi.error("Invalid priority scheme passed!")
		end
    end
end

local function init_chronos()

end

if chronos then
    init_chronos()
else
    multi.print("In order to have time based priority management, you need to install the chronos library!")
end

init()

--chronos.nanotime()