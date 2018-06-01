local __CURRENTVERSION=2
bin.registerBlock("t",function(SIZE_OR_NIL,ref)
	local header=ref:read(3)
	if not header:match("(LT.)") then error("Not a valid table struct!") end
	if bin.defualtBit.new(header:sub(3,3)):tonumber(1)>__CURRENTVERSION then error("Incompatible Version of LuaTable!") end
	local len=ref:getBlock("n",4) -- hehe lets make life easier
	local tab={}
	local ind
	local n=0
	while true do
		local _dat=ref:read(2)
		if _dat==nil then break end
		local it,dt=_dat:match("(.)(.)")
		n=n+2
		if it=="N" then -- get the index stuff out of the way first
			ind=ref:getBlock("n",4)
			n=n+4
		else
			indL=ref:getBlock("n",1)
			n=n+1+indL
			ind=ref:read(indL)
		end
		if dt=="N" then
			tab[ind]=ref:getBlock("d")
			n=n+8
		elseif dt=="I" then
			tab[ind]=math.huge
			ref:getBlock("n",4)
			n=n+4
		elseif dt=="i" then
			tab[ind]=-math.huge
			ref:getBlock("n",4)
			n=n+4
		elseif dt=="S" then
			local nn=ref:getBlock("n",4)
			tab[ind]=ref:read(nn)
			n=n+4+nn
		elseif dt=="B" then
			tab[ind]=({["\255"]=true,["\0"]=false})[ref:read(1)]
			n=n+1
		elseif dt=="F" then
			local nn=ref:getBlock("n",4)
			tab[ind]=loadstring(ref:read(nn))
			n=n+4+nn
		elseif dt=="T" then
			local cur=ref:getSeek()
			local size=ref:getBlock("n",4)
			ref:setSeek(cur)
			ref:read(4)
			if size==7 then
				tab[ind]={}
				ref:read(7)
				n=n+11
			else
				local data=bin.new(ref:read(size))
				local dat=data:getBlock("t")
				if dat.__RECURSIVE then
					tab[ind]=tab
				else
					tab[ind]=dat
				end
				n=n+data:getSize()+4
			end
		end
		if n==len then break end
	end
	return bin.resolveType(tab)
end,function(d,fit,fmt,self,rec,tabsaw)
	-- INGORE FIT WE ARE CREATING A STRUCT!!!
	-- fmt will apply to all numbers
	local __rem=nil
	if not tabsaw then rem=true end
	local tabsaw=tabsaw or {}
	if rem then
		table.insert(tabsaw,d)
	end
	local bData={}
	for i,v in pairs(d) do -- this is for tables, all but userdata is fine. Depending on where you are using lua functions may or may not work
		local tp=type(v):sub(1,1):upper() -- uppercase of datatype
		if type(i)=="number" then -- Lets handle indexies
			if v==math.huge then
				tp="I"
				v=0
			elseif v==-math.huge then
				tp="i"
				v=0
			end
			table.insert(bData,"N"..tp..bin.defualtBit.numToBytes(i,4)) -- number index?
		elseif type(i)=="string" then
			if #i>255 then error("A string index cannot be larger than 255 bytes!") end
			table.insert(bData,"S"..tp..bin.defualtBit.numToBytes(#i,1)..i) -- string index?
		else
			error("Only numbers and strings can be a table index!") -- throw error?
		end
		if type(v)=="number" then
			-- How do we handle number data
			local temp=bin.new()
			temp:addBlock(v,nil,"d")
			table.insert(bData,temp.data)
		elseif type(v)=="string" then
			-- Lets work on strings
			table.insert(bData,bin.defualtBit.numToBytes(#v,4)) -- add length of string
			table.insert(bData,v) -- add string
		elseif type(v)=="boolean" then -- bools are easy :D
			table.insert(bData,({[true]="\255",[false]="\0"})[v])
		elseif type(v)=="function" then -- should we allow this? why not...
			local dump=string.dump(v)
			table.insert(bData,bin.defualtBit.numToBytes(#dump,4)) -- add length of dumped string
			table.insert(bData,dump) -- add it
		elseif type(v)=="table" then -- tables...
			if tabsaw[1]==v then
				v={__RECURSIVE=i}
			else
				tabsaw[i]=v
			end
			local data=rec(v,nil,"t",self,rec,tabsaw)
			table.insert(bData,bin.defualtBit.numToBytes(#data,4)) -- add length of string
			table.insert(bData,data) -- add string
		end
	end
	local data=table.concat(bData)
	return "LT"..string.char(__CURRENTVERSION)..bin.defualtBit.numToBytes(#data,4)..data
end)
bin.registerBlock("b",function(SIZE_OR_NIL,ref)
	return ({["\255"]=true,["\0"]=false})[ref:read(1)]
end,function(d)
	return ({[true]="\255",[false]="\0"})[d]
end)
bin.registerBlock("f",function(SIZE_OR_NIL,ref)
	local nn=ref:getBlock("n",4)
	return loadstring(ref:read(nn))
end,function(d)
	local dump=string.dump(d)
	return bin.defualtBit.numToBytes(#dump,4)..dump
end)
bin.registerBlock("d",function(SIZE_OR_NIL,ref)
	local w,p=ref:getBlock("n",4),ref:getBlock("n",4)
	p=tonumber("0."..tostring(p))
	return w+p
end,function(d,fit,fmt,self,rec,tabsaw)
	local w,p = toFraction(d)
	local temp=bin.new()
	temp:addBlock(w,4)
	temp:addBlock(p,4)
	return temp.data
end)