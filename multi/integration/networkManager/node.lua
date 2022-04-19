--[[
MIT License

Copyright (c) 2022 Ryan Ward

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
local net = require("net")
local cmd = require("multi.integration.networkManager.cmds")
local multi,thread = require("multi"):init()
local node = {}
node.__index = node
local rand = {}
for i = 65,90 do
    rand[#rand+1] = string.char(i)
end
local function randName(n)
    local str = {}
    for i=1,(n or 10) do
        str[#str+1] = rand[math.random(1,#rand)]
    end
    return table.concat(str)
end
local getNames = thread:newFunction(function(names)
    local listen = socket.udp() -- make a new socket
	listen:setsockname(net.getLocalIP(), 11111)
	listen:settimeout(0)
    local data, ip, port = listen:receivefrom()
    thread.holdWithin(1,function()
        if data then
            local n, tp, ip, port = data:match("(%S-)|(%S-)|(%S-):(%d+)")
            if n then
                names[n]=true
            end
        end
    end)
    return multi.NIL
end)
local function setName(ref,name)
    if name then
        ref.name = "NODE_"..name
        ref.connection:broadcast(name)
        return
    end
    local names = {}
    getNames(names).wait() -- Prevents duplicate names from spawning!
    local name = randName()
    while names["NODE_"..name] do
        name = randName()
    end
    ref.name = "NODE_"..name
    ref.connection:broadcast(ref.name)
end
node.ServerCode = require("multi.integration.networkManager.serverSide")
node.ClientCode = require("multi.integration.networkManager.clientSide")
function node.random()
    return randName(12)
end
function node:registerWithManager(ip,port)
    if self.type ~= "server" then return end
    if not self.manager then
        self.manager = net:newTCPClient(ip,port)
        if not self.manager then
            error("Unable to connect to the node Manager! Is it running? Perhaps the hostname or port is incorrect!")
        end
    end
    thread:newFunction(function()
        thread.hold(function() return self.name end)
        self.manager:send("!REG_NODE!"..self.name.."|"..net.getLocalIP().."|"..self.connection.port)
    end)()
end
function node:new(host,port,name)
    local c = {}
    c.links = {}
    setmetatable(c,node)
    if type(host)=="number" or type(host)=="nil" then
        c.connection = net:newTCPServer(host or cmd.defaultPort)
        c.connection:enableBinaryMode()
        c.type = "server"
        c.connection.node = c
        c.connection.OnDataRecieved(self.ServerCode)
        setName(c)
    elseif type(host)=="table" and host.Type == "tcp" then
        c.connection = host
        c.connection:enableBinaryMode()
        c.type = "client"
        c.connection.node = c
        c.connection.OnDataRecieved(self.ClientCode)
        c.name = "MASTER_NODE"
    elseif type(host) == "string" and type(port)=="number" then
        c.connection = net:newTCPClient(host, port)
        c.connection:enableBinaryMode()
        c.type = "client"
        c.connection.node = c
        c.connection.OnDataRecieved(self.ClientCode)
        c.name = "MASTER_NODE"
    else
        error("Invalid arguments!")
    end
    return c
end
function node:ping()
    if self.type ~= "client" then return end
    self:send("!PING!")
    return {pong=self.connection.OnDataRecieved}
end
function node:send(data)
    if self.type ~= "client" then return end
    self.connection:send(data)
end
return node