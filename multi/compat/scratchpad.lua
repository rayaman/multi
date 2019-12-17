--local test = love.newByteData(string.rep("\0",16)
local ffi = require("ffi")
local scratchpad = {}
local mt = {
    __index = function(t, k)
        if type(k)=="string" then
            local a, b = k:match("(%d+):(%d+)")
            return t:read(tonumber(a),tonumber(b))
        elseif type(k)=="number" then
            return t:read(k,1)
        end
    end,
    __newindex = function(t, k, v)
        t:write(v,k)
    end
}
function scratchpad:new(data, size, rep)
    local c = {}
    local pad
    if type(data)=="string" then
        pad = love.data.newByteData(data or string.rep(rep or "\0",size or 16))
    elseif data:type()=="ByteData" then
        pad = bytedata
    end
    local ptr = ffi.cast("unsigned char*",pad:getPointer())
    local size = pad:getSize()
    function c:write(data, loc, len)
        if loc+(len or #data)>size then
            error("Attpemting to write data outside the bounds of data byte array!")
        end
        ffi.copy(ptr+(loc or 0), data, len or #data)
    end
    function c:read(loc, len)
        return ffi.string(ptr+(loc or 0), len or size)
    end
    setmetatable(c,mt)
    return c
end
return scratchpad