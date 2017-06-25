--[[
	UPCOMMING ADDITIONS
	AUDP - advance udp/ Ensures packets arrive and handles late packets.
	P2P - peer to peer (Server to set up initial connection)
	Relay - offput server load (locally)
	Threading - Simple threading (UDP/AUDP Only)
	Priority handling
]]
--[[
	TODO: Finish stuff for Priority handling
]]
function table.merge(t1, t2)
    for k,v in pairs(t2) do
    	if type(v) == 'table' then
    		if type(t1[k] or false) == 'table' then
    			table.merge(t1[k] or {}, t2[k] or {})
    		else
    			t1[k] = v
    		end
    	else
    		t1[k] = v
    	end
    end
    return t1
end
function string.trim(s)
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end
socket=require("socket")
http=require("socket.http")
mime=require("mime")
net={}
net.Version={2,0,0} -- This will probably stay this version for quite a while... The modules on the otherhand will be more inconsistant
net._VERSION="2.0.0"
net.OnServerCreated=multi:newConnection()
net.OnClientCreated=multi:newConnection()
net.loadedModules={}
net.autoInit=true
function net.normalize(input)
	local enc=mime.b64(input)
	return enc
end
function net.denormalize(input)
	local unenc=mime.unb64(input)
	return unenc
end
function net.getLocalIP()
	local someRandomIP = "192.168.1.122"
	local someRandomPort = "3102"
	local mySocket = socket.udp()
	mySocket:setpeername(someRandomIP,someRandomPort)
	local dat = (mySocket:getsockname())
	mySocket:close()
	return dat
end
function net.getExternalIP()
	local data=http.request("http://whatismyip.org/")
	return data:match("600;\">(%d-.%d-.%d-.%d-)</span>")
end
function net:registerModule(mod,version)
	if net[mod] then
		error("Module by the name: "..mod.." has already been registered! Remember some modules are internal and use certain names!")
	end
	table.insert(self.loadedModules,mod)
	net[mod]={}
	if version then
		net[mod].Version=version
		net[mod]._VERSION=version[1].."."..version[2].."."..version[3]
	else
		net[mod].Version={1,0,0}
		net[mod]._VERSION={1,0,0}
	end
	return {Version=version,_VERSION=version[1].."."..version[2].."."..version[3]}
end
function net.getModuleVersion(ext)
	if not ext then
		return string.format("%d.%d.%d",net.Version[1],net.Version[2],net.Version[3])
	end
	return string.format("%d.%d.%d",net[ext].Version[1],net[ext].Version[2],net[ext].Version[3])
end
function net.resolveID(obj)
	local num=math.random(10000000,99999999)
	if obj[tostring(num)] then
		return net.resolveID(obj)
	end
	obj.ids[tostring(num)]=true
	return tostring(num)
end
function net.inList(list,dat)
	for i,v in pairs(list) do
		if v==dat then
			return true
		end
	end
	return false
end
function net.setTrigger(funcW,funcE)
	multi:newTrigger(func)
end
net:registerModule("net",net.Version)
-- Client broadcast
function net:newCastedClient(name) -- connects to the broadcasted server
	local listen = socket.udp() -- make a new socket
	listen:setsockname(net.getLocalIP(), 11111)
	listen:settimeout(0)
	local timer=multi:newTimer()
	while true do
		local data, ip, port = listen:receivefrom()
		if timer:Get()>3 then
			error("Timeout! Server by the name: "..name.." has not been found!")
		end
		if data then
			local n,tp,ip,port=data:match("(%S-)|(%S-)|(%S-):(%d+)")
			if n:match(name) then
				print("Found Server!",n,tp,ip,port)
				if tp=="tcp" then
					return net:newTCPClient(ip,tonumber(port))
				else
					return net:newClient(ip,tonumber(port))
				end
			end
		end
	end
