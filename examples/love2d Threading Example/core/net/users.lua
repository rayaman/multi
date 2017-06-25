require("net.identity") --[[ This module extends the functions of the identity module
It aims to make the handling of users who are not online more seamless.
Without this handling offline users is a pain.
]]
net:registerModule("users",{1,0,0})
net.users.online={} -- all online users and offline users
net.users.offline={} -- all online users and offline users
net.OnServerCreated:connect(function(s)
	s.OnUserLoggedIn(function(user,cid,ip,port,dTable)
		--
	end)
	s.OnDataRecieved(function(self,data,CID_OR_HANDLE,IP_OR_HANDLE,PORT_OR_IP)
		if self:userLoggedIn(cid) then -- If the user is logged in we do the tests
			--
		else
			return
		end
	end,"users")
end)
net.OnClientCreated:connect(function(c)
	c.OnUserList=multi:newConnection()
	c.OnDataRecieved(function(self,data)
		--
	end,"users")
	function c:searchUsers(nickname) -- sends a query to the server, returns list of userids and nicks close to the query
		--
	end
	function c:addFriend(USERID)
		--
	end
	function c:removeFriend(USERID)
		--
	end
	function c:getFriends(USERID)
		--
	end
end)
