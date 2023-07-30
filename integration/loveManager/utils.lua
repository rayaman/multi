require("love.data")
local sutils = {}
local NIL = {Type="nil"}

--love.data.newByteData("\2"..serpent.dump({t,true},{safe = true}))

local ltype = function(v) return v:type() end
local t = function(value)
    local v = type(value)
    if v == "userdata" then
        local status, return_or_err = pcall(ltype, value)
        if status then return return_or_err else return "userdata" end
    else return v end
end

function sutils.pack(tbl, seen)
    if type(tbl) == "function" then return {["__$FUNC$__"] = love.data.newByteData(string.dump(tbl))} end
    if type(tbl) ~= "table" then return tbl end
    local seen = seen or {}
    local result = {}
    for i,v in pairs(tbl) do
        if seen[v] then
            result[i] = v
        elseif t(v) == "table" then
            seen[v] = true
            result[i] = sutils.pack(v, seen)
        elseif t(v) == "function" then
            result["$F"..i] = love.data.newByteData(string.dump(v))
        elseif t{v} == "userdata" then
            result[i] = tostring(v)
        else -- Handle what we need to and pass the rest along as a value
            result[i] = v
        end
    end
    return result
end

function sutils.unpack(tbl)
    if type(tbl) ~= "table" then return tbl end
    if tbl["__$FUNC$__"] then return loadstring(tbl["__$FUNC$__"]:getString()) end
    for i,v in pairs(tbl) do
        if type(i) == "string" and i:sub(1,2) == "$F" then
            local rawfunc = v:getString()
            v:release()
            tbl[i] = nil
            tbl[i:sub(3,-1)] = loadstring(rawfunc)
        end
        if type(v) == "table" then
            sutils.unpack(v)
        end
    end
    return tbl
end

return sutils