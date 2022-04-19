package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.threading"):init()

-- Using a system thread, but both system and local threads support this!
-- Don't worry if you don't have lanes or love2d. PesudoThreading will kick in to emulate the threading features if you do not have access to system threading.
func = THREAD:newFunction(function(count)
	print("Starting Status test: ",count)
	local a = 0
	while true do
		a = a + 1
		THREAD.sleep(.1)
		-- Push the status from the currently running threaded function to the main thread
		THREAD.pushStatus(a,count)
		if a == count then break end
	end
	return "Done"
end)

thread:newThread("test",function()
	local ret = func(10)
	ret.OnStatus(function(part,whole)
		print("Ret1: ",math.ceil((part/whole)*1000)/10 .."%")
	end)
	print("TEST",func(5).wait())
	-- The results from the OnReturn connection is passed by thread.hold
	print("Status:",thread.hold(ret.OnReturn))
	print("Function Done!")
end).OnError(function(...)
	print("Error:",...)
end)

local ret = func(10)
local ret2 = func(15)
local ret3 = func(20)
local s1,s2,s3 = 0,0,0
ret.OnError(function(...)
	print("Error:",...)
end)
ret2.OnError(function(...)
	print("Error:",...)
end)
ret3.OnError(function(...)
	print("Error:",...)
end)
ret.OnStatus(function(part,whole)
	s1 = math.ceil((part/whole)*1000)/10
	print(s1)
end)
ret2.OnStatus(function(part,whole)
	s2 = math.ceil((part/whole)*1000)/10
	print(s2)
end)
ret3.OnStatus(function(part,whole)
	s3 = math.ceil((part/whole)*1000)/10
	print(s3)
end)

loop = multi:newTLoop()

function loop:testing()
	print("testing haha")
end

loop:Set(1)
t = loop:OnLoop(function()
	print("Looping...")
end):testing()

local proc = multi:newProcessor("Test")
local proc2 = multi:newProcessor("Test2")
local proc3 = proc2:newProcessor("Test3")
proc.Start()
proc2.Start()
proc3.Start()
proc:newThread("TestThread_1",function()
	while true do
		thread.sleep(1)
	end
end)
proc:newThread("TestThread_2",function()
	while true do
		thread.sleep(1)
	end
end)
proc2:newThread("TestThread_3",function()
	while true do
		thread.sleep(1)
	end
end)

thread:newThread(function()
	thread.sleep(1)
	local tasks = multi:getStats()

	for i,v in pairs(tasks) do
		print("Process: " ..i.. "\n\tTasks:")
		for ii,vv in pairs(v.tasks) do
			print("\t\t"..vv:getName())
		end
		print("\tThreads:")
		for ii,vv in pairs(v.threads) do
			print("\t\t"..vv:getName())
		end
	end

	thread.sleep(10) -- Wait 10 seconds then kill the process!
	os.exit()
end)

multi:mainloop()