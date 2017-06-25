engine={}
function engine:init(bytecodeFile)
	self.code=bin.load(bytecodeFile).data
end
--[[OP-CODES

]]
function engine:run(assessors)
	--
end