end
-- UDP Stuff
function net:newServer(port,servercode)
	local c={}
	c.udp=assert(socket.udp())
	c.udp:settimeout(0)
	c.udp:setsockname("*", port)
	c.ips={}
	c.Type="udp"
	c.port=port
	c.ids={}
	c.servercode=servercode
	c.bannedIPs={}
	c.bannedCIDs={}
	c.autoNormalization=false
	function c:setUpdateRate(n)
		print("Not needed in a udp server!")
	end
	function c:banCID(cid)
		table.insert(self.bannedCIDs,cid)
	end
	function c:banIP(ip)
		table.insert(self.bannedIPs,cid)
	end
	c.broad=socket.udp()
	c.hostip=net.getLocalIP()
	function c:broadcast(name)
		local loop=multi:newTLoop(function(dt,loop)
			self.broad:setoption('broadcast',true)
			self.broad:sendto(name.."|"..self.Type.."|"..self.hostip..":"..self.port, "255.255.255.255", 11111)
			self.broad:setoption('broadcast',false)
		end,1)
	end
	function c:send(ip,data,port,cid)
		if self.autoNormalization then
			data=net.normalize(data)
		end
		if self.servercode then
			cid=cid or self:CIDFrom(ip,port)
			if not self.ips[cid] then
				print("Can't determine cid from client... sending the client a new one!")
				local cid=net.resolveID(self)
				print("Sending unique cid to client: "..cid)
				self.ips[cid]={ip,port,0,self.servercode==nil}
				print(ip)
				self.udp:sendto("I!"..cid,ip,port)
				if self.servercode then
					self.udp:sendto("S!",ip,port)
				end
				return
			end
			if net.inList(self.bannedIPs,ip) or net.inList(self.bannedCIDs,cid) then
				self.udp:sendto("BANNED CLIENT", ip, port or self.port)
			elseif self.ips[cid][4] then
				self.udp:sendto(data, ip, port or self.port)
			elseif self.ips[cid][4]==false then
				self.udp:sendto("Make sure your server code is correct!", ip, port)
			end
		else
			self.udp:sendto(data, ip, port or self.port)
		end
	end
	function c:pollClientModules(ip,port)
		self:send(ip,"L!",port)
	end
	function c:CIDFrom(ip,port)
		for i,v in pairs(self.ips) do
			if(ip==v[1] and v[2]==port) then
				return i
			end
		end
	end
	function c:sendAll(data)
		for i,v in pairs(self.ips) do
			self:send(v[1],data,v[2],i)
		end
	end
	function c:sendAllBut(data,cid)
		for i,v in pairs(self.ips) do
			if i~=cid then
				self:send(v[1],data,v[2],i)
			end
		end
	end
	function c:clientRegistered(cid)
		return self.ips[cid]
	end
	function c:clientLoggedIn(cid)
		if not self.clientRegistered(cid) then
			return nil
		end
		return self.ips[cid][4]
	end
	function c:update()
		local data,ip,port=self.udp:receivefrom()
		if net.inList(self.bannedIPs,ip) or net.inList(self.bannedCIDs,cid) then
			print("We will ingore data from a banned client!")
			return
		end
		if data then
			if self.autoNormalization then
				data=net.denormalize(data)
			end
			if data:sub(1,4)=="pong" then
				--print("Recieved pong from: "..data:sub(5,-1))
				self.ips[data:sub(5,-1)][3]=os.clock()
			elseif data:sub(1,2)=="S!" then
				local cid=self:CIDFrom(ip,port)
				if data:sub(3,-1)==self.servercode then
					print("Servercode Accepted: "..self.servercode)
					if self.ips[cid] then
						self.ips[cid][4]=true
					else
						print("Server can't keep up! CID: "..cid.." has been skipped! Sending new CID to the client!")
						local cid=net.resolveID(self)
						print("Sending unique cid to client: "..cid)
						self.ips[cid]={ip,port,0,self.servercode==nil}
						print(ip)
						self.udp:sendto("I!"..cid,ip,port)
						if self.servercode then
							self.udp:sendto("S!",ip,port)
						end
					end
				else
					self.udp:sendto("Make sure your server code is correct!", ip, port)
				end
			elseif data:sub(1,2)=="C!" then
				local hook=(data:sub(11,-1)):match("!(.-)!")
				self.OnDataRecieved:getConnection(hook):Fire(self,data:sub(11,-1),data:sub(3,10),ip,port)
			elseif data:sub(1,2)=="E!" then
				self.ips[data:sub(3,10)]=nil
				obj.ids[data:sub(3,10)]=false
				self.OnClientClosed:Fire(self,"Client Closed Connection!",data:sub(3,10),ip,port)
			elseif data=="I!" then
				local cid=net.resolveID(self)
				print("Sending unique cid to client: "..cid)
				self.ips[cid]={ip,port,os.clock(),self.servercode==nil}
				print(ip)
				self.udp:sendto("I!"..cid,ip,port)
				if self.servercode then
					self.udp:sendto("S!",ip,port)
				end
				self.OnClientConnected:Fire(self,cid,ip,port)
			elseif data:sub(1,2)=="L!" then
				cid,cList=data:sub(3,10),data:sub(11,-1)
				local list={}
				for m,v in cList:gmatch("(%S-):(%S-)|") do
					list[m]=v
				end
				self.OnClientsModulesList:Fire(list,cid,ip,port)
			end
		end
		for cid,dat in pairs(self.ips) do
			if not((os.clock()-dat[3])<65) then
				self.ips[cid]=nil
				self.OnClientClosed:Fire(self,"Client lost Connection: ping timeout",cid,ip,port)
			end
		end
	end
	c.OnClientsModulesList=multi:newConnection()
	c.OnDataRecieved=multi:newConnection()
	c.OnClientClosed=multi:newConnection()
	c.OnClientConnected=multi:newConnection()
	c.connectiontest=multi:newAlarm(30)
	c.connectiontest.link=c
	c.connectiontest:OnRing(function(alarm)
		--print("pinging clients!")
		alarm.link:sendAll("ping")
		alarm:Reset()
	end)
	multi:newLoop(function()
		c:update()
	end)
	net.OnServerCreated:Fire(c)
	return c
