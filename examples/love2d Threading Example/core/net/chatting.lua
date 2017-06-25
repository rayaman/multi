require("net")
require("net.identity")
--General Stuff
--[[ What this module does!
Adds
net.chatting:init()
server:OnChatRecieved(function({user,msg}) end)
client:OnChatRecieved(function(user,msg) end)
client:sendChat(user,msg)
]]
net:registerModule("chatting",{3,0,0})
net.chatting.users={}
function net.chatting:getUserIdFromIP(ip)
	return net.chatting.users[ip]
end
function net.chatting:init() -- calling this initilizes the library and binds it to the servers and clients created
	--Server Stuff
	net.OnServerCreated:connect(function(s)
		print("The Chatting Module has been loaded onto the server!")
		s.OnUserLoggedIn(function(user,cid,ip,port,dTable)
			dTable=loadstring("return "..dTable)()
			local USERID=bin.new(user):getHash(32)
			net.chatting.users[USERID]={dTable.nick,cid,ip,port,dTable} -- add users that log in to the userlist
			net.chatting.users[ip]=USERID -- add users that log in to the userlist
			local users={}
			for i,v in pairs(net.chatting.users) do
				if type(i)~="userdata" then
					table.insert(users,i.."|"..net.chatting.users[i][1])
				end
			end
			table.insert(users,"")
			for i,v in pairs(s.ips) do
				s:send(v,"!chatting! $Users|NIL|NIL '"..table.concat(users,",").."'")
			end
		end)
		s.OnUserLoggerOut(function(self,user)
			local USERID=bin.new(user):getHash(32)
			local ip=net.chatting.users[USERID]
			print(USERID)
			net.chatting.users[USERID]=nil
			net.chatting.users[ip]=nil
		end)
		s.OnDataRecieved(function(self,data,cid,ip,port) -- when the server recieves data this method is triggered
			--First Lets make sure we are getting chatting data
			local user,msg = data:match("!chatting! (%S-) (.+)")
			if user and msg then
				if user:sub(1,1)=="$" then
					local cmd,arg=user:match("$(.+)|(.+)")
					print("Using extended chatting protocal!")
					if cmd=="DM" then
						local struct={ -- pack the info up as a table so the server can do filtering and whatnot to the chat
							user=user,
							msg=net.denormalize(msg)
						}
						self.OnChatRecieved:Fire(struct,"PRIVATE")
						print("USERID",arg)
						self:send(net.chatting.users[arg][3],"!chatting! $DM|"..net.chatting.users[arg][1].."|"..net.chatting:getUserIdFromIP(ip).." "..net.normalize(struct.msg).."",net.chatting.users[arg][4])
					elseif cmd=="getUsers" then
						local users={}
						for i,v in pairs(net.chatting.users) do
							if type(i)~="userdata" then
								table.insert(users,i.."|"..net.chatting.users[i][1])
							end
						end
						table.insert(users,"")
						self:send(ip,"!chatting! $Users|NIL|NIL "..table.concat(users,",").."",port)
					end
				else
					local struct={ -- pack the info up as a table so the server can do filtering and whatnot to the chat
						user=user,
						msg=net.denormalize(msg)
					}
					self.OnChatRecieved:Fire(struct,"GROUP") -- trigger the chat event
					local USERID=net.chatting:getUserIdFromIP(ip)
					for i,v in pairs(self.ips) do
						if ip==v then
							self:send(v,"!chatting! 1|"..struct.user.."|"..USERID.." "..net.normalize(struct.msg).."")
						else
							self:send(v,"!chatting! 0|"..struct.user.."|"..USERID.." "..net.normalize(struct.msg).."")
						end
					end
				end
			end
		end,"chatting")
		s.rooms={}
		function s:regesterRoom(roomname)
			self.rooms[roomname]={}
		end
		s.OnChatRecieved=multi:newConnection() -- create a chat event
	end)
	--Client Stuff
	net.OnClientCreated:connect(function(c)
		c.OnDataRecieved(function(self,data) -- when the client recieves data this method is triggered
			--First Lets make sure we are getting chatting data
			local isself,user,USERID,msg = data:match("!chatting! (%S-)|(%S-)|(%S-) (.+)")
			if not isself then return end
			if tonumber(isself) then
				--This is the client so our job here is done
				local msg=net.denormalize(msg)
				self.OnChatRecieved:Fire(user,msg,({["1"]=true, ["0"]=false})[isself],USERID) -- trigger the chat event
			elseif isself:sub(1,1)=="$" then
				local cmd=isself:match("$(.+)")
				if cmd=="DM" then
					local msg=net.denormalize(msg)
					c.OnPrivateChatRecieved:Fire(user,msg,USERID)
				elseif cmd=="Users" then
					local tab={}
					for ID,nick in msg:gmatch("(%S-)|(%S-),") do
						tab[nick]=ID
					end
					c.OnUserList:Fire(tab)
				end
			end
		end,"chatting")
		function c:sendChat(user,msg)
			self:send("!chatting! "..user.." "..net.normalize(msg).."")
		end
		function c:sendChatTo(user,touser,msg)
			self:send("!chatting! $DM|"..touser.." "..net.normalize(msg).."")
		end
		function c:getUserList()
			self:send("!chatting! $getUsers|NIL NIL")
		end
		function c:getChatFrom(userID)
			self:send("!chatting! getPrivateChat|NIL "..userID) -- add if time permits
		end
		c.OnPrivateChatRecieved=multi:newConnection()
		c.OnUserList=multi:newConnection()
		c.OnChatRecieved=multi:newConnection() -- create a chat event
	end)
end
if net.autoInit then
	net.chatting:init()
end
