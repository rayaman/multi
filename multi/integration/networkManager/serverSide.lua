local bin, bits = require("bin").init()
return function(self,data,client)
    local cmd,data = data:match("!(.-)!(.*)")
    --print("SERVER",cmd,data)
    if cmd == "PING" then
        self:send(client,"!PONG!")
    elseif cmd == "N_THREAD" then
        local dat = bin.new(data)
        local t = dat:getBlock("t")
        local ret = bin.new()
        ret:addBlock{ID = t.id,rets = {t.func(unpack(t.args))}}
        self:send(client,"!RETURNS!"..ret:getData())
	elseif cmd == "CHANNEL" then
        local dat = bin.new(data):getBlock("t")
        
    end
end