end

function net:newClient(host,port,servercode,nonluaServer)
	local c={}
	c.ip=assert(socket.dns.toip(host))
	c.udp=assert(socket.udp())
	c.udp:settimeout(0)
	c.udp:setpeername(c.ip, port)
	c.cid="NIL"
	c.lastPing=0
	c.Type="udp"
	c.servercode=servercode
	c.autoReconnect=true
	c.autoNormalization=false
	function c:pollPing(n)
		return not((os.clock()-self.lastPing)<(n or 60))
	end
	function c:send(data)
		if self.autoNormalization then
			data=net.normalize(data)
		end
		self.udp:send("C!"..self.cid..data)
	end
	function c:sendRaw(data)
		if self.autoNormalization then
			data=net.normalize(data)
		end
		self.udp:send(data)
	end
	function c:getCID()
		if self:IDAssigned() then
			return self.cid
		end
	end
	function c:close()
		self:send("E!")
	end
	function c:IDAssigned()
		return self.cid~="NIL"
	end
	function c:update()
		local data=self.udp:receive()
		if data then
			if self.autoNormalization then
				data=net.denormalize(data)
			end
			if data:sub(1,2)=="I!" then
				self.cid=data:sub(3,-1)
				self.OnClientReady:Fire(self)
			elseif data=="S!" then
				self.udp:send("S!"..(self.servercode or ""))
			elseif data=="L!" then
				local mods=""
				local m=""
				for i=1,#net.loadedModules do
					m=net.loadedModules[i]
					mods=mods..m..":"..net.getModuleVersion(m).."|"
				end
				self.udp:send("L!"..self.cid..mods)
			elseif data=="ping" then
				self.lastPing=os.clock()
				self.OnPingRecieved:Fire(self)
				self.udp:send("pong"..self.cid)
			else
				local hook=data:match("!(.-)!")
				self.OnDataRecieved:getConnection(hook):Fire(self,data)
			end
		end
	end
	function c:reconnect()
		if not nonluaServer then
			self.cid="NIL"
			c.udp:send("I!")
		end
		self.OnConnectionRegained:Fire(self)
	end
	c.pingEvent=multi:newEvent(function(self) return self.link:pollPing() end)
	c.pingEvent:OnEvent(function(self)
		if self.link.autoReconnect then
			self.link.OnServerNotAvailable:Fire("Connection to server lost: ping timeout! Attempting to reconnect...")
			self.link.OnClientDisconnected:Fire(self,"closed")
			self.link:reconnect()
		else
			self.link.OnServerNotAvailable:Fire("Connection to server lost: ping timeout!")
			self.link.OnClientDisconnected:Fire(self,"closed")
		end
	end)
	c.pingEvent.link=c
	c.OnPingRecieved=multi:newConnection()
	c.OnDataRecieved=multi:newConnection()
	c.OnServerNotAvailable=multi:newConnection()
	c.OnClientReady=multi:newConnection()
	c.OnClientDisconnected=multi:newConnection()
	c.OnConnectionRegained=multi:newConnection()
	c.notConnected=multi:newFunction(function(self)
		self:hold(3)
		if self.link:IDAssigned()==false then
			self.link.OnServerNotAvailable:Fire("Can't connect to the server: no response from server")
		end
	end)
	c.notConnected.link=c
	if not nonluaServer then
		c.udp:send("I!")
	end
	multi:newLoop(function()
		c:update()
	end)
	multi:newJob(function() c.notConnected() end)
	net.OnClientCreated:Fire(c)
	return c
