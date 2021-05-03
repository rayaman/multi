--[[
MIT License

Copyright (c) 2020 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
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
		return temp
	else
		return "arg1 must be a table or a function"
	end
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

local link={MainLibrary=Library}
Library.inject(Library,"meta",{
	__Link=link,
	__call=function(self,func) func(link) end,
})
local multi, thread = require("multi").init()
os.sleep = love.timer.sleep
multi.drawF = {}
function multi:onDraw(func, i)
	i = i or 1
	table.insert(self.drawF, i, func)
end
multi.OnKeyPressed = multi:newConnection()
multi.OnKeyReleased = multi:newConnection()
multi.OnMousePressed = multi:newConnection()
multi.OnMouseReleased = multi:newConnection()
multi.OnMouseWheelMoved = multi:newConnection()
multi.OnMouseMoved = multi:newConnection()
multi.OnDraw = multi:newConnection()
multi.OnTextInput = multi:newConnection()
multi.OnUpdate = multi:newConnection()
multi.OnQuit = multi:newConnection()
multi.OnPreLoad(function()
	local function Hook(func, conn)
		if love[func] ~= nil then
			love[func] = Library.convert(love[func])
			love[func]:inject(function(...)
				conn:Fire(...)
				return {...}
			end,1)
		elseif love[func] == nil then
			love[func] = function(...)
				conn:Fire(...)
			end
		end
	end
	Hook("quit", multi.OnQuit)
	Hook("keypressed", multi.OnKeyPressed)
	Hook("keyreleased", multi.OnKeyReleased)
	Hook("mousepressed", multi.OnMousePressed)
	Hook("mousereleased", multi.OnMouseReleased)
	Hook("wheelmoved", multi.OnMouseWheelMoved)
	Hook("mousemoved", multi.OnMouseMoved)
	Hook("draw", multi.OnDraw)
	Hook("textinput", multi.OnTextInput)
	Hook("update", multi.OnUpdate)
	multi.OnDraw(function()
		for i = 1, #multi.drawF do
			love.graphics.setColor(255, 255, 255, 255)
			multi.drawF[i]()
		end
	end)
end)

function multi:loveloop(light)
	local link
	link = multi:newThread(function()
		local mainloop = love.run()
		while true do
			thread.yield()
			pcall(mainloop)
		end
	end).OnError(function(...)
		print(...)
	end)
	if light==false then
		multi:mainloop()
	else
		multi:lightloop()
	end
end

multi.OnQuit(function()
	multi.Stop()
	love.event.quit()
end)
return multi
