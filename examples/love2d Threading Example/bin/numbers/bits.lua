local bits={}
bits.data=''
bits.t='bits'
bits.Type='bits'
bits.__index = bits
bits.__tostring=function(self) return self.data end
bits.__len=function(self) return (#self.data)/8 end
local floor,insert = math.floor, table.insert
function bits.newBitBuffer(n)
	--
end
function bits.newConverter(bitsIn,bitsOut)
	local c={}
	--
end
function basen(n,b)
    if not b or b == 10 then return tostring(n) end
    local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local t = {}
    local sign = ""
    if n < 0 then
        sign = "-"
    n = -n
    end
    repeat
        local d = n % b + 1
        n = n / b
        insert(t, 1, digits:sub(d,d))
    until n == 0
    return sign .. table.concat(t,"")
end
bits.ref={}
function bits.newByte(d)
	local c={}
	if type(d)=="string" then
		if #d>1 or #d<1 then
			error("A byte must be one character!")
		else
			c.data=string.byte(d)
		end
	elseif type(d)=="number" then
		if d>255 or d<0 then
			error("A byte must be between 0 and 255!")
		else
			c.data=d
		end
	else
		error("cannot use type "..type(d).." as an argument! Takes only strings or numbers!")
	end
	c.__index=function(self,k)
		if k>=0 and k<9 then
			if self.data==0 then
				return 0
			elseif self.data==255 then
				return 1
			else
				return bits.ref[self.data][k]
			end
		end
	end
	c.__tostring=function(self)
		return bits.ref[tostring(self.data)]
	end
	setmetatable(c,c)
	return c
end
function bits.newByteArray(s)
	local c={}
	if type(s)~="string" then
		error("Must be a string type or bin/buffer type")
	elseif type(s)=="table" then
		if s.t=="sink" or s.t=="buffer" or s.t=="bin" then
			local data=s:getData()
			for i=1,#data do
				c[#c+1]=bits.newByte(data:sub(i,i))
			end
		else
			error("Must be a string type or bin/buffer type")
		end
	else
		for i=1,#s do
			c[#c+1]=bits.newByte(s:sub(i,i))
		end
	end
	return c
end
function bits.new(n,binary)
	local temp={}
	temp.t="bits"
	temp.Type="bits"
	if type(n)=="string" then
		if binary then
			temp.data=n:match("[10]+")
		else
			local t={}
			for i=#n,1,-1 do
				table.insert(t,bits:conv(string.byte(n,i)))
			end
			temp.data=table.concat(t)
		end
	elseif type(n)=="number" or type(n)=="table" then
		temp.data=basen(n,2)
	end
	if #temp.data%8~=0 then
		temp.data=string.rep('0',8-#temp.data%8)..temp.data
	end
	setmetatable(temp, bits)
	return temp
end
for i=0,255 do
	local d=bits.new(i).data
	bits.ref[i]={d:match("(%d)(%d)(%d)(%d)(%d)(%d)(%d)(%d)")}
	bits.ref[tostring(i)]=d
	bits.ref[d]=i
	bits.ref["\255"..string.char(i)]=d
end
function bits.numToBytes(n,fit,func)
	local num=string.reverse(bits.new(n):toSbytes())
	local ref={["num"]=num,["fit"]=fit}
	if fit then
		if fit<#num then
			if func then
				print("Warning: attempting to store a number that takes up more space than allotted! Using provided method!")
				func(ref)
			else
				print("Warning: attempting to store a number that takes up more space than allotted!")
			end
			return ref.num:sub(1,ref.fit)
		elseif fit==#num then
			return string.reverse(num)
		else
			return string.reverse(string.rep("\0",fit-#num)..num)
		end
	else
		return string.reverse(num)
	end
end
function bits:conv(n)
	local tab={}
	while n>=1 do
		table.insert(tab,n%2)
		n=math.floor(n/2)
	end
	local str=string.reverse(table.concat(tab))
	if #str%8~=0 or #str==0 then
		str=string.rep('0',8-#str%8)..str
	end
	return str
end
function bits:tonumber(s,e)
	if s==0 then
		return tonumber(self.data,2)
	end
	s=s or 1
	return tonumber(string.sub(self.data,(8*(s-1))+1,8*s),2) or error('Bounds!')
end
function bits:isover()
	return #self.data>8
end
function bits:flipbits()
	tab={}
	for i=1,#self.data do
		if string.sub(self.data,i,i)=='1' then
			table.insert(tab,'0')
		else
			table.insert(tab,'1')
		end
	end
	self.data=table.concat(tab)
end
function bits:tobytes()
	local tab={}
	for i=self:getbytes(),1,-1 do
		table.insert(tab,string.char(self:tonumber(i)))
	end
	return bin.new(table.concat(tab))
end
function bits:toSbytes()
	local tab={}
	for i=self:getbytes(),1,-1 do
		table.insert(tab,string.char(self:tonumber(i)))
	end
	return table.concat(tab)
end
function bits:getBin()
	return self.data
end
function bits:getbytes()
	return #self.data/8
end
return bits
