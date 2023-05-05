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

local PROFILE_COUNT = 5

-- self:setCurrentProcess() a bit slower than using the local var, but there isn't another option

local priorityManager = multi:newProcessor("Priority Manager", true)
priorityManager.newThread = function() multi.warn("You cannot spawn threads on the priority manager!") end

priorityManager.setPriorityScheme = function() multi.warn("You cannot set priority on the priorityManager!") end

local function average(t)
	local sum = 0
	for _,v in pairs(t) do
		sum = sum + v
	end
	return sum / #t
end

local function getPriority(obj)
	local avg = average(obj.__profiling)
	if avg < 0.0002 then
		multi.print("Setting priority to: core")
		return PList[1]
	elseif avg < 0.0004 then
		multi.print("Setting priority to: very high")
		return PList[2]
	elseif avg < 0.0008 then
		multi.print("Setting priority to: high")
		return PList[3]
	elseif avg < 0.001 then
		multi.print("Setting priority to: above normal")
		return PList[4]
	elseif avg < 0.0025 then
		multi.print("Setting priority to: normal")
		return PList[5]
	elseif avg < 0.005 then
		multi.print("Setting priority to: below normal")
		return PList[6]
	elseif avg < 0.008 then
		multi.print("Setting priority to: low")
		return PList[7]
	elseif avg < 0.01 then
		multi.print("Setting priority to: very low")
		return PList[8]
	else
		multi.print("Setting priority to: idle")
		return PList[9]
	end
end

local start, stop

priorityManager.uManager = function(self)
	-- proc.run already checks if the processor is active
	self:setCurrentProcess()
	local Loop=self.Mainloop
	local ctask
	for _D=#Loop,1,-1 do
		ctask = Loop[_D]
		ctask:setCurrentTask()
		start = chronos.nanotime()
		if ctask:Act() then
			stop = chronos.nanotime()
			if ctask.__profiling then
				table.insert(ctask.__profiling, stop - start)
			end
			if ctask.__profiling and #ctask.__profiling == PROFILE_COUNT then
				ctask:setPriority(getPriority(ctask))
				ctask:reallocate(ctask.__restoreProc)
				ctask.__restoreProc = nil
				ctask.__profiling = nil
			end
		end
		self:setCurrentProcess()
	end
end

local function processHook(obj, proc)
	if obj.Type == multi.PROCESS or not(obj.IsAnActor) then return end
	obj.__restoreProc = proc
	obj.__profiling = {}
	obj:reallocate(priorityManager)
end

local function init()
	local registry = {}

    multi.priorityScheme = {
        RoundRobin = "RoundRobin",
        PriorityBased = "PriorityBased",
        TimeBased = "TimeBased"
    }

	function multi:setProfilerCount(count)
		PROFILE_COUNT = count
	end

	function multi:recalibrate()
		if self.__processConn then
			local items = self.Mainloop
			for i,v in pairs(items) do
				processHook(v, self)
			end
		else
			multi.error("Cannot recalibrate the priority if not using Time based mangement!")
		end
	end

	function multi:isRegistredScheme(scheme)
		return registry[name] ~= nil
	end

	function multi:getRegisteredScheme(scheme)
		return registry[name].mainloop, registry[name].umanager, registry[name].condition
	end

	local empty_func = function() return true end
	function multi:registerScheme(name,options)
		local mainloop = options.mainloop or multi.error("You must provide a mainloop option when registring a scheme!")
		local umanager = options.umanager or multi.error("You must provide a umanager option when registring a scheme!")

		if not options.condition then 
			multi.warn("You might want to use condition when registring a scheme! A function that returns true has been auto generated for you!")
		end

		local condition = options.condition or empty_func

		if registry[name] and not registry[name].static then 
			multi.warn("A scheme named: \"" .. name .. "\" has already been registred, overriting!") 
		else
			multi.error("A scheme named: \"" .. name .. "\" has already been registred!")
		end

		registry[name] = {
			mainloop = mainloop,
			umanager = umanger,
			condition = condition,
			static = options.static or false
		}

		multi.priorityScheme[name] = name

		return true
	end

    function multi:setPriorityScheme(scheme)

        if not self.Type == multi.PROCESS or not self.Type == multi.ROOTPROCESS then
			multi.warn("You should only invoke setPriorityScheme on a processor object!")
		end

        if scheme == multi.priorityScheme.RoundRobin then
			if self.__processConn then self.OnObjectCreated:Unconnect(self.__processConn) self.__processConn = nil end
			self.mainloop = mainloop
			self.uManager = uManagerRef
		elseif scheme == multi.priorityScheme.PriorityBased then
			if self.__processConn then self.OnObjectCreated:Unconnect(self.__processConn) self.__processConn = nil end
			self.mainloop = mainloop_p
			self.uManager = uManagerRefP
		elseif scheme == multi.priorityScheme.TimeBased then
			if not chronos then return multi.warn("Unable to use TimeBased Priority without the chronos library!") end
			if self.__processConn then multi.warn("Already enabled TimeBased Priority!") end
			self.__processConn = self.OnObjectCreated(processHook)
			self.mainloop = mainloop_p
			self.uManager = uManagerRefP
		elseif self:isRegistredScheme(scheme) then
			local mainloop, umanager, condition = self:getRegisteredScheme(scheme)
			if condition() then
				self.mainloop = mainloop
				self.uManager = umanager
			end
		else
			self.error("Invalid priority scheme selected!")
		end

    end
end

local function init_chronos()
	-- Let's implement a higher precision clock
	multi.setClock(chronos.nanotime) -- This is also in .000 format. So a plug and play works.
	thread:newThread("System Priority Manager", function()
		while true do
			thread.yield()
			priorityManager.run()
		end
	end).OnError(multi.error)
end

if chronos then
    init_chronos()
else
    multi.warn("In order to have time based priority management, you need to install the chronos library!")
end

init()