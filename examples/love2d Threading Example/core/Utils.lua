-- os Additions
function os.getSystemBit()
	if (os.getenv('PROCESSOR_ARCHITEW6432')=='AMD64' or os.getenv('PROCESSOR_ARCHITECTURE')=='AMD64') then
		return 64
	else
		return 32
	end
end
function os.sleep(n)
	if not n then n=0 end
	local t0 = os.clock()
	while os.clock() - t0 <= n do end
end
function os.pause(msg)
	if msg ~= nil then
		print(msg)
	end
	io.read()
end
function os.batCmd(cmd)
	io.mkFile('temp.bat',cmd)
	local temp = os.execute([[temp.bat]])
	io.delFile('temp.bat')
	return temp
end
function os._getOS()
	if package.config:sub(1,1)=='\\' then
		return 'windows'
	else
		return 'unix'
	end
end
function os.getOS(t)
	if not t then
		return os._getOS()
	end
	if os._getOS()=='unix' then
		fh,err = io.popen('uname -o 2>/dev/null','r')
		if fh then
			osname = fh:read()
		end
		if osname then return osname end
	end
	local winver='Unknown Version'
	local a,b,c=os.capture('ver'):match('(%d+).(%d+).(%d+)')
	local win=a..'.'..b..'.'..c
	if type(t)=='string' then
		win=t
	end
	if win=='4.00.950' then
		winver='95'
	elseif win=='4.00.1111' then
		winver='95 OSR2'
	elseif win=='4.00.1381' then
		winver='NT 4.0'
	elseif win=='4.10.1998' then
		winver='98'
	elseif win=='4.10.2222' then
		winver='98 SE'
	elseif win=='4.90.3000' then
		winver='ME'
	elseif win=='5.00.2195' then
		winver='2000'
	elseif win=='5.1.2600' then
		winver='XP'
	elseif win=='5.2.3790' then
		winver='Server 2003'
	elseif win=='6.0.6000' then
		winver='Vista/Windows Server 2008'
	elseif win=='6.0.6002' then
		winver='Vista SP2'
	elseif win=='6.1.7600' then
		winver='7/Windows Server 2008 R2'
	elseif win=='6.1.7601' then
		winver='7 SP1/Windows Server 2008 R2 SP1'
	elseif win=='6.2.9200' then
		winver='8/Windows Server 2012'
	elseif win=='6.3.9600' then
		winver='8.1/Windows Server 2012'
	elseif win=='6.4.9841' then
		winver='10 Technical Preview 1'
	elseif win=='6.4.9860' then
		winver='10 Technical Preview 2'
	elseif win=='6.4.9879' then
		winver='10 Technical Preview 3'
	elseif win=='10.0.9926' then
		winver='10 Technical Preview 4'
	end
	return 'Windows '..winver
