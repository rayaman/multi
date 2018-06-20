-- CURRENT TASK: newNetThread()

local multi = require("multi")
local net = require("net")
local bin = require("bin")

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

local char = string.char
local byte = string.byte

-- Helper for piecing commands
local function pieceCommand(cmd,...)
	local tab = {...}
	table.insert(tab,1,cmd)
	return table.concat(tab)
end

-- Internal queue system for network queues
local queue = {}
queue.__index = queue
function queue:newQueue()
	local c = {}
	setmetatable(c,self)
	return c
end
function queue:push(data)
	table.insert(self,packData(data))
end
function queue:raw_push(data) -- Internal usage only
	table.insert(self,data)
end
function queue:pop()
	return resolveData(table.remove(self,1))
end
function queue:peek()
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

-- The main driving force of the network manager: Nodes
function multi:newNode(name,settings)
	-- Here we have to use the net library to broadcast our node across the network
	math.randomseed(os.time())
	local name = name or multi.randomString(8)
	local node = {}
	node.name = name
	node.server = net:newUDPServer(0) -- hosts the node using the default port
	node.port = node.server.port
	node.connections = net.ClientCache
	node.queue = queue:newQueue()
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
						local name,d=dat:match("(.-)|(.+)")
						multi.OnNetQueue:Fire(name,d)
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
			local name,d=dat:match("(.-)|(.+)")
			multi.OnNetQueue:Fire(name,d)
		elseif cmd == CMD_TASK then
			local args,func = dat:match("(.-)|(.+)")
			func = resolveData(func)
			args = resolveData(args)
			func(unpack(args))
		elseif cmd == CMD_INITNODE then
			print("Connected with another node!")
			node.connections[dat]={server,ip,port}
			multi.OnGUpdate(function(k,v)
				server:send(ip,table.concat{char(CMD_GLOBAL),k,"|",v},port)
			end)-- set this up
		elseif cmd == CMD_INITMASTER then
			print("Connected to the master!")
			node.connections[dat]={server,ip,port}
			multi.OnGUpdate(function(k,v)
				server:send(ip,table.concat{char(CMD_GLOBAL),k,"|",v},port)
			end)-- set this up
			multi:newTLoop(function()
				server:send(ip,char(CMD_LOAD)..node.name.."|"..multi:getLoad(),port)
			end,node.loadRate)
			server:send(ip,char(CMD_LOAD)..node.name.."|"..multi:getLoad(),port)
		elseif cmd == CMD_GLOBAL then
			local k,v = dat:match("(.-)|(.+)")
			PROXY[k]=resolveData(v)
		end
	end)
	function node:sendToMaster(name,data)
		self.connections[name]:send(data)
	end
	function node:sendToNode(name,data)
		self.connections[name]:send(data)
	end
	node.server:broadcast("NODE_"..name)
	return node
end

-- Masters
function multi:newMaster(name,settings) -- You will be able to have more than one master connecting to node(s) if that is what you want to do. I want you to be able to have the freedom to code any way that you want to code. 
	local master = {}
	master.name = name
	master.conn = multi:newConnection()
	master.conn2 = multi:newConnection()
	master.OnFirstNodeConnected = multi:newConnection()
	master.queue = queue:newQueue()
	master.connections = net.ClientCache -- Link to the client cache that is created on the net interface
	master.loads = {}
	master.trigger = multi:newFunction(function(self)
		master.OnFirstNodeConnected:Fire()
		self:Pause()
	end)
	function master:newNetworkThread(tname,name,func,...) -- If name specified then it will be sent to the specified node! Otherwise the least worked node will get the job
		local fData = packData(func)
		local tab = {...}
		local aData = ""
		if #tab~=o then
			aData = (packData{...}).."|"
		else
			aData = (packData{1,1}).."|"
		end
		if not name then
			local name = self:getFreeNode()
			if not name then
				name = self:getRandomNode()
			end
			if name==nil then
				multi:newTLoop(function(loop)
					if name~=nil then
						print("Readying Func")
						self:sendTo(name,char(CMD_TASK)..aData..fData)
						loop:Desrtoy()
					end
				end,.1)
			else
				self:sendTo(name,char(CMD_TASK)..aData..fData)
			end
		else
			local name = "NODE_"..name
			self:sendTo(name,char(CMD_TASK)..aData..fData)
		end
	end
	function master:sendTo(name,data)
		if self.connections["NODE_"..name]==nil then
			multi:newTLoop(function(loop)
				if self.connections["NODE_"..name]~=nil then
					self.connections["NODE_"..name]:send(data)
					loop:Desrtoy()
				end
			end,.1)
		else
			self.connections["NODE_"..name]:send(data)
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
		print("Found a new node! Node_List:")
		for i,v in pairs(master.connections) do
			print(i)
		end
		client.OnClientReady(function()
			client:send(char(CMD_INITMASTER)..name) -- Tell the node that you are a master trying to connect
			client.OnDataRecieved(function(client,data)
				local cmd = byte(data:sub(1,1)) -- the first byte is the command
				local dat = data:sub(2,-1) -- the data that you want to read
				master.trigger()
				if cmd == CMD_ERROR then
					
				elseif cmd == CMD_PING then
					
				elseif cmd == CMD_PONG then
					
				elseif cmd == CMD_QUEUE then
					local name,d=dat:match("(.-)|(.+)")
					multi.OnNetQueue:Fire(name,d)
				elseif cmd == CMD_GLOBAL then
					local k,v = dat:match("(.-)|(.+)")
					PROXY[k]=resolveData(v)
					print("Got Global Command")
				elseif cmd == CMD_LOAD then
					local name,load = dat:match("(.-)|(.+)")
					master.loads[name]=tonumber(load)
				end
			end)
		end)
	end)
	net:newCastedClients("NODE_(.+)") -- Searches for nodes and connects to them, the master.clients table will contain them by name
	return master
end

-- The init function that gets returned
return {init = function()
	return GLOBAL
end}