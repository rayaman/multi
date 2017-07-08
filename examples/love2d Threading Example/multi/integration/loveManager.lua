require("multi.compat.love2d")
function multi:canSystemThread()
	return true
end
multi.integration={}
multi.integration.love2d={}
multi.integration.love2d.ThreadBase=[[
tab={...}
__THREADNAME__=tab[2]
__THREADID__=tab[1]
require("love.filesystem")
require("love.system")
require("love.timer")
require("multi")
GLOBAL={}
setmetatable(GLOBAL,{
	__index=function(t,k)
		__sync__()
		return __proxy__[k]
	end,
	__newindex=function(t,k,v)
		__sync__()
		__proxy__[k]=v
		if type(v)=="userdata" then
			__MainChan__:push(v)
		else
			__MainChan__:push("SYNC "..type(v).." "..k.." "..resolveData(v))
		end
	end,
})
function __sync__()
	local data=__mythread__:pop()
	while data do
		love.timer.sleep(.001)
		if type(data)=="string" then
			local cmd,tp,name,d=data:match("(%S-) (%S-) (%S-) (.+)")
			if name=="__DIEPLZ"..__THREADID__.."__" then
				error("Thread: "..__THREADID__.." has been stopped!")
			end
			if cmd=="SYNC" then
				__proxy__[name]=resolveType(tp,d)
			end
		else
			__proxy__[name]=data
		end
		data=__mythread__:pop()
	end
end
function ToStr(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    if name then
		if type(name) == "string" then
			tmp = tmp .. "[\""..name.."\"] = "
		else
			tmp = tmp .. "["..(name or "").."] = "
		end
	end
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and " " or "")
        for k, v in pairs(val) do
            tmp =  tmp .. ToStr(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and " " or "")
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
	elseif type(val) == "function" then
        tmp = tmp .. "loadDump([===["..dump(val).."]===])"
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end
function resolveType(tp,d)
	if tp=="number" then
		return tonumber(d)
	elseif tp=="bool" then
		return (d=="true")
	elseif tp=="function" then
		return loadDump("[==["..d.."]==]")
	elseif tp=="table" then
		return loadstring("return "..d)()
	elseif tp=="nil" then
		return nil
	else
		return d
	end
end
function resolveData(v)
	local data=""
	if type(v)=="table" then
		return ToStr(v)
	elseif type(v)=="function" then
		return dump(v)
	elseif type(v)=="string" or type(v)=="number" or type(v)=="bool" or type(v)=="nil" then
		return tostring(v)
	end
	return data
end
sThread={}
local function randomString(n)
	local c=os.clock()
	local a=0
	while os.clock()<c+.1 do
		a=a+1 -- each cpu has a different load... Doing this allows up to make unique seeds for the random string
	end
	math.randomseed(a)
	local str = ''
	local strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		str = str..''..strings[math.random(1,#strings)]
	end
	return str
end
__proxy__={} -- this is where the actual globals will live
__MainChan__=love.thread.getChannel("__MainChan__")
__mythreadname__=randomString(16)
__mythread__=love.thread.getChannel(__mythreadname__)
__MainChan__:push("NEWTHREAD "..__mythreadname__.." | |")
function loadDump(d)
	local s={}
	for p in d:gmatch("(%d-)\\") do
		s[#s+1]=string.char(tonumber(p))
	end
	return loadstring(table.concat(s))
end
function dump(func)
	local code,t={},string.dump(func)
	for i=1,#t do
		code[#code+1]=string.byte(t:sub(i,i)).."\\"
	end
	return table.concat(code)
end
function sThread.set(name,val)
	GLOBAL[name]=val
end
function sThread.get(name)
	return GLOBAL[name]
end
function sThread.waitFor(name)
	repeat __sync__() until GLOBAL[name]
	return GLOBAL[name]
end
function sThread.getCores()
	return love.system.getProcessorCount()
end
function sThread.sleep(n)
	love.timer.sleep(n)
end
function sThread.hold(n)
	repeat __sync__() until n()
end
multi:newLoop(function(self)
	self:Pause()
	local ld=multi:getLoad()
	self:Resume()
	if ld<80 then
		love.timer.sleep(.01)
	end
end)
updater=multi:newUpdater()
updater:OnUpdate(__sync__)
func=loadDump([=[INSERT_USER_CODE]=])()
multi:mainloop()
]]
GLOBAL={} -- Allow main thread to interact with these objects as well
__proxy__={}
setmetatable(GLOBAL,{
	__index=function(t,k)
		return __proxy__[k]
	end,
	__newindex=function(t,k,v)
		__proxy__[k]=v
		for i=1,#__channels__ do
			if type(v)=="userdata" then
				__channels__[i]:push(v)
			else
				__channels__[i]:push("SYNC "..type(v).." "..k.." "..resolveData(v))
			end
		end
	end,
})
THREAD={} -- Allow main thread to interact with these objects as well
multi.integration.love2d.mainChannel=love.thread.getChannel("__MainChan__")
function ToStr(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    if name then
		if type(name) == "string" then
			tmp = tmp .. "[\""..name.."\"] = "
		else
			tmp = tmp .. "["..(name or "").."] = "
		end
	end
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and " " or "")
        for k, v in pairs(val) do
            tmp =  tmp .. ToStr(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and " " or "")
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
	elseif type(val) == "function" then
        tmp = tmp .. "loadDump([===["..dump(val).."]===])"
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end
function resolveType(tp,d)
	if tp=="number" then
		return tonumber(d)
	elseif tp=="bool" then
		return (d=="true")
	elseif tp=="function" then
		return loadDump("[==["..d.."]==]")
	elseif tp=="table" then
		return loadstring("return "..d)()
	elseif tp=="nil" then
		return nil
	else
		return d
	end
end
function resolveData(v)
	local data=""
	if type(v)=="table" then
		return ToStr(v)
	elseif type(v)=="function" then
		return dump(v)
	elseif type(v)=="string" or type(v)=="number" or type(v)=="bool" or type(v)=="nil" then
		return tostring(v)
	end
	return data
end
function loadDump(d)
	local s={}
	for p in d:gmatch("(%d-)\\") do
		s[#s+1]=string.char(tonumber(p))
	end
	return loadstring(table.concat(s))
end
function dump(func)
	local code,t={},string.dump(func)
	for i=1,#t do
		code[#code+1]=string.byte(t:sub(i,i)).."\\"
	end
	return table.concat(code)
end
local function randomString(n)
	local str = ''
	local strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
	for i=1,n do
		str = str..''..strings[math.random(1,#strings)]
	end
	return str
end
function multi:newSystemThread(name,func) -- the main method
    local c={}
    c.name=name
	c.ID=c.name.."<ID|"..randomString(8)..">"
    c.thread=love.thread.newThread(multi.integration.love2d.ThreadBase:gsub("INSERT_USER_CODE",dump(func)))
	c.thread:start(c.ID,c.name)
	function c:kill()
		multi.integration.GLOBAL["__DIEPLZ"..self.ID.."__"]="__DIEPLZ"..self.ID.."__"
	end
	return c
end
function love.threaderror( thread, errorstr )
	multi.OnError:Fire(thread,errorstr)
	print("Error in systemThread: "..tostring(thread)..": "..errorstr)
end
local THREAD={}
function THREAD.set(name,val)
	GLOBAL[name]=val
end
function THREAD.get(name)
	return GLOBAL[name]
end
function THREAD.waitFor(name)
	multi.OBJ_REF:Pause()
	repeat multi:lManager() until GLOBAL[name]
	multi.OBJ_REF:Resume()
	return GLOBAL[name]
end
function THREAD.getCores()
	return love.system.getProcessorCount()
end
function THREAD.sleep(n)
	love.timer.sleep(n)
end
function THREAD.hold(n)
	multi.OBJ_REF:Pause()
	repeat multi:lManager() until n()
	multi.OBJ_REF:Resume()
end
__channels__={}
multi.integration.GLOBAL=GLOBAL
multi.integration.THREAD=THREAD
updater=multi:newUpdater()
updater:OnUpdate(function(self)
	local data=multi.integration.love2d.mainChannel:pop()
	while data do
		--print("MAIN:",data)
		if type(data)=="string" then
			local cmd,tp,name,d=data:match("(%S-) (%S-) (%S-) (.+)")
			if cmd=="SYNC" then
				__proxy__[name]=resolveType(tp,d)
				for i=1,#__channels__ do
					-- send data to other threads
					if type(v)=="userdata" then
						__channels__[i]:push(v)
					else
						__channels__[i]:push("SYNC "..tp.." "..name.." "..d)
					end
				end
			elseif cmd=="NEWTHREAD" then
				__channels__[#__channels__+1]=love.thread.getChannel(tp)
				for k,v in pairs(__proxy__) do -- sync the global with each new thread
					if type(v)=="userdata" then
						__channels__[#__channels__]:push(v)
					else
						__channels__[#__channels__]:push("SYNC "..type(v).." "..k.." "..resolveData(v))
					end
				end
			end
		else
			__proxy__[name]=data
		end
		data=multi.integration.love2d.mainChannel:pop()
	end
end)
require("multi.integration.shared")
print("Integrated Love2d!")
return {
	init=function(t)
		if t then
			if t.threadNamespace then
				multi.integration.THREADNAME=t.threadNamespace
				multi.integration.love2d.ThreadBase:gsub("sThread",t.threadNamespace)
			end
			if t.globalNamespace then
				multi.integration.GLOBALNAME=t.globalNamespace
				multi.integration.love2d.ThreadBase:gsub("GLOBAL",t.globalNamespace)
			end
		end
		return GLOBAL,THREAD
	end
}
