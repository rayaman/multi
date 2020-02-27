package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
-- local sterilizer = require("multi.integration.sterilization")
multi,thread = require("multi"):init()
test = {}
test.temp = {}
test.temp.hello = multi:newAlarm(3)
local function inList(t,o)
    for i,v in pairs(t) do
        if v==o then
            return v
        end
    end
end
local function convertFunc(func)
    local c = {}
    c.func = func
    c.__call = function(self,...)
        if self.called then return unpack(self.rets) end
        self.rets = {self.func(...)}
        self.called = true
        return unpack(self.rets)
    end
    setmetatable(c,c)
    return c
end
function getPath(tbl, obj, conn, indent, loop, path)
    conn = convertFunc(conn)
    if not indent then indent = 0 end
    if not loop then loop = {} end
    if not path then path = {"\0"} end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            if not inList(loop,v) and type(k)~="number" then
                table.insert(loop,v)
                table.insert(path,k)
                getPath(v, obj, conn, indent + 1, loop, path)
                table.remove(path)
            end
        end
        if v==obj then
            if type(k)=="number" then return end
            local str = table.concat(path,".").."."..k
            str = str:reverse()
            conn(str:sub(1,(str:find("\0"))-2):reverse())
            return
        end
    end
    --conn(nil,"Path not found")
end
local hmm = test.temp.hello
getPath(_G, hmm, function(path)
    print(path)
end)