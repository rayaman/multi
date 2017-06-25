EBIM={}
EBIM.functions={
	getEBIMVersion=function(self)
		return "1.0.0"
	end,
}
EBIM.registry={}
function EBIM:registerEBlock(name,func)
	self.registry[name]=func
end
function EBIM:InitSyntax(obj,name)
	obj:debug("Now using the Extended Block Interface module!")
	obj.OnExtendedBlock(self.blockModule)
	obj.OnCustomSyntax(self.syntaxModule)
	obj:define(self.functions)
end
EBIM.syntaxModule=function(self,line)
	local cmd,args=line:match("(.-) (.+):")
	if cmd then
		local goal=nil
		local _tab={}
		for i=self.pos+1,#self._cblock do
			if self._cblock[i]=="end"..cmd then
				goal=i
				break
			else
				table.insert(_tab,self._cblock[i])
			end
		end
		if goal==nil then
			self:pushError("'end"..cmd.."' Expected to close '"..cmd.."'")
		end
		if EBIM.registry[cmd] then
			EBIM.registry[cmd](self,args,_tab)
			self.pos=goal+1
		else
			self:pushError("Unknown command: "..cmd)
		end
		return {
			Type="EBIM-Data",
			text=cmd.." Block"
		}
	else
		return
	end
end
EBIM.blockModule=function(obj,name,t,chunk,filename)
	--print(">: ",obj,name,t,chunk,filename)
end
EBIM:registerEBlock("string",function(self,args,tab)
	local str={}
	for i=1,#tab do
		table.insert(str,tab[i])
	end
	self:setVariable(args,table.concat(str,"\n"))
end)
EBIM:registerEBlock("list",function(self,args,tab)
	local str={}
	for i=1,#tab do
		table.insert(str,self:varExists(tab[i]))
	end
	self:setVariable(args,str)
end)
EBIM:registerEBlock("dict",function(self,args,tab)
	local str={}
	for i=1,#tab do
		local a,b=tab[i]:match("(.-):%s*(.+)")
		str[a]=self:varExists(b)
	end
	self:setVariable(args,str)
end)
