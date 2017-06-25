require("net")
require("net.aft")
net:registerModule("version",{1,0,0}) -- allows communication of versions for modules
net.version.HOSTS={
	["Lua"]=1,
	["LuaJIT"]=1,
	["Love2d"]=2, -- Yes love2d uses luaJIT, but the filesystem works a bit differently
	["Corona"]=3,
}
net.version.OS={
	["Windows"]=1,
	["Unix"]=2,
	["RPI"]=3,
}
--net.version.EOL="\60\69\110\100\45\79\102\45\70\105\108\101\45\84\114\97\110\115\102\101\114\62"
net.OnServerCreated:connect(function(s)
	s.OnDataRecieved(function(self,data,CID_OR_HANDLE,IP_OR_HANDLE,PORT_OR_IP)
		local cmd,arg1,arg2=data:match("!version! ")
	end,"version")
	s.OnClientConnected(function(self,CID_OR_HANDLE,IP_OR_HANDLE,PORT_OR_IP)
		multi:newFunction(function(func) -- anom func, allows for fancy multitasking
			multi:newFunction(function(self)
				local range=self:newRange()
				for i in range(1,#self.loadedModules) do
					local mod=self.loadedModules[i]
					self:send(IP_OR_HANDLE,"!version! CHECK "..mod.." NIL",PORT_OR_IP) -- sends command to client to return the version of the module
				end
			end)()
			func=nil -- we dont want 1000s+ of these anom functions lying around
		end)()-- lets call the function
		self:send(IP_OR_HANDLE,"!version! HOST NIL NIL",PORT_OR_IP)
	end)
end)
net.OnClientCreated:connect(function(c)
	c.OnDataRecieved(function(self,data)
		local cmd,module,arg1=data:match("!version! (%S+) (%S+) (%S+)")
		if cmd=="CHECK" then
			self:send("!version! VER "..self.loadedModules[module].." "..net.getModuleVersion(module))
		elseif cmd=="UPDATE" then
			--
		end
	end,"version")
end)
