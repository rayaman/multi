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