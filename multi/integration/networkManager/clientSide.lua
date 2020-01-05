return function(self,data)
    local cmd,data = data:match("!(.-)!(.*)")
    if cmd == "PONG" then
        --
    elseif cmd == "CHANNEL" then
        --
    elseif cmd == "RETURNS" then
        local rets = bin.new(data):getBlock("t")
        self.node.master.OnDataReturned:Fire(rets)
    end
end