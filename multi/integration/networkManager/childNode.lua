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
local cmd = require("multi.integration.networkManager.cmds")
local node = require("multi.integration.networkManager.node")
local net = require("net")
local bin = require("bin")
local child = {}
child.__index = child
function multi:newChildNode(cd)
    local c = {}
    setmetatable(c,child)
    local name
    if cd then
        if cd.name then
            name = cd.name
        end
        c.node = node:new(cd.nodePort or cmd.defaultPort,nil,name)
        if cd.managerHost then
            cd.managerPort = cd.managerPort or cmd.defaultManagerPort
            c.node:registerWithManager(cd.managerHost,cd.managerPort)
        end
    end
    return c
end