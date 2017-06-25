require("net")
--General Stuff
--[[ What this module does!
Adds
net.settings:init()
server:regSetting(namespace,setting)
]]
net:registerModule("settings",{1,0,0})
net.settings.config={}
function net.settings:init() -- calling this initilizes the library and binds it to the servers and clients created
	--Server Stuff
	net.OnServerCreated:connect(function(s)
		print("The Settings Module has been loaded onto the server!")
		s.OnDataRecieved(function(self,data,cid,ip,port) -- when the server recieves data this method is triggered
			local namespace,args=data:match("!settings! (%s+) (.+)")
			local args
			if namespace then
				for i,v in pairs(net.settings.config) do
					args={data:match(v[1])}
					if #args~=0 then
						v[2]:Fire(self,data,cid,ip,port,unpack(args))
						break
					end
				end
			end
		end,"settings")
		function s:regSetting(namespace,settings)
			if not net.settings.config[namespace] then
				net.settings.config[namespace]={}
			end
			local connection=multi:newConnection()
			table.insert(net.settings.config[namespace],{"!settings! "..namespace.." "..settings,connection})
			return connection
		end
	end)
	--Client Stuff
	net.OnClientCreated:connect(function(c)
		c.OnDataRecieved:(function(self,data) -- when the client recieves data this method is triggered
			--First Lets make sure we are getting Setting data
		end,"setings")
		function sendSetting(namespace,args)
			self:send("!settings! "..namespace.." "..args)
		end
	end)
end
if net.autoInit then
	net.settings:init()
end
