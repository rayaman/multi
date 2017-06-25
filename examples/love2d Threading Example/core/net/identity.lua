require("net")
--General Stuff
--[[ What this module does!
Adds
net.identity:init()

]]
net:registerModule("identity",{2,1,0})--1.0.1 Note: Added eaiser ways to get user data using only cid
function net.hash(text,n)
	n=n or 16
	return bin.new(text.."jgmhktyf"):getHash(n)
end
net.identity.UIDS={}
net.identity.UIDS.ids={}
function net.identity:init() -- calling this initilizes the library and binds it to the servers and clients created
	--Server Stuff
	net.OnServerCreated(function(s)
		s.userFolder="./USERS"
		print("The identity Module has been loaded onto the server!")
		function s:_isRegistered(user)
			return io.fileExists(self.userFolder..net.hash(user)..".dat")
		end
		function s:getUserData(user)
			local userdata=bin.load(self.userFolder..net.hash(user)..".dat")
			local nick,dTable=userdata:match("%S-|%S-|(%S-)|(.+)")
			return nick,loadstring("return "..(dTable or "{}"))()
		end
		function s:modifyUserData(user,oldpass,pass,nick,dTable)
			if self:_isRegistered(user) then
				local userdata=bin.load(self.userFolder..net.hash(user)..".dat")
				local args={}
				local _pass,_nick,_dTable=userdata:match("%S-|(%S-)|(%S-)|(.+)")
				if oldpass~=_pass then
					args.invalidPass=true
					pass=_pass
				end
				if not nick then nick=_nick args.invalidNick=true end
				table.merge(_dTable or {}, dTable or {})
				bin.new(string.format("%s|%s|%s|%s\n",user,pass,nick,dTable)):tofile(self.userFolder..net.hash(user)..".dat")
			else
				return false
			end
		end
		function s:getUserCred(user)
			local userdata=bin.load(self.userFolder..net.hash(user)..".dat")
			return userdata:match("%S-|(%S-)|")
		end
		function s:getUSERID(cid)
			return (net.identity.UIDS[cid] or "User Not Logged In!")
		end
		function s:getUsername(cid)
			return self:userLoggedIn(cid)
		end
		function s:getNickname(cid)
			return self.loggedIn[self:getUsername(cid)].nick
		end
		function s:getdTable(cid)
			return self.loggedIn[self:getUsername(cid)]
		end
		function s:getUserDat(cid)
			return self:getUserDataHandle(self:getUsername(cid))
		end
		function s:getNickFromUSERID(USERID)
			return bin.load(self.userFolder..net.hash(user)..".dat"):match("%S-|%S-|(%S-)|")
		end
		function s:userLoggedIn(cid)
			for i,v in pairs(self.loggedIn) do
				if v.cid==cid then
					return i
				end
			end
			return false
		end
		function s:setDataLocation(loc)
			if not io.dirExists(loc) then
				io.mkDir(loc)
			end
			self.userFolder=loc
		end
		s:setDataLocation("USERS/")
		function s:logoutUser(user)
			net.identity.UIDS.ids[user.UID]=nil
			self.loggedIn[user]=nil
		end
		function s:loginUser(user,cid)
			net.identity.UIDS[cid]=net.hash(user)
			local nick,dTable=self:getUserData(user)
			self.loggedIn[user]={}
			table.merge(self.loggedIn[user],dTable or {})
			self.loggedIn[user].cid=cid
			self.loggedIn[user].nick=nick
			self.loggedIn[user].UID=net.resolveID(net.identity.UIDS)
			return self.loggedIn[user]
		end
		function s:getUserDataHandle(user)
			return self.loggedIn[user]
		end
		function s:syncUserData(user,ip,port)
			local handle=self:getUserDataHandle(user)
			self:send(ip,"!identity! SYNC <-|"..bin.ToStr(handle).."|->",port)
		end
		s.loggedIn={}
		s.allowDuplicateNicks=true
		s.minimumNickLength=4
		s.minimumUserLength=4
		s.OnUserRegistered=multi:newConnection()
		s.OnUserLoggedIn=multi:newConnection()
		s.OnUserLoggerOut=multi:newConnection()
		s.OnAlreadyLoggedIn=multi:newConnection()
		s.OnPasswordForgotten=multi:newConnection()
		s.OnDataRecieved:connect(function(self,data,cid,ip,port) -- when the server recieves data this method is triggered
			local cmd,arg1,arg2,arg3,arg4 = data:match("!identity! (%S-) '(.-)' '(.-)' '(.-)' <%-|(.+)|%->")
			if cmd=="register" then
				local user,pass,nick,dTable = arg1,arg2,arg3,arg4
				if self:_isRegistered(user) then
					self:send(ip,"!identity! REGISTERED <-|"..user.."|->",port)
				else
					if not(self.userFolder:sub(-1,-1)=="/" or self.userFolder:sub(-1,-1)=="\\") then
						self.userFolder=self.userFolder.."/"
					end
					local rets=self.OnUserRegistered:Fire(user,pass,nick,loadstring("return "..(dTable or "{}"))())
					if #user<=self.minimumUserLength then
						self:send(ip,"!identity! REGISTERREFUSED <-|Username too short|->",port)
						return
					end
					if #user<=self.minimumNickLength then
						self:send(ip,"!identity! REGISTERREFUSED <-|Nickname too short|->",port)
						return
					end
					for i=1,#rets do
						if rets[i][1]==false then
							print("Server refused to accept registration request!")
							self:send(ip,"!identity! REGISTERREFUSED <-|Unspecified Error|->",port)
							return
						end
					end
					multi:newFunction(function(func) -- anom func, allows for fancy multitasking
						local dupnickfilemanager=bin.stream(self.userFolder.."Nicks.dat",false)
						local isValid=func:newCondition(function() return t~=nil end)
						local tab={}
						local t=dupnickfilemanager:getBlock("s")
						if self.allowDuplicateNicks==false then
							while func:condition(isValid) do
								tab[#tab]=t
								if t==nick then
									self:send(ip,"!identity! REGISTERREFUSED <-|Duplicate Nicks are not allowed|->",port)
									dupnickfilemanager:close()
									return
								end
							end
							t=dupnickfilemanager:getBlock("s")
						end
						dupnickfilemanager:addBlock(nick.."|"..bin.new(user):getHash(32))
						dupnickfilemanager:close()
						bin.new(string.format("%s|%s|%s|%s\n",user,pass,nick,dTable)):tofile(self.userFolder..net.hash(user)..".dat")
						self:send(ip,"!identity! REGISTEREDGOOD <-|"..user.."|->",port)
						func=nil -- we dont want 1000s+ of these anom functions lying around
						return
					end)()-- lets call the function
				end
				return
			elseif cmd=="login" then
				local user,pass = arg1,arg2
				local _pass=s:getUserCred(user)
				if not(self:_isRegistered(user)) then
					self:send(ip,"!identity! LOGINBAD <-|nil|->",port)
					return
				end
				if pass==_pass then
					if self:userLoggedIn(cid) then
						self.OnAlreadyLoggedIn:Fire(self,user,cid,ip,port)
						self:send(ip,"!identity! ALREADYLOGGEDIN <-|nil|->",port)
						return
					end
					local handle=self:loginUser(user,cid) -- binds the cid to username
					self:send(ip,"!identity! LOGINGOOD <-|"..bin.ToStr(handle).."|->",port)
					self.OnUserLoggedIn:Fire(user,cid,ip,port,bin.ToStr(handle))
					return
				else
					self:send(ip,"!identity! LOGINBAD <-|nil|->",port)
					return
				end
			elseif cmd=="logout" then
				self:logoutUser(user)
				self.OnClientClosed:Fire(self,"User logged out!",cid,ip,port)
			elseif cmd=="sync" then
				local dTable = loadstring("return "..(arg4 or "{}"))()
				local handle = self:getUserDataHandle(self:userLoggedIn(cid))
				table.merge(handle,dTable)
			elseif cmd=="pass" then
				local user=arg1
				if self:_isRegistered(user) then
					self.OnPasswordForgotten:Fire(arg1,cid)
					self:send(ip,"!identity! PASSREQUESTHANDLED <-|NONE|->",port)
				else
					self:send(ip,"!identity! NOUSER <-|"..user.."|->",port)
				end
			end
		end)
		s.OnClientClosed:connect(function(self,reason,cid,ip,port)
			self.OnUserLoggerOut:Fire(self,self:userLoggedIn(cid),cid,reason)
		end)
	end,"identity")
	--Client Stuff
	net.OnClientCreated:connect(function(c)
		c.userdata={}
		c.OnUserLoggedIn=multi:newConnection()
		c.OnBadLogin=multi:newConnection()
		c.OnUserAlreadyRegistered=multi:newConnection()
		c.OnUserAlreadyLoggedIn=multi:newConnection()
		c.OnUserRegistered=multi:newConnection()
		c.OnNoUserWithName=multi:newConnection()
		c.OnPasswordRequest=multi:newConnection()
		c.OnUserRegisterRefused=multi:newConnection()
		function c:logout()
			self:send("!identity! logout 'NONE' 'NONE' 'NONE' <-|nil|->")
		end
		c.OnDataRecieved(function(self,data) -- when the client recieves data this method is triggered
			local cmd,arg1 = data:match("!identity! (%S-) <%-|(.+)|%->")
			if cmd=="REGISTERED" then
				self.OnUserAlreadyRegistered:Fire(self,arg1)
			elseif cmd=="REGISTEREDGOOD" then
				self.OnUserRegistered:Fire(self,arg1)
			elseif cmd=="REGISTERREFUSED" then
				self.OnUserRegisterRefused:Fire(self,arg1)
			elseif cmd=="ALREADYLOGGEDIN" then
				self.OnUserAlreadyLoggedIn:Fire(self,arg1)
			elseif cmd=="LOGINBAD" then
				self.OnBadLogin:Fire(self)
			elseif cmd=="LOGINGOOD" then
				local dTable=loadstring("return "..(arg1 or "{}"))()
				table.merge(self.userdata,dTable)
				self.OnUserLoggedIn:Fire(self,self.userdata)
			elseif cmd=="SYNC" then
				local dTable=loadstring("return "..(arg1 or "{}"))()
				table.merge(self.userdata,dTable)
			elseif cmd=="NOUSER" then
				self.OnNoUserWithName:Fire(self,arg1)
			elseif cmd=="PASSREQUESTHANDLED" then
				self.OnPasswordRequest:Fire(self)
			end
		end,"identity")
		function c:syncUserData()
			self:send(string.format("!identity! sync 'NONE' 'NONE' 'NONE' <-|%s|->",bin.ToStr(dTable)))
		end
		function c:forgotPass(user)
			self:send(string.format("!identity! pass '%s' 'NONE' 'NONE' <-|nil|->",user))
		end
		function c:getUserDataHandle()
			return self.userdata
		end
		function c:logIn(user,pass)
			self:send(string.format("!identity! login '%s' '%s' 'NONE' <-|nil|->",user,net.hash(pass)))
		end
		function c:register(user,pass,nick,dTable)
			if dTable then
				self:send(string.format("!identity! register '%s' '%s' '%s' <-|%s|->",user,net.hash(pass),nick,bin.ToStr(dTable)))
			else
				self:send(string.format("!identity! register '%s' '%s' '%s' <-|nil|->",user,net.hash(pass),nick))
			end
		end
	end)
end
if net.autoInit then
	net.identity:init()
end
