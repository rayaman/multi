Thread={}
Thread.ChannelT1 = love.thread.getChannel("Easy1")
Thread.ChannelT2 = love.thread.getChannel("Easy2")
Thread.ChannelT3 = love.thread.getChannel("Easy3")
Thread.ChannelT4 = love.thread.getChannel("Easy4")
Thread.ChannelMain = love.thread.getChannel("EasyMain")
Thread.Name = "Thread Main"
Thread.n=0
Thread.count=1
function Thread:packTable(G)
	function escapeStr(str)
		local temp=""
		for i=1,#str do
			temp=temp.."\\"..string.byte(string.sub(str,i,i))
		end
		return temp
	end
	function ToStr(t)
		local dat="{"
		for i,v in pairs(t) do
			if type(i)=="number" then
				i="["..i.."]="
			else
				i=i.."="
			end
			if type(v)=="string" then
				dat=dat..i.."\""..v.."\","
			elseif type(v)=="number" then
				dat=dat..i..v..","
			elseif type(v)=="boolean" then
				dat=dat..i..tostring(v)..","
			elseif type(v)=="table" and not(G==v) then
				dat=dat..i..bin.ToStr(v)..","
			--elseif type(v)=="table" and G==v then
			--	dat=dat..i.."assert(loadstring(\"return self\")),"
			elseif type(v)=="function" then
				dat=dat..i.."assert(loadstring(\""..escapeStr(string.dump(v)).."\")),"
			end
		end
		return string.sub(dat,1,-2).."}"
	end
	return ToStr(G)
end
Thread.last={}
function Thread:GetStatus()
	print(self.n.." Threads Exist!!!")
	for i=1,self.n do
		print("\tThread "..i.." Running: "..tostring(self["Thread"..i]:isRunning()))
		if not(self["Thread"..i]:isRunning()) then
			print("\t\t"..self["Thread"..i]:getError())
		end
	end
end
function Thread:Start(n)
	local x=love.system.getProcessorCount()
	if x>1 then
		x=x-1
	else
		x=1
	end
	n=n or x
	if n<1 then
		print("Must be atleast 1 thread running!!!")
		return
	end
	if n>4 then
		print("Must be no more than 4 threads running!!!")
		return
	end
	for i=1,n do
		self["Thread"..i]=love.thread.newThread("Libs/T"..i..".lua")
		self["Thread"..i]:start()
	end
	Thread.n=n
end
function Thread:RestartBroken()
	for i=1,self.n do
		if self["Thread"..i]:isRunning()==false then
			self["Thread"..i]:start()
		end
		Thread:Boost(Thread.last[1],Thread.last[2])
	end
end
function Thread:Send(name,var,arg3)
	if self.n>0 then
		if type(var)=="table" then
			var=Thread:packTable(var)
			arg3=name
			name="table"
		end
		self["ChannelT"..((self.count-1)%self.n)+1]:push({name,var,arg3})
		self.count=self.count+1
	end
end
function Thread:SendAll(name,var,arg3)
	if self.n>0 then
		for i=1,self.n do
			if type(var)=="table" then
				var=Thread:packTable(var)
				arg3=name
				name="table"
			end
			self["ChannelT"..i]:push({name,var,arg3})
		end
	end
end
function Thread:UnPackChannel()
	local c=self.ChannelMain:getCount()
	for i=1,c do
		local temp=self.ChannelMain:pop()
		if temp[3]=="table" then
			_G[temp[1]]=assert(loadstring(temp[2]))()
		else
			if Thread.OnDataRecieved then
				Thread.OnDataRecieved(temp[1],temp[2],temp[3])
			end
			_G[temp[1]]=temp[2]
		end
	end
end
function Thread:Boost(func,name)
	if Thread.last[1]==nil then
		return
	end
	Thread.last={func,name}
	name=name or "nil"
	if self.n>0 then
		self:Send("func",string.dump(func),name)
	end
end
function Thread:SendLibs(func,name)
	name=name or "nil"
	if self.n>0 then
		self:SendAll("func",string.dump(func),name)
	end
end
function Thread.mainloop()
	if Thread.n>0 then
		Thread:UnPackChannel()
	end
end
Thread.MainThread=true
local loop = multi:newLoop()
loop:OnLoop(Thread.mainloop)
OnThreadError=multi:newConnection()
function love.threaderror(thread, errorstr)
	Thread:GetStatus()
	Thread:RestartBroken()
	Thread:GetStatus()
	OnThreadError:Fire(thread,errorstr)
end
multi:newTask(function()
	math.randomseed(math.floor(os.time()/2))
	for i=1,Thread.n do
		Thread["ChannelT"..i]:push({"randseed",math.random(-1000000,1000000)})
		Thread["ChannelT"..i]:push({"func",string.dump(function() math.randomseed(randseed) end),"randomizing"})
	end
end)
