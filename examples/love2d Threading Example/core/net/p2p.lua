net:registerModule("p2p",{1,0,0})
net.p2p.peerdata={}
--[[
PID(peerID)=<CID|IP|PORT>

]]
function net.newP2PClient(host,port)
	--
end
function net.aft:init() -- calling this initilizes the library and binds it to the servers and clients created
	--Server Stuff
	net.OnServerCreated:connect(function(s)
		print("The aft(Advance File Transfer) Module has been loaded onto the server!")
		if s.Type~="udp" then
			print("As of right now p2p is only avaliable using udp!")
			return "ERR_NOT_UDP"
		end
		s.OnDataRecieved(function(self,data,cid,ip,port) -- when the server recieves data this method is triggered
			--
		end,"p2p") -- some new stuff
	end)
	--Client Stuff
	net.OnClientCreated:connect(function(c)
		c.OnDataRecieved(function(self,data) -- when the client recieves data this method is triggered
			--
		end,"p2p")
	end)
end
if net.autoInit then
	net.aft.init()
end
