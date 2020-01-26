local bin, bits = require("bin").init()
return function(self,data,client)
    local cmd,data = data:match("!(.-)!(.*)")
    --print("SERVER",cmd,data)
    if cmd == "PING" then
        self:send(client,"!PONG!")
    elseif cmd == "N_THREAD" then
        print(1)
        local dat = bin.new(data)
        print(2)
        local t = dat:getBlock("t")
        print(3)
        local ret = bin.new()
        print(4)
        ret:addBlock{ID = t.id,rets = {t.func(unpack(t.args))}}
        print(5)
        print(client,"!RETURNS!"..ret:getData())
        self:send(client,"!RETURNS!"..ret:getData())
        print(6)
	elseif cmd == "CHANNEL" then
        local dat = bin.new(data):getBlock("t")
        
    end
end