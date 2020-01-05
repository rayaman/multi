local multi, thread = require("multi"):init()
local cmd = require("multi.integration.networkManager.cmds")
local net = require("net")
local bin = require("bin")
local nodes = { -- Testing stuff
    
}
function multi:newNodeManager(port)
    print("Running node manager on port: "..(port or cmd.defaultManagerPort))
    local server = net:newTCPServer(port or cmd.defaultManagerPort)
    server.OnDataRecieved(function(serv, data, client)
        local cmd = data:match("!(.+)!")
        data = data:gsub("!"..cmd.."!","")
        if cmd == "NODES" then 
            for i,v in ipairs(nodes) do
                -- Sample data
                serv:send(client, "!NODE!".. v[1].."|"..v[2].."|"..v[3])
            end
        elseif cmd == "REG_NODE" then
            local name, ip, port = data:match("(.-)|(.-)|(.+)")
            table.insert(nodes,{name,ip,port})
            print("Registering Node:",name, ip, port)
        end
    end)
end