end
function os.getLuaArch()
	return (#tostring({})-7)*4
end
if os.getOS()=='windows' then
	function os.sleep(n)
		if n > 0 then os.execute('ping -n ' .. tonumber(n+1) .. ' localhost > NUL') end
	end
else
	function os.sleep(n)
		os.execute('sleep ' .. tonumber(n))
	end
end
function os.capture(cmd, raw)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	if raw then return s end
	s = string.gsub(s, '^%s+', '')
	s = string.gsub(s, '%s+$', '')
	s = string.gsub(s, '[\n\r]+', ' ')
	return s
end
function os.getCurrentUser()
	return os.getenv('$USER') or os.getenv('USERNAME')
end
-- string Additions
function string.trim(s)
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end
function string.random(n)
	local str = ''
	strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		h = math.random(1,#strings)
		str = str..''..strings[h]
	end
	return str
end
function string.linesToTable(s)
	local t = {}
	local i = 0
	while true do
		i = string.find(s, '\n', i+1)
		if i == nil then return t end
		table.insert(t, i)
	end
end
function string.lines(str)
	local t = {}
	local function helper(line) table.insert(t, line) return '' end
	helper((str:gsub('(.-)\r?\n', helper)))
	return t
end
function string.split(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = '(.-)' .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= '' then
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end
function string.shuffle(inputStr)
	math.randomseed(os.time());
	local outputStr = '';
	local strLength = string.len(inputStr);
	while (strLength ~=0) do
		local pos = math.random(strLength);
		outputStr = outputStr..string.sub(inputStr,pos,pos);
		inputStr = inputStr:sub(1, pos-1) .. inputStr:sub(pos+1);
		strLength = string.len(inputStr);
	end
	return outputStr;
end
function string.genKeys(chars,a,f,s,GG)
	if GG then
		chars=string.rep(chars,a)
	end
	if s then
		chars=string.shuffle(chars)
	end
	b=#chars
    if a==0 then return end
    local taken = {} local slots = {}
    for i=1,a do slots[i]=0 end
    for i=1,b do taken[i]=false end
    local index = 1
	local tab={}
	for i=1,#chars do
		table.insert(tab,chars:sub(i,i))
	end
    while index > 0 do repeat
        repeat slots[index] = slots[index] + 1
        until slots[index] > b or not taken[slots[index]]
        if slots[index] > b then
            slots[index] = 0
            index = index - 1
            if index > 0 then
                taken[slots[index]] = false
            end
            break
        else
            taken[slots[index]] = true
        end
        if index == a then
			local tt={}
            for i=1,a do
				table.insert(tt,tab[slots[i]])
			end
			f(table.concat(tt))
            taken[slots[index]] = false
            break
        end
        index = index + 1
    until true end
end
-- io Additions
function io.getInput(msg)
	if msg ~= nil then
		io.write(msg)
	end
	return io.read()
end
function io.scanDir(directory)
	directory=directory or io.getDir()
    local i, t, popen = 0, {}, io.popen
	if os.getOS()=='unix' then
		for filename in popen('ls -a \''..directory..'\''):lines() do
			i = i + 1
			t[i] = filename
		end
	else
		for filename in popen('dir \''..directory..'\' /b'):lines() do
			i = i + 1
			t[i] = filename
		end
	end
    return t
end
function io.buildFromTree(tbl, indent,folder)
	if not indent then indent = 0 end
	if not folder then folder = '' end
	for k, v in pairs(tbl) do
		formatting = string.rep(' ', indent) .. k .. ':'
		if type(v) == 'table' then
			if not(io.dirExists(folder..string.sub(formatting,1,-2))) then
				io.mkDir(folder..string.sub(formatting,1,-2))
			end
			io.buildFromTree(v,0,folder..string.sub(formatting,1,-2)..'\\')
		else
			a=string.find(tostring(v),':',1,true)
			if a then
				file=string.sub(tostring(v),1,a-1)
				data=string.sub(tostring(v),a+1)
				io.mkFile(folder..file,data,'wb')
			else
				io.mkFile(folder..v,'','wb')
			end
		end
	end
end
function io.cpFile(path,topath)
	if os.getOS()=='unix' then
		os.execute('cp '..file1..' '..file2)
	else
		os.execute('Copy '..path..' '..topath)
	end
end
function io.delDir(directoryname)
	if os.getOS()=='unix' then
		os.execute('rm -rf '..directoryname)
	else
		os.execute('rmdir '..directoryname..' /s /q')
	end
end
function io.delFile(path)
	os.remove(path)
end
function io.mkDir(dirname)
	os.execute('mkdir "' .. dirname..'"')
end
function io.mkFile(filename,data,tp)
	if not(tp) then tp='wb' end
	if not(data) then data='' end
	file = io.open(filename, tp)
	if file==nil then return end
	file:write(data)
	file:close()
end
function io.movFile(path,topath)
	io.cpFile(path,topath)
	io.delFile(path)
end
function io.listFiles(dir)
	if not(dir) then dir='' end
	local f = io.popen('dir \''..dir..'\'')
	if f then
		return f:read('*a')
	else
		print('failed to read')
	end
end
function io.getDir(dir)
	if not dir then return io.getWorkingDir() end
	if os.getOS()=='unix' then
		return os.capture('cd '..dir..' ; cd')
	else
		return os.capture('cd '..dir..' & cd')
	end
end
function io.getWorkingDir()
	return io.popen'cd':read'*l'
end
function io.fileExists(path)
	g=io.open(path or '','r')
	if path =='' then
		p='empty path'
		return nil
	end
	if g~=nil and true or false then
		p=(g~=nil and true or false)
	end
	if g~=nil then
		io.close(g)
	else
		return false
	end
	return p
end
function io.fileCheck(file_name)
	if not file_name then print('No path inputed') return false end
	local file_found=io.open(file_name, 'r')
	if file_found==nil then
		file_found=false
	else
		file_found=true
	end
	return file_found
end
function io.dirExists(strFolderName)
	strFolderName = strFolderName or io.getDir()
	local fileHandle, strError = io.open(strFolderName..'\\*.*','r')
	if fileHandle ~= nil then
		io.close(fileHandle)
		return true
	else
		if string.match(strError,'No such file or directory') then
			return false
		else
			return true
		end
	end
end
function io.getAllItems(dir)
	local t=os.capture("cd \""..dir.."\" & dir /a-d | find",true):lines()
	return t
end
function io.listItems(dir)
	if io.dirExists(dir) then
		temp=io.listFiles(dir) -- current directory if blank
		if io.getDir(dir)=='C:\\\n' then
			a,b=string.find(temp,'C:\\',1,true)
			a=a+2
		else
			a,b=string.find(temp,'..',1,true)
		end
		temp=string.sub(temp,a+2)
		list=string.linesToTable(temp)
		temp=string.sub(temp,1,list[#list-2])
		slist=string.lines(temp)
		table.remove(slist,1)
		table.remove(slist,#slist)
		temp={}
		temp2={}
		for i=1,#slist do
			table.insert(temp,string.sub(slist[i],40,-1))
		end
		return temp
	else
		return nil
	end
end
function io.getDirectories(dir,l)
	if dir then
		dir=dir..'\\'
	else
		dir=''
	end
	local temp2=io.scanDir(dir)
	for i=#temp2,1,-1 do
		if io.fileExists(dir..temp2[i]) then
			table.remove(temp2,i)
		elseif l then
			temp2[i]=dir..temp2[i]
		end
	end
	return temp2
end
function io.getFiles(dir,l)
	if dir then
		dir=dir..'\\'
	else
		dir=''
	end
	local temp2=io.scanDir(dir)
	for i=#temp2,1,-1 do
		if io.dirExists(dir..temp2[i]) then
			table.remove(temp2,i)
		elseif l then
			temp2[i]=dir..temp2[i]
		end
	end
	return temp2
end
function io.getFullName(name)
	local temp=name or arg[0]
	if string.find(temp,'\\',1,true) or string.find(temp,'/',1,true) then
		temp=string.reverse(temp)
		a,b=string.find(temp,'\\',1,true)
		if not(a) or not(b) then
			a,b=string.find(temp,'/',1,true)
		end
		return string.reverse(string.sub(temp,1,b-1))
	end
	return temp
end
function io.getName(file)
	local name=io.getFullName(file)
	name=string.reverse(name)
	a,b=string.find(name,'.',1,true)
	name=string.sub(name,a+1,-1)
	return string.reverse(name)
end
function io.readFile(file)
    local f = io.open(file, 'rb')
    local content = f:read('*all')
    f:close()
    return content
end
function io.getExtension(file)
	local file=io.getFullName(file)
	file=string.reverse(file)
	local a,b=string.find(file,'.',0,true)
	local temp=string.sub(file,1,b)
	return string.reverse(temp)
end
function io.pathToTable(path)
	local p=io.splitPath(path)
	local temp={}
	temp[p[1]]={}
	local last=temp[p[1]]
	for i=2,#p do
		snd=last
		last[p[i]]={}
		last=last[p[i]]
	end
	return temp,last,snd
end
function io.splitPath(str)
   return string.split(str,'[\\/]+')
end

function io.parseDir(dir,t)
	io.tempFiles={}
	function _p(dir)
		local dirs=io.getDirectories(dir,true)
		local files=io.getFiles(dir,true)
		for i=1,#files do
			p,l,s=io.pathToTable(files[i])
			if t then
				s[io.getFullName(files[i])]=io.readFile(files[i])
			else
				s[io.getFullName(files[i])]=io.open(files[i],'r+')
			end
			table.merge(io.tempFiles,p)
		end
		for i=1,#dirs do
			table.merge(io.tempFiles,io.pathToTable(dirs[i]))
			_p(dirs[i],t)
		end
	end
	_p(dir)
	return io.tempFiles
end
function io.parsedir(dir,f)
	io.tempFiles={}
	function _p(dir,f)
		local dirs=io.getDirectories(dir,true)
		local files=io.getFiles(dir,true)
		for i=1,#files do
			if not f then
				table.insert(io.tempFiles,files[i])
			else
				f(files[i])
			end
		end
		for i=1,#dirs do
			_p(dirs[i],f)
		end
	end
	_p(dir,f)
	return io.tempFiles
end
function io.driveReady(drive)
	drive=drive:upper()
	if not(drive:find(':',1,true)) then
		drive=drive..':'
	end
	drives=io.getDrives()
	for i=1,#drives do
		if drives[i]==drive then
			return true
		end
	end
	return false
end
function io.getDrives()
	if os.getOS()=='windows' then
		local temp={}
		local t1=os.capture('wmic logicaldisk where drivetype=2 get deviceid, volumename',true)
		local t2=os.capture('wmic logicaldisk where drivetype=3 get deviceid, volumename',true)
		for drive,d2 in t1:gmatch('(.:)%s-(%w+)') do
			if #d2>1 then
				table.insert(temp,drive)
			end
		end
		for drive in t2:gmatch('(.:)') do
			table.insert(temp,drive)
		end
		return temp
	end
	error('Command is windows only!')
end
-- table Additions
function table.dump(t,indent)
    local names = {}
    if not indent then indent = '' end
    for n,g in pairs(t) do
        table.insert(names,n)
    end
    table.sort(names)
    for i,n in pairs(names) do
        local v = t[n]
        if type(v) == 'table' then
            if(v==t) then
                print(indent..tostring(n)..': <-')
            else
                print(indent..tostring(n)..':')
                table.dump(v,indent..'   ')
            end
        else
            if type(v) == 'function' then
                print(indent..tostring(n)..'()')
            else
                print(indent..tostring(n)..': '..tostring(v))
            end
        end
    end
end
function table.alphanumsort(o)
	local function padnum(d) local dec, n = string.match(d, '(%.?)0*(.+)')
		return #dec > 0 and ('%.12f'):format(d) or ('%s%03d%s'):format(dec, #n, n)
	end
	table.sort(o, function(a,b) return tostring(a):gsub('%.?%d+',padnum)..('%3d'):format(#b)< tostring(b):gsub('%.?%d+',padnum)..('%3d'):format(#a) end)
	return o
end
function table.foreach(t,f)
	for i,v in pairs(t) do
		f(v)
	end
end
function table.merge(t1, t2)
    for k,v in pairs(t2) do
    	if type(v) == 'table' then
    		if type(t1[k] or false) == 'table' then
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
function table.print(tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
		formatting = string.rep('  ', indent) .. k .. ': '
		if type(v) == 'table' then
			print(formatting)
			table.print(v, indent+1)
		else
			print(formatting .. tostring(v))
		end
	end
end
function table.merge(t1, t2)
    for k,v in pairs(t2) do
    	if type(v) == 'table' then
    		if type(t1[k] or false) == 'table' then
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
function table.clear(t)
	for k in pairs (t) do
		t[k] = nil
	end
end
function table.copy(t)
	function deepcopy(orig)
		local orig_type = type(orig)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key)] = deepcopy(orig_value)
			end
			setmetatable(copy, deepcopy(getmetatable(orig)))
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
	end
	return deepcopy(t)
end
function table.swap(tab,i1,i2)
	tab[i1],tab[i2]=tab[i2],tab[i1]
end
function table.append(t1, ...)
	t1,t2= t1 or {},{...}
    for k,v in pairs(t2) do
    	t1[#t1+1]=t2[k]
    end
    return t1
end
function table.compare(t1, t2,d)
	if d then
		return table.deepCompare(t1,t2)
	end
	--if #t1 ~= #t2 then return false end
	if #t2>#t1 then
		for i=1,#t2 do
			if t1[i] ~= t2[i] then
				return false,t2[i]
			end
		end
	else
		for i=1,#t1 do
			if t1[i] ~= t2[i] then
				return false,t2[i]
			end
		end
	end
	return true
end
function table.deepCompare(t1,t2)
	if t1==t2 then return true end
	if (type(t1)~='table') then return false end
	local mt1 = getmetatable(t1)
	local mt2 = getmetatable(t2)
	if( not table.deepCompare(mt1,mt2) ) then return false end
	for k1,v1 in pairs(t1) do
		local v2 = t2[k1]
		if( not table.deepCompare(v1,v2) ) then return false end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if( not table.deepCompare(v1,v2) ) then return false end
	end
	return true
end
function table.has(t,_v)
	for i,v in pairs(t) do
		if v==_v then
			return true
		end
	end
	return false
end
function table.reverse(tab)
	local size = #tab
	local newTable = {}
	for i,v in ipairs (tab) do
		newTable[size-i] = v
	end
	for i=1,#newTable do
		tab[i]=newTable[i]
	end
end
-- Math Additions
local Y = function(g) local a = function(f) return f(f) end return a(function(f) return g(function(x) local c=f(f) return c(x) end) end) end
local F = function(f) return function(n)if n == 0 then return 1 else return n*f(n-1) end end end
math.factorial = Y(F)
math.fib={}
math.fib.fibL={}
setmetatable(math.fib,{__call=function(self,n)
	if n<=2 then
		return 1
	else
		if self.fibL[n] then
			return self.fibL[n]
		else
			local t=math.fib(n-1)+math.fib(n-2)
			self.fibL[n]=t
			return t
		end
	end
end})
local floor,insert = math.floor, table.insert
function math.basen(n,b)
    n = floor(n)
    if not b or b == 10 then return tostring(n) end
    local digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local t = {}
    local sign = ''
    if n < 0 then
        sign = '-'
    n = -n
    end
    repeat
        local d = (n % b) + 1
        n = floor(n / b)
        insert(t, 1, digits:sub(d,d))
    until n == 0
    return sign .. table.concat(t,'')
end
function math.convbase(n,b,tb)
	return math.basen(tonumber(tostring(n),b),tb)
end
if BigNum then
	function BigNum.mod(a,b)
		return a-((a/b)*b)
	end
	local floor,insert = math.floor, table.insert
	function math.basen(n,b)
		n = BigNum.new(n)
		if not b or b == 10 then return tostring(n) end
		local digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		local t = {}
		local sign = ''
		if n < BigNum.new(0) then
			sign = '-'
		n = -n
		end
		repeat
			local d = BigNum.mod(n , b) + 1
			n = n/b
			d=tonumber(tostring(d))
			insert(t, 1, digits:sub(d,d))
		until tonumber(tostring(n)) == 0
		return sign .. table.concat(t,'')
	end
	function math.to10(n,b)
		local num=tostring(n)
		local sum=BigNum.new()
		local digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		for i=1,#num do
			local v=digits:find(num:sub(i,i),1,true)
			sum=sum+BigNum.new(tonumber(v)-1)*BigNum.pow(BigNum.new(b),BigNum.new(#num-i))
		end
		return sum
	end
	function math.convbase(n,b,tb)
		return math.basen(math.to10(n,b),tb)
	end
end
function math.numfix(n,x)
	local str=tostring(n)
	if #str<x then
		str=('0'):rep(x-#str)..str
	end
	return str
end
-- Misc Additions
function smartPrint(...)
	local args={...}
	for i=1,#args do
		if type(args[i])=='table' then
			table.print(args[i])
		else
			print(args[i])
		end
	end
end
function totable(v)
	if type(v)=='table' then return v end
	return {v}
end
print(math.factorial(2))
