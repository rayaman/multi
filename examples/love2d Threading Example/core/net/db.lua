require("parseManager")
require("net.identity") -- serversie module
net:registerModule("db",{1,0,0})
net.OnServerCreated:connect(function(s)
	s.OnUserLoggedIn(function(user,cid,ip,port,dTable) -- dealing with userdata
		--
	end)
	function s:createTable(PKey,fmt,path)
		--
	end
end)
--keys are case insensitive, hex and regular base 10 numbers are allowed as well as other structures
--We define a table below with keys and their max size


