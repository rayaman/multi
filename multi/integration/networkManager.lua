local multi = require("multi")
local net = require("net")
local nGLOBAL = {}
local nTHREAD = {}
-- This integration is a bit different than the others! Nodes should include both the system threading integration and the network integration. This is because each node has a "main thread" as well. The examples will make this clear!
multi.defaultNetworkPort = 30341 -- This port has a meaning to it... convert to base 36 and see what you get.
function multi:setdefaultNetworkPort(port)
	multi.defaultNetworkPort = port
end
function multi:newNode(name,settings)
	-- Here we have to use the net library to broadcast our node across the network
	local port = multi.defaultNetworkPort
	math.randomseed(os.time())
	local name = name or multi.randomString(8)
	if settings then
		port = settings.port or port
		-- When I think of more they will be added here
	end
	local node = {}
	node.server = net:newServer(port) -- hosts the node using the default port
	node.port = multi.defaultNetworkPort
	-- Lets tell the network we are alive!
	node.server:broadcast("NODE_"..name)
end
function multi:newMaster(name,settings) -- You will be able to have more than one master connecting to a node if that is what you want to do. I want you to be able to have the freedom to code any way that you want to code. 
	local master = {}
	master.clients = net.ClientCache -- Link to the client cache that is created on the net interface
	net.OnCastedClientInfo(function(client,name,ip,port)
		print("Found a new node!")
		-- Do the handshake and start up stuff here
	end)
	net:newCastedClients("NODE_(.+)") -- Searches for nodes and connects to them, the master.clients table will contain them by name
end
-- For the same reasons that the other integrations have this
multi.integration.nGLOBAL=nGLOBAL
multi.integration.nTHREAD=nTHREAD
return {init=function()
	return nGLOBAL, nTHREAD
end}