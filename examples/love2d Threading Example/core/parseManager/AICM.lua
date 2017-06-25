AICM={}
AICM.functions={
	getAICMVersion=function(self)
		return "1.0.0"
	end,
}
function AICM:InitSyntax(obj,name)
	obj:debug("Now using the Artificial Intelligence Communication module!")
	obj.OnExtendedBlock(self.blockModule)
	obj.OnCustomSyntax(self.syntaxModule)
	obj:define(self.functions)
end
AICM.syntaxModule=function(self,line)
	pVars,mStr=line:match("p%((.-)%)(.+)")
	if pVars then
		local vRef,vars=pVars:match("(.-):(.+)")
		if vars:find(",") then
			vars={unpack(vars:split(","))}
		else
			vars={vars}
		end
		tab={self:varExists(vRef):match(mStr)} -- self:varExists allows for all internal structures to just work
		for i=1,#tab do
			if vars[i] then
				self._variables[vars[i]]=tab[i]
			end
		end
		self:p() -- requried to progress the script
		return {
			text=line,
			Type="AICMModule"
		}
	end
end
AICM.blockModule=function(obj,name,t,chunk,filename)
	--
end
