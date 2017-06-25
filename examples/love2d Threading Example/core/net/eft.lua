require("net")
net:registerModule("eft",{1,0,0})
--[[
	This module provides a dedicated socket for file transfer
	This allows us to do some more complex stuff with it
	The only data that is non file stuff is the initial handshake
	CMDs are done on the general socket while transfers are done on the file socket
]]
net.OnServerCreated:connect(function(s)
	print("The eft(Expert File Transfer) Module has been loaded onto the server!")
	if s.Type~="tcp" then
		print("It is recomended that you use tcp to transfer files!")
	end
	s.OnDataRecieved(function(self,data,CID_OR_HANDLE,IP_OR_HANDLE,PORT_OR_IP)
		--
	end,"eft")
	--
end)
net.OnClientCreated:connect(function(c)
	c.OnDataRecieved(function(self,data)
		--
	end,"eft")
	--
end)
