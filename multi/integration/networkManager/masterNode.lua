--[[
MIT License

Copyright (c) 2020 Ryan Ward

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
local multi, thread = require("multi"):init()
local cmd = require("multi.integration.networkManager.cmds")
local node = require("multi.integration.networkManager.node")
local net = require("net")
local bin = require("bin")
local master = {}
master.__index = master
function master:addNode(ip,port)
    return node:new(ip,port)
end
function master:getNodesFromBroadcast()
    net:newCastedClients("NODE_.+")
    net.OnCastedClientInfo(function(client, n, ip, port)
        self.nodes[n] = node:new(client)
    end)
end
function master:getNodesFromManager(ip,port)
    local mn = self.nodes
    if not self.manager then
        self.manager = net:newTCPClient(ip,port)
        if not self.manager then
            error("Unable to connect to the node Manager! Is it running? Perhaps the hostname or port is incorrect!")
        end
    end
    self.manager.OnDataRecieved(function(self,data,client)
        local cmd = data:match("!(.+)!")
        data = data:gsub("!"..cmd.."!","")
        if cmd == "NODE" then
            local n,h,p = data:match("(.-)|(.-)|(.+)")
            mn[n] = node:new(h,tonumber(p))
        end
    end)
    self.manager:send("!NODES!")
end
function master:setDefaultNode(nodeName)
    if self:nodeExists(nodeName) then
        self.defaultNode = nodeName
    end
end
function master:getRandomNode()
    local t = {}
    for i,v in pairs(self.nodes) do t[#t+1] = i end
    return t[math.random(1,#t)]
end
local netID = 0
function master:newNetworkThread(nodeName,func,...)
    local args = {...}
    local dat = bin.new()
    local ret
    local nID = netID
    local conn = multi:newConnection()
    multi:newThread(function()
        dat:addBlock{
            args = args,
            func = func,
            id = netID
        }
        netID = netID + 1
        if type(nodeName) == "function" then
            func = nodeName
            nodeName = self.defaultNode or self:getRandomNode()
            if not func then
                error("You must provide a function!")
            end
        end
        self:sendTo(nodeName,"!N_THREAD!"..dat.data)
        self.OnDataReturned(function(rets)
            if rets.ID == nID then
                conn:Fire(unpack(rets.rets))
            end
        end)
    end)
    return conn
end
function master:newNetworkChannel(nodeName)
    --
end
function master:sendTo(nodeName,data)
    self:queue("send",nodeName,data)
end
function master:demandNodeExistance(nodeName)
    if self.nodes[nodeName] then
        return multi.hold(self.nodes[nodeName]:ping().pong)
    else
        return false
    end
end
function master:queue(c,...)
    table.insert(self._queue,{c,{...}})
end
function multi:newMasterNode(cd)
    local c = {}
    setmetatable(c, master)
    c.OnNodeDiscovered = multi:newConnection()
    c.OnNodeRemoved = multi:newConnection()
    c.OnDataRecieved = multi:newConnection()
    c.OnDataReturned = multi:newConnection()
    c.defaultNode = ""
    c.nodes = {}
    setmetatable(c.nodes,
        {__newindex = function(t,k,v)
            rawset(t,k,v)
            v.master = c
            c.OnNodeDiscovered:Fire(k,v)
        end})
    c._queue = {}
    if cd then
        if cd.nodeHost then
            cd.nodePort = cd.nodePort or cmd.defaultPort
            local n,no = c:addNode(cd.nodeHost,cd.nodePort)
            if n then
                c.nodes[n] = no
            end
        elseif cd.managerHost then
            cd.managerPort = cd.managerPort or cmd.defaultManagerPort
            c:getNodesFromManager(cd.managerHost,cd.managerPort)
        else
            c:getNodesFromBroadcast()
        end
    else
        c:getNodesFromBroadcast()
    end
    multi:newThread("CMDQueueProcessor",function()
        while true do
            thread.skip(128)
            local data = table.remove(c._queue,1)
            if data then
                local cmd = data[1]
                if cmd == "send" then
                    local nodeName = data[2][1]
                    local dat = data[2][2]
                    c.nodes[nodeName]:send(dat)
                end
            end
        end
    end):OnError(function(...)
        print(...)
    end)
    return c
end