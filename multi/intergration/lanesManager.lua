function os.getOS()
	if package.config:sub(1,1)=='\\' then
		return 'windows'
	else
		return 'unix'
	end
end
-- Step 1 get lanes
lanes=require("lanes").configure()
package.path="lua/?/init.lua;lua/?.lua;"..package.path
require("multi.all") -- get it all and have it on all lanes
local multi=multi
-- Step 2 set up the linda objects
local __GlobalLinda = lanes.linda() -- handles global stuff
local __SleepingLinda = lanes.linda() -- handles sleeping stuff
-- For convience a GLOBAL table will be constructed to handle requests
local GLOBAL={}
setmetatable(GLOBAL,{
	__index=function(t,k)
		return __GlobalLinda:get(k)
	end,
	__newindex=function(t,k,v)
		__GlobalLinda:set(k,v)
	end,
})
-- Step 3 rewrite the thread methods to use lindas
local THREAD={}
function THREAD.set(name,val)
	__GlobalLinda:set(name,val)
end
function THREAD.get(name)
	__GlobalLinda:get(name)
end
function THREAD.waitFor(name)
	--
end
function THREAD.testFor(name,val,sym)
	--
end
function THREAD.getCores()
	return THREAD.__CORES
end
if os.getOS()=="windows" then
	THREAD.__CORES=tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
else
	THREAD.__CORES=tonumber(io.popen("nproc --all"):read("*n"))
end
-- Step 4 change the coroutine threading methods to work the same, but with lanes TODO when the lanes scheduler is ready!
function THREAD.skip(n)
	-- Do Nothing
end
function THREAD.kill() -- trigger the lane destruction
	-- coroutine.yield({"_kill_",":)"})
end
--[[ Step 5 We need to get sleeping working so we need a lane to handle timing... We want idle wait not busy wait
Idle wait keeps the CPU running better where busy wait wastes CPU cycles... Lanes does not have a sleep method
however, a linda recieve will in fact be a idle wait! So when wait is called we can pack the cmd up and send it to
the sleeping thread manager to send the variable for the other thread to consume, sending only after a certain time has passed!
]]
local function randomString(n)
	local str = ''
	local strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		str = str..''..strings[math.random(1,#strings)]
	end
	return str
end
function THREAD.sleep(n)
	math.randomseed(os.time())
	local randKey=randomString(12) -- generate a random string a-Z and 0-9
	__SleepingLinda:send("tired","SLEEP|"..randKey.."|"..tostring(n)) -- send the data that needs to be managed
	local dat=__SleepingLinda:receive(randKey)
	return dat
end
function THREAD.hold(n)
	while not(n()) do
		-- holding
	end
end
-- start the time manager lane
--~ lanes.gen("*", function()
--~ 	local timers={}
--~ 	while true do -- forever loop!
--~ 		local data=__SleepingLinda:receive(.001,"tired") -- timeout after .001 seconds and handle the other stuff
--~ 		if data then -- the .001 is an entarnal timer that keeps this thread from using too much CPU as well!
--~ 			print(data)
--~ 			local cmd,key,sec=data:match("(%S-)|(%S-)|(.+)")
--~ 			if cmd=="SLEEP" then
--~ 				print("GOT!")
--~ 				timers[#timers+1]={os.clock()+tonumber(sec),key}
--~ 				--__SleepingLinda:set()
--~ 			elseif cmd=="audit" then
--~ 				--
--~ 			end
--~ 		end
--~ 		for i=1,#timers do
--~ 			if os.clock()>=timers[i][1] then
--~ 				__SleepingLinda:send(timers[i][2],true)
--~ 				table.remove(timers,i)
--~ 			end
--~ 		end
--~ 	end
--~ end)() -- The global timer is now activated, and it works great!
-- Step 6 Basic Threads!
function multi:newSystemThread(name,func)
    local c={}
    local __self=c
    c.name=name
    c.thread=lanes.gen("*", func)()
	function c:kill()
		self.status:Destroy()
		self.thread:cancel()
		print("Thread: '"..self.name.."' has been stopped!")
	end
	c.status=multi:newUpdater(multi.Priority_IDLE)
	c.status.link=c
	c.status:OnUpdate(function(self)
		local v,err,t=self.link.thread:join(.001)
		if err then
			print("Error in thread: '"..self.link.name.."' <"..err..">",t)
			self:Destroy()
		end
	end)
    return c
end
_G["GLOBAL"]=GLOBAL
_G["__GlobalLinda"]=__GlobalLinda
