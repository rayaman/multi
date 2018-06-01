local binNum=require("bin.numbers.BigNum")
local infinabits={}
infinabits.data=''
infinabits.t='infinabits'
infinabits.Type='infinabits'
infinabits.__index = infinabits
infinabits.__tostring=function(self) return self.data end
infinabits.__len=function(self) return (#self.data)/8 end
local floor,insert = math.floor, table.insert
function basen(n,b)
    n=BigNum.new(n)
    if not b or b == 10 then return tostring(n) end
    local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local t = {}
    local sign = ""
    if n < BigNum.new(0) then
        sign = "-"
    n = -n
    end
    repeat
        local d = tonumber(tostring(n % b)) + 1
        n = n / b
        insert(t, 1, digits:sub(d,d))
    until n == BigNum.new(0)
    return sign .. table.concat(t,"")
end
function base2to10(num)
	local n=BigNum.new(0)
	for i = #num-1,0,-1 do
		nn=BigNum.new(num:sub(i+1,i+1))*(BigNum.new(2)^((#num-i)-1))
		n=n+nn
	end
	return n
end
function infinabits.newBitBuffer(n)
	-- WIP
end
function infinabits.newConverter(bitsIn,bitsOut)
	local c={}
	-- WIP
end
infinabits.ref={}
function infinabits.newByte(d)-- WIP
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
				return infinabits.ref[self.data][k]
			end
		end
	end
	c.__tostring=function(self)
		return infinabits.ref[tostring(self.data)]
	end
	setmetatable(c,c)
	return c
end
function infinabits.newByteArray(s)-- WIP
	local c={}
	if type(s)~="string" then
		error("Must be a string type or bin/buffer type")
	elseif type(s)=="table" then
		if s.t=="sink" or s.t=="buffer" or s.t=="bin" then
			local data=s:getData()
			for i=1,#data do
				c[#c+1]=infinabits.newByte(data:sub(i,i))
			end
		else
			error("Must be a string type or bin/buffer type")
		end
	else
		for i=1,#s do
			c[#c+1]=infinabits.newByte(s:sub(i,i))
		end
	end
	return c
end
function infinabits.new(n,binary)
	local temp={}
	temp.t="infinabits"
	temp.Type="infinabits"
	if type(n)=="string" then
		if binary then
			temp.data=n:match("[10]+")
		else
			local t={}
			for i=#n,1,-1 do
				table.insert(t,infinabits:conv(string.byte(n,i)))
			end
			temp.data=table.concat(t)
		end
	elseif type(n)=="number" or type(n)=="table" then
		temp.data=basen(tostring(n),2)
	end
	if #temp.data%8~=0 then
		temp.data=string.rep('0',8-#temp.data%8)..temp.data
	end
	setmetatable(temp, infinabits)
	return temp
end
for i=0,255 do
	local d=infinabits.new(i).data
	infinabits.ref[i]={d:match("(%d)(%d)(%d)(%d)(%d)(%d)(%d)(%d)")}
	infinabits.ref[tostring(i)]=d
	infinabits.ref[d]=i
	infinabits.ref["\255"..string.char(i)]=d
end
function infinabits.numToBytes(n,fit,func)
	local num=string.reverse(infinabits.new(BigNum.new(n)):toSbytes())
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
function infinabits.numToBytes(n,fit,fmt,func)
	if fmt=="%e" then
		local num=string.reverse(infinabits.new(BigNum.new(n)):toSbytes())
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
				return num
			else
				return string.rep("\0",fit-#num)..num
			end
		else
			return num
		end

	else
		local num=string.reverse(infinabits.new(BigNum.new(n)):toSbytes())
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
end
function infinabits:conv(n)
	local tab={}
	local one=BigNum.new(1)
	local n=BigNum.new(n)
	while n>=one do
		table.insert(tab,tonumber(tostring(n%2)))
		n=n/2
	end
	local str=string.reverse(table.concat(tab))
	if #str%8~=0 or #str==0 then
		str=string.rep('0',8-#str%8)..str
	end
	return str
end
function infinabits:tonumber(s)
	if s==0 then
		return tonumber(self.data,2)
	end
	s=s or 1
	return tonumber(tostring(base2to10(string.sub(self.data,(8*(s-1))+1,8*s)))) or error('Bounds!')
end
function infinabits:isover()
	return #self.data>8
end
function infinabits:flipbits()
	tab={}
	local s=self.data
	s=s:gsub("1","_")
	s=s:gsub("0","1")
	s=s:gsub("_","0")
	self.data=s
end
function infinabits:tobytes()
	local tab={}
	for i=self:getbytes(),1,-1 do
		table.insert(tab,string.char(self:tonumber(i)))
	end
	return bin.new(table.concat(tab))
end
function infinabits:toSbytes()
	local tab={}
	for i=self:getbytes(),1,-1 do
		table.insert(tab,string.char(self:tonumber(i)))
	end
	return table.concat(tab)
end
function infinabits:getBin()
	return self.data
end
function infinabits:getbytes()
	return #self.data/8
end
return infinabits
