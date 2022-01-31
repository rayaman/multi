function connectionThreadTests(multi,thread)
	print("Starting Connection and Thread tests!")
	func = thread:newFunction(function(count)
		print("Starting Status test: ",count)
		local a = 0
		while true do
			a = a + 1
			thread.sleep(.1)
			thread.pushStatus(a,count)
			if a == count then break end
		end
		return "Done"
	end)
    local ret = func(10)
    local ret2 = func(15)
    local ret3 = func(20)
	local s1,s2,s3 = 0,0,0
	ret.OnError(function(...)
		print("Error:",...)
	end)
    ret.OnStatus(function(part,whole)
		s1 = math.ceil((part/whole)*1000)/10
		print(s1)
    end)
    ret2.OnStatus(function(part,whole)
        s2 = math.ceil((part/whole)*1000)/10
    end)
    ret3.OnStatus(function(part,whole)
        s3 = math.ceil((part/whole)*1000)/10
    end)
	ret.OnReturn(function()
		print("Done")
	end)
	local err, timeout = thread.hold(ret.OnReturn + ret2.OnReturn + ret3.OnReturn)
	if s1 == 100 and s2 == 100 and s3 == 100 then
		print("Threads: Ok")
	else
		print("Threads OnStatus or thread.hold(conn) Error!")
	end
	if timeout then
		print("Threads or Connection Error!")
	else
		print("Connection Test 1: Ok")
	end
	conn1 = multi:newConnection()
	conn2 = multi:newConnection()
	conn3 = multi:newConnection()
	local c1,c2,c3,c4 = false,false,false,false
	local a = conn1(function()
		c1 = true
	end)
	local b = conn2(function()
		c2 = true
	end)
	local c = conn3(function()
		c3 = true
	end)
	local d = conn3(function()
		c4 = true
	end)
	conn1:Fire()
	conn2:Fire()
	conn3:Fire()
	if c1 and c2 and c3 and c4 then
		print("Connection Test 2: Ok")
	else
		print("Connection Test 2: Error")
	end
	c3 = false
	c4 = false
	d:Destroy()
	conn3:Fire()
	if c3 and not(c4) then
		print("Connection Test 3: Ok")
	else
		print("Connection Test 3: Error removing connection")
	end
end
return connectionThreadTests