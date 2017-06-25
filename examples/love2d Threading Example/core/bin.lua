--[[TODO
	+Better compatiblity with streamables
	+Add Data Compression
	+Add Encryption(better)
	+Create full documentation
	+Enhance VFS stuff
]]
bin={}
bin.Version={4,5,0}
bin.stage='stable'
bin.help=[[
For a list of features do print(bin.Features)
For a list of changes do print(bin.changelog)
For current version do print(bin.Version)
For current stage do print(bin.stage)
For help do print(bin.help) :D
]]
bin.credits=[[
Credits:
	Crafted by, Ryan Ward
	lzw,bit shift, and b64 conversion are not mine
]]
bin.Features=bin.Version[1]..'.'..bin.Version[2]..'.'..bin.Version[3]..' '..bin.stage..[[

print(bin.Features) And you get this thing
print(bin.Version) ]]..bin.Version[1]..'.'..bin.Version[2]..'.'..bin.Version[3]..[[ <-- your version
print(bin.Changlog) -- gives you a list of changes
print(bin.stage) ]]..bin.stage..[[ <-- your stage

Purpose
-------
Made to assist with the manipulation of binary data and efficent data management
Created by: Ryan Ward

Full documentation with examples of every function soon to come!!!
This is a brief doc for reference
Misc
----
nil					 = log(data,name,fmt)  -- data is the text that you want to log to a file, the name argument only needs to be called with the first log. It tells where to log to. If name is used again it will change the location of the log file.
string,string,string = bin.getLuaVersion() -- returns PUC/JIT,major,minor

Constructors
------------
binobj		=	bin.load(filename,s,r)						-- creates binobj from file in s and r nil then reads entire file but if not s is the start point of reading and r is either the #to read after s or from s to '#' (like string.sub())
binobj		=	bin.new(string data)						-- creates binobj from a string
binobj		=	bin.stream(file,lock)						-- creates a streamable binobj lock is defult to true if locked file is read only
binobj		=	bin.newTempFile(data)						-- creates a tempfile in stream mode
bitobj		=	bits.new(n)									-- creates bitobj from a number
vfs			=	bin.newVFS()								-- creates a new virtual file system 	--Beta
vfs			=	bin.loadVFS(path)							-- loads a saved .lvfs file				--Beta
buf			=	bin:newDataBuffer(s)						-- creates a databuffer
binobj		=	bin.bufferToBin(b)							-- converts a buffer object to a bin object
buf			=	bin.binToBuffer(b)							-- converts a bin object to a buffer obj
buf			=	bin:getDataBuffer(a,b)						-- gets a speical buffer that opperates on a streamed file. It works just like a regular data buffer
blockWriter =	bin.newNamedBlock(indexSize)				-- returns a block writer object index size is the size of the index where labels and pointers are stored
blockWriter =	bin.newStreamedNamedBlock(indexSize,path)	-- returns a streamed version of the above path is the path to write the file
blockReader =	bin.loadNamedBlock(path)					-- returns a block reader object, path is where the file is located
blockHandler=	bin.namedBlockManager(arg)					-- returns a block handler object, if arg is a string it will loade a named block file, if its a number or nil it will create a nambed block object

Note: the blockWriter that isn't streamed needs to have tofile(path) called on it to write it to a file
Note: the streamed blockWriter must have the close method used when you are done writing to it!

Helpers
-------
string	=	bin.randomName(n,ext)					-- creates a random file name if n and ext is nil then a random length is used, and '.tmp' extension is added
string	=	bin.NumtoHEX(n)							-- turns number into hex
binobj	=	bin.HEXtoBin(s)*D						-- turns hex data into binobj
string	=	bin.HEXtoStr(s)*D						-- turns hex data into string/text
string	=	bin.tohex(s)							-- turns string to hex
string	=	bin.fromhex(s)							-- turns hex to string
string	=	bin.endianflop(data)					-- flips the high order bits to the low order bits and viseversa
string	=	bin.getVersion()						-- returns the version as a string
string	=	bin.escapeStr(str)						-- system function that turns functions into easy light
string	=	bin.ToStr(tab)							-- turns a table into a string (even functions are dumped; used to create compact data files)
nil		=	bin.packLLIB(name,tab,ext)				-- turns a bunch of 'files' into 1 file tab is a table of file names, ext is extension if nil .llib is used Note: Currently does not support directories within .llib
nil		=	bin.unpackLLIB(name,exe,todir,over,ext)	-- takes that file and makes the files Note: if exe is true and a .lua file is in the .llib archive than it is ran after extraction ext is extension if nil .llib is used
boolean	=	bin.fileExist(path)						-- returns true if the file exist false otherwise
boolean*=	bin.closeto(a,b,v)						-- test data to see how close it is (a,b=tested data v=#difference (v must be <=255))
String	=	bin.textToBinary(txt)					-- turns text into binary data 10101010's
binobj	=	bin.decodeBits(bindata)					-- turns binary data into text
string	=	bin.trimNul(s)							-- terminates string at the nul char
number	=	bin.getIndexSize(tab)					-- used to get the index size of labels given to a named block
string	=	bits.numToBytes(num,occ)				-- returns the number in base256 string data, occ is the space the number will take up

Assessors
---------
nil***	=	binobj:tofile(filename)					-- writes binobj data as a file
binobj*	=	binobj:clone()							-- clones and returns a binobj
number*	=	binobj:compare(other binobj,diff)		-- returns 0-100 % of simularity based on diff factor (diff must be <=255)
string	=	binobj:sub(a,b)							-- returns string data like segment but dosen't alter the binobject
num,num	=	binobj:tonumber(a,b)					-- converts from a-b (if a and b are nil it uses the entire binobj) into a base 10 number so 'AXG' in data becomes 4675649 returns big,little endian
number	=	binobj:getbyte(n)						-- gets byte at location and converts to base 10 number
bitobj	=	binobj:tobits(i)						-- returns the 8bits of data as a bitobj Ex: if value of byte was a 5 it returns a bitobj with a value of: '00000101'
string	=	binobj:getHEX(a,b)						-- gets the HEX data from 'a' to 'b' if both a,b are nil returns entire file as hex
a,b		=	binobj:scan(s,n,f)						-- searches a binobj for 's'; n is where to start looking, 'f' is weather or not to flip the string data entered 's'
string	=	binobj:streamData(a,b)					-- reads data from a to b or a can be a data handle... I will explain this and more in offical documentation
string#	=	binobj:streamread(a,b)					-- reads data from a stream object between a and b (note: while other functions start at 1 for both stream and non stream 0 is the starting point for this one)
boolean	=	binobj:canStreamWrite()					-- returns true if the binobj is streamable and isn't locked
string	=	bitobj:conv(n)							-- converts number to binary bits (system used)
binobj	=	bitobj:tobytes()						-- converts bit obj into a string byte (0-255)
number	=	bitobj:tonumber()						-- converts '10101010' to a number
boolean	=	bitobj:isover()							-- returns true if the bits exceed 8 bits false if 8 or less
string	=	bitobj:getBin()							-- returns the binary 10100100's of the data as a string
string	=	binobj:getHash(n)						-- returns a Hash of a file (This is my own method of hashing btw) n is the length you want the hash to be
string	=	binobj:getData()						-- returns the bin object as a string
depends =	blockReader:getBlock(name)				-- returns the value associated with the name, values can be any lua data except userdata

Mutators (Changes affect the actual object or if streaming the actual file) bin:remove()
--------
nil		=	binobj:setEndOfFile(n)	-- sets the end of a file
nil		=	binobj:reverse() 		-- reverses binobj data ex: hello --> olleh
nil		=	binobj:flipbits() 		-- flips the binary bits
nil** 	=	binobj:segment(a,b)		-- gets a segment of the binobj data works just like string.sub(a,b) without str
nil*	=	binobj:insert(a,i)		-- inserts i (string or number(converts into string)) in position a
nil*	=	binobj:parseN(n)		-- removes ever (nth) byte of data
nil 	=	binobj:getlength()		-- gets length or size of binary data
nil*	=	binobj:shift(n)			-- shift the binary data by n positive --> negitive <--
nil*	=	binobj:delete(a,b)		-- deletes part of a binobj data Usage: binobj:delete(#) deletes at pos # binobj:delete(#1,#2) deletes from #1 to #2 binobj:delete('string') deletes all instances of 'byte' as a string Use string.char(#) or '\#' to get byte as a string
nil*	=	binobj:encrypt(seed)	-- encrypts data using a seed, seed may be left blank
nil*	=	binobj:decrypt(seed)	-- decrypts data encrypted with encrypt(seed)
nil*	=	binobj:shuffle()		-- Shuffles the data randomly Note: there is no way to get it back!!! If original is needed clone beforehand
nil**	=	binobj:mutate(a,i)		-- changes position a's value to i
nil		=	binobj:merge(o,t)		-- o is the binobj you are merging if t is true it merges the new data to the left of the binobj EX: b:merge(o,true) b='yo' o='data' output: b='datayo' b:merge(o) b='yo' o='data' output: b='yodata'
nil*	=	binobj:parseA(n,a,t)	-- n is every byte where you add, a is the data you are adding, t is true or false true before false after
nil		=	binobj:getHEX(a,b)		-- returns the HEX of the bytes between a,b inclusive
nil		=	binobj:cryptM()			-- a mirrorable encryptor/decryptor
nil		=	binobj:addBlock(d,n)	-- adds a block of data to a binobj s is size d is data e is a bool if true then encrypts string values. if data is larger than 'n' then data is lost. n is the size of bytes the data is Note: n is no longer needed but you must use getBlock(type) to get it back
nil		=	binobj:getBlock(t,n)	-- gets block of code by type
nil		=	binobj:seek(n)			-- used with getBlock EX below with all 3
nil*	=	binobj:morph(a,b,d)		-- changes data between point a and b, inclusive, to d
nil		=	binobj:fill(n,d)		-- fills binobj with data 'd' for n
nil		=	binobj:fillrandom(n)	-- fills binobj with random data for n
nil		=	binobj:shiftbits(n)		-- shifts all bits by n amount
nil		=	binobj:shiftbit(n,i)	-- shifts a bit ai index i by n
nil#	=	binobj:streamwrite(d,n)	-- writes to the streamable binobj d data n position
nil#	=	binobj:open()			-- opens the streamable binobj
nil#	=	binobj:close()			-- closes the streamable binobj
nil		=	binobj:wipe()			-- erases all data in the file
nil*	=	binobj:tackB(d)			-- adds data to the beginning of a file
nil		=	binobj:tackE(d)			-- adds data to the end of a file
nil		=	binobj:parse(n,f)		-- loops through each byte calling function 'f' with the args(i,binobj,data at i)
nil		=	binobj:flipbit(i)		-- flips the binary bit at position i
nil*	=	binobj:gsub()			-- just like string:gsub(), but mutates self
nil		=	blockWriter:addNamedBlock(name,value) -- writes a named block to the file with name 'name' and the value 'value'

Note: numbers are written in Big-endian use bin.endianflop(d) to filp to Little-endian

Note: binobj:tonumber() returns big,little endian so if printing do: b,l=binobj:tonumber() print(l) print(b)

nil		=	bitobj:add(i)		-- adds i to the bitobj i can be a number (base 10) or a bitobj
nil		=	bitobj:sub(i)		-- subs i to the bitobj i can be a number (base 10) or a bitobj
nil		=	bitobj:multi(i)		-- multiplys i to the bitobj i can be a number (base 10) or a bitobj
nil		=	bitobj:div(i)		-- divides i to the bitobj i can be a number (base 10) or a bitobj
nil		=	bitobj:flipbits()	-- filps the bits 1 --> 0, 0 --> 1
string	=	bitobj:getBin()		-- returns 1's & 0's of the bitobj

# stream objects only
* not compatible with stream files
** works but do not use with large files or it works to some degree
*** in stream objects all changes are made directly to the file, so there is no need to do tofile()
*D
]]

bin.Changelog=[[
Version.Major.Minor
-------------------------
1.0.0	: initial release 	load/new/tofile/clone/closeto/compare/sub/reverse/flip/segment/insert/insert/parseN/getlength/shift
1.0.1	: update			Delete/tonumber/getbyte/
1.0.2	: update			Changed how delete works. Added encrypt/decrypt/shuffle
1.0.3	: update			Added bits class, Added in bin: tobit/mutate/parseA Added in bits: add/sub/multi/div/isover/tobyte/tonumber/flip
1.0.4	: update			Changed tobyte() to tobytes()/flipbit() to flipbits() and it now returns a binobj not str Added bin:merge
1.0.5	: update			Changed bin.new() now hex data can be inserted EX: bin.new('0xFFC353D') Added in bin: getHEX/cryptM/addBlock/getBlock/seek
1.0.6	: update			Added bin.NumtoHEX/bin:getHEX/bin.HEXtoBin/bin.HEXtoStr/bin.tohex/bin.fromhex
1.0.7	: update			Added bin:morph/bin.endianflop/bin:scan/bin.ToStr
1.0.8	: update			Added bin:fill/bin:fillrandom
1.1.0	: update			Added bin.packLLIB/bin.unpackLLIB
1.2.0	: update			Updated llib files
1.3.0	: Update			Changed bin.unpackLLIB and bin.load() Added: bin.fileExist
1.4.0	: Update			Changed bin.unpackLLIB bin.packLLIB Added: bin:shiftbits(n) bin:shiftbit(n,i)

Woot!!! Version 2
2.0.0 HUGE UPDATE			Added Streamable files!!! lua 5.1, 5.2 and 5.3 compatable!!!
#binobj is the same as binobj:getlength() but only works in 5.2 and 5.3, in 5.1 just use getlength() or getSize() for compatibility
Now you can work with gigabyte sized data without memory crashes(streamable files[WIP]).

Stream Compatible methods:
	sub(a,b)
	getlength()
	tofile(filename)
	flipbits()
	tonumber(a,b)
	getbyte(n)
	segment(a,b)
	parse(n,f)
	tobits(i)
	reverse()
	flipbit(i)
	cryptM()
	getBlock(t,n)
	addBlock(d,n)
	shiftbits(n)
	shiftbit(n,i)
	getHEX(a,b)

Added functions in this version:
	binobj:streamwrite(d,n)
	binobj:open()
	binobj:close()
	binobj:tackB(d)
	binobj:tackE(d)
	binobj:parse(n,f)
	binobj:flipbit(i)
	bin.stream(file)
	binobj:streamData(a,b)
	bin.getVersion()
	bin.escapeStr(str)
	binobj:streamread(a,b)
	binobj:canStreamWrite()
	binobj:wipe()

Woot!!! Version 3
3.0.0 HUGE UPDATE!!!
		Added:		bin.newVFS() bin.loadVFS() bin.textToBinary(txt) bin.decodeBits(bindata) bitobj:getBin()
		Updated:	bin.addBlock() <-- Fixed error with added features to the bits.new() function that allow for new functions to work
		Notice:		The bin library now requires the utils library!!! Put utils.lua in the lua/ directory
3.1.0
		Added: bin.newTempFile(data) binobj:setEndOfFile(n) bin.randomName(n,ext)
		Updated: bin:tackE() bin:fill() bin:fillrandom() are now stream compatible!
		Notice: bin:setEndOfFile() only works on streamable files!
3.1.1
		Added: bin.trimNul(s) bin:gsub()
3.1.2
		Added: log(data,name,fmt)
		In secret something is brewing...

3.1.3
		Added: bin:getHash(n)
3.2.1
		Added: bin.encryptA(data,seed), bin.decryptA(data,seed), bin.encryptB(data,seed), bin.decryptB(data,seed), bin:flush()
		Updated: bin:encrypt(seed) and bin:decrypt(seed)
		Fixed: bin:shiftbit() not working right with streamable files
3.2.2
		Fixed: bits.new() -- minor mistake huge error
3.2.3
		General bug fixes
		Changed how bin.ToStr(t) -- functions are no longer valid data types
3.3.0
		Added:
			bin:getSize() -- same as bin:getlength() just makes more sense. bin:getlength() is still valid and always will be.
			bin.newLink() -- creates a link to a file object... Its like opening a file without opening it... Lua can only open a maximum of 200 files so use links if you will be going beyond that or make sure to close your files
			bin.getHash2(h,n) -- 'h' hash size 8bit,16bit,32bit,64bit, 128bit, 100000bit whatever. is a number 'n' is the segmentation size defualt is 1024 greater numbers result in faster hashes but eaiser to forge hashes
3.4.1:(7/22/2016) NOTE: I started to add dates so I can see my work flow
		Added:
			binobj:getData() -- returns bin object as a string
			bin:newDataBuffer(s)
		Fixed: binobj:tonumber(a,b)
4.0.0:(7/23/2016)
		Added:
			bin.bufferToBin(b)
			bin.binToBuffer(b)
			bin.getLuaVersion()
			bin.newNamedBlock(indexSize)
			bin.newStreamedNamedBlock(indexSize,path)
			bin.loadNamedBlock(path)
			bin.getIndexSize(tab)
			bits.numToBytes(num,occ)
4.1.0:(11/2/2016) NOTE: I took quite a long break due to college lol
	Added:
		bin.namedBlockManager(name)
			Allows for a new way to use NamedBlocks
			Example usage:
				test=bin.namedBlockManager()
				test["name"]="Ryan" -- My name lol
				test["age"]=21 -- my age lol
				test:tofile("test.dat")
				--Now lets load the data we created
				test2=bin.namedBlockManager("test.dat")
				print(test2["name"])
				print(test2["age"])
	Changed:
		bin.newNamedBlock(indexSize)
			Now allows for indexSize to be nil and dynamacally adds to the size of the index
	Fixed:
		bin.loadNamedBlock(name)
			Issue with indexing
	TODO:
		Allow streamed files to have expanding indexes
4.2.0:(12/21/2016)
	Added:
		bin.gcd(m,n) *takes number types returns a number
			gets the greatest common denominator between 2 numbers m and n
		bin.numToFraction(num) *takes number type returns a string type
			converts a decimal to a fraction
			so 5.5 would become 11/2
		bin.doubleToString(double) *takes number type returns string
			converts a double to a string
		bin.stringToDouble(str) *takes string type returns number type
			converts the doublestring into a number
			NOTE: this string can be 2 lengths! Either 9 bytes or 25 bytes... depending on the precision needed the program will convert the data
			Also: the miniheader -/+ is for 9byte doubles the miniheader _/=(same keys as -/+ on an American keyboard) is for 25byte doubles
	Changed:
		bits.numToBytes(n,fit,func)
		added argument func which is called when the number n takes up more space than size 'fit'
		passes a ref table with keys num and fit, modifying these effects the output.
		Note: If you change ref.fit make sure to make ref.num fits by adding \0 to the beginning of the numberstring
	TODO:
		add more useful features :P
4.2.1:(12/23/2016)
	Added:
		bin.decompress(comp) lzw commpression
		bin.compress(uncomp) lzw decommpression
		bin:segmentedRead(size,func)
4.3.0:(12/26/2016)
	Added:
		bin.tob64(data)
			converts string data to b64 data
		bin.fromb64(data)
			converts b64 data to string data
		bin:getB64()
			returns b64 data from binobj
		bits.lsh(value,shift) bit lshift
		bits.rsh(value,shift) bit rshift
		bits.bit(x,b) bit thing
		bits.lor(x,y) or
	Changed:
		bin.new(data,hex,b64) hex if true treats data as hexdata, b64 if true treats data like b64data
			Now allows b64 data to be used in construction of a bin file
4.4.0:(1/1/2017)
	Added:
		sinkobj=bin:newSink()
			nil=sinkobj:tackE(data)
				adds data into the sink, same method that binobj and streamobjs have. This does what you would expest the binobj to do but much quicker
			nil=sinkobj:tofile(path)
				creates a file containing the contents of the sink
			str=sinkobj:getData()
				returns the data of the sink as a string
			nil=sinkobj:reset()
				Clears the sink
4.4.1:(1/2/2017)
	Changed:
		bin.stream(file,lock)
			Modified stream files so that multiple streams can link to one file by sharing handles
4.4.2:(1/10/2017)
	Added:
		bin.freshStream(file)
			creates a stream object that wipes all data if the file already exists and readys the object for writing. In short it's doing: bin.new():tofile(file) return bin.stream(file,false)
			-- I found myself doing that so much I made a method to simplify the process
4.5.0:(3/31/2017)
	Added:
		bin:getDataBuffer(a,b) -- a and b are the location to open on the streamed object they are not required though
		-- If left out the entire file is open to used as a buffer! Even a empty streamed file works. Be sure to fill the buffer before trying to write to a location without data
		-- Index 1 is the start regardless of where you open up the file
	Note: Only works on streamed files! Use bin:newDataBuffer(s) to use the non streamed version
]]
bin.data=''
bin.t='bin'
bin.__index = bin
bin.__tostring=function(self) return self:getData() end
bin.__len=function(self) return self:getlength() end
bits={}
bits.data=''
bits.t='bits'
bits.__index = bits
bits.__tostring=function(self) return self.data end
bits.__len=function(self) return (#self.data)/8 end
bin.lastBlockSize=0
bin.streams={} -- allows for multiple stream objects on one file... tricky stuff lol
--[[----------------------------------------
Links
------------------------------------------]]
function bin.newLink(path)
	if not path then
		error("Must include a path when using a link!")
	end
	local c={}
	c.path=path
	c.tempfile={}
	local mt={
		__tostring=function(self)
			if self:getlength()>2048 then
				--
			end
		end,
		__len=function(self)
			return self:getlength()
		end
	}
	function c:getlength()
		--
	end
end


--[[----------------------------------------
utils
------------------------------------------]]
function cleanName(name)
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
		name=cleanName(name)
	end
	if not bin.logger then
		bin.logger = bin.stream(name or 'lua.log',false)
	elseif bin.logger and name then
		bin.logger:close()
		bin.logger = bin.stream(name or 'lua.log',false)
	end
	local d=os.date('*t',os.time())
	bin.logger:tackE((fmt or '['..math.numfix(d.month,2)..'-'..math.numfix(d.day,2)..'-'..d.year..'|'..math.numfix(d.hour,2)..':'..math.numfix(d.min,2)..':'..math.numfix(d.sec,2)..']\t')..data..'\n')
end
function io.mkFile(filename,data,tp)
	if not(tp) then tp='wb' end
	if not(data) then data='' end
	file = io.open(filename, tp)
	if file==nil then return end
	file:write(data)
	file:close()
end
function io.getWorkingDir()
	return io.popen'cd':read'*l'
end
function getAllItems(dir)
	local t=os.capture("cd \""..dir.."\" & dir /a-d | find",true):lines()
	return t
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
function io.scanDir(directory)
	directory=directory or io.getDir()
    local i, t, popen = 0, {}, io.popen
	if os.getOS()=='unix' then
		for filename in popen('ls -a "'..directory..'"'):lines() do
			i = i + 1
			t[i] = filename
		end
	else
		for filename in popen('dir "'..directory..'" /b'):lines() do
			i = i + 1
			t[i] = filename
		end
	end
    return t
end
function io.getDir(dir)
	if not dir then return io.getWorkingDir() end
	if os.getOS()=='unix' then
		return os.capture('cd '..dir..' ; cd')
	else
		return os.capture('cd '..dir..' & cd')
	end
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
function io.readFile(file)
    local f = io.open(file, 'rb')
    local content = f:read('*all')
    f:close()
    return content
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
function io.getPathName(path)
	return path:sub(1,#path-#io.getFullName(path))
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
function io.splitPath(str)
   return string.split(str,'[\\/]+')
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
--[[----------------------------------------
Random
Not all of this is mine
------------------------------------------]]
--[[------------------------------------
RandomLua v0.3.1
Pure Lua Pseudo-Random Numbers Generator
Under the MIT license.
copyright(c) 2011 linux-man
--]]------------------------------------

local math_floor = math.floor

local function normalize(n) --keep numbers at (positive) 32 bits
	return n % 0x80000000
end

local function bit_and(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if (a % 2 == 1) and (b % 2 == 1) then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function bit_or(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if (a % 2 == 1) or (b % 2 == 1) then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function bit_xor(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if a % 2 ~= b % 2 then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function seed()
	--return normalize(tonumber(tostring(os.time()):reverse()))
	return normalize(os.time())
end

--Mersenne twister
mersenne_twister = {}
mersenne_twister.__index = mersenne_twister

function mersenne_twister:randomseed(s)
	if not s then s = seed() end
	self.mt[0] = normalize(s)
	for i = 1, 623 do
		self.mt[i] = normalize(0x6c078965 * bit_xor(self.mt[i-1], math_floor(self.mt[i-1] / 0x40000000)) + i)
	end
end

function mersenne_twister:random(a, b)
	local y
	if self.index == 0 then
		for i = 0, 623 do
			--y = bit_or(math_floor(self.mt[i] / 0x80000000) * 0x80000000, self.mt[(i + 1) % 624] % 0x80000000)
			y = self.mt[(i + 1) % 624] % 0x80000000
			self.mt[i] = bit_xor(self.mt[(i + 397) % 624], math_floor(y / 2))
			if y % 2 ~= 0 then self.mt[i] = bit_xor(self.mt[i], 0x9908b0df) end
		end
	end
	y = self.mt[self.index]
	y = bit_xor(y, math_floor(y / 0x800))
	y = bit_xor(y, bit_and(normalize(y * 0x80), 0x9d2c5680))
	y = bit_xor(y, bit_and(normalize(y * 0x8000), 0xefc60000))
	y = bit_xor(y, math_floor(y / 0x40000))
	self.index = (self.index + 1) % 624
	if not a then return y / 0x80000000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a)
		end
	else
		return a + (y % (b - a + 1))
	end
end

function twister(s)
	local temp = {}
	setmetatable(temp, mersenne_twister)
	temp.mt = {}
	temp.index = 0
	temp:randomseed(s)
	return temp
end

--Linear Congruential Generator
linear_congruential_generator = {}
linear_congruential_generator.__index = linear_congruential_generator

function linear_congruential_generator:random(a, b)
	local y = (self.a * self.x + self.c) % self.m
	self.x = y
	if not a then return y / 0x10000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a) end
	else
		return a + (y % (b - a + 1))
	end
end

function linear_congruential_generator:randomseed(s)
	if not s then s = seed() end
	self.x = normalize(s)
end

function lcg(s, r)
	local temp = {}
	setmetatable(temp, linear_congruential_generator)
	temp.a, temp.c, temp.m = 1103515245, 12345, 0x10000  --from Ansi C
	if r then
		if r == 'nr' then temp.a, temp.c, temp.m = 1664525, 1013904223, 0x10000 --from Numerical Recipes.
		elseif r == 'mvc' then temp.a, temp.c, temp.m = 214013, 2531011, 0x10000 end--from MVC
	end
	temp:randomseed(s)
	return temp
end

-- Multiply-with-carry
multiply_with_carry = {}
multiply_with_carry.__index = multiply_with_carry

function multiply_with_carry:random(a, b)
	local m = self.m
	local t = self.a * self.x + self.c
	local y = t % m
	self.x = y
	self.c = math_floor(t / m)
	if not a then return y / 0x10000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a) end
	else
		return a + (y % (b - a + 1))
	end
end

function multiply_with_carry:randomseed(s)
	if not s then s = seed() end
	self.c = self.ic
	self.x = normalize(s)
end

function mwc(s, r)
	local temp = {}
	setmetatable(temp, multiply_with_carry)
	temp.a, temp.c, temp.m = 1103515245, 12345, 0x10000  --from Ansi C
	if r then
		if r == 'nr' then temp.a, temp.c, temp.m = 1664525, 1013904223, 0x10000 --from Numerical Recipes.
		elseif r == 'mvc' then temp.a, temp.c, temp.m = 214013, 2531011, 0x10000 end--from MVC
	end
	temp.ic = temp.c
	temp:randomseed(s)
	return temp
end
-- Little bind for the methods: My code starts
randomGen={}
randomGen.__index=randomGen
function randomGen:new(s)
	local temp={}
	setmetatable(temp,randomGen)
	temp[1]=twister()
	temp[2]=lcg()
	temp[3]=mwc()
	temp.pos=1
	for i=1,3 do
		temp[i]:randomseed(s)
	end
	return temp
end
function randomGen:randomseed(s)
	self.pos=1
	self[1]:randomseed(s)
	self[2]:randomseed(s)
	self[3]:randomseed(s)
end
function randomGen:randomInt(a,b)
	local t=self[self.pos]:random(a,b)
	self.pos=self.pos+1
	if self.pos>3 then
		self.pos=1
	end
	return t
end
function randomGen:newND(a,b,s)
	if not(a) or not(b) then error('You must include a range!') end
	local temp=randomGen:new(s)
	temp.a=a
	temp.b=b
	temp.range=b-a+1
	temp.dups={no=0}
	function temp:nextInt()
		local t=self:randomInt(self.a,self.b)
		if self.dups[t]==nil then
			self.dups[t]=true
			self.dups.no=self.dups.no+1
		else
			return self:nextInt()
		end
		if self.dups.no==self.range then
			function self:nextInt()
				return 1,true
			end
			return t
		else
			return t
		end
	end
	function temp:nextIInt()
		return function() return self:nextInt() end
	end
	return temp
end
lzw = {}
function lzw.encode(uncompressed) -- string
  local dictionary, result, dictSize, w, c = {}, {}, 255, ""
  for i = 0, 255 do
    dictionary[string.char(i)] = i
  end
  for i = 1, #uncompressed do
    c = string.sub(uncompressed, i, i)
    if dictionary[w .. c] then
      w = w .. c
    else
      table.insert(result, dictionary[w])
      dictSize = dictSize + 1
      dictionary[w .. c] = dictSize
      w = c
    end
  end
  if w ~= "" then
    table.insert(result, dictionary[w])
  end
  return result
end

function lzw.decode(compressed) -- table
  local dictionary, dictSize, entry, result, w, k = {}, 255, "", "", ""
  for i = 0, 255 do
    dictionary[i] = string.char(i)
  end
  for i = 1, #compressed do
    k = compressed[i]
    if dictionary[k] then
      entry = dictionary[k]
    elseif k == dictSize then
      entry = w .. string.sub(w, 1, 1)
    else
      return nil, i
    end
    result = result .. entry
    dictionary[dictSize] = w .. string.sub(entry, 1, 1)
    dictSize = dictSize + 1
    w = entry
  end
  return result
end
--[[----------------------------------------
BIN
------------------------------------------]]

function bin:newSink()
	local c={}
	c.data={}
	c.name="sinkobj"
	c.num=1
	c.type="sink"
	function c:tackE(data)
		self.data[self.num]=data
		self.num=self.num+1
	end
	function c:tofile(path)
		bin.new(table.concat(self.data)):tofile(path)
	end
	function c:getData()
		return table.concat(self.data)
	end
	function c:reset()
		self.data={}
	end
	function c:close()
		-- does nothing lol
	end
	return c
end
function bin:segmentedRead(size,func)
	local mSize=self:getSize()
	local pSize=size
	local iter=math.ceil(mSize/pSize)
	for i=0,iter-1 do
		func(self:sub((i*pSize)+1,(i+1)*pSize))
	end
end
function bin.compress(uncomp,n)
	n=n or 9
	local cipher = lzw.encode(uncomp)
	local dat={}
	for i=1,#cipher do
		local fix=bits.new(cipher[i]).data:match("0*(%d+)")
		if cipher[i]==0 then
			fix=string.rep("0",n)
		end
		fix=string.rep("0",n-#fix)..fix
		table.insert(dat,fix)
	end
	str=table.concat(dat,"")
	str=string.rep("0",8-#str%8)..str
	comp={}
	for i=0,(#str/8) do
		table.insert(comp,bits.new(str:sub(i*8+1,i*8+8)):toSbytes())
	end
	return table.concat(comp,"")
end
function bin.decompress(comp,n)
	n=n or 9
	local tab={}
	for i=1,#comp do
		table.insert(tab,bits.new(comp:sub(i,i)).data)
	end
	tab=table.concat(tab,"")
	tab=tab:match("0*(%d+)")
	tab=string.rep("0",n-#tab%n)..tab
	uncomp={}
	for i=0,(#tab/n) do
		table.insert(uncomp,tonumber(tab:sub(i*n+1,i*n+n),2))
	end
	return lzw.decode(uncomp)
end
function bin:getSize()
	return self:getlength()
end
function bin.getVersion()
	return bin.Version[1]..'.'..bin.Version[2]..'.'..bin.Version[3]
end
function bin:gsub(...)
	self.data=self.data:gsub(...)
end
--
function bin:trim()
	self.data=self.data:match'^()%s*$' and '' or self.data:match'^%s*(.*%S)'
end
function bin._trim(str)
	return str:match'^()%s*$' and '' or str:match'^%s*(.*%S)'
end
function bin:fullTrim(empty)
	local t=self:lines()
	for i=#t,1,-1 do
		t[i]=bin._trim(t[i])
		if empty then
			if t[i]=="" then
				table.remove(t,i)
			end
		end
	end
	self.data = table.concat(t,"\n")
end
function bin:lines()
	local t = {}
	local function helper(line) table.insert(t, line) return '' end
	helper((self.data:gsub('(.-)\r?\n', helper)))
	return t
end
function bin._lines(str)
	local t = {}
	local function helper(line) table.insert(t, line) return '' end
	helper((str:gsub('(.-)\r?\n', helper)))
	return t
end
--
function bin:find(...)
	return self.data:find(...)
end
function bin.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

-- working lua base64 codec (c) 2006-2008 by Alex Kloss
-- compatible with lua 5.1
-- http://www.it-rfc.de
-- licensed under the terms of the LGPL2
bin.base64chars = {[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',[8]='I',[9]='J',[10]='K',[11]='L',[12]='M',[13]='N',[14]='O',[15]='P',[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',[21]='V',[22]='W',[23]='X',[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',[31]='f',[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',[40]='o',[41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',[48]='w',[49]='x',[50]='y',[51]='z',[52]='0',[53]='1',[54]='2',[55]='3',[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',[61]='9',[62]='-',[63]='_'}
function bin.tob64(data)
	local bytes = {}
	local result = ""
	for spos=0,string.len(data)-1,3 do
		for byte=1,3 do bytes[byte] = string.byte(string.sub(data,(spos+byte))) or 0 end
		result = string.format('%s%s%s%s%s',result,bin.base64chars[bits.rsh(bytes[1],2)],bin.base64chars[bits.lor(bits.lsh((bytes[1] % 4),4), bits.rsh(bytes[2],4))] or "=",((#data-spos) > 1) and bin.base64chars[bits.lor(bits.lsh(bytes[2] % 16,2), bits.rsh(bytes[3],6))] or "=",((#data-spos) > 2) and bin.base64chars[(bytes[3] % 64)] or "=")
	end
	return result
end
bin.base64bytes = {['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['-']=62,['_']=63,['=']=nil}
function bin.fromb64(data)
	local chars = {}
	local result=""
	for dpos=0,string.len(data)-1,4 do
		for char=1,4 do chars[char] = bin.base64bytes[(string.sub(data,(dpos+char),(dpos+char)) or "=")] end
		result = string.format('%s%s%s%s',result,string.char(bits.lor(bits.lsh(chars[1],2), bits.rsh(chars[2],4))),(chars[3] ~= nil) and string.char(bits.lor(bits.lsh(chars[2],4), bits.rsh(chars[3],2))) or "",(chars[4] ~= nil) and string.char(bits.lor(bits.lsh(chars[3],6) % 192, (chars[4]))) or "")
	end
	return result
end
-- ^^

function bin:getB64()
	return bin.tob64(self.data)
end
if table.unpack==nil then
	table.unpack=unpack
end
function bin.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end
function bin:streamData(a,b)
	if type(a)=='table' then
		a,b,t=table.unpack(a)
	end
	if type(a)=='number' and type(b)=='string' then
		return bin.load(self.file,a,b),bin.load(self.file,a,b).data
	else
		error('Invalid args!!! Is do you have a valid stream handle or is this a streamable object?')
	end
end
function bin.new(data,hex,b64)
	data=data or ""
	data=tostring(data)
	local c = {}
    setmetatable(c, bin)
	if string.sub(data,1,2)=='0x' and hex then
		data=string.sub(data,3)
		data=bin.fromhex(data)
	elseif hex then
		data=bin.fromhex(data)
	end
	if b64 then
		data=bin.fromb64(data)
	end
	c.data=data
	c.t='bin'
	c.Stream=false
    return c
end
function bin.freshStream(file)
	bin.new():tofile(file)
	return bin.stream(file,false)
end
function bin.stream(file,l)
	local c=bin.new()
	if bin.streams[file]~=nil then
		c.file=file
		c.lock = l
		c.workingfile=bin.streams[file].workingfile
		c.Stream=true
		return c
	end
	if bin.fileExist(file) then
		c.file=file
		c.lock = l
		c.workingfile=io.open(file,'rb+')
	else
		c.file=file
		c.lock = l
		c.workingfile=io.open(file,'w')
		io.close(c.workingfile)
		c.workingfile=io.open(file,'rb+')
	end
	c.Stream=true
	bin.streams[file]=c
	return c
end
function bin:streamwrite(d,n)
	if self:canStreamWrite() then
		if n then
			self.workingfile:seek('set',n)
		else
			self.workingfile:seek('set',self.workingfile:seek('end'))
		end
		self.workingfile:write(d)
	end
end
function bin:streamread(a,b)
	a=a-1
	local loc=self.workingfile:seek('cur')
	self.workingfile:seek('set',a)
	local dat=self.workingfile:read(b-a)
	self.workingfile:seek('set',loc)
	return dat
end
function bin:streamreadNext(a)
	return self.workingfile:read(a)
end
function bin:close()
	if self:canStreamWrite() then
		self.workingfile:close()
	end
end
function bin:flush()
	if self:canStreamWrite() then
		self.workingfile:flush()
	else
		self:tofile(self.filepath)
	end
end
function bin:open()
	if self:canStreamWrite() then
		self.workingfile=io.open(self.file,'r+')
	end
end
function bin:canStreamWrite()
	return (self.Stream==true and self.lock==false)
end
function bin:getDataBuffer(a,b,filler)
	if self:canStreamWrite() then
		if not(a) and not(b) then
			a=1
			b=math.huge
		elseif a and not(b) then
			b=a
			a=1
			if self:getSize()<a then
				stt="\0"
				if filler then
					stt=filler:sub(1,1)
				end
				self:streamwrite(string.rep(stt,b-1),1)
			end
		elseif self:getSize()<b then
			stt="\0"
			if filler then
				stt=filler:sub(1,1)
			end
			self:streamwrite(string.rep(stt,b-a),a)
		end
		local me=self
		local s=b-a
		local ss=a
		local max=b
		local c={}
		local mt={
			__index=function(t,k,v) -- GOOD
				if k<=s then
					return string.byte(me:streamread(k+(ss-1),k+(ss-1)))
				else
					return
				end
			end,
			__newindex=function(t,k,v) -- GOOD
				k=k-1
				if type(v)=="number" and s>=k then
					me:streamwrite(string.char(v),k+(ss-1))
				elseif type(v)=="string" and s>=k then
					if #v~=1 then
						t:fillBuffer(v,k+(ss))
					elseif s>=k then
						me:streamwrite(v,k+(ss-1))
					else
						print("Buffer Overflow!")
					end
				else
					print("Warning Attempting to index outside defined range!")
				end
			end,
			__tostring=function(t) -- GOOD
				return t:getBuffer()
			end
		}
		c.t="buffer"
		c.dataS={}
		function c:getBuffer(a,b) -- GOOD
			if not(a) and not(b) then
				local str={}
				for i=ss,max do
					table.insert(str,me:streamread(i+(ss-1),i+(ss-1)))
				end
				return table.concat(str)
			else
				return me:streamread(a+(ss-1),b+(ss-1))
			end
		end
		function c:getData() -- GOOD
			return self:getBuffer()
		end
		function c:getBufferTable() -- GOOD
			local str={}
			for i=ss,max do
				table.insert(str,me:streamread(i+(ss-1),i+(ss-1)))
			end
			return str
		end
		function c:getBufferSize() -- GOOD
			return #self:getBuffer()
		end
		function c:getlength() -- GOOD
			return #self:getBuffer()
		end
		function c:tonumber(a,b) -- GOOD
			return bin.new(self:getBuffer(a,b)):tonumber()
		end
		c.getSize=c.getlength
		function c:fillBuffer(sg,a) -- GOOD
			for i=#sg+(a-1),a,-1 do
				if i<=max then
					local ii=(a+#sg)-i
					self[ii+(a-1)]=sg:sub(ii,ii)
				else
					return print("Buffer Overflow!")
				end
			end
			return a,a+#sg-1
		end
		setmetatable(c,mt)
		return c
	else
		error("Stream not opened for writing!")
	end
end
function bin.load(file,s,r)
	if not(s) or not(r) then
	if type(file)~="string" then return bin.new() end
		local f = io.open(file, 'rb')
		local content = f:read('*a')
		f:close()
		return bin.new(content)
	end
	s=s or 0
	r=r or -1
	if type(r)=='number' then
		r=r+s-1
	elseif type(r)=='string' then
		r=tonumber(r) or -1
	end
    local f = io.open(file, 'rb')
	f:seek('set',s)
    local content = f:read((r+1)-s)
    f:close()
	local temp=bin.new(content)
	temp.filepath=file
    return temp
end
function bin:tofile(filename)
	if not(filename) or self.Stream then return nil end
	io.mkFile(filename,self.data)
end
function bin.trimNul(s)
	for i=1,#s do
		if s:sub(i,i)=='\0' then
			return s:sub(1,i-1)
		end
	end
	return s
end
function bin:match(pat)
	return self.data:match(pat)
end
function bin:gmatch(pat)
	return self.data:gmatch(pat)
end
function bin:getHash(n)
	if self:getlength()==0 then
		return "NaN"
	end
	n=(n or 32)/2
	local rand = randomGen:newND(1,self:getlength(),self:getlength())
	local h,g={},0
	for i=1,n do
		g=rand:nextInt()
		table.insert(h,bin.tohex(self:sub(g,g)))
	end
	return table.concat(h,'')
end
function bin:getRandomHash(n)
	if self:getlength()==0 then
		return "NaN"
	end
	n=(n or 32)/2
	local rand = randomGen:new(math.random(1,self:getlength()^2))
	local h,g={},0
	for i=1,n do
		g=rand:randomInt(1,self:getlength())
		table.insert(h,bin.tohex(self:sub(g,g)))
	end
	return table.concat(h,'')
end
function bin:newDataBuffer(s,def)
	local c={}
	local mt={
		__index=function(t,k,v)
			if k<=t.maxBuffer then
				if t.dataS[k] then
					return string.byte(t.dataS[k])
				else
					return "NOINDEX"
				end
			else
				return
			end
		end,
		__newindex=function(t,k,v)
			if type(v)=="number" and t.maxBuffer>=k then
				t.dataS[k]=string.char(v)
			elseif type(v)=="string" and t.maxBuffer>=k then
				if #v~=1 then
					t:fillBuffer(v,k)
				elseif t.maxBuffer>=k then
					t.dataS[k]=v
				else
					print("Buffer Overflow!")
				end
			end
		end,
		__tostring=function(t)
			return t:getBuffer()
		end
	}
	c.t="buffer"
	c.dataS={}
	if s then
		if type(s)=="number" then
			c.maxBuffer=s
			s=string.rep(def or"\0",s)
		else
			c.maxBuffer=math.huge
		end
		for i=1,#s do
			c.dataS[i]=s:sub(i,i)
		end
	else
		c.maxBuffer=math.huge
	end
	function c:getBuffer(a,b)
		if a and b then
			return table.concat(self.dataS,""):sub(a,b)
		else
			return table.concat(self.dataS,"")
		end
	end
	function c:getData()
		return table.concat(self.dataS,"")
	end
	function c:getBufferTable()
		return self.dataS
	end
	function c:getBufferSize()
		if self.maxBuffer~=math.huge then
			return self.maxBuffer
		end
		return #self:getBuffer()
	end
	function c:getlength()
		return #self:getBuffer(a,b)
	end
	function c:tonumber(a,b)
		return bin.new(self:getBuffer(a,b)):tonumber()
	end
	c.getSize=c.getlength
	function c:fillBuffer(s,a)
		for i=0,#s-1 do
			if i+a<=self.maxBuffer then
				c.dataS[i+a]=s:sub(i+1,i+1)
			else
				return "Buffer Overflow!"
			end
		end
		return a,a+#s-1
	end
	setmetatable(c,mt)
	return c
end
function bin:getHash2(h,n)
	n=n or 1024
	h=(h or 32)
	local temp=bin.new()
	local len=self:getSize()
	local seg=math.ceil(len/n)
	temp:fill("\0",h)
	for i=1,seg do
		local s=bin.new(self:sub(n*(i-1)+1,n*i)):getHash(h)
		for i=1,h do
			temp:shiftbit(string.byte(s:sub(i,i)),i)
		end
	end
	return temp:getHEX()
end
function bin.encryptA(data,seed)
	seed=seed or 1
	local d=bin.new(data)
	local r=randomGen:newND(1,#d.data,seed)
	for i=1,#d.data do
		d:shiftbit(r:nextInt(),i)
	end
	return bin.tohex(d.data)
end
function bin.decryptA(data,seed)
	seed=seed or 1
	local d=bin.new('0x'..data)
	local r=randomGen:newND(1,#d.data,seed)
	for i=1,#d.data do
		d:shiftbit(-r:nextInt(),i)
	end
	return d.data
end
function bin.encryptB(data,seed)
	seed=seed or 'abcdefghijklmnopqrstuvwxyz'
	seed=tostring(seed)
	local d=bin.new(data)
	local r,mr=1,#seed
	for i=1,#d.data do
		d:shiftbit(string.byte(seed:sub(r,r)),i)
		r=r+1
		if r>mr then
			r=1
		end
	end
	return bin.tohex(d.data)
end
function bin.decryptB(data,seed)
	seed=seed or 'abcdefghijklmnopqrstuvwxyz'
	seed=tostring(seed)
	local d=bin.new('0x'..data)
	local r,mr=1,#seed
	for i=1,#d.data do
		d:shiftbit(-string.byte(seed:sub(r,r)),i)
		r=r+1
		if r>mr then
			r=1
		end
	end
	return d.data
end
function bin:encrypt(seed)
	seed=seed or 'abcdefghijklmnopqrstuvwxyz'
	seed=tostring(seed)
	local r,mr=1,#seed
	for i=1,self:getlength() do
		self:shiftbit(string.byte(seed:sub(r,r)),i)
		r=r+1
		if r>mr then
			r=1
		end
	end
end
function bin:decrypt(seed)
	seed=seed or 'abcdefghijklmnopqrstuvwxyz'
	seed=tostring(seed)
	local r,mr=1,#seed
	for i=1,self:getlength() do
		self:shiftbit(-string.byte(seed:sub(r,r)),i)
		r=r+1
		if r>mr then
			r=1
		end
	end
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
function bin.newTempFile(data)
	data=data or ''
	local name=bin.randomName()
	bin.new():tofile(name)
	local tempfile=bin.stream(name,false)
	tempfile:streamwrite(data,0)
	tempfile:setEndOfFile(#data)
	return tempfile
end
function bin:wipe()
	if self:canStreamWrite() then
		self:close()
		os.remove(self.file)
		self:open()
	else
		self.data=''
	end
end
function bin:setEndOfFile(n)
	if self:canStreamWrite() then
		local name=bin.randomName()
		local tempfile=bin.stream(name,false)
		tempfile:streamwrite(self:sub(0,n-1))
		self:close()
		os.remove(self.file)
		tempfile:close()
		os.rename(name,self.file)
		self:open()
		tempfile=nil
	else
		self.data=self.data:sub(1,n)
	end
end
function bin:reverse()
	if self:canStreamWrite() then
		local x,f,b=self:getlength(),0,0
		for i=0,math.floor((x-1)/2) do
			self:streamwrite(self:sub(i+1,i+1),x-i-1)
			self:streamwrite(self:sub(x-i,x-i),i)
		end
	elseif self.Stream==false then
		self.data=string.reverse(self.data)
	end
end
function bin:flipbits()
	if self:canStreamWrite() then
		for i=0,self:getlength()-1 do
			self:streamwrite(string.char(255-string.byte(self:streamread(i,i))),i)
		end
	elseif self.Stream==false then
		local temp={}
		for i=1,#self.data do
			table.insert(temp,string.char(255-string.byte(string.sub(self.data,i,i))))
		end
		self.data=table.concat(temp,'')
	end
end
function bin:flipbit(i)
	if self:canStreamWrite() then
		self:streamwrite(string.char(255-string.byte(self:streamread(i-1,i-1))),i-1)
	elseif self.Stream==false then
		self:mutate(string.char(255-string.byte(string.sub(self.data,i,i))),i)
	end
end
function bin:segment(a,b) -- needs to be updated!!!
	if self:canStreamWrite() then
		--[[local pos=1
		for i=a,b do
			self:streamwrite(self:sub(i,i),b-a-i)
		end]]
		local temp=self:sub(a,b)
		self:close()
		local f=io.open(self.file,'w')
		f:write(temp)
		io.close(f)
		self:open()
	elseif self.Stream==false then
		self.data=string.sub(self.data,a,b)
	end
end
function bin:insert(i,a)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		if type(i)=='number' then i=string.char(i) end
		self.data=string.sub(self.data,1,a)..i..string.sub(self.data,a+1)
	end
end
function bin:parseN(n)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		local temp={}
		for i=1,#self.data do
			if i%n==0 then
				table.insert(temp,string.sub(self.data,i,i))
			end
		end
		self.data=table.concat(temp,'')
	end
end
function bin:parse(n,f)
	local f = f
	local n=n or 1
	if not(f) then return end
	for i=1,self:getlength() do
		if i%n==0 then
			f(i,self,self:sub(i,i))
		end
	end
end
function bin.copy(file,tofile,s)
	if not(s) then
		bin.load(file):tofile(tofile)
	else
		rf=bin.stream(file)
		wf=bin.stream(tofile,false)
		for i=1,rf:getlength(),s do
			wf:streamwrite(rf:sub(i,i-1+s))
		end
	end
end
function bin:getlength()
	if self.Stream then
		if self.workingfile==nil then print("Error getting size of file!") return 0 end
		local current = self.workingfile:seek()      -- get current position
		local size = self.workingfile:seek('end')    -- get file size
		self.workingfile:seek('set', current)        -- restore position
		return size
	elseif self.Stream==false then
		return #self.data
	end
end
function bin:sub(a,b)
	if self.Stream then
		return bin.load(self.file,a-1,tostring(b-1)).data
	elseif self.Stream==false then
		return string.sub(self.data,a,b)
	end
end
function bin:tackB(d)
	if self:canStreamWrite() then
		-- do something don't know if possible
	elseif self.Stream==false then
		self.data=d..self.data
	end
end
function bin:tackE(d)
	if type(d)=='table' then
		if d:canStreamWrite() then
			d=d:sub(1,d:getlength())
		else
			d=d.data
		end
		return
	end
	if self:canStreamWrite() then
		self:streamwrite(d)
	elseif self.Stream==false then
		self.data=self.data..d
	end
end
function bin:clone(filename)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		return bin.new(self.data)
	end
end
function bin.closeto(a,b,v)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		if type(a)~=type(b) then
			error('Attempt to compare unlike types')
		elseif type(a)=='number' and type(b)=='number' then
			return math.abs(a-b)<=v
		elseif type(a)=='table' and type(b)=='table' then
			if a.data and b.data then
				return (math.abs(string.byte(a.data)-string.byte(b.data)))<=v
			else
				error('Attempt to compare non-bin data')
			end
		elseif type(a)=='string' and type(b)=='string' then
			return math.abs(string.byte(a)-string.byte(b))<=v
		else
			error('Attempt to compare non-bin data')
		end
	end
end
function bin:compare(_bin,t)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		t=t or 1
		local tab={}
		local a,b=self:getlength(),_bin:getlength()
		if not(a==b) then
			print('Unequal Lengths!!! Equalizing...')
			if a>b then
				_bin.data=_bin.data..string.rep(string.char(0),a-b)
			else
				self.data=self.data..string.rep(string.char(0),b-a)
			end
		end
		if t==1 then
			for i=1,self:getlength() do
				table.insert(tab,self:sub(i,i)==_bin:sub(i,i))
			end
		else
			for i=1,self:getlength() do
				table.insert(tab,bin.closeto(self:sub(i,i),_bin:sub(i,i),t))
			end
		end
		local temp=0
		for i=1,#tab do
			if tab[i]==true then
				temp=temp+1
			end
		end
		return (temp/#tab)*100
	end
end
function bin:shift(n)
	if self:canStreamWrite() then
		local a,b,x,p='','',self:getlength(),0
		for i=1,x do
			if i+n>x then
				p=(i+n)-(x)
			else
				p=i+n
			end
		end
	elseif self.Stream==false then
		n=n or 0
		local s=#self.data
		if n>0 then
			self.data = string.sub(self.data,s-n+1)..string.sub(self.data,1,s-n)
		elseif n<0 then
			n=math.abs(n)
			self.data = string.sub(self.data,n+1)..string.sub(self.data,1,n*1)
		end
	end
end
function bin:delete(a,b)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		if type(a)=='string' then
			local tab={}
			for i=1,self:getlength() do
				if self:getbyte(i)~=string.byte(a) then
					table.insert(tab,self:sub(i,i))
				end
			end
			self.data=table.concat(tab)
		elseif a and not(b) then
			self.data=self:sub(1,a-1)..self:sub(a+1)
		elseif a and b then
			self.data=self:sub(1,a-1)..self:sub(b+1)
		else
			self.data=''
		end
	end
end
function bin:tonumber(a,b)
	local temp={}
	if a then
		temp.data=self:sub(a,b)
	else
		temp=self
	end
	local l,r=0,0
	local g=#temp.data
	for i=1,g do
		r=r+(256^(g-i))*string.byte(string.sub(temp.data,i,i))
		l=l+(256^(i-1))*string.byte(string.sub(temp.data,i,i))
	end
	return r,l
end
function bin:getbyte(n)
	return string.byte(self:sub(n,n))
end
function bin:shuffle(s)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		s=tonumber(s) or 4546
		math.randomseed(s)
		local t={}
			for i=1,self:getlength() do
				table.insert(t,self:sub(i,i))
			end
		local n = #t
		while n >= 2 do
			local k = math.random(n)
			t[n], t[k] = t[k], t[n]
			n = n - 1
		end
		self.data=table.concat(t)
	end
end
function bin:tobits(i)
	return bits.new(self:getbyte(i))
end
function bin:mutate(a,i)
	if self:canStreamWrite() then
		self:streamwrite(a,i-1)
	elseif self.Stream==false then
		self:delete(i)
		self:insert(a,i-1)
	end
end
function bin:parseA(n,a,t)
	if self:canStreamWrite() then
		-- do something
	elseif self.Stream==false then
		local temp={}
		for i=1,#self.data do
			if i%n==0 then
				if t then
					table.insert(temp,a)
					table.insert(temp,string.sub(self.data,i,i))
				else
					table.insert(temp,string.sub(self.data,i,i))
					table.insert(temp,a)
				end
			else
				table.insert(temp,string.sub(self.data,i,i))
			end
		end
		self.data=table.concat(temp,'')
	end
end
function bin:merge(o,t)
	if self:canStreamWrite() then
		self:close()
		self.workingfile=io.open(self.file,'a+')
		self.workingfile:write(o.data)
		self:close()
		self:open()
	elseif self.Stream==false then
		if not(t) then
			self.data=self.data..o.data
		else
			seld.data=o.data..self.data
		end
	end
end
function bin:cryptM()
	self:flipbits()
	self:reverse()
end
function bin.escapeStr(str)
	local temp=''
	for i=1,#str do
		temp=temp..'\\'..string.byte(string.sub(str,i,i))
	end
	return temp
end

function bin.ToStr(val, name, skipnewlines, depth)
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
            tmp =  tmp .. bin.ToStr(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and " " or "")
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end
function bin:addBlock(d,n,e)
	local temp={}
	if type(d)=='table' then
		if d.t=='bin' then
			temp=d
		elseif d.t=='bit' then
			temp=bin.new(d:tobytes())
		else
			self:addBlock('return '..bin.ToStr(d))
			return
		end
	elseif type(d)=='string' then
		temp=bin.new(d)
		if e or not(n) then
			temp.data=temp.data..'_EOF'
			temp:flipbits()
		end
	elseif type(d)=='function' then
		temp=bin.new(string.dump(d))
		if e or not(n) then
			temp.data=temp.data..'_EOF'
			temp:flipbits()
		end
	elseif type(d)=='number' then
		local nn=tostring(d)
		if nn:find('.',1,true) then
			temp=bin.new(nn)
			temp.data=temp.data..'_EOF'
			temp:flipbits()
		else
			temp=bits.new(d):tobytes()
			if not n then
				temp.data=temp.data..'_EOF'
				temp:flipbits()
			end
		end
	elseif type(d)=='boolean' then
		n=1
		if d then
			temp=bits.new(math.random(0,127)):tobytes()
		else
			temp=bits.new(math.random(128,255)):tobytes()
		end
	end
	if n then
		if temp:getlength()<n then
			temp:merge(bin.new(string.rep(string.char(0),n-temp:getlength())))
		elseif temp:getlength()>n then
			temp:segment(1,n)
		end
	end
	self:merge(temp)
end
function bin:getBlock(t,n,se)
	if not(self.Block) then
		self.Block=1
	end
	local x=self.Block
	local temp=bin.new()
	if n then
		temp=bin.new(self:sub(x,x+n-1))
		self.Block=self.Block+n
	end
	if se then
		self.Block=self.Block+se
	end
	if t=='stringe' or t=='stre' or t=='se' and n then
		temp:flipbits()
		bin.lastBlockSize=#temp
		return temp.data
	elseif t=='string' or t=='str' or t=='s' and n then
		bin.lastBlockSize=#temp
		return temp.data
	elseif t=='number' or t=='num' or t=='n' and n then
		bin.lastBlockSize=n
		return self:tonumber(x,x+n-1)
	elseif t=='boolean' or t=='bool' or t=='b' then
		self.Block=self.Block+1
		bin.lastBlockSize=1
		return self:tonumber(x,x)<127
	elseif t=='stringe' or t=='stre' or t=='se' or t=='string' or t=='str' or t=='s' then
		local a,b=self:scan('_EOF',self.Block,true)
		if not(b) then return nil end
		local t=bin.new(self:sub(self.Block,b-4))
		bin.lastBlockSize=t:getlength()
		t:flipbits()
		self.Block=self.Block+t:getlength()+4
		return tostring(t)
	elseif t=='table' or t=='tab' or t=='t' then
		temp=self:getBlock('s')
		bin.lastBlockSize=#temp
		return assert(loadstring(temp))()
	elseif t=='function' or t=='func' or t=='f' then
		local temp=self:getBlock('s')
		bin.lastBlockSize=#temp
		return assert(loadstring(temp))
	elseif t=='number' or t=='num' or t=='n' then
		local num=bin.new(self:getBlock('s'))
		bin.lastBlockSize=#num
		if tonumber(num.data) then
			return tonumber(num.data)
		end
		local a,b=num:tonumber()
		return a
	elseif n then
		-- C data
	else
		print('Invalid Args!!!')
	end
end
function bin:seek(n)
	self.Block=self.Block+n
end
function bin.NumtoHEX(num)
	local hexstr = '0123456789ABCDEF'
	local s = ''
	while num > 0 do
		local mod = math.fmod(num, 16)
		s = string.sub(hexstr, mod+1, mod+1) .. s
		num = math.floor(num / 16)
	end
	if s == '' then
		s = '0'
	end
	return s
end
function bin:getHEX(a,b,e)
	a=a or 1
	local temp = self:sub(a,b)
	if e then temp=string.reverse(temp) end
	return bin.tohex(temp)
end
function bin.HEXtoBin(hex,e)
	if e then
		return bin.new(string.reverse(bin.fromhex(hex)))
	else
		return bin.new(bin.fromhex(hex))
	end
end
function bin.HEXtoStr(hex,e)
	if e then
		return string.reverse(bin.fromhex(hex))
	else
		return bin.fromhex(hex)
	end
end
function bin:morph(a,b,d)
	if self:canStreamWrite() then
		local len=self:getlength()
		local temp=bin.newTempFile(self:sub(b+1,self:getlength()))
		self:streamwrite(d,a-1)
		print(temp:sub(1,temp:getlength()))
		self:setEndOfFile(len+(b-a)+#d)
		self:streamwrite(temp:sub(1,temp:getlength()),a-1)
		temp:remove()
	elseif self.Stream==false then
		if a and b then
			self.data=self:sub(1,a-1)..d..self:sub(b+1)
		else
			print('error both arguments must be numbers and the third a string')
		end
	end
end
function bin.endianflop(data)
	return string.reverse(data)
end
function bin:scan(s,n,f)
	n=n or 1
	if self.Stream then
		for i=n,self:getlength() do
			if f then
				local temp=bin.new(self:sub(i,i+#s-1))
				temp:flipbits()
				if temp.data==s then
					return i,i+#s-1
				end
			else
				if self:sub(i,i+#s-1)==s then
					return i,i+#s-1
				end
			end
		end
	elseif self.Stream==false then
		if f then
			s=bin.new(s)
			s:flipbits()
			s=s.data
		end
		n=n or 1
		local a,b=string.find(self.data,s,n,true)
		return a,b
	end
end
function bin:fill(s,n)
	if self:canStreamWrite() then
		self:streamwrite(string.rep(s,n),0)
		self:setEndOfFile(n*#s)
	elseif self.Stream==false then
		self.data=string.rep(s,n)
	end
end
function bin:fillrandom(n)
	if self:canStreamWrite() then
		local t={}
		for i=1,n do
			table.insert(t,string.char(math.random(0,255)))
		end
		self:streamwrite(table.concat(t),0)
		self:setEndOfFile(n)
	elseif self.Stream==false then
		local t={}
		for i=1,n do
			table.insert(t,string.char(math.random(0,255)))
		end
		self.data=table.concat(t)
	end
end
function bin.packLLIB(name,tab,ext)
	local temp=bin.new()
	temp:addBlock('³Šž³–')
	temp:addBlock(bin.getVersion())
	temp:addBlock(tab)
	for i=1,#tab do
		temp:addBlock(tab[i])
		temp:addBlock(bin.load(tab[i]).data)
	end
	temp:addBlock('Done')
	temp:tofile(name.. ('.'..ext or '.llib'))
end
function bin.unpackLLIB(name,exe,todir,over,ext)
	local temp=bin.load(name..('.'..ext or '.llib'))
	local name=''
	Head=temp:getBlock('s')
	ver=temp:getBlock('s')
	infiles=temp:getBlock('t')
	if ver~=bin.getVersion() then
		print('Incompatable llib file')
		return nil
	end
	local tab={}
	while name~='Done' do
		name,data=temp:getBlock('s'),bin.new(temp:getBlock('s'))
		if string.find(name,'.lua',1,true) then
			table.insert(tab,data.data)
		else
			if not(bin.fileExist((todir or '')..name) and not(over)) then
				data:tofile((todir or '')..name)
			end
		end
	end
	os.remove((todir or '')..'Done')
	if exe then
		for i=1,#tab do
			assert(loadstring(tab[i]))()
		end
	end
	return infiles
end
function bin.fileExist(path)
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
function bin:shiftbits(n)
	if self:canStreamWrite() then
		n=n or 0
		if n>=0 then
			for i=0,self:getlength() do
				print(string.byte(self:sub(i,i))+n%256)
				self:streamwrite(string.char(string.byte(self:sub(i,i))+n%256),i-1)
			end
		else
			n=math.abs(n)
			for i=0,self:getlength() do
				self:streamwrite(string.char((string.byte(self:sub(i,i))+(256-n%256))%256),i-1)
			end
		end
	elseif self.Stream==false then
		n=n or 0
		if n>=0 then
			for i=1,self:getlength() do
				self:morph(i,i,string.char(string.byte(self:sub(i,i))+n%256))
			end
		else
			n=math.abs(n)
			for i=1,self:getlength() do
				self:morph(i,i,string.char((string.byte(self:sub(i,i))+(256-n%256))%256))
			end
		end
	end
end
function bin:shiftbit(n,i)
	if self:canStreamWrite() then
		i=i-1
		n=n or 0
		if n>=0 then
			print((string.byte(self:sub(i,i))+n)%256,n)
			self:streamwrite(string.char((string.byte(self:sub(i,i))+n)%256),i-1)
		else
			n=math.abs(n)
			print((string.byte(self:sub(i,i))+(256-n))%256,n)
			self:streamwrite(string.char((string.byte(self:sub(i,i))+(256-n%256))%256),i-1)
		end
	elseif self.Stream==false then
		n=n or 0
		if n>=0 then
			self:morph(i,i,string.char((string.byte(self:sub(i,i))+n)%256))
		else
			n=math.abs(n)
			self:morph(i,i,string.char((string.byte(self:sub(i,i))+(256-n%256))%256))
		end
	end
end
function bin.decodeBits(par)
	if type(par)=='table' then
		if par.t=='bit' then
			return bin.new(par:toSbytes())
		end
	else
		if par:find(' ') then
			par=par:gsub(' ','')
		end
		local temp=bits.new()
		temp.data=par
		return bin.new((temp:toSbytes()):reverse())
	end
end
function bin.textToBinary(txt)
	return bin.new(bits.new(txt:reverse()):getBin())
end
function bin:getData()
	if self.Stream then
		return self:sub(1,self:getSize())
	else
		return self.data
	end
end
function bin.getLuaVersion()
	if type(jit)=="table" then
		if jit.version then
			return "JIT",jit.version
		end
	end
	return "PUC",_VERSION:match("(%d-)%.(%d+)")
end
function bin.binToBuffer(b)
	return bin:newDataBuffer(b.data)
end
function bin.bufferToBin(b)
	return bin.new(b:getBuffer())
end
function bin.newNamedBlock(indexSize)
	local c={}
	c.data=bin.new()
	c.lastLoc=0
	if indexSize then
		indexSize=indexSize+4
	end
	c.index=bin:newDataBuffer(indexSize)
	c.conv={
		["n"]="\1",
		["b"]="\2",
		["s"]="\3",
		["t"]="\4",
		["f"]="\5"
	}
	if indexSize then
		c.index:fillBuffer(bits.numToBytes(indexSize,4),1)
		c.lastLoc=4
	else
		--c.index:fillBuffer(bits.numToBytes(2048,4),1)
	end
	function c:tofile(path)
		bin.new(self:tostring()):tofile(path)
	end
	function c:tostring()
		c.index:fillBuffer(bits.numToBytes(c.index:getSize()-4,4),1)
		return self.index:getBuffer()..self.data.data
	end
	function c:setPointer(name,data,t)
		t=c.conv[t]
		data=t..data
		local dSize=#data
		local index=bin:newDataBuffer()
		local nLen=#name
		local test=""
		index:fillBuffer(bits.numToBytes(self.data:getSize()+1,4),1)
		index:fillBuffer(name,5)
		self.data:tackE(data)
		test=self.index:fillBuffer(index:getBuffer().."\31",self.lastLoc+1)
		self.lastLoc=self.lastLoc+1+index:getBufferSize()
		if test=="Buffer Overflow!" then
			error("Increase Index size!")
		end
	end
	function c:addNamedBlock(name,value)
		local bSize=#name
		local ftype={}
		if type(value)=="number" then
			local dat=bits.numToBytes(value,8) -- makes 64 bit version of lua compatable
			self:setPointer(name,dat,"n")
		elseif type(value)=="boolean" then
			if value then
				self:setPointer(name,"1","b")
			else
				self:setPointer(name,"0","b")
			end
		elseif type(value)=="string" then
			self:setPointer(name,value,"s")
		elseif type(value)=="table" then
			local str=bin.ToStr(value)
			self:setPointer(name,str,"t")
		elseif type(value)=="function" then
			local ver,verM,verm=bin.getLuaVersion()
			local data=string.dump(value)
			if ver=="JIT" then
				ftype=bin:newDataBuffer(bits.numToBytes(0,4)) -- luajit version
			else
				ftype=bin:newDataBuffer(bits.numToBytes(tonumber(verM..verm),4))  -- lua version with MajorMinor data
			end
			local fdata=bin.new()
			fdata:tackE(ftype:getBuffer()..data)
			self:setPointer(name,fdata.data,"f")
		elseif type(value)=="userdata" then
			error("Userdata cannot be put into a block!")
		end
	end
	if not indexSize then
		c:addNamedBlock("__UNBOUNDEDINDEX__",true)
	end
	return c
end
function bin.newStreamedNamedBlock(indexSize,path,update)
	local c={}
	c.data=bin.stream(path,false)
	c.lastLoc=4
	c.conv={
		["n"]="\1",
		["b"]="\2",
		["s"]="\3",
		["t"]="\4",
		["f"]="\5"
	}
	if not update then
		c.data:tackE(bin:newDataBuffer(indexSize+4 or 2052):getBuffer())
		if indexSize then
			c.data:mutate(bits.numToBytes(indexSize,4),1)
		else
			c.data:mutate(bits.numToBytes(2048,4),1)
		end
		c.indexSize=indexSize+4 or 2052
	else
		c.indexSize=c.data:tonumber(1,4)
		local i=bin.new(c.data:sub(5,c.indexSize+4)).data
		local last=0
		for b=#i,1,-1 do
			if i:sub(b,b)=="\31" then
				last=b+4
				break
			end
		end
		c.lastLoc=last
	end
	function c:tofile(path)
		--No need when using a streamed block
	end
	function c:tostring()
		return self.index:getBuffer()..self.data.data
	end
	function c:setPointer(name,data,t)
		t=c.conv[t]
		data=t..data
		local dSize=#data
		local index=bin:newDataBuffer()
		local nLen=#name
		local test=""
		index:fillBuffer(bits.numToBytes((self.data:getSize()+1)-self.indexSize,4),1)
		index:fillBuffer(name,5)
		local test=self.data:mutate(index:getBuffer().."\31",self.lastLoc+1)
		self.lastLoc=self.lastLoc+1+index:getBufferSize()
		self.data:tackE(data)
		if test=="Buffer Overflow!" then
			error("Increase Index size!")
		end
	end
	function c:addNamedBlock(name,value)
		local bSize=#name
		local ftype={}
		if type(value)=="number" then
			local dat=bits.numToBytes(value,8) -- makes 64 bit version of lua compatable
			self:setPointer(name,dat,"n")
		elseif type(value)=="boolean" then
			if value then
				self:setPointer(name,"1","b")
			else
				self:setPointer(name,"0","b")
			end
		elseif type(value)=="string" then
			self:setPointer(name,value,"s")
		elseif type(value)=="table" then
			local str=bin.ToStr(value)
			self:setPointer(name,str,"t")
		elseif type(value)=="function" then
			local ver,verM,verm=bin.getLuaVersion()
			local data=string.dump(value)
			if ver=="JIT" then
				ftype=bin:newDataBuffer(bits.numToBytes(0,4)) -- luajit version
			else
				ftype=bin:newDataBuffer(bits.numToBytes(tonumber(verM..verm),4))  -- lua version with MajorMinor data
			end
			local fdata=bin.new()
			fdata:tackE(ftype:getBuffer()..data)
			self:setPointer(name,fdata.data,"f")
		elseif type(value)=="userdata" then
			error("Userdata cannot be put into a block!")
		end
	end
	function c:close()
		self:addNamedBlock("",false)
		self.data:close()
	end
	return c
end
function bin.loadNamedBlock(path)
	local c={}
	c.data=bin.stream(path)
	c.iSize=c.data:tonumber(1,4)
	c.index=bin.new(c.data:sub(5,c.iSize+4))
	c.sData=bin.new(c.data:sub(c.iSize+5,-1))
	function c:CheckRestOfIndex(name)
		local a,b=self.index:scan(name)
		local d=self.index:tonumber(b+2,b+5)
		if d==0 or b+5>self.iSize then
			return -1
		end
		return d
	end
	function c:getIndexes()
		local tab={}
		ind=5
		while ind do
			local a=self.index:find("\31",ind)
			if not a then break end
			local b=self.index:sub(ind,a-1)
			table.insert(tab,b)
			ind=a+5
		end
		return tab
	end
	function c:getBlock(name)
		local a,b=self.index:scan(name)
		if not a then return "index not found" end
		local dloc=self.index:tonumber(a-4,a-1)
		local dindex=bin:newDataBuffer(self.sData:sub(dloc,dloc))
		if dindex[1]==0x01 then -- type number
			return self.sData:tonumber(dloc+1,dloc+8)
		elseif dindex[1]==0x02 then -- type bool
			return ({[1]=true,[0]=false})[tonumber(self.sData:sub(dloc+1,dloc+1))]
		elseif dindex[1]==0x03 then -- type string
			local dend=self:CheckRestOfIndex(name)--self.index:tonumber(b+2,b+5)
			return self.sData:sub(dloc+1,dend-1)
		elseif dindex[1]==0x04 then -- type table
			local dend=self.index:tonumber(b+2,b+5)
			return loadstring("return "..self.sData:sub(dloc+1,dend-1))()
		elseif dindex[1]==0x05 then -- type function
			local dend=self:CheckRestOfIndex(name)--self.index:tonumber(b+2,b+5)
			local _ver=self.sData:tonumber(dloc+1,dloc+4)
			local ver,verM,verm=bin.getLuaVersion()
			if tonumber(verM..verm)==_ver then
				return loadstring(self.sData:sub(dloc+5,dend-1))
			else
				return function() error("This lua function is not compatible with the current version of lua!") end
			end
		end
	end
	return c
end
function bin.namedBlockManager(name)
	if type(name)=="string" then
		local i={}
		local data=bin.loadNamedBlock(name)
		local mt={
			__index=function(t,k)
				return data:getBlock(k)
			end,
		}
		setmetatable(i,mt)
		return i
	else
		local i={}
		local data=bin.newNamedBlock(name)
		local mt={
			__newindex=function(t,k,v)
				data:addNamedBlock(k,v)
			end,
			__index=data
		}
		setmetatable(i,mt)
		return i
	end
end
function bin.getIndexSize(tab)
	size=0
	for i=1,#tab do
		size=size+#tab[i]+5
	end
	return size+5
end
function bin.gcd( m, n )
    while n ~= 0 do
        local q = m
        m = n
        n = q % n
    end
    return m
end
function bin.numToFraction(num)
	num=num or error("Must enter a number!")
	local n=#tostring(num)
	num=num*(10^n)
	local d=(10^n)
	local g=bin.gcd(num,d)
	return tostring(num/g).."/"..tostring(d/g),num/g,d/g
end
function bin.doubleToString(double)
	local s=({[false]="-",[true]="+"})[double>=0]
	double=math.abs(double)
	local _,n,d=bin.numToFraction(double)
	gfit=4
	local a=bits.numToBytes(n,gfit,function(ref)
		ref.fit=12 -- should be able to pack any number into that space
		ref.num=string.rep("\0",12-#ref.num)..ref.num
		if s=="-" then
			s="_"
		else
			s="="
		end
		gfit=12
	end)
	local b=bits.numToBytes(d,gfit)
	return s..a..b
end
function bin.stringToDouble(str)
	local s=str:sub(1,1)
	if #str~=9 and #str~=25 then
		if s~="-" and s~="+" and s~="_" and s~="=" then
			print(s)
			error("Not a double encoded string")
		end
		error("Not a double encoded string")
	end
	local n,d
	if s=="_" or s=="=" then
		n,d=str:sub(2,13),str:sub(14)
	else
		n,d=str:sub(2,5),str:sub(6)
	end
	local n=bin.new(n):tonumber()
	local d=bin.new(d):tonumber()
	local num=n/d
	if s=="-" or s=="_" then
		num=-num
	end
	return num
end
--[[----------------------------------------
VFS
------------------------------------------]]
local _require = require
function require(path,vfs)
	if bin.fileExist(path..'.lvfs') then
		local data = bin.loadVFS(path..'.lvfs')
		if data:fileExist(vsf) then
			loadstring(data:readFile(vfs))()
		end
	else
		return _require(path)
	end
end
function bin.loadVFS(path)
	local vfs=bin.newVFS()
	local temp=bin.stream(path,false)
	local files=temp:getBlock("t")
	local size=0
	for i=1,#files do
		local p,len=files[i]:match("(.-)|(.+)")
		len=tonumber(len)
		size=size+bin.lastBlockSize
		local dat=temp:sub(size+5,size+len+4)
		bin.lastBlockSize=len
		vfs:mkfile(p:gsub("%./",""),dat)
	end
	return vfs
end
function bin.copyDir(dir,todir)
	local vfs=bin.newVFS(dir,true)
	vfs:toFS(todir)
	vfs=nil
end
function bin.newVFS(t,l)
	l=l or true
	if type(t)=='string' then
		t=io.parseDir(t,l)
	end
	local c={}
	c.FS= t or {}
	function c:merge(vfs)
		bin.newVFS(table.merge(self.FS,vfs.FS))
	end
	function c:mirror(file)
		self:mkfile(file,file)
	end
	function c:mkdir(path)
		table.merge(self.FS,io.pathToTable(path))
	end
	function c:scanDir(path)
		path=path or ''
		local tab={}
		if path=='' then
			for i,v in pairs(self.FS) do
				tab[#tab+1]=i
			end
			return tab
		end
		spath=io.splitPath(path)
		local last=self.FS
		for i=1,#spath-1 do
			last=last[spath[i]]
		end
		return last[spath[#spath]]
	end
	function c:getFiles(path)
		if not self:dirExist(path) then return end
		path=path or ''
		local tab={}
		if path=='' then
			for i,v in pairs(self.FS) do
				if self:fileExist(i) then
					tab[#tab+1]=i
				end
			end
			return tab
		end
		spath=io.splitPath(path)
		local last=self.FS
		for i=1,#spath-1 do
			last=last[spath[i]]
		end
		local t=last[spath[#spath]]
		for i,v in pairs(t) do
			if self:fileExist(path..'/'..i) then
				tab[#tab+1]=path..'/'..i
			end
		end
		return tab
	end
	function c:getDirectories(path)
		if not self:dirExist(path) then return end
		path=path or ''
		local tab={}
		if path=='' then
			for i,v in pairs(self.FS) do
				if self:dirExist(i) then
					tab[#tab+1]=i
				end
			end
			return tab
		end
		spath=io.splitPath(path)
		local last=self.FS
		for i=1,#spath-1 do
			last=last[spath[i]]
		end
		local t=last[spath[#spath]]
		for i,v in pairs(t) do
			if self:dirExist(path..'/'..i) then
				tab[#tab+1]=path..'/'..i
			end
		end
		return tab
	end
	function c:mkfile(path,data)
		local name=io.getFullName(path)
		local temp=path:reverse()
		local a,b=temp:find('/')
		if not a then
			a,b=temp:find('\\')
		end
		if a then
			temp=temp:sub(a+1):reverse()
			path=temp
			local t,l=io.pathToTable(path)
			l[name]=data
			table.merge(self.FS,t)
		else
			self.FS[name]=data
		end
	end
	function c:remove(path)
		if path=='' or path==nil then return end
		spath=io.splitPath(path)
		local last=self.FS
		for i=1,#spath-1 do
			last=last[spath[i]]
		end
		last[spath[#spath]]=nil
	end
	function c:readFile(path)
		spath=io.splitPath(path)
		local last=self.FS
		for i=1,#spath do
			last=last[spath[i]]
		end
		if type(last)=='userdata' then
			last=last:read('*all')
		end
		return last
	end
	function c:copyFile(p1,p2)
		self:mkfile(p2,self:readFile(p1))
	end
	function c:moveFile(p1,p2)
		self:copyFile(p1,p2)
		self:remove(p1)
	end
	function c:fileExist(path)
		return type(self:readFile(path))=='string'
	end
	function c:dirExist(path)
		if path=='' or path==nil then return end
		spath=io.splitPath(path)
		local last=self.FS
		for i=1,#spath-1 do
			last=last[spath[i]]
		end
		if last[spath[#spath]]~=nil then
			if type(last[spath[#spath]])=='table' then
				return true
			end
		end
		return false
	end
	function c:_getHierarchy()
		local ord={}
		local datlink=bin.new()
		local function toStr(val, name, skipnewlines, depth, path)
			skipnewlines = skipnewlines or false
			path=path or "."
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
				tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
				for k, v in pairs(val) do
					tmp =  tmp .. toStr(v, k, skipnewlines, depth + 1,path.."/"..k) .. "," .. (not skipnewlines and "\n" or "")
				end
				tmp = tmp .. string.rep(" ", depth) .. "}"
			elseif type(val) == "string" then
				tmp = tmp .. #val
				datlink:tackE(val)
				ord[#ord+1]=path.."|"..#val
			end
			return tmp
		end
		return toStr(self.FS),ord,datlink
	end
	function c:getHierarchy()
		local ord={}
		local function toStr(val, name, skipnewlines, depth, path)
			skipnewlines = skipnewlines or false
			path=path or "."
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
				tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
				for k, v in pairs(val) do
					tmp =  tmp .. toStr(v, k, skipnewlines, depth + 1,path.."/"..k) .. "," .. (not skipnewlines and "\n" or "")
				end
				tmp = tmp .. string.rep(" ", depth) .. "}"
			elseif type(val) == "string" then
				tmp = tmp .. ";"
				ord[#ord+1]=path.."|"..#val
			end
			return tmp
		end
		return toStr(self.FS),ord
	end
	function c:tofile(path)
		local temp=bin.new()
		local h,o,link=self:_getHierarchy()
		temp:addBlock(o)
		temp:merge(link)
		temp:tofile(path)
	end
	function c:toFS(path)
		if path then
			if path:sub(-1,-1)~='\\' then
				path=path..'\\'
			elseif path:find('/') then
				path=path:gsub('/','\\')
			end
			io.mkDir(path)
		else
			path=''
		end
		function build(tbl, indent, folder)
			if not indent then indent = 0 end
			if not folder then folder = '' end
			for k, v in pairs(tbl) do
				formatting = string.rep(' ', indent) .. k .. ':'
				if type(v) == 'table' then
					if v.t~=nil then
						io.mkFile(folder..k,tostring(v),'wb')
					else
						if not(io.dirExists(path..folder..string.sub(formatting,1,-2))) then
							io.mkDir(folder..string.sub(formatting,1,-2))
						end
						build(v,0,folder..string.sub(formatting,1,-2)..'\\')
					end
				elseif type(v)=='string' then
					io.mkFile(folder..k,v,'wb')
				elseif type(v)=='userdata' then
					io.mkFile(folder..k,v:read('*all'),'wb')
				end
			end
		end
		build(self.FS,0,path)
	end
	function c:print()
		table.print(self.FS)
	end
	return c
end
--[[----------------------------------------
BITS
------------------------------------------]]
function bits.lsh(value,shift)
	return (value*(2^shift)) % 256
end
function bits.rsh(value,shift)
	return math.floor(value/2^shift) % 256
end
function bits.bit(x,b)
	return (x % 2^b - x % 2^(b-1) > 0)
end
function bits.lor(x,y)
	result = 0
	for p=1,8 do result = result + (((bits.bit(x,p) or bits.bit(y,p)) == true) and 2^(p-1) or 0) end
	return result
end
function bits.newBitBuffer(n)
	--
end
function bits.newConverter(bitsIn,bitsOut)
	local c={}
	--
end
bits.ref={}
function bits.newByte(d)
	local c={}
	if type(d)=="string" then
		if #d>1 or #d<1 then
			error("A byte must be one character!")
		else
			c.data=string.byte(d)
		end
	elseif type(d)=="number" then
		if d>255 or d<0 then
			error("A byte must be between 0 and 255!")
		else
			c.data=d
		end
	else
		error("cannot use type "..type(d).." as an argument! Takes only strings or numbers!")
	end
	c.__index=function(self,k)
		if k>=0 and k<9 then
			if self.data==0 then
				return 0
			elseif self.data==255 then
				return 1
			else
				return bits.ref[self.data][k]
			end
		end
	end
	c.__tostring=function(self)
		return bits.ref[tostring(self.data)]
	end
	setmetatable(c,c)
	return c
end
function bits.newByteArray(s)
	local c={}
	if type(s)~="string" then
		error("Must be a string type or bin/buffer type")
	elseif type(s)=="table" then
		if s.t=="sink" or s.t=="buffer" or s.t=="bin" then
			local data=s:getData()
			for i=1,#data do
				c[#c+1]=bits.newByte(data:sub(i,i))
			end
		else
			error("Must be a string type or bin/buffer type")
		end
	else
		for i=1,#s do
			c[#c+1]=bits.newByte(s:sub(i,i))
		end
	end
	return c
end
function bits.new(n,s)
	if type(n)=='string' then
		local t=tonumber(n,2)
		if t and #n<8 and not(s) then
			t=nil
		end
		if not(t) then
			t={}
			for i=#n,1,-1 do
				table.insert(t,bits:conv(string.byte(n,i)))
			end
			n=table.concat(t)
		else
			n=t
		end
	end
	local temp={}
	temp.t='bit'
	setmetatable(temp, bits)
	if type(n)~='string' then
		local tab={}
		while n>=1 do
			table.insert(tab,n%2)
			n=math.floor(n/2)
		end
		local str=string.reverse(table.concat(tab))
		if #str%8~=0 then
			str=string.rep('0',8-#str%8)..str
		end
		temp.data=str
	else
		temp.data=n
	end
	setmetatable({__tostring=function(self) return self.data end},temp)
	return temp
end
for i=0,255 do
	local d=bits.new(i).data
	bits.ref[i]={d:match("(%d)(%d)(%d)(%d)(%d)(%d)(%d)(%d)")}
	bits.ref[tostring(i)]=d
	bits.ref[d]=i
	bits.ref["\255"..string.char(i)]=d
end
function bits.numToBytes(n,fit,func)
	local num=bits.new(n):toSbytes()
	num=bin.endianflop(num)
	local ref={["num"]=num,["fit"]=fit}
	if fit then
		if fit<#num then
			if func then
				print("Warning: attempting to store a number that takes up more space than allotted! Using provided method!")
				func(ref)
			else
				print("Warning: attempting to store a number that takes up more space than allotted!")
			end
			return ref.num:sub(1,ref.fit)
		elseif fit==#num then
			return num
		else
			return string.rep("\0",fit-#num)..num
		end
	else
		return num
	end
end
function bits:conv(n)
	local tab={}
	while n>=1 do
		table.insert(tab,n%2)
		n=math.floor(n/2)
	end
	local str=string.reverse(table.concat(tab))
	if #str%8~=0 then
		str=string.rep('0',8-#str%8)..str
	end
	return str
end
function bits:add(i)
	if type(i)=='number' then
		i=bits.new(i)
	end
	self.data=self:conv(tonumber(self.data,2)+tonumber(i.data,2))
end
function bits:sub(i)
	if type(i)=='number' then
		i=bits.new(i)
	end
	self.data=self:conv(tonumber(self.data,2)-tonumber(i.data,2))
end
function bits:multi(i)
	if type(i)=='number' then
		i=bits.new(i)
	end
	self.data=self:conv(tonumber(self.data,2)*tonumber(i.data,2))
end
function bits:div(i)
	if type(i)=='number' then
		i=bits.new(i)
	end
	self.data=self:conv(tonumber(self.data,2)/tonumber(i.data,2))
end
function bits:tonumber(s)
	if type(s)=='string' then
		return tonumber(self.data,2)
	end
	s=s or 1
	return tonumber(string.sub(self.data,(8*(s-1))+1,8*s),2) or error('Bounds!')
end
function bits:isover()
	return #self.data>8
end
function bits:flipbits()
	tab={}
	for i=1,#self.data do
		if string.sub(self.data,i,i)=='1' then
			table.insert(tab,'0')
		else
			table.insert(tab,'1')
		end
	end
	self.data=table.concat(tab)
end
function bits:tobytes()
	local tab={}
	for i=self:getbytes(),1,-1 do
		table.insert(tab,string.char(self:tonumber(i)))
	end
	return bin.new(table.concat(tab))
end
function bits:toSbytes()
	local tab={}
	for i=self:getbytes(),1,-1 do
		table.insert(tab,string.char(self:tonumber(i)))
	end
	return table.concat(tab)
end
function bits:getBin()
	return self.data
end
function bits:getbytes()
	return #self.data/8
end
