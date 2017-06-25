if table.unpack then
	unpack=table.unpack
end
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end
function table.merge(t1, t2)
	t1,t2= t1 or {},t2 or {}
    for k,v in pairs(t2) do
    	if type(v) == "table" then
    		if type(t1[k] or false) == "table" then
    			table.merge(t1[k] or {}, t2[k] or {})
    		else
    			t1[k] = v
    		end
    	else
    		t1[k] = v
    	end
    end
    return t1
end
Library={}
function Library.optimize(func)
	local test=Library.convert(func)
	rawset(test,"link",{})
	rawset(test,"last","")
	rawset(test,"org",func)
	test:inject(function(...)
		rawset(test,"last",table.tostring({...}))
		if test.link[test.last]~=nil then
			return Library.forceReturn(unpack(test.link[test.last]))
		end
		return {...}
	end,1)
	test:inject(function(...)
		test.link[test.last]={test.org(...)}
		return test.org(...)
	end)
	return test
end
function Library.forceReturn(...)
	return {[0]="\1\7\6\3\2\99\125",...}
end
function Library.inject(lib,dat,arg)
	if type(lib)=="table" then
		if type(dat)=="table" then
			table.merge(lib,dat)
		elseif type(dat)=="string" then
			if lib.Version and dat:match("(%d-)%.(%d-)%.(%d-)") then
				lib.Version={dat:match("(%d+)%.(%d+)%.(%d+)")}
			elseif dat=="meta" and type(arg)=="table" then
				local _mt=getmetatable(lib) or {}
				local mt={}
				table.merge(mt,arg)
				table.merge(_mt,mt)
				setmetatable(lib,_mt)
			elseif dat=="compat" then
				lib["getVersion"]=function(self) return self.Version[1].."."..self.Version[2].."."..self.Version[3] end
				if not lib.Version then
					lib.Version={1,0,0}
				end
			elseif dat=="inhert" then
				if not(lib["!%"..arg.."%!"]) then print("Wrong Password!!") return end
				lib["!%"..arg.."%!"].__index=lib["!!%"..arg.."%!!"]
			end
		elseif type(dat)=="function" then
			for i,v in pairs(lib) do
				dat(lib,i,v)
			end
		end
	elseif type(lib)=="function" or type(lib)=="userdata" then
		if lib==unpack then
			print("function unpack cannot yet be injected!")
			return unpack
		elseif lib==pairs then
			print("function pairs cannot yet be injected!")
			return lib
		elseif lib==ipairs then
			print("function ipairs cannot yet be injected!")
			return lib
		elseif lib==type then
			print("function type cannot yet be injected!")
			return lib
		end
		temp={}
		local mt={
			__call=function(t,...)
				local consume,MainRet,init={},{},{...}
				local tt={}
				for i=1,#t.__Link do
					tt={}
					if t.__Link[i]==t.__Main then
						if #consume~=0 then
							MainRet={t.__Link[i](unpack(consume))}
						else
							MainRet={t.__Link[i](unpack(init))}
						end
					else
						if i==1 then
							consume=(t.__Link[i](unpack(init)))
						else
							if type(MainRet)=="table" then
								table.merge(tt,MainRet)
							end
							if type(consume)=="table" then
								table.merge(tt,consume)
							end
							consume={t.__Link[i](unpack(tt))}
						end
						if i==#t.__Link then
							return unpack(consume)
						end
						if consume then if consume[0]=="\1\7\6\3\2\99\125" then consume[0]=nil return unpack(consume) end end
					end
				end
				if type(MainRet)=="table" then
					table.merge(tt,MainRet)
				end
				if type(consume)=="table" then
					table.merge(tt,consume)
				end
				return unpack(tt)
			end,
		}
		temp.__Link={lib}
		temp.__Main=lib
		temp.__self=temp
		function temp:inject(func,i)
			if i then
				table.insert(self.__Link,i,func)
			else
				table.insert(self.__Link,func)
			end
		end
		function temp:consume(func)
			for i=1,#self.__Link do
				if self.__Link[i]==self.__Main then
					self.__Link[i]=func
					self.__self.__Main=func
					return true
				end
			end
			return false
		end
		setmetatable(temp,mt)
		Library.protect(temp,"lolz")
		return temp
	else
		return "arg1 must be a table or a function"
	end
