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