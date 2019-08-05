--[[
MIT License

Copyright (c) 2019 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local multi, thread = require("multi")
local net = require("net")
local bin = require("bin")
bin.setBitsInterface(infinabits) -- the bits interface does not work so well, another bug to fix

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
local CMD_CONSOLE		= 0x0B

local char = string.char
local byte = string.byte
-- Process to hold all of the networkManager's muilt objects

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
			multi:newThread("Node Client Manager",function(loop)
				while true do
					if server.timeouts[cid]==true then
						server.OnNodeRemoved:Fire(server.nodes[cid])
						server.nodes[cid] = nil
						server.timeouts[cid] = nil
						thread.kill()
					else
						server.timeouts[cid] = true
						server:send(cid,"ping")
					end
					thread.sleep(1)
				end
			end)
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
	multi:enableLoadDetection()
	settings = settings or {}
	-- Here we have to use the net library to broadcast our node across the network
	math.randomseed(os.time())
	local name = settings.name or multi.randomString(8)
	local node = {}
	node.name = name
	multi.OnError(function(i,error)
		node.OnError:Fire(node,error,node.server)
	end)
	node.server = net:newUDPServer(0) -- hosts the node using the default port
	_, node.port = node.server.udp:getsockname()
	node.connections = net.ClientCache
	node.queue = Queue:newQueue()
	node.functions = bin.stream("RegisteredFunctions.dat",false)
	node.hasFuncs = {}
	node.OnError = multi:newConnection()
	node.OnError(function(node,err,master)
		multi.print("ERROR",err,node.name)
		local temp = bin.new()
		temp:addBlock(#node.name,2)
		temp:addBlock(node.name)
		temp:addBlock(#err,2)
		temp:addBlock(err)
		for i,v in pairs(node.connections) do
			multi.print(i)
			v[1]:send(v[2],char(CMD_ERROR)..temp.data,v[3])
		end
	end)
	if settings.managerDetails then
		local c = net:newTCPClient(settings.managerDetails[1],settings.managerDetails[2])
		if not c then
			multi.print("Cannot connect to the node manager! Ensuring broadcast is enabled!") settings.noBroadCast = false
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
			multi.print("We have function(s) to preload!")
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
	function node:getConsole()
		local c = {}
		local conn = node.connections
		function c.print(...)
			local data = char(CMD_CONSOLE)..packData({...})
			for i,v in pairs(conn) do
				--print(i)
				v[1]:send(v[2],data,v[3])
			end
		end
		-- function c:printTo()
			
		-- end
		return c
	end
	node.loadRate=1
	-- Lets tell the network we are alive!
	node.server.OnDataRecieved(function(server,data,cid,ip,port)
		local cmd = byte(data:sub(1,1)) -- the first byte is the command
		local dat = data:sub(2,-1) -- the data that you want to read
		if cmd == CMD_PING then
			server:send(ip,char(CMD_PONG),port)
		elseif cmd == CMD_QUEUE then
			node.queue:push(resolveData(dat))
		elseif cmd == CMD_REG then
			if not settings.allowRemoteRegistering then
				multi.print(ip..": has attempted to register a function when it is currently not allowed!")
				return
			end
			local temp = bin.new(dat)
			local len = temp:getBlock("n",1)
			local name = temp:getBlock("s",len)
			if node.hasFuncs[name] then
				multi.print("Function already preloaded onto the node!")
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
			len = temp:getBlock("n",4)
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
			status, err = pcall(func,node,unpack(args))
			if not status then
				node.OnError:Fire(node,err,server)
			end
		elseif cmd == CMD_INITNODE then
			multi.print("Connected with another node!")
			node.connections[dat]={server,ip,port}
			multi.OnGUpdate(function(k,v)
				server:send(ip,table.concat{char(CMD_GLOBAL),k,"|",v},port)
			end)-- set this up
		elseif cmd == CMD_INITMASTER then
			multi.print("Connected to the master!",dat)
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
	master.OnError = multi:newConnection()
	master.queue = Queue:newQueue()
	master.connections = net.ClientCache -- Link to the client cache that is created on the net interface
	master.loads = {}
	master.timeouts = {}
	master.trigger = multi:newFunction(function(self,node)
		master.OnFirstNodeConnected:Fire(node)
		self:Pause()
	end)
	if settings.managerDetails then
		local client = net:newTCPClient(settings.managerDetails[1],settings.managerDetails[2])
		if not client then
			multi.print("Warning: Cannot connect to the node manager! Ensuring broadcast listening is enabled!") settings.noBroadCast = false
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
		temp:addBlock(#args,4)
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
				multi:newEvent(function() return name~=nil end):OnEvent(function(evnt)
					self:sendTo(name,char(CMD_TASK)..len..aData..len2..fData)
					evnt:Destroy()
				end):SetName("DelayedSendTask"):SetName("DelayedSendTask"):SetTime(8):OnTimedOut(function(self)
					self:Destroy()
				end)
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
			multi:newEvent(function() return self.connections[name]~=nil end):OnEvent(function(evnt)
				self.connections[name]:send(data)
				evnt:Destroy()
			end):SetName("DelayedSendTask"):SetTime(8):OnTimedOut(function(self)
				self:Destroy()
			end)
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
			if not settings.managerDetails then
				multi:newThread("Node Data Link Controller",function(loop)
					while true do
						if master.timeouts[name]==true then
							master.timeouts[name] = nil
							master.connections[name] = nil
							thread.kill()
						else
							master.timeouts[name] = true
							master:sendTo(name,char(CMD_PING))
						end
						thread.sleep(1)
					end
				end)
			end
			client.name = name
			client.OnDataRecieved(function(client,data)
				local cmd = byte(data:sub(1,1)) -- the first byte is the command
				local dat = data:sub(2,-1) -- the data that you want to read
				master.trigger(nodename)
				if cmd == CMD_ERROR then
					local temp = bin.new(dat)
					local len = temp:getBlock("n",2)
					local node = temp:getBlock("s",len)
					len = temp:getBlock("n",2)
					local err = temp:getBlock("s",len)
					master.OnError:Fire(name,err)
				elseif cmd == CMD_CONSOLE then
					print(unpack(resolveData(dat)))
				elseif cmd == CMD_PONG then
					master.timeouts[client.name] = nil
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
multi.print("Integrated Network Parallelism")
return {init = function()
	return GLOBAL
end}
