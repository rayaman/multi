require("love.data")
local utils = {}
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

function utils.pack(tbl, seen)
    if type(tbl) == "function" then return {["__$FUNC$__"] = love.data.newByteData(string.dump(tbl))} end
    if type(tbl) ~= "table" then return tbl end
    local seen = seen or {}
    local result = {}
    result.__isPacked = true
    for i,v in pairs(tbl) do
        if seen[v] then
            result[i] = v
        elseif t(v) == "table" then
            seen[v] = true
            result[i] = utils.pack(v, seen)
        elseif t(v) == "function" then
            result["$F"..i] = love.data.newByteData(string.dump(v))
        elseif t{v} == "userdata" then
            result[i] = "userdata"
        else -- Handle what we need to and pass the rest along as a value
            result[i] = v
        end
    end
    return result
end

function utils.unpack(tbl)
    if not tbl then return nil end
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
            utils.unpack(v)
        end
    end
    tbl.__isPacked = nil
    return tbl
end

return utils