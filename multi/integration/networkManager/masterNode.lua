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
local net = require("net")
local bin = require("bin")
local master = {}
master.__index = master
function multi:newMasterNode(connectionDetails)
    local c = {}
    c.OnDataRecieved = multi:newConnection()
    c.defaultNode = ""
    c.nodes = {}
    if connectionDetails then
        -- We do what we do
    else
        -- Lets make assumptions
    end
    setmetatable(c, master)
    return c
end
function master:setDefaultNode(nodeName)
    -- Verify Node is active
    if self:nodeExists(nodeName) then
        self.defaultNode = nodeName
    end
end
function master:newNetworkThread(nodeName,func)
    --
end
function master:newNetworkChannel(nodeName)
    --
end
function master:sendTo(nodeName,data)
    if self:nodeExists(nodeName):wait() then
        print("It exists!")
    end
end
master.nodeExists = thread:newFunction(function(self,nodeName)
    if self.nodes[nodeName] then
        local wait = nodes[nodeName]:ping()
        local bool = thread.hold(function()
            return wait()
        end)
        return bool
    else
        return false
    end
end)