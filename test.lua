package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
-- local sterilizer = require("multi.integration.sterilization")
multi,thread = require("multi"):init()
local function inList(t,o,n)
    local c = 1
    if not o["$__COUNTER__$"] then
        o["$__COUNTER__$"] = 1
    end
    if o["$__COUNTER__$"]==n then
        return o
    end
    for i,v in pairs(t) do
        if v==o then
            o["$__COUNTER__$"] = o["$__COUNTER__$"] + 1
            if o["$__COUNTER__$"]==n then
                return o
            end
        end
    end
end
local function initLoop(t,max)
    for i,v in pairs(t) do
        v["$__COUNTER__$"] = max
    end
    return t
end
function _getPath(tbl, obj, conn, loop, path, orig)
    local max = 100
    if not loop then loop = initLoop({package,_G,math,io,os,debug,string,table,coroutine},max) end
    if not path then path = {} end
    if not ref then ref = {} end
    for k, v in pairs(tbl) do
        if type(v) == "table" and type(k)~="number" and not inList(loop,v,max) then -- Only go this deep
            if v~=orig and k=="Parent" then
                --
            else
                --print(table.concat(path,".").."."..k)
                table.insert(ref,v)
                table.insert(loop,v)
                table.insert(path,k)
                if v==obj then
                    conn(table.concat(path,".").."."..k,ref)
                end
                _getPath(v, obj, conn, loop, path, orig)
                table.remove(path)
                table.remove(ref)
            end
        end
        if v==obj and orig[k] then
            conn(k,ref)
        elseif v==obj then
            if type(k)=="number" then return end
            local str = table.concat(path,".").."."..k
            conn(str,ref)
        end
    end
end
function getPath(tbl,obj)
    local instances = {}
    _getPath(tbl, obj, function(ins)
        table.insert(instances,ins)
    end,nil,nil,tbl)
    local min = math.huge
    local ins
    for i,v in pairs(instances) do
        if #v<min then
            ins = v
            min = #v
        end
    end
    return ins or false
end
test = {}
test.temp = {}
test.temp.hello = multi:newAlarm(3)
test.temp.yo = multi:newEvent()
local hmm = test.temp.hello
local hmm2 = test.temp.yo
local hmm3 = multi.DestroyedObj.t()
for i,v in pairs(hmm3) do
    print(i,v)
end
-- print(getPath(_G, hmm))
-- print(getPath(_G, hmm2)) -- Cannot index into multi because of __index
-- print(getPath(multi, hmm3))