-- In an attempt to speed up my library I will use a virtual machine that runs bytecode
compiler={}
compiler.cmds={ -- list of all of the commands
	EVAL="\01", -- evaluate
	SPLT="\02", -- split
	TRIM="\03", -- trim
	VEXT="\04", -- variable exists
	ILST="\05", -- is a list
	LSTR="\06", -- load string
	FCAL="\07", -- Function call
	SVAR="\08", -- set variable
	LOAD="\09", -- load file
	LAOD="\10", -- _load file
	DEFN="\11", -- define external functions
	HCBK="\12", -- Has c Block
	CMBT="\13", -- combine truths
	SETB="\14", -- set block
	STRT="\15", -- start
	PERR="\16", -- push error
	PROG="\17", -- progress
	PHED="\18", -- parse header
	SSLT="\19", -- split string
	NEXT="\20", -- next
	-- Needs refining... One step at a time right!
}
function compiler:compile(filename) -- compiles the code into bytecode
	-- First we load the code but don't run it
	local engine=parseManager:load(filename)
	-- This captures all of the methods and important info. This also ensures that the compiler and interperter stay in sync!
	local bytecodeheader=bin.new() -- header will contain the order of blocks and important flags
	local bytecode=bin.newDataBuffer() -- lets leave it at unlimited size because we don't know how long it will need to be
	local functions={} -- will be populated with the important methods that must be preloaded
	local prebytecode={} -- this contains bytecode that has yet to be sterilized
	for blockname,blockdata in pairs(engine._chunks) do
		-- lets get some variables ready
		local code,_type,nextblock,filename=blockdata[1],blockdata[2],blockdata.next,blockdata.file
		-- note nextblock may be nil on 2 condidions. The first is when the leaking flag is disabled and the other is when the block in question was the last block defined
		local lines=bin._lines(code)
		print("\n["..blockname.."]\n")
		for i=1,#lines do
			print(lines[i])
		end
	end
end
