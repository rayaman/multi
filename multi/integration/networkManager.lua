-- CURRENT TASK: newNetThread()

local multi = require("multi")
local net = require("net")
require("bin")
bin.setBitsInterface(infinabits)

-- Commands that the master and node will respect, max of 256 commands
local CMD_ERROR			= 0x00
local CMD_PING			= 0x01
local CMD_PONG			= 0x02
local CMD_QUEUE			= 0x03
local CMD_TASK			= 0x04
local CMD_INITNODE		= 0x05
local CMD_INITMASTER	= 0x06
local CMD_GLOBAL		= 0x07
local CMD_LOAD			= 0x08
local CMD_CALL			= 0x09
local CMD_REG			= 0x0A

local char = string.char
local byte = string.byte

-- Helper for piecing commands
local function pieceCommand(cmd,...)
	local tab = {...}
	table.insert(tab,1,cmd)
	return table.concat(tab)
end

-- Internal queue system for network queues
local Queue = {}
Queue.__index = Queue
function Queue:newQueue()
	local c = {}
	setmetatable(c,self)
	return c
end
function Queue:push(data)
	table.insert(self,data)
end
function Queue:raw_push(data) -- Internal usage only
	table.insert(self,data)
end
function Queue:pop()
	return table.remove(self,1)
end
function Queue:peek()
	return self[1]
end
local queues = {}
multi.OnNetQueue = multi:newConnection()
multi.OnGUpdate = multi:newConnection()

