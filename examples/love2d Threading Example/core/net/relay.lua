require("net")
net:registerModule("relay",{1,0,0})
net.OnServerCreated:connect(function(s)
	s.OnDataRecieved(function(self,data,CID_OR_HANDLE,IP_OR_HANDLE,PORT_OR_IP)
		local IP=""
		if self.Type=="tcp" then
			error("Relays only work when using UDP or AUDP! They will not function with TCP! Support may one day be added for TCP!")
		else
			IP=IP_OR_HANDLE
		end
		local cmd,dat=data:match("!relay! (%S-) (.+)")
		if cmd == "RELAY" then
			--
		elseif cmd == "LOAD" then
			local cpuload=multi:getLoad()
			self:send(IP_OR_HANDLE,"!relay! LOAD "..cpuload,PORT_OR_IP)
		end
	end,"relay")
end)
net.OnClientCreated:connect(function(c)
	c.OnDataRecieved(function(self,data)
		--
	end,"relay")
end)