end
--TCP Stuff
function net:newTCPServer(port)
	local c={}
	c.tcp=assert(socket.bind("*", port))
	c.tcp:settimeout(0)
	c.ip,c.port=c.tcp:getsockname()
	c.ips={}
	c.port=port
	c.ids={}
	c.bannedIPs={}
	c.Type="tcp"
	c.rMode="*l"
	c.sMode="*l"
	c.updaterRate=1
	c.autoNormalization=false
	c.updates={}
	c.links={}
	c.broad=socket.udp()
	c.hostip=net.getLocalIP()
	function c:broadcast(name)
		local loop=multi:newTLoop(function(dt,loop)
			self.broad:setoption('broadcast',true)
			self.broad:sendto(name.."|"..self.Type.."|"..self.hostip..":"..self.port, "255.255.255.255", 11111)
			self.broad:setoption('broadcast',false)
		end,1)
	end
	function c:setUpdateRate(n)
		self.updaterRate=n
	end
	function c:setReceiveMode(mode)
		self.rMode=mode
	end
	function c:setSendMode(mode)
		self.rMode=mode
	end
	function c:banCID(cid)
		print("Function not supported on a tcp server!")
	end
	function c:banIP(ip)
		table.insert(self.bannedIPs,cid)
	end
	function c:send(handle,data)
		if self.autoNormalization then
			data=net.normalize(data)
		end
		if self.sMode=="*l" then
			handle:send(data.."\n")
		else
			handle:send(data)
		end
	end
	function c:sendAllData(handle,data)
		if self.autoNormalization then
			data=net.normalize(data)
		end
		handle:send(data)
	end
	function c:pollClientModules(ip,port)
		self:send(ip,"L!",port)
	end
	function c:CIDFrom(ip,port)
		print("Method not supported when using a TCP Server!")
		return "CIDs in TCP work differently!"
	end
	function c:sendAll(data)
		for i,v in pairs(self.ips) do
			self:send(v,data)
		end
	end
	function c:sendAllBut(data,cid)
		for i,v in pairs(self.ips) do
			if not(cid==i) then
				self:send(v,data)
			end
		end
	end
	function c:clientRegistered(cid)
		return self.ips[cid]
	end
	function c:clientLoggedIn(cid)
		return self.ips[cid]
	end
	function c:getUpdater(cid)
		return self.updates[cid]
	end
	function c:update()
		local client = self.tcp:accept(self.rMode)
		if not client then return end
		table.insert(self.ips,client)
		client:settimeout(0)
		--client:setoption('tcp-nodelay', true)
		client:setoption('keepalive', true)
		ip,port=client:getpeername()
		if ip and port then
			print("Got connection from: ",ip,port)
			local updater=multi:newUpdater(skip)
			self.updates[client]=updater
			self.OnClientConnected:Fire(self,self.client,self.client,ip)
			updater:OnUpdate(function(self)
				local data, err = self.client:receive(self.rMode or self.Link.rMode)
				if err=="closed" then
					for i=1,#self.Link.ips do
						if self.Link.ips[i]==self.client then
							table.remove(self.Link.ips,i)
						end
					end
					self.Link.OnClientClosed:Fire(self.Link,"Client Closed Connection!",self.client,self.client,ip)
					self.Link.links[self.client]=nil -- lets clean up
					self:Destroy()
				end
				if data then
					if self.autoNormalization then
						data=net.denormalize(data)
					end
					if net.inList(self.Link.bannedIPs,ip) then
						print("We will ingore data from a banned client!")
						return
					end
					local hook=data:match("!(.-)!")
					self.Link.OnDataRecieved:getConnection(hook):Fire(self.Link,data,self.client,self.client,ip,self)
					if data:sub(1,2)=="L!" then
						cList=data
						local list={}
						for m,v in cList:gmatch("(%S-):(%S-)|") do
							list[m]=v
						end
						self.Link.OnClientsModulesList:Fire(list,self.client,self.client,ip)
					end
				end
			end)
			updater:setSkip(self.updaterRate)
			updater.client=client
			updater.Link=self
			function updater:setReceiveMode(mode)
				self.rMode=mode
			end
			self.links[client]=updater
		end
	end
	c.OnClientsModulesList=multi:newConnection()
	c.OnDataRecieved=multi:newConnection()
	c.OnClientClosed=multi:newConnection()
	c.OnClientConnected=multi:newConnection()
	multi:newLoop(function()
		c:update()
	end)
	net.OnServerCreated:Fire(c)
	return c
