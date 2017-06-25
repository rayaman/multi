function trim(s)
	return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end
parseManager={}
parseManager._VERSION={1,0,0}
dialogueManager=parseManager -- for backwards purposes
parseManager.OnExtendedBlock=multi:newConnection(true) -- true protects the module from crashes
parseManager.OnCustomSyntax=multi:newConnection(true) -- true protects the module from crashes
function string:split( inSplitPattern, outResults )
	if not outResults then
		outResults = {}
	end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	while theSplitStart do
		table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	end
	table.insert( outResults, string.sub( self, theStart ) )
	return outResults
end
function parseManager:debug(txt)
	if self.stats.debugging then
		self._methods:debug(txt)
	end
end
function parseManager.split(s,pat)
	local pat=pat or ","
	local res = {}
	local start = 1
	local state = 0
	local c = '.'
	local elem = ''
	for i = 1, #s do
		c = s:sub(i, i)
		if state == 0 or state == 3 then -- start state or space after comma
			if state == 3 and c == ' ' then
				state = 0 -- skipped the space after the comma
			else
				state = 0
				if c == '"' or c=="'" then
					state = 1
					elem = elem .. '"'
				elseif c=="[" then
					state = 1
					elem = elem .. '['
				elseif c == pat then
					res[#res + 1] = elem
					elem = ''
					state = 3 -- skip over the next space if present
				else
					elem = elem .. c
				end
			end
		elseif state == 1 then -- inside quotes
			if c == '"' or c=="'" then --quote detection could be done here
				state = 0
				elem = elem .. '"'
			elseif c=="]" then
				state = 0
				elem = elem .. ']'
			elseif c == '\\' then
				state = 2
			else
				elem = elem .. c
			end
		elseif state == 2 then -- after \ in string
			elem = elem .. c
			state = 1
		end
	end
	res[#res + 1] = elem
	return res
end
parseManager._chunks={}
parseManager._cblock={}
parseManager._cblockname=""
parseManager._pos=1
parseManager._labels={
	-- {chunkname,pos}
}
parseManager.stats={
	leaking=false,
	debugging=false,
	topdown=true,
	forseelabels=true,
}
parseManager._types={}
parseManager.__index=parseManager
parseManager._variables={__TYPE="ENV"}
parseManager.defualtENV=parseManager._variables
function parseManager:varExists(var)
	if var==nil or var=="nil" then return end
	if type(var)=="userdata" then return var end
	if tonumber(var) then
		return tonumber(var)
	end
	local aa,bb=var:match("(.-)%[\"(.-)\"%]")
	if aa and bb then
		return self.defualtENV[aa][bb]
	end
	if var:find('"') then
		return self:parseHeader(var:sub(2,-2),self.defualtENV)
	end
	if var:find("%[%]") then
		return {}
	end
	if var:sub(1,1)=="[" and var:sub(-1,-1)=="]" then
		local list=var:match("[(.+)]")
		if not list then
			self:pushError("Invalid List assignment!")
		end
		local t=list:split(",")
		local nlist={}
		local a=":)"
		for i=1,#t do
			a=self:varExists(t[i])
			if a then
				table.insert(nlist,a)
			end
		end
		return nlist
	end
	if var=="true" then
		return true
	elseif var=="false" then
		return false
	end
	local a,b=var:match("(.-)%[(.-)%]")
	if a and b then
		if type(self.defualtENV[a])=="table" then
			if b=="-1" then
				return self.defualtENV[a][#self.defualtENV[a]]
			elseif b=="#" then
				return self.defualtENV[a][math.random(1,#self.defualtENV[a])]
			else
				return self.defualtENV[a][tonumber(b) or self:varExists(b)]
			end
		end
		if type(self.defualtENV[var])=="table" then
			return self.defualtENV[var]
		end
	end
	return self.defualtENV[var] or var -- if all tests fail, just pass on the data for the function to manage
end
function parseManager:isList(var)
	local a,b=var:match("(.-)%[(.-)%]")
	if not a or b then return end
	if type(self.defualtENV[a])=="table" then
		if b=="-1" then
			return self.defualtENV[a][#self.defualtENV[a]]
		else
			return self.defualtENV[a][tonumber(b)]
		end
	end
	return
end
function parseManager:loadString(data)
	self:_load(bin.new(data),self)
end
parseManager.loadeddata={}
parseManager.envs={}
parseManager._methods={
	getLength=function(self,list)
		return #(self:varExists(list) or {})
	end,
	emptyList=function(self)
		return {}
	end,
	DEBUG=function(self,text)
		print(text)
	end,
	DIS=function(self,var)
		print(var)
	end,
	SEED=function(self,n)
		math.randomseed(tonumber(self:varExists(n) or n) or os.time())
	end,
	delElem=function(self,l,i)
		table.remove(l,i)
	end,
	addElem=function(self,l,d,i)
		table.insert(l,(i or -1),d)
		return l
	end,
	RANDOM=function(self,v1,v2)
		if v1 then
			return math.random(1,v1)
		elseif v1 or v2 then
			return math.random(tonumber(v1),tonumber(v2))
		else
			return math.random()
		end
	end,
	CALC=function(self,eq)
		return self:evaluate(eq)
	end,
	GOTOV=function(self,label)
		print(self:varExists(label))
		self._methods.GOTO(self,self:varExists(label))
	end,
	GOTO=function(self,label)
		label=label:gsub("-","")
		if label=="__LASTGOTO" then
			self:setBlock(self._labels.__LASTGOTO[1])
			self.pos=self._labels[label][2]
			return true
		end
		--search current block for a label
		if self.pos==nil then
			error("Attempt to load a non existing block from the host script!")
		end
		for i=self.pos,#self._cblock do
			local line=self._cblock[i]
			local labeltest=line:match("::(.-)::")
			if labeltest==label then
				self._labels["__LASTGOTO"]={self._cblockname,self.pos}
				self.pos=i
				return true
			end
		end
		--search for saved labels
		if self._labels[label] then
			self._labels["__LASTGOTO"]={self._cblockname,self.pos}
			self:setBlock(self._labels[label][1])
			self.pos=self._labels[label][2]
			return true
		end
		--search other blocks if enabled for labels
		if self.stats.forseelabels then
			for i,v in pairs(self._chunks) do
				local chunks=bin._lines(v[1])
				for p=1,#chunks do
					local line=chunks[p]
					local labeltest=line:match("::(.-)::")
					if labeltest==label then
						self._labels["__LASTGOTO"]={self._cblockname,self.pos}
						self:setBlock(i)
						self.pos=p-1
						return true
					end
				end
			end
		end
		if self.stats.forseelabels then
			if self._methods.GOTOV(self,label) then return end
		end
		self:pushError("Attempt to goto a non existing label! You can only access labels in the current scope! Or labels that the code has seen thus far! "..label.." does not exist as a label!")
	end,
	QUIT=function()
		os.exit()
	end,
	EXIT=function(self)
		self.pos=math.huge
	end,
	TYPE=function(self,val)
		return type(val)
	end,
	SAVE=function(self,filename)
		if trim(filename)=="" then filename="saveData.sav" end
		local t=bin.new()
		t:addBlock(self.defualtENV)
		t:addBlock(self._cblockname)
		t:addBlock(self.pos)
		t:addBlock(self._labels)
		t:tofile(filename)
	end,
	UNSAVE=function(self,filename)
		if trim(filename)=="" then filename="saveData.sav" end
		self.defualtENV={}
		os.remove(filename)
	end,
	RESTORE=function(self)
		if not(self.loadeddata.load) then self:pushError("A call to RESTORE without calling LOAD") end
		self.defualtENV=self.loadeddata:getBlock("t")
		self:setBlock(self.loadeddata:getBlock("s"))
		self.pos=self.loadeddata:getBlock("n")
		self._labels=self.loadeddata:getBlock("t")
	end,
	LOAD=function(self,filename)
		print(filename)
		if not filename then filename="saveData.sav" end
		if io.fileExists(filename) then
			self.loadeddata=bin.load(filename)
			return 1
		end
		return 0
	end,
	JUMP=function(self,to)
		self:setBlock(to)
	end,
	SKIP=function(self,n)
		self.pos=self.pos+tonumber(n)
	end,
	PRINT=function(self,text) print(text) end,
	TRIGGER=function(self,to)
		self:setBlock(to)
	end,
	COMPARE=function(self,t,v1,v2,trueto,falseto) -- if a blockname is __STAY then it will continue on
    if t=="=" or t=="==" then
			if v1==v2 then
				self:setBlock(trueto)
			else
				self:setBlock(falseto)
			end
		elseif t==">=" then
			if v1>=v2 then
				self:setBlock(trueto)
			else
				self:setBlock(falseto)
			end
		elseif t=="<=" then
			if v1<=v2 then
				self:setBlock(trueto)
			else
				self:setBlock(falseto)
			end
		elseif t==">" then
			if v1>v2 then
				self:setBlock(trueto)
			else
				self:setBlock(falseto)
			end
		elseif t=="<" then
			if v1<v2 then
				self:setBlock(trueto)
			else
				self:setBlock(falseto)
			end
		end
	end,
	getInput=function(self,msg)
		io.write((msg or ""))
		return io.read()
	end,
	debug=function(self,txt)
		-- if self.stats.debugging then
			print("DEBUG: "..txt)
		-- end
	end,
	ADD=function(self,val,n)
		return val+n
	end,
	SUB=function(self,val,n)
		return val-n
	end,
	MUL=function(self,val,n)
		return val*n
	end,
	DIV=function(self,val,n)
		return val/n
	end,
	MOD=function(self,val,n)
		return val%n
	end,
	["return"]=function(self,n)
		if type(n)~="number" then self:pushError("For now only numbers can be returned!") end
		self.defualtENV["ret-urn"]=n
	end,
	SYSTEMTIME=os.clock,
	STRFORMAT=string.format,
	error=function(self,msg)
		self:pushError(msg)
	end,
	setENV=function(self,env)
		self.defualtENV=env
	end,
	getENV=function(self,name)
		if name then
			return self._variables
		end
		return self.defualtENV
	end,
	createENV=function(self)
		local _env={__TYPE="ENV"}
		setmetatable(_env,{__index=self._variables})
		return _env
	end,
	setGlobal=function(self)
		self.defualtENV=self._variables
	end,
	setLocal=function(self)
		self.defualtENV=self._methods.createENV(self)
		return self.defualtENV
	end,
	stringSUB=function(self,str,a,b)
		return str:sub(a,b)
	end,
	stringFIND=function(self,str,pat)
		return str:find(pat)
	end,
	stringLEN=function(self,str)
		return #str
	end,
	stringLOWER=function(self,str)
		return str:lower()
	end,
	stringUPPER=function(self,str)
		return str:upper()
	end,
	stringREVERSE=function(self,str)
		return str:reverse()
	end,
	stringREP=function(self,str,n)
		return str:rep(n)
	end,
	stringReplace=function(self,str,rep)
		return str:gsub(rep)
	end,
	setVar=function(self,name,value)
		self.defualtENV[name]=value
	end,
}
function parseManager:setVariable(name,value)
	self.defualtENV[name]=value
end
function parseManager:setGlobalVariable(name,value)
	self._variables[name]=value
end
function parseManager:_load(filename,c)
	local file={}
	if love then
		file=bin.new((love.filesystem.read(filename)))
	elseif type(filename)=="table" then
		file=filename
	else
		file=bin.load(filename)
	end
	file:gsub("%-%-%[%[.-%]%]","\n")
	file:gsub('%b""',function(a) a=a:gsub("%-%-","\2") return a end)
	file:gsub("%b''",function(a) a=a:gsub("%-%-","\2") return a end)
	file:gsub("(%-%-.-)\n","\n")
	file:gsub("%-:.-:%-","\n")
	file:gsub('%b""',function(a) a=a:gsub(";","\1") return a end)
	file:gsub("%b''",function(a) a=a:gsub(";","\1") return a end)
	file:gsub(";\n","\n")
	file:gsub(";\r","\r")
	file:gsub(";","\n")
	file:gsub("\r\n","\n")
	file:gsub("\n\n","")
	file:gsub("\1",";")
	file:gsub("\2","--")
	for fn in file:gmatch("LOAD (.-)\n") do
		self:_load(fn,c)
	end
	for fn in file:gmatch("ENABLE (.-)\n") do
		self.stats[string.lower(fn)]=true
	end
	for fn in file:gmatch("USING (.-)\n") do
		require("parseManager."..fn)
		_G[fn]:InitSyntax(c,fn)
	end
	for fn in file:gmatch("DISABLE (.-)\n") do
		self.stats[string.lower(fn)]=false
	end
	file:fullTrim(true)
	for blockname,chunk in file:gmatch("%[(.-)[:.-]?%].-{(.-)}")  do
		if not c.firstblcok then c.firstblcok=blockname end
		if blockname:find(":") then
			local name,t=blockname:match("(.-):(.+)")
			c._chunks[name]={chunk,t,file=filename}
			if c.stats.leaking then
				if c.lastblock then
					c._chunks[c.lastblock]={c._chunks[c.lastblock][1],c._chunks[c.lastblock][2],next=name,file=filename}
				end
			end
			local rets=parseManager.OnExtendedBlock:Fire(c,name,t,chunk,filename)
			for i=1,#rets do
				if rets[i][1]==true then
					c._chunks[name]=nil
				end
			end
			if c._chunks[name] then
				c.lastblock=name
			end
		else
			c._chunks[blockname]={chunk,"ALL",file=filename}
			if c.stats.leaking then
				if c.lastblock then
					c._chunks[c.lastblock]={c._chunks[c.lastblock][1],c._chunks[c.lastblock][2],next=blockname,file=filename}
				end
			end
			c.lastblock=blockname
		end
	end
	return c
end
function parseManager:load(filename)
	local c={}
	setmetatable(c,parseManager)
	local file={}
	if love then
		file=bin.new((love.filesystem.read(filename)))
	elseif type(filename)=="table" then
		file=filename
	else
		file=bin.load(filename)
	end
	file:gsub("%-%-%[%[.-%]%]","\n")
	file:gsub('%b""',function(a) a=a:gsub("%-%-","\2") return a end)
	file:gsub("%b''",function(a) a=a:gsub("%-%-","\2") return a end)
	file:gsub("(%-%-.-)\n","\n")
	file:gsub("%-:.-:%-","\n")
	file:gsub('%b""',function(a) a=a:gsub(";","\1") return a end)
	file:gsub("%b''",function(a) a=a:gsub(";","\1") return a end)
	file:gsub(";\n","\n")
	file:gsub(";\r","\r")
	file:gsub(";","\n")
	file:gsub("\r\n","\n")
	file:gsub("\n\n","")
	file:gsub("\1",";")
	file:gsub("\2","--")
	file:fullTrim(true)
	for fn in file:gmatch("LOAD (.-)\n") do
		self:_load(fn,c)
	end
	local test=file:match("ENTRY (.-)\n")
	if test then
		c.entrypoint=test
	end
	for fn in file:gmatch("ENABLE (.-)\n") do
		self.stats[string.lower(fn)]=true
	end
	for fn in file:gmatch("USING (.-)\n") do
		require("parseManager."..fn)
		_G[fn]:InitSyntax(c,fn)
	end
	for fn in file:gmatch("DISABLE (.-)\n") do
		self.stats[string.lower(fn)]=false
	end
	for blockname,chunk in file:gmatch("%[(.-)[:.-]?%].-{(.-)}")  do
		if blockname:find(":") then
			local name,t=blockname:match("(.-):(.+)")
			if t=="struct" then
				local lines=bin._lines(chunk)
				self.defualtENV[name]={}
			else
				c._chunks[name]={chunk,t,file=filename}
				if c.stats.leaking then
					if c.lastblock then
						c._chunks[c.lastblock]={c._chunks[c.lastblock][1],c._chunks[c.lastblock][2],next=name,file=filename}
					end
				end
        local rets=parseManager.OnExtendedBlock:Fire(c,name,t,chunk,filename)
        for i=1,#rets do
			if rets[i][1]==true then
				c._chunks[name]=nil
			end
		end
        if c._chunks[name] then
          c.lastblock=name
        end
			end
		else
			c._chunks[blockname]={chunk,"ALL",file=filename}
			if c.stats.leaking then
				if c.lastblock then
					c._chunks[c.lastblock]={c._chunks[c.lastblock][1],c._chunks[c.lastblock][2],next=blockname,file=filename}
				end
			end
			c.lastblock=blockname
		end
		if not self.firstloadedblock then
			self.firstloadedblock=blockname
			fir=true
		end
	end
	setmetatable(c._variables,{__index=_G})
	parseManager.loaded=true
	return c
end
function parseManager:define(t)
	table.merge(self._methods,t)
end
function parseManager:hasCBlock()
	return #self._cblock~=0
end
function parseManager:combineTruths(t)
	--t={1,"a",0,"o",0}
	if #t==1 then
		return t[1]
	end
	local v=false
	for i=#t,1,-2 do
		if t[i-1] then
			if t[i-1]=="o" then
				v=(t[i] or t[i-2])
			elseif t[i-1]=="a" then
				v=(t[i] and t[i-2])
			else
				self:pushError("INVALID TRUTH TABLE!!!")
			end
			t[i-2]=v -- set the next index to the value
		end
	end
	return v
end
function parseManager:setBlock(chunk)
	if chunk:find("%-") then
		local label=chunk:match("%-(.-)%-")
		self._methods.GOTO(self,label)
		return
	end
	if chunk=="__STAY" then return end
	if chunk:sub(1,6)=="__SKIP" then local n=tonumber(chunk:sub(7,-1)) if n==-1 then self:pushError("-1 will put the skip command back on its self, creating an infinte pause! use -2 or less to go back 1 or more") return end self.pos=self.pos+n return end
	if not(self._chunks[chunk]) then self._methods.GOTO(self,chunk) return end
	local test=bin.new(self._chunks[chunk][1])
	test:fullTrim(true)
	if self._cblockname~="" then
		self.pos=0
	elseif self._cblockname==chunk then
		self.pos=-1
	else
		self.pos=1
	end
	self._cblockname=chunk
	self._cblock=bin._lines(test.data)
end
function parseManager:start(chunk,env)
	local chunk = self.entrypoint or chunk or self.firstblcok
	return self:next(chunk,nil,env)
end
--~ function parseManager:pushError(err)
--~ 	local file=self._chunks[self._cblockname].file
--~ 	local d={}
--~ 	if love then
--~ 		d=bin.new((love.filesystem.read(file)))
--~ 	else
--~ 		d=bin.load(file)
--~ 	end
--~ 	local t=d:lines()
--~ 	local pos=0
--~ 	local switch=false
--~ 	for i=1,#t do
--~ 		if t[i]:find("["..self._cblockname,1,true) then
--~ 			switch=true
--~ 		end
--~ 		if switch==true and bin._trim(t[i])==self._cblock[self.pos] then
--~ 			pos=i
--~ 			break
--~ 		end
--~ 	end
--~ 	print("In Block '"..self._cblockname.."' LIQ: '"..self._cblock[self.pos].."' Filename: "..file.." On line: "..pos..": "..err)
--~ 	io.read()
--~ 	os.exit()
--~ end
--~ function parseManager:pushError(err)
--~ 	print(err) -- print to the console
--~ 	local file=self._chunks[self._cblockname].file
--~ 	local d={}
--~ 	if love then
--~ 		print(file)
--~ 		d=bin.new((love.filesystem.read(file)))
--~ 	else
--~ 		d=bin.load(file)
--~ 	end
--~ 	local _d={}
--~ 	local t=d:lines()
--~ 	for i=1,#t do
--~ 		_d[i]=trim(t[i])
--~ 	end
--~ 	d=table.concat(_d,"\n")
--~ 	local pos=0
--~ 	local cc=d:match("%["..self._cblockname..".*%].*({.-})")
--~ 	cc=cc:gsub("{.-\n","")
--~ 	cc=cc:gsub((self._cblock[self.pos]:gsub("%%","%%%%"):gsub("%(","%%%("):gsub("%)","%%%)"):gsub("%[","%%%["):gsub("%]","%%%]"):gsub("%+","%%%+"):gsub("%-","%%%-"):gsub("%*","%%%*"):gsub("%.","%%%."):gsub("%$","%%%$"):gsub("%^","%%%^")).."(.+)","NOPE LOL")
--~ 	_,b=cc:gsub("^(%-%-.-)\n","\n")
--~ 	_,c=cc:gsub("%-:.-:%-","\n")
--~ 	e=b+c
--~ 	for i=1,#t do
--~ 		if t[i]:find("["..self._cblockname,1,true) then
--~ 			pos=i+self.pos
--~ 			break
--~ 		end
--~ 	end
--~ 	error("In Block '"..self._cblockname.."' LIQ: '"..self._cblock[self.pos].."' Filename: "..file.." On line: "..pos+e..": "..err)
--~ end
function dialogueManager:pushError(err)
	print(err) -- print to the console
	local file=self._chunks[self._cblockname].file
	local d={}
	if love then
		print(file)
		d=bin.new((love.filesystem.read(file)))
	elseif type(file)=="table" then
		d=file
	else
		d=bin.load(file)
	end
	local t=d:lines()
	local pos=0
	--Sigh... comments are still a pain to deal with...
	local cc=d:match("%["..self._cblockname.."[:.-]?%].-({.-})")
	cc=cc:gsub("{.-\n","")
	cc=cc:gsub((self._cblock[self.pos]:gsub("%%","%%%%"):gsub("%(","%%%("):gsub("%)","%%%)"):gsub("%[","%%%["):gsub("%]","%%%]"):gsub("%+","%%%+"):gsub("%-","%%%-"):gsub("%*","%%%*"):gsub("%.","%%%."):gsub("%$","%%%$"):gsub("%^","%%%^")).."(.+)","NOPE LOL")
	--mlc,a=cc:gsub("%-%-%[%[.-%]%]","\n")
	--print(mlc)
	--d=#bin._lines(mlc or "")
	_,b=cc:gsub("(%-%-.-)\n","\n")
	_,c=cc:gsub("%-:.-:%-","\n")
	e=b+c
	print(a,b,c)
	for i=1,#t do
		if t[i]:find("["..self._cblockname,1,true) then
			pos=i+self.pos
			break
		end
	end
	if type(file)=="table" then
		filename="runCode"
	else
		filename=file
	end
	error("In Block '"..self._cblockname.."' LIQ: '"..self._cblock[self.pos].."' Filename: "..filename.." On line: "..pos+e..": "..err)
end
function parseManager:p()
	self.pos=self.pos+1
end
function parseManager:parseHeader(header,env)
	header=header:gsub("(%$%S-%$)",function(a)
		local t1,t2=a:match("%$(.-)%[(.-)%]%$")
		if t1 and t2 then
			if type(env[t1])=="table" then
				if t2=="-1" then
					return env[t1][#env[t1]]
				end
				if env[t1][t2] then
					return tostring(env[t1][t2])
				else
					return tostring(env[t1][tonumber(self:varExists(t2) or t2) or self:varExists(t2)])
				end
			end
		end
		a=a:gsub("%$","")
		if type(env[a])=="table" then
			if #env[a]==0 then
				self:pushError("Invalid Syntax!")
			end
			return env[a][math.random(1,#env[a])]
		end
		return tostring(env[a])
	end)
	return header
end
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end
function parseManager:next(chunk,a,env,dd)
	if not env then
		env=self.defualtENV
	end
	if self.stats.topdown and chunk==nil then
		chunk=self.firstloadedblock
	else
		chunk=chunk or "START"
	end
	if not self:hasCBlock() then
		self:setBlock(chunk)
	end
	local line=self._cblock[self.pos]
	if type(a)=="number" then
		for i=1,#dd.methods+1 do
			self:p()
		end
		line=dd.methods[a] -- sneaky, but also prevents wrong choices
	end
	if line==nil then
		if self.stats.leaking then
			if self._chunks[self._cblockname].next then
				self:setBlock(self._chunks[self._cblockname].next)
				self:p()
				return {
					Type="end",
					text="leaking",
					blocktype=self._chunks[self._cblockname][2]
				}
			else
        self.endData={Type="end",text="Reached end of block!",lastblock=self._cblockname,lastline=self._cblock[self.pos-1],blocktype=self._chunks[self._cblockname][2]}
				return self.endData
			end
		end
		return {Type="end",text="Reached end of block!",lastblock=self._cblockname,lastline=self._cblock[self.pos-1],blocktype=self._chunks[self._cblockname][2]}
	end
	local holder,functest,args=line:match("([%w_]-):([%w_]-)%s*%((.-)%)$")
	if not functest then
		functest,args=line:match("([%w_]-)%s*%((.-)%)$")
	end
	if functest then
		local funccheck=line:match("([%+%-%*/]+).-%(.-%)")
		if funccheck then
			functest=nil
		end
		for i,v in pairs(math) do
			if functest==i and type(v)=="function" then
				functest=nil
				break
			end
		end
	end
	line=line:gsub("(.-)%[\"(.-)\"%]=(.+)",function(a,b,c)
		return b.."="..c.."->"..a
	end)
	local choicetest=line:find("<$") or line:find("^<")
	local lasttest=line:match("^\"(.+)\"$")
	local labeltest=line:match("::(.-)::")
	local var,list=line:match("([%w_]-)=%[(.+)%]")
	local assignA,assignB=line:match("(.-)=(.+)")
	local cond,f1,f2=line:match("^if%s*(.-)%s*then%s*([%w-%(%)]-)%s*|%s*([%w-%(%)]*)")
	if choicetest then
		local c=self._chunks[self._cblockname][1]
		local test=bin.new(c:match("\"<(.-)>"))
		test:fullTrim(true)
		local header=line:match("\"(.-)\"<")
		local stuff=test:lines()
		local cho,met={},{}
		for i=1,#stuff do
			local a1,a2=stuff[i]:match("\"(.-)\" (.+)")
			a1=tostring(self:parseHeader(a1,env))
			table.insert(cho,a1)
			table.insert(met,a2)
		end
		return {
			Type="choice",
			text=tostring(self:parseHeader(header,env)),
			choices=cho,
			methods=met,
			blocktype=self._chunks[self._cblockname][2]
		}
	elseif cond and f1 and f2 then
		conds={["andors"]={}}
		mtc=""
		for a,b in cond:gmatch("(.-)([and ]+[or ]+)") do
			b=b:gsub(" ","")
			mtc=mtc..".-"..b
			v1,c,v2=a:match("(.-)%s*([<>!~=]+)%s*(.+)")
			table.insert(conds,{v1,c,v2})
			table.insert(conds.andors,b)
		end
		a=cond:match(mtc.."%s*(.+)")
		v1,c,v2=a:match("(.-)%s*([<>!~=]+)%s*(.+)")
		table.insert(conds,{v1,c,v2})
		truths={}
		for i=1,#conds do
			conds[i][1]=conds[i][1]:gsub("\"","")
			conds[i][3]=conds[i][3]:gsub("\"","")
			if conds[i][2]=="==" then
				table.insert(truths,tostring((self:varExists(conds[i][1]) or conds[i][1]))==tostring((self:varExists(conds[i][3]) or conds[i][3])))
			elseif conds[i][2]=="!=" or conds[i][2]=="~=" then
				table.insert(truths,tostring((self:varExists(conds[i][1]) or conds[i][1]))~=tostring((self:varExists(conds[i][3]) or conds[i][3])))
			elseif conds[i][2]==">=" then
				table.insert(truths,tonumber((self:varExists(conds[i][1]) or conds[i][1]))>=tonumber((self:varExists(conds[i][3]) or conds[i][3])))
			elseif conds[i][2]=="<=" then
				table.insert(truths,tonumber((self:varExists(conds[i][1]) or conds[i][1]))<=tonumber((self:varExists(conds[i][3]) or conds[i][3])))
			elseif conds[i][2]==">" then
				table.insert(truths,tonumber((self:varExists(conds[i][1]) or conds[i][1]))>tonumber((self:varExists(conds[i][3]) or conds[i][3])))
			elseif conds[i][2]=="<" then
				table.insert(truths,tonumber((self:varExists(conds[i][1]) or conds[i][1]))<tonumber((self:varExists(conds[i][3]) or conds[i][3])))
			else
				self:pushError("Invalid condition! "..conds[i][2].." is not a valid condition!")
			end
			if conds.andors[i] then
				table.insert(truths,conds.andors[i]:sub(1,1))
			end
		end
		local val=self:combineTruths(truths)
		if val then
			_args={}
			functest,args=f1:match("([%w_]-)%s*%((.-)%)$")
			for k, v in ipairs(parseManager.split(args)) do
				table.insert(_args,v)
			end
			self._methods[functest](self,unpack(_args))
		else
			_args={}
			functest,args=f2:match("([%w_]-)%s*%((.-)%)$")
			for k, v in ipairs(parseManager.split(args)) do
				table.insert(_args,self:varExists(v))
			end
			self._methods[functest](self,unpack(_args))
		end
		self:p()
		return{
			Type="condition",
			text="Result of the test was: "..tostring(val)
		}
	elseif "\""..(lasttest or "").."\""==line then
		self:p()
		local lasttest=tostring(self:parseHeader(lasttest,env))
		return {
			Type="text",
			text=lasttest,
			blocktype=self._chunks[self._cblockname][2]
		}
	elseif var1 and cond and var2 and f1 and f2 then
		if cond~="==" or cond~="~=" or cond~="!=" then
			var1=self:varExists(var1) or tonumber(var1)
			var2=self:varExists(var2) or tonumber(var2)
		else
			var1=self:varExists(var1) or var1
			var2=self:varExists(var2) or var2
		end
	elseif labeltest then
		if labeltest:find("|") then
			labeltest,t1=labeltest:match("(.-)|(.+)")
			self._methods["JUMP"](self,t1)
		end
		self._labels[labeltest]={self._cblockname,self.pos}
		self:p()
		return {
			Type="label",
			text="Label was assigned {"..self._cblockname..","..self.pos.."}"
		}
	elseif var and list then
		local t=list:split(",")
		local nlist={}
		local slist="["
		local a=":)"
		for i=1,#t do
			a=self:varExists(t[i])
			if a then
				table.insert(nlist,a)
				slist=slist..a..","
			end
		end
		slist=slist:sub(1,-2).."]"
		env[var]=nlist
		self:p()
		return {
			Type="assignment",
			text=var.."="..slist
		}
	elseif functest then
		local vars={}
		if line:find("^(.-)=.+") then
			local t=line:match("^(.-)=.+")
			if t:find(",") then
				for k, v in ipairs(parseManager.split(t)) do
					table.insert(vars,v)
				end
			else
				vars={t}
			end
		end
		_args={}
		for k, v in ipairs(parseManager.split(args)) do
			if type(v)=="userdata" then
				table.insert(_args,v)
			else
				table.insert(_args,(self:varExists(v)))
			end
		end
		if not holder then
			if not(self._methods[functest]) then return self:pushError("Attempt to call a non existing method: "..functest) end
		end
		local stuff={}
		if holder then
			if not type(holder)=="table" then self:pushError(holder.." Is not an object!") end
			if not self.defualtENV[holder][functest] then self:pushError(holder.." does not contain a method: "..functest) end
			stuff={self.defualtENV[holder][functest](self.defualtENV[holder],unpack(_args))}
		else
			stuff={self._methods[functest](self,unpack(_args))}
		end
		for i=1,#vars do
			env[vars[i]]=stuff[i] or "NONE"
		end
		self:p()
		return {
			Type="method",
			returns=stuff,
			blocktype=self._chunks[self._cblockname][2]
		}
	elseif assignA and assignB then
		--if pp
		local vv,d,_env=assignB:match("(.-)([<%-][%->])(.+)")
		if d then
			if d=="<-" then
				self:setVariable(assignA,self.defualtENV[_env][vv])
				self:p()
				return  {
					Type="assignment",
					var=assignA,
					value=assignB,
					env=true,
					text=assignA.."="..assignB
			}
			elseif d=="->" then
				self.defualtENV[_env][assignA]=self:varExists(vv)
				self:p()
				return  {
					Type="assignment",
					var=assignA,
					value=assignB,
					env=true,
					text=assignA.."="..assignB
			}
			end
		end
		local a1,a2=parseManager.split(assignA),parseManager.split(assignB)
		for i=1,#a1 do
			local a=self._methods.CALC(self,a2[i])
			if a then
				a2[i]=a
			end
			local t=tonumber(a2[i])
			if not t then
				t=a2[i]
			end
			env[a1[i]]=t
		end
		self:p()
		return {
			Type="assignment",
			var=assignA,
			value=assignB,
			text=assignA.."="..assignB
		}
	else
		local rets=self.OnCustomSyntax:Fire(self,line)
		for i=1,#rets do
			if type(rets[i][1])=="table" then
				return rets[i][1]
			else
				return {
					Type="unknown",
					text=line
				}
			end
		end
		self:p()
		return {
			Type="unknown",
			text=line
		}
	end
end
function parseManager:RunCode(code,entry,sel,env) -- returns an env or selectVarName
	local file = bin.new("ENTRY "..(entry or "START").."\n"..code)
	local run=parseManager:load(file)
	run._methods = self._methods
	run.defualtENV=self.defualtENV
	run.defualtENV=self.defualtENV
	for i,v in pairs(env or {}) do
		run.defualtENV[i]=v
	end
	local t=run:start()
	while true do
		if t.Type=="text" then
			print(t.text)
			t=run:next()
		elseif t.Type=="condition" then
			t=run:next()
		elseif t.Type=="assignment" then
			t=run:next()
		elseif t.Type=="label" then
			t=run:next()
		elseif t.Type=="method" then
			t=run:next()
		elseif t.Type=="choice" then
			t=run:next(nil,math.random(1,#t.choices),nil,t)
		elseif t.Type=="end" then
			if t.text=="leaking" then -- go directly to the block right under the current block if it exists
				t=run:next()
			else
				return (run.defualtENV[sel] or run.defualtENV)
			end
		elseif t.Type=="error" then
			error(t.text)
		else
			t=run:next()
		end
	end
end
parseManager.symbols={} -- {sym,code}
function parseManager:registerSymbol(sym,code)
	self.symbols[#self.symbols+1]={sym,code}
end
function parseManager:populateSymbolList(o)
	local str=""
	for i=1,#self.symbols do
		str=self.symbols[i][1]..str
	end
	return str
end
function parseManager:isRegisteredSymbol(o,r,v)
	for i=1,#self.symbols do
		if self.symbols[i][1]==o then
			return parseManager:RunCode(self.symbols[i][2],"CODE","ret-urn",{["l"]=r,["r"]=v,["mainenv"]=self.defualtENV})
		end
	end
	return false --self:pushError("Invalid Symbol "..o.."!")
end
function parseManager:evaluate(cmd,v)
	v=v or 0
	local loop
	local count=0
	local function helper(o,v,r)
		if type(v)=="string" then
			if v:find("%D") then
				v=self:varExists(v)
			end
		end
		if type(r)=="string" then
			if r:find("%D") then
				r=self:varExists(r)
			end
		end
		local r=tonumber(r) or 0
		local gg=self:isRegisteredSymbol(o,r,v)
		if gg then
			return gg
		elseif o=="+" then
			return r+v
		elseif o=="-" then
			return r-v
		elseif o=="/" then
			return r/v
		elseif o=="*" then
			return r*v
		elseif o=="^" then
			return r^v
		end
	end
	for i,v in pairs(math) do
		cmd=cmd:gsub(i.."(%b())",function(a)
			a=a:sub(2,-2)
			if a:sub(1,1)=="-" then
				a="0"..a
			end
			return v(self:evaluate(a))
		end)
	end
	cmd=cmd:gsub("%b()",function(a)
		return self:evaluate(a:sub(2,-2))
	end)
	for l,o,r in cmd:gmatch("(.*)([%+%^%-%*/"..self:populateSymbolList().."])(.*)") do
		loop=true
		count=count+1
		if l:find("[%+%^%-%*/]") then
			v=self:evaluate(l,v)
			v=helper(o,r,v)
		else
			if count==1 then
				v=helper(o,r,l)
			end
		end
	end
	if not loop then return self:varExists(cmd) end
	return v
end
parseManager.constructType=function(self,name,t,data,filename)
	if t~="construct" then return end
	--print(name,t,"[CODE]{"..data.."}")
	self:registerSymbol(name,"[CODE]{"..data.."}")
end
-- Let's add function
Stack = {}
function Stack:Create()
  local t = {}
  t._et = {}
  function t:push(...)
    if ... then
      local targs = {...}
      for _,v in ipairs(targs) do
        table.insert(self._et, v)
      end
    end
  end
  function t:pop(num)
    local num = num or 1
    local entries = {}
    for i = 1, num do
      if #self._et ~= 0 then
        table.insert(entries, self._et[#self._et])
        table.remove(self._et)
      else
        break
      end
    end
    return unpack(entries)
  end
  function t:getn()
    return #self._et
  end
  function t:list()
    for i,v in pairs(self._et) do
      print(i, v)
    end
  end
  return t
end
parseManager.funcstack=Stack:Create()
parseManager:define{
	__TRACEBACK=function(self) -- internal function to handle function calls
		local t=self.funcstack:pop()
		self:setBlock(t[1])
		self.pos=t[2]
		-- We finished the function great. Lets restore the old env
		self._methods.setENV(self,t[3])
	end
}
parseManager.funcType=function(link,name,t,data,filename)
	local test,args=t:match("(function)%(*([%w,]*)%)*")
	if not test then return false end
	local vars={}
	if args~="" then
		for k, v in ipairs(parseManager.split(args)) do
			table.insert(vars,v)
		end
		-- Time to collect local vars to populate we will use these below
	end
	link._chunks[name][1]=link._chunks[name][1].."\n__TRACEBACK()"
    local func=function(self,...)
		-- Here we will use the vars. First lets capture the args from the other side
		local args={...}
		-- Here we will play a matching game assigning vars to values. This cannot be done yet...
		-- Now we have to change the enviroment so function vars are local to the function.
		-- Also we need functions to be able to access the globals too
		-- Now we invoke the createnv method
		local env=self._methods.createENV(self)
		-- A little messy compared to how its done within the interpreted language
		-- Now we need a copy of the previous Env
		-- We then invoke getEnv method
		local lastEnv=self._methods.getENV(self)
		-- Great now we have a new enviroment to play with and the current one
		-- Next we need to store the current one somewhere
		self.funcstack:push({self._cblockname,self.pos,lastEnv})
		-- We use a stack to keep track of function calls. Before I tried something else and it was a horrible mess
		-- Stacks make it real nice and easy to use. We store a bit of data into the stack to use later
		if self.funcstack:getn()>1024 then self:pushError("Stack Overflow!") end
		-- Throw an error if the stack reaches 1024 elements. We don't want it to go forever and odds are neither does the user
		-- Lets set that new env and prepare for the jump. To do this we invoke setEnv
		self._methods.setENV(self,env)
		-- Now lets play match making
		for i=1,#vars do
			self:setVariable(vars[i],args[i]) -- this method defualts to the current env
		end
		-- We are ready to make the jump with our stored data
		self._methods.JUMP(self,name)
		-- we need to be able to catch returns... This is where things get tricky.
		-- We need a way to run the other code while also waiting here so we can return data
		-- What we can do is return a reference to the enviroment and from there you can take what you want from the function
		-- This is a really strange way to do things, but whats wrong with different
		return env
    end
    link._methods[name]=func
end
parseManager.OnExtendedBlock(parseManager.funcType)
parseManager.constructType=function(link,name,t,data,filename)
	local test,args=t:match("(construct)%(*([%w,]*)%)*")
	if not test then return false end
	local vars={}
	if args~="" then
		for k, v in ipairs(parseManager.split(args)) do
			table.insert(vars,v)
		end
	end
	link._chunks[name][1]=link._chunks[name][1].."\n__TRACEBACK()"
    local func=function(self,...)
		local args={...}
		local env=self._methods.createENV(self)
		local lastEnv=self._methods.getENV(self)
		self.funcstack:push({self._cblockname,self.pos,lastEnv})
		if self.funcstack:getn()>1024 then self:pushError("Stack Overflow!") end
		self._methods.setENV(self,env)
		for i=1,#vars do
			self:setVariable(vars[i],args[i])
		end
		self._methods.JUMP(self,name)
		return env
    end
    link._methods[name]=func
end
parseManager.OnExtendedBlock(parseManager.constructType)
