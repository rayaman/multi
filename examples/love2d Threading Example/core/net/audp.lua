function net:newAUDPServer(port,servercode)
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
		print("Not needed in a audp server!")
	end
	function c:banCID(cid)
		table.insert(self.bannedCIDs,cid)
	end
	function c:banIP(ip)
		table.insert(self.bannedIPs,cid)
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

function net:newAUDPClient(host,port,servercode,nonluaServer)
	local c={}
	c.ip=assert(socket.dns.toip(host))
	c.udp=assert(socket.udp())
	c.udp:settimeout(0)
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