end
function net:newTCPClient(host,port)
	local c={}
	c.ip=assert(socket.dns.toip(host))
	c.port=port
	c.tcp=socket.connect(c.ip,port)
	if not c.tcp then
		print("Can't connect to the server: no response from server")
		return false
	end
	c.tcp:settimeout(0)
	--c.tcp:setoption('tcp-nodelay', true)
	c.tcp:setoption('keepalive', true)
	c.Type="tcp"
	c.autoReconnect=true
	c.rMode="*l"
	c.sMode="*l"
	c.autoNormalization=false
	function c:setReceiveMode(mode)
		self.rMode=mode
	end
	function c:setSendMode(mode)
		self.sMode=mode
	end
	function c:send(data)
		if self.autoNormalization then
			data=net.normalize(data)
		end
		if self.sMode=="*l" then
			ind,err=self.tcp:send(data.."\n")
		else
			ind,err=self.tcp:send(data)
		end
		if err=="closed" then
			self.OnClientDisconnected:Fire(self,err)
		elseif err=="timeout" then
			self.OnClientDisconnected:Fire(self,err)
		elseif err then
			print(err)
		end
	end
	function c:sendRaw(data)
		if self.autoNormalization then
			data=net.normalize(data)
		end
		self.tcp:send(data)
	end
	function c:getCID()
		return "No Cid on a tcp client!"
	end
	function c:close()
		self.tcp:close()
	end
	function c:IDAssigned()
		return true
	end
	function c:update()
		if not self.tcp then return end
		local data,err=self.tcp:receive()
		if err=="closed" then
			self.OnClientDisconnected:Fire(self,err)
		elseif err=="timeout" then
			self.OnClientDisconnected:Fire(self,err)
		elseif err then
			print(err)
		end
		if data then
			if self.autoNormalization then
				data=net.denormalize(data)
			end
			local hook=data:match("!(.-)!")
			self.OnDataRecieved:getConnection(hook):Fire(self,data)
		end
	end
	function c:reconnect()
		multi:newFunction(function(func)
			self.tcp=socket.connect(self.ip,self.port)
			if self.tcp==nil then
				print("Can't connect to the server: No response from server!")
				func:hold(3)
				self:reconnect()
				return
			end
			self.OnConnectionRegained:Fire(self)
			self.tcp:settimeout(0)
			--self.tcp:setoption('tcp-nodelay', true)
			self.tcp:setoption('keepalive', true)
		end)
	end
	c.event=multi:newEvent(function(event)
		return event.link:IDAssigned()
	end)
	c.event:OnEvent(function(event)
		event.link.OnClientReady:Fire(event.link)
	end)
	c.event.link=c
	c.OnClientReady=multi:newConnection()
	c.OnClientDisconnected=multi:newConnection()
	c.OnDataRecieved=multi:newConnection()
	c.OnConnectionRegained=multi:newConnection()
	multi:newLoop(function()
		c:update()
	end)
	net.OnClientCreated:Fire(c)
	return c
end
