--Needs:SystemType.bat
function RandomString(num)
string = ""
strings = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","1","2","3","4","5","6","7","8","9","0","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
for i=1,num do
h = math.random(1,#strings)
string = string..""..strings[h]
end
return string
end
----------------------------------------------------------------------------------------------------
function GetSystemType()
return BatCmd([[
for /f "skip=1 delims=" %%x in ('wmic cpu get addresswidth') do if not defined AddressWidth set AddressWidth=%%x

if %AddressWidth%==64 (
  exit /b 64
) else (
  exit /b 32
)
]])
end
----------------------------------------------------------------------------------------------------
local clock = os.clock
function sleep(n)  -- seconds
if not n then n=0 end
local t0 = clock()
while clock() - t0 <= n do end
end
----------------------------------------------------------------------------------------------------
function SetCounter()
return os.clock()
end
----------------------------------------------------------------------------------------------------
function GetCounter(count)
if count~=nil then
return os.clock()-count
else
return 0
end
end
----------------------------------------------------------------------------------------------------
-- sleep and wait script for n seconds
function wait(n)
sleep(n)
end
----------------------------------------------------------------------------------------------------
-- pause into any key pressed
function pause(msg)
if msg ~= nil then
print(msg)
end
io.read()
end
----------------------------------------------------------------------------------------------------
-- gets input
function getInput(msg)
if msg ~= nil then
io.write(msg)
end
return io.read()
end
----------------------------------------------------------------------------------------------------
-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function print(...)
arg={...}
if arg[1]==nil then
return nil
end
for i,v in ipairs(arg) do
function tprint(tbl, indent)
if not indent then indent = 0 end
for k, v in pairs(tbl) do
formatting = string.rep(" ", indent) .. k .. ": "
if type(v) == "table" then
print(formatting)
tprint(v, indent+1)
else
print(formatting .. tostring(v))
end
end
end
if type(v)=="string" then
io.write(v..[[

]])
elseif type(v)=="table" then
function test(v)
return v:tostring()
end
if v.tostring ~=nil then
print(test(v))
else
tprint(v)
end
elseif type(v)=="number" then
io.write(tostring(v..[[

]]))
elseif type(v)=="boolean" then
if v then
io.write("true"..[[

]])
else
io.write("false"..[[

]])
end
end
end
end
math.randomseed(clock())
----------------------------------------------------------------------------------------------------
-- gets the length of a table or a string or the number of digits in a number including the decimal
function len(T)
if type(T)=="table" then
local count = 0
for _ in pairs(T) do count = count + 1 end
return count
elseif type(T)=="string" then
return string.len(T)
elseif type(T)=="number" then
return string.len(tostring(T))
end
end
----------------------------------------------------------------------------------------------------
function dump(t,indent)
    local names = {}
    if not indent then indent = "" end
    for n,g in pairs(t) do
        table.insert(names,n)
    end
    table.sort(names)
    for i,n in pairs(names) do
        local v = t[n]
        if type(v) == "table" then
            if(v==t) then -- prevent endless loop if table contains reference to itself
                print(indent..tostring(n)..": <-")
            else
                print(indent..tostring(n)..":")
                dump(v,indent.."   ")
            end
        else
            if type(v) == "function" then
                print(indent..tostring(n).."()")
            else
                print(indent..tostring(n)..": "..tostring(v))
            end
        end
    end
end
----------------------------------------------------------------------------------------------------
function BuildFromTree(tbl, indent,folder)
if not indent then indent = 0 end
if not folder then folder = "" end
for k, v in pairs(tbl) do
formatting = string.rep(" ", indent) .. k .. ":"
if type(v) == "table" then
--print(formatting)
mkdir(folder..string.sub(formatting,1,-2))
BuildFromTree(v,0,folder..string.sub(formatting,1,-2).."\\")
print(v,0,folder..string.sub(formatting,1,-2).."\\")
else
a=string.find(tostring(v),":",1,true)
file=string.sub(tostring(v),1,a-1)
data=string.sub(tostring(v),a+1)
mkfile(folder..file,data,"w")
print(folder..tostring(v))
end
end
end
----------------------------------------------------------------------------------------------------
function CopyFile(path,topath)
print("Copy "..path.." "..topath)
os.execute("Copy "..path.." "..topath)
end
----------------------------------------------------------------------------------------------------
function DeleteFile(path)
os.remove(path)
end
----------------------------------------------------------------------------------------------------
function mkdir(dirname)
os.execute("mkdir \"" .. dirname.."\"")
end
----------------------------------------------------------------------------------------------------
function mkfile(filename,data,tp)
if not(tp) then tp="w" end
if not(data) then data="" end
file = io.open(filename, tp)
file:write(data)
file:close()
end
----------------------------------------------------------------------------------------------------
function MoveFile(path,topath)
CopyFile(path,topath)
DeleteFile(path)
end
----------------------------------------------------------------------------------------------------
function List_Files(dir)
if not(dir) then dir="" end
local f = io.popen("dir \""..dir.."\"")
if f then
    return f:read("*a")
else
    print("failed to read")
end
end
----------------------------------------------------------------------------------------------------
function StringLineToTable(s)
local t = {}                   -- table to store the indices
local i = 0
while true do
i = string.find(s, "\n", i+1)    -- find 'next' newline
if i == nil then return t end
table.insert(t, i)
end
end
----------------------------------------------------------------------------------------------------
function GetDirectory(dir,flop)
s=List_Files(dir)
drive=string.sub(string.match(s,"drive.."),-1)
local t = {}                   -- table to store the indices
local i = 0
while true do
i = string.find(s, "\n", i+1)    -- find 'next' newline
if i == nil then
a,b=string.find(s,drive..":\\",1,true)
main = string.gsub(string.sub(s,a,t[4]), "\n", "")
if flop then
main=main:gsub("%\\", "/")
end
return main
end
table.insert(t, i)
end
end
----------------------------------------------------------------------------------------------------
function lines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end
----------------------------------------------------------------------------------------------------
function File_Exist(path)
g=io.open(path or '','r')
if path =="" then
p="empty path"
return nil
end
if g~=nil and true or false then
p=(g~=nil and true or false)
end
--p=(g~=nil and true or false..(path=='' and 'empty path entered!' or (path or 'arg "path" wasn\'t define to function call!')))
if g~=nil then
io.close(g)
else
return false
end
return p
end
----------------------------------------------------------------------------------------------------
function file_check(file_name)
if not file_name then print("No path inputed") return false end
local file_found=io.open(file_name, "r")
if file_found==nil then
file_found=false
else
file_found=true
end
return file_found
end
----------------------------------------------------------------------------------------------------
function Dir_Exist(strFolderName)
	local fileHandle, strError = io.open(strFolderName.."\\*.*","r")
	if fileHandle ~= nil then
		io.close(fileHandle)
		return true
	else
		if string.match(strError,"No such file or directory") then
			return false
		else
			return true
		end
	end
end
----------------------------------------------------------------------------------------------------
function ListItems(dir)
if Dir_Exist(dir) then
temp=List_Files(dir) -- current directory if blank
if GetDirectory(dir)=="C:\\\n" then
a,b=string.find(temp,"C:\\",1,true)
a=a+2
else
a,b=string.find(temp,"..",1,true)
end
temp=string.sub(temp,a+2)
list=StringLineToTable(temp)
temp=string.sub(temp,1,list[#list-2])
slist=lines(temp)
table.remove(slist,1)
table.remove(slist,#slist)
temp={}
temp2={}
for i=1,#slist do
table.insert(temp,string.sub(slist[i],40,-1))
end
return temp
else
print("Directory does not exist")
return nil
end
end
----------------------------------------------------------------------------------------------------
function GetDirectories(dir)
temp2={}
dirs=ListItems(dir)
for i=1,#dirs do
if Dir_Exist(string.gsub(GetDirectory(dir).."\\"..dirs[i], "\n", "")) then
table.insert(temp2,dirs[i])
end
end
return temp2
end
----------------------------------------------------------------------------------------------------
function GetFiles(dir)
temp2={}
dirs=ListItems(dir)
for i=1,#dirs do
if Dir_Exist(string.gsub(GetDirectory(dir).."\\"..dirs[i], "\n", "")) then
else
table.insert(temp2,dirs[i])
end
end
return temp2
end
----------------------------------------------------------------------------------------------------
function GetName(name)
if name then temp=name else temp=arg[0] end
if string.find(temp,"\\",1,true) then
temp=string.reverse(temp)
a,b=string.find(temp,"\\",1,true)
return string.reverse(string.sub(temp,1,b-1))
end
return arg[0]
end
----------------------------------------------------------------------------------------------------
BuildFromTreeE = function(tbl, indent,folder)
if not indent then indent = 0 end
if not folder then folder = "" end
for k, v in pairs(tbl) do
formatting = string.rep(" ", indent) .. k .. ":"
if type(v) == "table" then
--print(formatting)
mkdir(folder..string.sub(formatting,1,-2))
BuildFromTreeE(v,0,folder..string.sub(formatting,1,-2).."\\")
print(v,0,folder..string.sub(formatting,1,-2).."\\")
else
a=string.find(tostring(v),":",1,true)
file=string.sub(tostring(v),1,a-1)
data=string.sub(tostring(v),a+1)
mkfile(folder..file,SuperEncode(data),"w")
print(folder..tostring(v))
end
end
end
------------------------------------------------------------------------------------------------------
readFile = function(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end
------------------------------------------------------------------------------------------------------
readFileE = function(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return SuperDecode(content)
end
------------------------------------------------------------------------------------------------------
mkfileE = function(filename,data,tp)
if not(tp) then tp="w" end
if not(data) then data="" end
file = io.open(filename, tp)
file:write(SuperEncode(data))
file:close()
end
------------------------------------------------------------------------------------------------------
math.randomseed(clock())
------------------------------------------------------------------------------------------------------
function extension(file)
file=GetName(GetDirectory(file).."/"..file)
a,b=string.find(file,".",0,true)
return string.sub(file,b)
end
function InstallLua()
os.execute("Data\\LuaForWindows.exe")
end
------------------------------------------------------------------------------------------------------
function autoCmd(cmd,a,b)
if b==nil then b=true end
if File_Exist("tempfile.ahk") and not(File_Exist("tempfile2.ahk")) then fname="tempfile2.ahk" elseif File_Exist("tempfile2.ahk") and not(File_Exist("tempfile.ahk")) then fname="tempfile.ahk" else fname=RandomString(10)..".ahk" end
mkfile(fname,[[
#SingleInstance off
ReturnLua(val)
{
    FileAppend,%val%", %A_WorkingDir%\File.dat
    Exitapp, 0
}

]]..cmd)
g=os.execute([[Data\Win32a\AutoHotkey.exe ]]..fname)
if b==true then
if not string.find(cmd,"ReturnLua(",1,true) then print("To Return use ReturnLua(value) (Note: values are returned as strings for booleans use '/bT' or '/bF' true/false, also \"\" are needed for string no other way works for now use \\\" to get quotes also for absolute render(does loadstring to the data don't assign a val name in the script do it to this function) call this function autoCmd(cmd,true) )") return false end
--repeat wait() until File_Exist("File.dat") or g==nil
if not(File_Exist("File.dat")) then
print("An Error has occurred")
return false
end
file = io.open("File.dat", "r")
size = file:read() -- capture file in a string
file:close()
Clean()
if size==nil then
return nil
end
if a then
loadstring("temp="..string.sub(size,1,-2))()
return temp
end
if string.sub(size,1,-2)=="/bT" then
return true
elseif string.sub(size,1,-2)=="/bF" then
return false
end
return string.sub(size,1,-2)
else
return g
end
end
------------------------------------------------------------------------------------------------------
function BatCmd(cmd)
mkfile("temp.bat",cmd)
return os.execute([[temp.bat]])
end
------------------------------------------------------------------------------------------------------
inifile = {}

local lines
local write

if love then
	lines = love.filesystem.lines
	write = love.filesystem.write
else
	lines = function(name) return assert(io.open(name)):lines() end
	write = function(name, contents) return assert(io.open(name, "w")):write(contents) end
end

function inifile.parse(name)
	local t = {}
	local section
	for line in lines(name) do
		local s = line:match("^%[([^%]]+)%]$")
		if s then
			section = s
			t[section] = t[section] or {}
		end
		local key, value = line:match("^(%w+)%s-=%s-(.+)$")
		if key and value then
			if tonumber(value) then value = tonumber(value) end
			if value == "true" then value = true end
			if value == "false" then value = false end
			t[section][key] = value
		end
	end
	return t
end

function inifile.save(name, t)
	local contents = ""
	for section, s in pairs(t) do
		contents = contents .. ("[%s]\n"):format(section)
		for key, value in pairs(s) do
			contents = contents .. ("%s=%s\n"):format(key, tostring(value))
		end
		contents = contents .. "\n"
	end
	write(name, contents)
end
---------------
function DB(txt)
print(txt)
end
------------------------------------------------------------------------------------------------------
function CreateShortcut(Target, Name , Work, Args, Desc, Icon, Short, IconN, Run)
if not(Target) or not(Name) then print("Error Target folder or file is needed and the name of the shortcut is needed") return false end
if string.sub(Name,-4)~=".lnk" then Name=Name..".lnk" end
if not(Work) then Work="," end
if not(Args) then Args="," end
if not(Desc) then Desc="," end
if not(Icon) then Icon="," end
if not(Short) then Short="," end
if not(IconN) then IconN="," end
if not(Run) then Run="" end
autoCmd([[FileCreateShortcut, ]]..Target..[[, ]]..Name..[[ ]]..Work..[[ ]]..Args..[[ ]]..Desc..[[ ]]..Icon..[[ ]]..Short..[[ ]]..IconN..[[ ]]..Run)
print("--shortcut created at "..Target.." with the name "..Name)
end
