require("parseManager")
require("net.identity")
require("net.aft")
net:registerModule("admin",{1,0,0})
-- Localhost does not need to log in to connect to the server and do whatever... This inculdes modules that you are writing for the server
-- LAN connections can request data from the server without logging in, but must log in to alter server settings
-- WAN connections can only request or alter settings if they are logged in

--[[
User levels: 	1 - SERVEROWNER/localhost (Autodetect)
				2 - ADMIN
				3 - Modded User
				4 - Privileged User
				5 - Regular User
				6 - Restricted User
				7 - USER DEFINED
				8 - USER DEFINED
				9 - USER DEFINED
				10 - Banned User
]]
if not io.dirExists("-ADMINS-") then
	io.mkdir("-ADMINS-")
end
if not io.fileExists("-ADMINS-/LEVELS-List.dat") then
	io.mkfile("-ADMINS-/LEVELS-List.dat")
end
net.statuslist={}
net.OnServerCreated:connect(function(s)
	s.OnDataRecieved(function(self,data,CID_OR_HANDLE,IP_OR_HANDLE,PORT_OR_IP)
		local IP=tonumber(IP_OR_HANDLE) or tonumber(PORT_OR_IP)
	end,"admin")
	function s:setUserLevel(user,n)
		--
	end
	function s:makeAdmin(user)
		--
	end
	function s:makeMod(user)
		--
	end
	function s:makePrivileged(user)
		--
	end
	function s:restrict(user)
		--
	end
	function s:ban(user)
		--
	end
	function s:getUserLevel(user)
		--
	end
end)
net.OnClientCreated:connect(function(c)
	c.OnDataRecieved(function(self,data)
		--
	end,"admin")
end)
