local base64={}
local bs = { [0] =
   'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
   'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
   'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
   'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/',
}
local bsd=table.flip(bs)
local char=string.char
function base64.encode(s)
   local byte, rep, pad = string.byte, string.rep, 2 - ((#s-1) % 3)
   s = (s..rep('\0', pad)):gsub("...", function(cs)
      local a, b, c = byte(cs, 1, 3)
      return bs[bit.rshift(a,2)] .. bs[bit.bor(bit.lshift(bit.band(a,3),4),bit.rshift(b,4))] .. bs[bit.bor(bit.lshift(bit.band(b,15),2),bit.rshift(c,6))] .. bs[bit.band(c,63)]
   end)
   return s:sub(1, #s-pad) .. rep('=', pad)
end
function base64.decode(s)
	local s=s:match("["..s.."=]+")
	local p,cc=s:gsub("=","A")
	local r=""
	local n=0
	s=s:sub(1,#s-#p)..p
	for c = 1,#s,4 do
		n = bit.lshift(bsd[s:sub(c, c)], 18) + bit.lshift(bsd[s:sub(c+1, c+1)], 12) + bit.lshift(bsd[s:sub(c + 2, c + 2)], 6) + bsd[s:sub(c + 3, c + 3)]
		r = r .. char(bit.band(bit.arshift(n, 16), 0xFF)) .. char(bit.band(bit.arshift(n, 8), 0xFF)) .. char(bit.band(n, 0xFF))
	end
	return r:sub(1,-(cc+1))
end
return base64
