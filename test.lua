package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
-- local sterilizer = require("multi.integration.sterilization")
multi,thread = require("multi"):init()
test = {}
test.temp = {}
test.temp.hello = multi:newAlarm(3)
function inList(t,o)
    for i,v in pairs(t) do
        if v==o then
            return v
        end
    end
end
function getPath(tbl, obj, conn, indent, loop, path)
    if not indent then indent = 0 end
    if not loop then loop = {} end
    if not path then path = {"_G"} end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        --print(k,v==obj)
        if type(v) == "table" then
            if not inList(loop,v) and type(k)~="number" then
                --print(formatting)
                table.insert(loop,v)
                table.insert(path,k)
                getPath(v, obj, conn, indent + 1, loop, path)
                table.remove(path)
            end
        end
        if v==obj then
            local str = table.concat(path,".").."."..k
            str = str:reverse()
            conn(str:sub(1,(str:find("G_"))+1):reverse())
        end
    end
end
getPath(_G, test.temp.hello.Act,function(path)
    print(path)
end)