-- Managing the data that goes through the system
local function packData(data)
	-- returns the data that was sterilized
	local dat = bin.new()
	dat:addBlock(#type(data),1)
	dat:addBlock(type(data)) -- The type is first
	if type(data)=="table" then
		dat:addBlock(data,nil,"t")
	elseif type(data) == "userdata" then
		error("Cannot sterilize userdata!")
	elseif type(data) == "number" then
		dat:addBlock(data,nil,"d")
	elseif type(data) == "string" then
		dat:addBlock(#data,4)
		dat:addBlock(data,nil,"s")
	elseif type(data) == "boolean" then
		dat:addBlock(data,1)
	elseif type(data) == "function" then
		dat:addBlock(data,nil,"f")
	end
	return dat.data
end
local function resolveData(data)
	-- returns the data that was sterilized
	local dat = bin.new(data)
	local tlen = dat:getBlock("n",1)
	local tp = dat:getBlock("s",tlen)
	if tp=="table" then
		return dat:getBlock("t")
	elseif tp=="number" then
		return dat:getBlock("d")
	elseif tp=="string" then
		local num = dat:getBlock("n",4)
		return dat:getBlock("s",num)
	elseif tp=="boolean" then
		return dat:getBlock("b",1)
	elseif tp=="function" then
		return dat:getBlock("f")
	end
end

-- internal global system
local GLOBAL = {}
local PROXY = {}
setmetatable(GLOBAL,{
	__index = function(t,k)
		return PROXY[k]
	end,
	__newindex = function(t,k,v)
		local v = v
		PROXY[k] = v
		multi.OnGUpdate:Fire(k,packData(v))
	end
})

-- In case you are unable to use broadcasting this can be used to help connect to nodes
function multi:nodeManager(port)
	if not port then
		error("You must provide a port in order to host the node manager!")
	end
	local server = net:newTCPServer(port)
	server.nodes = {}
	server.timeouts = {}
	server.OnNodeAdded = multi:newConnection()
	server.OnNodeRemoved = multi:newConnection()
	server.OnDataRecieved(function(server,data,cid,ip,port)
		local cmd = data:sub(1,1)
		if cmd == "R" then
			multi:newTLoop(function(loop)
				if server.timeouts[cid]==true then
					server.OnNodeRemoved:Fire(server.nodes[cid])
					server.nodes[cid] = nil
					server.timeouts[cid] = nil
					loop:Destroy()
					return
				end
				server.timeouts[cid] = true
				server:send(cid,"ping")
			end,.1)
			server.nodes[cid]=data:sub(2,-1)
			server.OnNodeAdded:Fire(server.nodes[cid])
		elseif cmd == "G" then
			server.OnNodeAdded(function(node)
				server:send(cid,node)
			end)
			server.OnNodeRemoved(function(node)
				server:send(cid,"R"..node:match("(.-)|"))
			end)
			for i,v in pairs(server.nodes) do
				server:send(cid,v)
			end
		elseif cmd == "P" then
			server.timeouts[cid] = nil
		end
	end)
end
-- The main driving force of the network manager: Nodes
function multi:newNode(settings)
	settings = settings or {}
	-- Here we have to use the net library to broadcast our node across the network
	math.randomseed(os.time())
	local name = settings.name or multi.randomString(8)
	local node = {}
	node.name = name
	node.server = net:newUDPServer(0) -- hosts the node using the default port
	node.port = node.server.port
	print(node.port,node.port.udp:getsockname())
	node.connections = net.ClientCache
	node.queue = Queue:newQueue()
	node.functions = bin.stream("RegisteredFunctions.dat",false)
	node.hasFuncs = {}
	if settings.managerDetails then
		local c = net:newTCPClient(settings.managerDetails[1],settings.managerDetails[2])
		if not c then 
			print("Cannot connect to the node manager! Ensuring broadcast is enabled!") settings.noBroadCast = false
		else
			c.OnDataRecieved(function(self,data)
				if data == "ping" then
					self:send("P")
				end
			end)
			c:send("RNODE_"..name.."|"..net.getLocalIP().."|"..node.port)
		end
	end
	if not settings.preload then
		if node.functions:getSize()~=0 then
			print("We have function(s) to preload!")
			local len = node.functions:getBlock("n",1)
			local name,func
			while len do
				name = node.functions:getBlock("s",len)
				len = node.functions:getBlock("n",2)
				func = node.functions:getBlock("s",len)
				len = node.functions:read(1)
				_G[name]=resolveData(func)
				node.hasFuncs[name]=true
				if not len then break end
				len = byte(len)
			end
		end
	end
	function node:pushTo(name,data)
		node:sendTo(name,char(CMD_QUEUE)..packData(data))
	end
	function node:peek()
		return node.queue:peek()
	end
	function node:pop()
		return node.queue:pop()
	end
	node.loadRate=1
	if settings then
		if settings.crossTalk then
			net.OnCastedClientInfo(function(client,name,ip,port)
				multi.OnGUpdate(function(k,v)
					client:send(table.concat{char(CMD_GLOBAL),k,"|",v})
				end)
				print("Found a new node! Node_List:")
				for i,v in pairs(node.connections) do
					print(i)
				end
				client:send(char(CMD_INITNODE)..name) -- Tell the node that you are a node trying to connect
				client.OnDataRecieved(function(client,data)
					local cmd = byte(data:sub(1,1)) -- the first byte is the command
					local dat = data:sub(2,-1) -- the data that you want to read
					if cmd == CMD_PING then
						
					elseif cmd == CMD_PONG then
						
					elseif cmd == CMD_QUEUE then
						queue:push(resolveData(dat))
					elseif cmd == CMD_GLOBAL then
						local k,v = dat:match("(.-)|(.+)")
						PROXY[k]=resolveData(v)
					end
				end)
			end)
			net:newCastedClients("NODE_(.+)")
		end
	end
	-- Lets tell the network we are alive!
	node.server.OnDataRecieved(function(server,data,cid,ip,port)
		local cmd = byte(data:sub(1,1)) -- the first byte is the command
		local dat = data:sub(2,-1) -- the data that you want to read
		if cmd == CMD_PING then
			
		elseif cmd == CMD_PONG then
			
		elseif cmd == CMD_QUEUE then	
			node.queue:push(resolveData(dat))
		elseif cmd == CMD_REG then
			if not settings.allowRemoteRegistering then
				print(ip..": has attempted to register a function when it is currently not allowed!")
				return
			end
			local temp = bin.new(dat)
			local len = temp:getBlock("n",1)
			local name = temp:getBlock("s",len)
			if node.hasFuncs[name] then
				print("Function already preloaded onto the node!")
				return
			end
			len = temp:getBlock("n",2)
			local func = temp:getBlock("s",len)
			_G[name]=resolveData(func)
			node.functions:addBlock(dat)
		elseif cmd == CMD_CALL then
			local temp = bin.new(dat)
			local len = temp:getBlock("n",1)
			local name = temp:getBlock("s",len)
			len = temp:getBlock("n",2)
			local args = temp:getBlock("s",len)
			_G[name](unpack(resolveData(args)))
		elseif cmd == CMD_TASK then
			local holder = bin.new(dat)
			local len = holder:getBlock("n",4)
			local args = holder:getBlock("s",len)
			local len2 = holder:getBlock("n",4)
			local func = holder:getBlock("s",len2)
			args = resolveData(args)
			func = resolveData(func)
			func(unpack(args))
		elseif cmd == CMD_INITNODE then
			print("Connected with another node!")
			node.connections[dat]={server,ip,port}
			multi.OnGUpdate(function(k,v)
				server:send(ip,table.concat{char(CMD_GLOBAL),k,"|",v},port)
			end)-- set this up
		elseif cmd == CMD_INITMASTER then
			print("Connected to the master!",dat)
			node.connections[dat]={server,ip,port}
			multi.OnGUpdate(function(k,v)
				server:send(ip,table.concat{char(CMD_GLOBAL),k,"|",v},port)
			end)-- set this up
			multi:newTLoop(function()
				server:send(ip,char(CMD_LOAD)..node.name.."|"..multi:getLoad(),port)
			end,node.loadRate)
			server:send(ip,char(CMD_LOAD)..node.name.."|"..multi:getLoad(),port)
			server:send(ip,char(CMD_INITNODE)..node.name,port)
		elseif cmd == CMD_GLOBAL then
			local k,v = dat:match("(.-)|(.+)")
			PROXY[k]=resolveData(v)
		end
	end)
	function node:sendTo(name,data)
		local conn = node.connections[name]
		conn[1]:send(conn[2],data,conn[3])
	end
	if not settings.noBroadCast then 
		node.server:broadcast("NODE_"..name)
	end
	return node
end

-- Masters
function multi:newMaster(settings) -- You will be able to have more than one master connecting to node(s) if that is what you want to do. I want you to be able to have the freedom to code any way that you want to code. 
	local master = {}
	local settings = settings or {}
	master.name = settings.name or multi.randomString(8)
	local name = master.name
	master.conn = multi:newConnection()
	master.conn2 = multi:newConnection()
	master.OnFirstNodeConnected = multi:newConnection()
	master.OnNodeConnected = multi:newConnection()
	master.queue = Queue:newQueue()
	master.connections = net.ClientCache -- Link to the client cache that is created on the net interface
	master.loads = {}
	master.trigger = multi:newFunction(function(self,node)
		master.OnFirstNodeConnected:Fire(node)
		self:Pause()
	end)
	if settings.managerDetails then
		local client = net:newTCPClient(settings.managerDetails[1],settings.managerDetails[2])
		if not client then 
			print("Cannot connect to the node manager! Ensuring broadcast listening is enabled!") settings.noBroadCast = false
		else
			client.OnDataRecieved(function(client,data)
				local cmd = data:sub(1,1)
				if cmd == "N" then
					print(data)
					local name,ip,port = data:match("(.-)|(.-)|(.+)")
					local c = net:newUDPClient(ip,port)
					net.OnCastedClientInfo:Fire(c,name,ip,port)master.connections[name]=c
				elseif cmd == "R" then
					local name = data:sub(2,-1)
					master.connections[name]=nil
				end
			end)
			client:send("G") -- init your connection as a master
		end
	end
	function master:doToAll(func)
		for i,v in pairs(master.connections) do
			func(i,v)
		end
	end
	function master:register(name,node,func)
		if not node then
			error("You must specify a node to execute a command on!")
		end
		local temp = bin.new()
		local fData = packData(func)
		temp:addBlock(CMD_REG,1)
		temp:addBlock(#name,1)
		temp:addBlock(name,#name)
		temp:addBlock(#fData,2)
		temp:addBlock(fData,#fData)
		master:sendTo(node,temp.data)
	end
	function master:execute(name,node,...)
		if not node then
			error("You must specify a node to execute a command on!")
		end
		if not name then
			error("You must specify a function name to call on the node!")
		end
		local args = packData{...}
		local name = name
		local node = node
		local temp, len, data
		temp = bin.new()
		temp:addBlock(CMD_CALL,1)
		temp:addBlock(#name,1)
		temp:addBlock(name,#name)
		temp:addBlock(#args,2)
		temp:addBlock(args,#args)
		master:sendTo(node,temp.data)
	end
	function master:pushTo(name,data)
		master:sendTo(name,char(CMD_QUEUE)..packData(data))
	end
	function master:peek()
		return self.queue:peek()
	end
	function master:pop()
		return self.queue:pop()
	end
	function master:newNetworkThread(tname,func,name,...) -- If name specified then it will be sent to the specified node! Otherwise the least worked node will get the job
		local fData = packData(func)
		local tab = {...}
		local aData = ""
		if #tab~=o then
			aData = (packData{...})
		else
			aData = (packData{"NO","ARGS"})
		end
		local temp = bin.new()
		temp:addBlock(#aData,4)
		local len = temp.data
		local temp2 = bin.new()
		temp2:addBlock(#fData,4)
		local len2 = temp2.data
		if not name then
			local name = self:getFreeNode()
			if not name then
				name = self:getRandomNode()
			end
			if name==nil then
				multi:newTLoop(function(loop)
					if name~=nil then
						self:sendTo(name,char(CMD_TASK)..len..aData..len2..fData)
						loop:Desrtoy()
					end
				end,.1)
			else
				self:sendTo(name,char(CMD_TASK)..len..aData..len2..fData)
			end
		else
			local name = "NODE_"..name
			self:sendTo(name,char(CMD_TASK)..len..aData..len2..fData)
		end
	end
	function master:sendTo(name,data)
		if name:sub(1,5)~="NODE_" then
			name = "NODE_"..name
		end
		if self.connections[name]==nil then
			multi:newTLoop(function(loop)
				if self.connections[name]~=nil then
					self.connections[name]:send(data)
					loop:Desrtoy()
				end
			end,.1)
		else
			self.connections[name]:send(data)
		end
	end
	function master:getFreeNode()
		local count = 0
		local min = math.huge
		local refO
		for i,v in pairs(master.loads) do
			if v<min then
				min = v
				refO = i
			end
		end
		return refO
	end
	function master:getRandomNode()
		local list = {}
		for i,v in pairs(master.connections) do
			list[#list+1]=i:sub(6,-1)
		end
		return list[math.random(1,#list)]
	end
	net.OnCastedClientInfo(function(client,name,ip,port)
		multi.OnGUpdate(function(k,v)
			client:send(table.concat{char(CMD_GLOBAL),k,"|",v})
		end)
		local nodename
		for i,v in pairs(master.connections) do
			nodename = i
		end
		client.OnClientReady(function()
			client:send(char(CMD_INITMASTER)..master.name) -- Tell the node that you are a master trying to connect
			client.OnDataRecieved(function(client,data)
				local cmd = byte(data:sub(1,1)) -- the first byte is the command
				local dat = data:sub(2,-1) -- the data that you want to read
				master.trigger(nodename)
				if cmd == CMD_ERROR then
					
				elseif cmd == CMD_PING then
					
				elseif cmd == CMD_PONG then
					
				elseif cmd == CMD_INITNODE then
					master.OnNodeConnected:Fire(dat)
				elseif cmd == CMD_QUEUE then
					master.queue:push(resolveData(dat))
				elseif cmd == CMD_GLOBAL then
					local k,v = dat:match("(.-)|(.+)")
					PROXY[k]=resolveData(v)
				elseif cmd == CMD_LOAD then
					local name,load = dat:match("(.-)|(.+)")
					master.loads[name]=tonumber(load)
				end
			end)
		end)
	end)
	if not settings.noBroadCast then
		net:newCastedClients("NODE_(.+)") -- Searches for nodes and connects to them, the master.clients table will contain them by name
	end
	return master
end

-- The init function that gets returned
print("Integrated Network Parallelism")
return {init = function()
	return GLOBAL
end}