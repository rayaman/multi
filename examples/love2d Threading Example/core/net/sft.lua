require("net")
--General Stuff
--[[ What this module does!
Adds

]]
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
net:registerModule("sft",{1,0,0})
function net.sft:init() -- calling this initilizes the library and binds it to the servers and clients created
	--Server Stuff
	net.OnServerCreated:connect(function(s)
		print("The sft(Simple File Transfer) Module has been loaded onto the server!")
		if s.Type~="tcp" then
			print("It is recomended that you use tcp to transfer files!")
		end
		s.transfers={}
		s.OnUploadRequest=multi:newConnection() -- create a sft event
		s.OnFileUploaded=multi:newConnection() -- create a sft event
		s.OnDownloadRequest=multi:newConnection()
		s.OnDataRecieved(function(self,data,cid,ip,port) -- when the server recieves data this method is triggered
			--First Lets make sure we are getting sft data
			--filename,dat=data:match("!sft! (%S-) (%S+)")
			local cmd,arg1,arg2=data:match("!sft! (%S-) (%S-) (.+)")
			if cmd=="tstart" then
				local rets=self.OnUploadRequest:Fire(self,cid,ip,port)
				for i=1,#rets do
					if rets[i][1]==false then
						print("Server refused to accept upload request!")
						self:send(ip,"!sft! CANTUPLOAD NIL NIL",port)
						return
					end
				end
				local ID,streamable=arg1:match("(.+)|(.+)")
				local file,hash=arg2:match("(.+)|(.+)")
				if streamable~="NIL" then
					self.transfers[ID]={bin.stream(streamable,false),hash,file}
				else
					self.transfers[ID]={bin.new(""),hash,file}
				end
				return
			elseif cmd=="transfer" then
				if self.transfers[arg1]~=nil then
					self.transfers[arg1][1]:tackE(bin.fromhex(arg2))
					--print(self.transfers[arg1][1]:getSize())
				end
				return
			elseif cmd=="tend" then
				if self.transfers[arg1]~=nil then
					if self.transfers[arg1][1]:getHash(32)==self.transfers[arg1][2] then
						self.OnFileUploaded:Fire(self,self.transfers[arg1][1],self.transfers[arg1][3],"Hash Good!")
					else
						print("Hash Error!")
						self.OnFileUploaded:Fire(self,self.transfers[arg1][1],self.transfers[arg1][3],"Hash Bad!")
					end
					self.transfers[arg1]=nil
				end
				return
			end
			local filename=cmd
			local dat=arg1
			if filename==nil then return end
			local rets=self.OnDownloadRequest:Fire(self,cid,ip,port)
			for i=1,#rets do
				if rets[i][1]==false then
					print("Server refused to accept download request!")
					self:send(ip,"!sft! CANTREQUEST NIL NIL",port)
					return
				end
			end
			if io.fileExists(filename) then
				--Lets first load the file
				local file=bin.stream(filename,false)
				local size=file:getSize()
				local pieceSize=512
				local pieces=math.ceil(size/pieceSize)
				local step=multi:newStep(1,pieces)
				step.TransferID=tostring(math.random(1000,9999))
				step.sender=self
				step.ip=ip
				step.port=port
				step.pieceSize=pieceSize
				step:OnStart(function(self)
					self.sender:send(self.ip,"!sft! TSTART "..self.TransferID.."|"..dat.." "..filename.."|"..file:getHash(32),self.port)
				end)
				step:OnStep(function(pos,self)
					self:hold(.01)
					self.sender:send(self.ip,"!sft! TRANSFER "..self.TransferID.." "..bin.tohex(file:sub(((self.pieceSize*pos)+1)-self.pieceSize,self.pieceSize*pos)),self.port)
				end)
				step:OnEnd(function(self)
					self.sender:send(self.ip,"!sft! TEND "..self.TransferID.." NIL",self.port)
				end)
			else
				self:send(ip,"!sft! CANTREQUEST NIL NIL",port)
			end
		end,"sft")
	end)
	--Client Stuff
	net.OnClientCreated:connect(function(c)
		c.transfers={}
		c.OnTransferStarted=multi:newConnection() -- create a sft event
		c.OnTransferFinished=multi:newConnection() -- create a sft event
		c.OnFileRequestFailed=multi:newConnection() -- create a sft event
		c.OnFileUploadFailed=multi:newConnection() -- create a sft event
		c.OnDataRecieved(function(self,data) -- when the client recieves data this method is triggered
			--First Lets make sure we are getting sft data
			local cmd,arg1,arg2=data:match("!sft! (%S-) (%S-) (.+)")
			if cmd=="TSTART" then
				local ID,streamable=arg1:match("(.+)|(.+)")
				local file,hash=arg2:match("(.+)|(.+)")
				if streamable~="NIL" then
					self.transfers[ID]={bin.stream(streamable,false),hash,file}
				else
					self.transfers[ID]={bin.new(""),hash,file}
				end
				self.OnTransferStarted:Fire(self)
			elseif cmd=="TRANSFER" then
				self.transfers[arg1][1]:tackE(bin.fromhex(arg2))
			elseif cmd=="TEND" then
				if self.transfers[arg1][1]:getHash(32)==self.transfers[arg1][2] then
					self.OnTransferFinished:Fire(self,self.transfers[arg1][1],self.transfers[arg1][3],"Hash Good!")
				else
					print("Hash Error!")
					self.OnTransferFinished:Fire(self,self.transfers[arg1][1],self.transfers[arg1][3],"Hash Bad!")
				end
				self.transfers[arg1]=nil
			elseif cmd=="CANTREQUEST" then
				self.OnFileRequestFailed:Fire(self,"Could not request the file for some reason!")
			elseif cmd=="CANTUPLOAD" then
				self.OnFileUploadFailed:Fire(self,"Could not upload the file for some reason!")
			end
		end,"sft")
		function c:uploadFile(filename)
			if io.fileExists(filename) then
				local file=bin.stream(filename,false)
				local size=file:getSize()
				local pieceSize=512
				local pieces=math.ceil(size/pieceSize)
				local step=multi:newStep(1,pieces)
				step.TransferID=tostring(math.random(1000,9999))
				step.sender=self
				step.pieceSize=pieceSize
				step:OnStart(function(self)
					self.sender:send("!sft! tstart "..self.TransferID.."|NIL "..filename.."|"..file:getHash(32))
				end)
				step:OnStep(function(pos,self)
					self:hold(.01)
					self.sender:send("!sft! transfer "..self.TransferID.." "..bin.tohex(file:sub(((self.pieceSize*pos)+1)-self.pieceSize,self.pieceSize*pos)))
				end)
				step:OnEnd(function(self)
					print("Request done!")
					self.sender:send("!sft! tend "..self.TransferID.." NIL")
				end)
			else
				self.OnFileUploadFailed:Fire(self,filename,"File does not exist!")
			end
		end
		function c:requestFile(filename)
			self:send("!sft! "..filename.." NIL NIL NIL")
		end
	end)
end
if net.autoInit then
	net.sft.init()
end
