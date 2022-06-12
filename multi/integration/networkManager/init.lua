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
local multi, thread = require("multi"):init()
local net = require("net")
--local bin = require("bin")
local char = string.char
local byte = string.byte
bin.setBitsInterface(infinabits)
--[[
--[=[ Pre reqs:
- Network contains nodes
- Network can broadcast/has nodemanager/ is simple and can be scanned

Outline:
- multi:newMasterNode(connectionDetails)
--  master:setDefaultNode(nodeName) -- Set default node
--  master:newNetworkThread(nodeName,func,...) -- Thread is ran on a random node or the default one if set if nodeName is set to nil
--  master:newNetworkChannel(nodeName)
--  master:sendTo(nodeName,data)
- multi:newNode(connectionDetails)
- multi:newNodeManager(connectionDetails) -- This will be incharge of a lot of data handling
]=]

local nGLOBAL, nTHREAD = require("multi.integration.networkManager"):init()
local master = multi:newMasterNode()
master:newNetworkThread("simpleNode",function(a,b,c)
    print(a,b,c)
end,1,2,3)  
]]

-- The init file should provide the structure that all the other modules build off of
return {
    init = function()
        --
    end
}