end
function Library.parse(lib)
	for i,v in pairs(lib) do
		print(i,v)
	end
end
function Library.protect(lib,pass)
	pass=pass or "*"
	local mt={}
	local test={
		__index = lib,
		__newindex = function(tab, key, value)
			local t,b=key:find(tab["!%"..pass.."%!"].__pass,1,true)
			if t then
				local _k=key:sub(b+1)
				rawset(tab,_k,value)
			else
				error("Cannot alter a protected library!")
			end
		end,
		__metatable = false,
		__pass=pass or "*"
	}
	local _mt=getmetatable(lib) or {}
	table.merge(mt,_mt)
	table.merge(mt,test)
	lib["!%"..pass.."%!"]=test
	lib["!!%"..pass.."%!!"]=lib
	local temp=setmetatable({},mt)
	for i,v in pairs(_G) do
		if v==lib then
			_G[i]=temp
			Library(function(link)
				link[i]=v
			end)
		end
	end
end
function Library.unprotect(lib,pass)
	if not(lib["!%"..pass.."%!"]) then print("Wrong Password or Library is not Protected!") return end
	if lib["!%"..pass.."%!"].__pass==pass then
		lib["!%"..pass.."%!"].__newindex=lib["!!%"..pass.."%!!"]
		lib["!%"..pass.."%!"].__index=nil
		lib["!%"..pass.."%!"].__newindex=nil
		lib["!%"..pass.."%!"].__metatable = true
		setmetatable(lib["!!%"..pass.."%!!"],lib["!%"..pass.."%!"])
		for i,v in pairs(_G) do
			if v==lib then
				_G[i]=lib["!!%"..pass.."%!!"]
			end
		end
		lib["!!%"..pass.."%!!"]["!%"..pass.."%!"]=nil
		lib["!!%"..pass.."%!!"]["!!%"..pass.."%!!"]=nil
	else
		print("Wrong Password!!!")
	end
end
function Library.addPoll(lib,polldata,ref)
	lib.__polldata={}
	Library.inject(lib.__polldata,polldata)
	if type(ref)=="table" then
		Library.inject(ref,"meta",{__newindex=function(t,k,v)
			t[k].__polldata=polldata
		end})
	end
end
function Library.newPollData(t)
	local temp={}
	temp.__onPolled=function() end
	temp.__pollData=false
	temp.__advDisc=""
	temp.__pollcalls=-1 -- infinte
	for i,v in pairs(t) do
		if type(v)=="string" then
			temp.__advDisc=v
		elseif type(v)=="number" then
			temp.__pollcalls=v
		elseif type(v)=="table" then
			temp[v[1]]=v[2]
		elseif type(v)=="function" then
			temp.__onPolled=v
		elseif type(v)=="boolean" then
			temp.__pollData=v
		else
			temp.__userdata=v
		end
	end
	return temp
end
function Library.convert(...)
	local temp,rets={...},{}
	for i=1,#temp do
		if type(temp[i])=="function" then
			table.insert(rets,Library.inject(temp[i]))
		else
			error("Takes only functions and returns in order from functions given. arg # "..i.." is not a function!!! It is a "..type(temp[i]))
		end
	end
	return unpack(rets)
end
function Library.convertIn(...)
	local temp,list={...},{}
	for i=1,#temp do
		if type(temp[i])=="table" then
			for k,v in pairs(temp[i]) do
				if type(v)=="function" then
					temp[i][k]=Library.inject(temp[i][k])
				end
			end
		else
			error("Takes only tables! Arg "..i.." isn't it is a "..type(temp[i]))
		end
	end
end
function Library.newInjectedFunction()
	return Library.convert(function(...) return unpack{...} end)
end
function Library.capulate(lib)
	Library.inject(lib,"meta",{
		__index=function(t,k,v)
			for i,_v in pairs(t) do
				if k:lower()==i:lower() then
					return t[i]
				end
			end
		end,
		__newindex=function(t,k,v)
			rawset(t,k:lower(),v)
		end
	})
end
local link={MainLibrary=Library}
Library.inject(Library,"meta",{
	__Link=link,
	__call=function(self,func) func(link) end,
})
--Library.protect(Library,"N@#P!KLkk1(93320")
