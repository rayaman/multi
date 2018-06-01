function table.print(tbl, indent)
	if not indent then indent = 0 end
		for k, v in pairs(tbl) do
		formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting)
			table.print(v, indent+1)
		elseif type(v) == 'boolean' then
			print(formatting .. tostring(v))
		else
			print(formatting .. tostring(v))
		end
	end
end
function table.flip(t)
	local tt={}
	for i,v in pairs(t) do
		tt[v]=i
	end
	return tt
end
function toFraction(n)
	local w,p=math.modf(n)
	if p~=0 then
		p=tonumber(tostring(p):sub(3))
	end
	return w,p
end
function io.cleanName(name)
	name=name:gsub("\\","")
	name=name:gsub("/","")
	name=name:gsub(":","")
	name=name:gsub("*","")
	name=name:gsub("%?","")
	name=name:gsub("\"","''")
	name=name:gsub("<","")
	name=name:gsub(">","")
	name=name:gsub("|","")
	return name
end
function math.numfix(n,x)
	local str=tostring(n)
	if #str<x then
		str=('0'):rep(x-#str)..str
	end
	return str
end
function bin.stripFileName(path)
	path=path:gsub("\\","/")
	local npath=path:reverse()
	a=npath:find("/",1,true)
	npath=npath:sub(a)
	npath=npath:reverse()
	return npath
end
function bin._trim(str)
	return str:match'^()%s*$' and '' or str:match'^%s*(.*%S)'
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
function bin.fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end
function bin.randomName(n,ext)
	n=n or math.random(7,15)
	if ext then
		a,b=ext:find('.',1,true)
		if a and b then
			ext=ext:sub(2)
		end
	end
	local str,h = '',0
	strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		h = math.random(1,#strings)
		str = str..''..strings[h]
	end
	return str..'.'..(ext or 'tmp')
end
function bin.trimNul(str)
	return str:match("(.-)[%z]*$")
end
function io.mkDir(dirname)
	os.execute('mkdir "' .. dirname..'"')
end
function string.lines(str)
	local t = {}
	local function helper(line) table.insert(t, line) return '' end
	helper((str:gsub('(.-)\r?\n', helper)))
	return t
end
function log(data,name,fmt)
	if name then
		name=io.cleanName(name)
	end
	if not bin.logger then
		bin.logger = bin.stream(name or 'lua.log',false)
	elseif bin.logger and name then
		bin.logger:close()
		bin.logger = bin.stream(name or 'lua.log',false)
	end
	local d=os.date('*t',os.time())
	bin.logger:tackE((fmt or '['..math.numfix(d.month,2)..'-'..math.numfix(d.day,2)..'-'..d.year..'|'..math.numfix(d.hour,2)..':'..math.numfix(d.min,2)..':'..math.numfix(d.sec,2)..']\t')..data..'\r\n')
end
function table.max(t)
    if #t == 0 then return end
    local value = t[1]
    for i = 2, #t do
        if (value < t[i]) then
            value = t[i]
        end
    end
    return value
end
