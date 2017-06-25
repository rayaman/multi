require("net")
--General Stuff
--[[ What this module does!
Allows reliable transfer of files over the internet!
Hash testing and piece transfer
TODO: Add uploading support... For now use sft less intensive on the client/server
]]
net:registerModule("aft",{2,1,0})
net.aft.transfers={}
net.aft.sinks={}
net.aft.cache={}
net.aft.preload={}
net.aft.pieceSize=768 -- max data packet for b64 that can safely be transfered without erroring! DO NOT CHANGE!!!
function net.aft:init() -- calling this initilizes the library and binds it to the servers and clients created
	--Server Stuff
	net.OnServerCreated:connect(function(s)
		print("The aft(Advance File Transfer) Module has been loaded onto the server!")
		if s.Type~="tcp" then
			print("It is recomended that you use tcp to transfer files!")
		end
		s.OnUploadRequest=multi:newConnection() -- create an aft event
		s.OnDownloadRequest=multi:newConnection()
		s.OnClientClosed:connect(function(self,reason,cid,ip,port)
			if net.aft.transfers[cid] then
				for i,v in pairs(net.aft.transfers[cid]) do
					v.resendAlarm:Destroy()
				end
				net.aft.transfers[cid]=nil
			end
		end)
		function s:preloadFile(name)
			net.aft.preload[name]={}
			local temp=bin.stream(name)
			temp:segmentedRead(768,function(data)
				local unpackedDATA1=data:sub(1,384)
				local unpackedDATA2=data:sub(385)
				local packedDATA=net.normalize(unpackedDATA1)..net.normalize(unpackedDATA2)
				table.insert(net.aft.preload,packedDATA)
			end)
		end
		function s:isPreloaded(name)
			return net.aft.preload[name]~=nil
		end
		s.allowSmallFileCaching=false
		s.cachable=10 -- 10 MBs
		s.OnDataRecieved(function(self,data,cid,ip,port) -- when the server recieves data this method is triggered
			local cmd,arg1,arg2=data:match("!aft! (%S+) (%S+) (%S+)")
			--print(cmd,arg1,arg2)
			if cmd=="PIECE" then
				local FID,piecenum=arg1,tonumber(arg2)
				local pp=piecenum-1
				net.aft.transfers[cid][FID].resendAlarm:Reset()
				if net.aft.transfers[cid][FID] then
					if pp>net.aft.transfers[cid][FID].pieces-1 then
						self:send(ip,"!aft! DOWNLOAD INVALID_PIECENUM NIL NIL NIL",port)
						print("ERROR 101")
					else
						if self:isPreloaded(name) then
							self:send(ip,net.aft.preload[name][piecenum],port)
							return
						end
						if self.allowSmallFileCaching then
							if net.aft.cache[net.aft.transfers[cid][FID].name] then
								if net.aft.cache[net.aft.transfers[cid][FID].name][piecenum] then
									self:send(ip,net.aft.cache[net.aft.transfers[cid][FID].name][piecenum],port)
									return
								end
							end
						end
						local ddata
						local unpackedDATA=net.aft.transfers[cid][FID].sink:sub((pp*net.aft.pieceSize)+1,(pp+1)*net.aft.pieceSize)
						local num=#unpackedDATA
						if num<384 then
							ddata="!aft! TRANS "..piecenum.." "..FID.." | "..net.normalize(unpackedDATA)
						else
							local unpackedDATA1=unpackedDATA:sub(1,384)
							local unpackedDATA2=unpackedDATA:sub(385)
							local packedDATA=net.normalize(unpackedDATA1)..net.normalize(unpackedDATA2)
							ddata="!aft! TRANS "..piecenum.." "..FID.." | "..packedDATA
						end
						net.aft.transfers[cid][FID].resendAlarm.piecenum=piecenum
						net.aft.transfers[cid][FID].resendAlarm.hash="" -- not needed anymore
						net.aft.transfers[cid][FID].resendAlarm.packedDATA=packedDATA
						-- SAFE
						if self.allowSmallFileCaching then
							net.aft.cache[net.aft.transfers[cid][FID].name][piecenum]=ddata
						end
						self:send(ip,ddata,port)
					end
				else
					self:send(ip,"!aft! DOWNLOAD INVALID_FID NIL NIL NIL",port)
					print("ERROR 102")
				end
			elseif cmd=="UPLOAD" then -- here we set up the spot for file writing
				local FID,filename=arg1:match("(.-)|(.+)")
				local struct={
					FID=FID,
					filename=filename,
					numpieces=tonumber(arg2) or -1
				}
				if struct.numpieces==-1 then -- error handling catch it all :)
					self:send(ip,"!aft! UPLOAD UPLOAD_REFUSED INVALID_NUMBER_OF_PIECES | |",port)
					return
				end
				self.OnUploadRequest:Fire(struct,cid,ip,port)
				if not(struct.deny) then -- block request or allow it
					-- If we are allowed to lets do this
					if not(net.aft.transfers.DOWNLOADS) then
						net.aft.transfers.DOWNLOADS={}
					end
					if not(net.aft.transfers.DOWNLOADS[FID]) then
						net.aft.transfers.DOWNLOADS[FID]={}
					end
					bin.new(""):tofile(struct.filename)
					net.aft.transfers.DOWNLOADS[struct.FID].sink=struct.sink or bin.stream(struct.filename,false)
					net.aft.transfers.DOWNLOADS[struct.FID].currentPiece=1
					net.aft.transfers.DOWNLOADS[struct.FID].numPieces=tonumber(arg2)
					--we got that setup... Lets Request a piece now!
					self:send(ip,"!aft! PIECE 1 "..FID.." | |",port) -- request piece # 1
				else
					self:send(ip,"!aft! UPLOAD UPLOAD_REFUSED "..(struct.reason or "UNSPECIFIED_ERROR").." | |",port)
				end
			elseif cmd=="TRANS" then
				local FID,piece=arg1:match("(.-)|(.+)")
				local piece=tonumber(piece) or -1
				if pieces==-1 then -- error handling catch it all :)
					self:send(ip,"!aft! UPLOAD UPLOAD_CANCLED PIECE_DATA_MALFORMED | |",port)
					return
				end
				if #arg2<512 then
					net.aft.transfers.DOWNLOADS[FID].sink:tackE(net.denormalize(arg2))
				else
					net.aft.transfers.DOWNLOADS[FID].sink:tackE(net.denormalize(arg2:sub(1,512))..net.denormalize(arg2:sub(513)))
				end
				-- request the next piece
				if piece==net.aft.transfers.DOWNLOADS[FID].numPieces then
					-- We are done!
					self:send(ip,"!aft! DONE "..FID.." | | |",port)
					net.aft.transfers.DOWNLOADS[FID].sink:close() -- close the file
				else
					self:send(ip,"!aft! PIECE "..piece+1 .." "..FID.." | |",port)
				end
			elseif cmd=="REQUEST" then
				local filename=arg1
				local struct={
					filename=filename
				}
				self.OnDownloadRequest:Fire(self,struct)
				if io.fileExists(struct.filename) or struct.handle then
					local FID=bin.new(filename):getRandomHash(16)
					if struct.handle then
						FID=struct.handle:getRandomHash(16)
					end
					if not net.aft.transfers[cid] then
						net.aft.transfers[cid]={} -- setup server-client filestream
					end
					net.aft.transfers[cid][FID]={}
					net.aft.transfers[cid][FID].name=struct.filename
					if struct.handle then
						net.aft.transfers[cid][FID].sink=struct.handle
					else
						net.aft.transfers[cid][FID].sink=bin.stream(struct.filename,false)
					end
					net.aft.transfers[cid][FID].size=net.aft.transfers[cid][FID].sink:getSize()
					net.aft.transfers[cid][FID].pieces=math.ceil(net.aft.transfers[cid][FID].size/net.aft.pieceSize)
					net.aft.transfers[cid][FID].resendAlarm=multi:newAlarm(.25)
					net.aft.transfers[cid][FID].resendAlarm:OnRing(function(alarm)
						if not(alarm.packedDATA) then return end
						self:send(ip,"!aft! TRANS "..alarm.piecenum.." "..FID.." | "..alarm.packedDATA,port)
						alarm:Reset()
					end)
					if self.allowSmallFileCaching then
						if net.aft.transfers[cid][FID].size<=1024*self.cachable then -- 10 MB or smaller can be cached
							net.aft.cache[struct.filename]={}
						end
					end
					self:send(ip,"!aft! START "..net.aft.transfers[cid][FID].pieces.." "..FID.." "..filename.." NIL",port)
				else
					self:send(ip,"!aft! DOWNLOAD REQUEST_REFUSED NIL NIL NIL",port)
					print("ERROR 103")
				end
			elseif cmd=="COMPLETE" then
				net.aft.transfers[cid][arg1].resendAlarm:Destroy()
				net.aft.transfers[cid][arg1]=nil
			end
		end,"aft") -- some new stuff
	end)
	--Client Stuff
	net.OnClientCreated:connect(function(c)
		c.OnPieceRecieved=multi:newConnection()
		c.OnTransferStarted=multi:newConnection()
		c.OnTransferCompleted=multi:newConnection()
		c.OnFileRequestFailed=multi:newConnection() -- create an aft event
		c.OnFileUploadFailed=multi:newConnection() -- not yet must ensure oneway works well first
		c.OnDataRecieved(function(self,data) -- when the client recieves data this method is triggered
			local cmd,pieces,FID,arg1,arg2=data:match("!aft! (%S+) (%S+) (%S+) (%S+) (%S+)")
			--print(cmd,pieces,FID,arg1,arg2)
			if cmd=="START" then-- FID filename #pieces
				local struct={
					FID=FID,
					filename=arg1,
					numpieces=tonumber(pieces)
				}
				self.OnTransferStarted:Fire(self,struct)
				local fid,filename,np=struct.FID,struct.filename,struct.numpieces
				local sink=""
				if type(net.aft.sinks[filename])=="table" then
					sink=net.aft.sinks[filename]
					sink.file=filename
				else
					if net.aft.sinks[filename] then
						bin.new():tofile(net.aft.sinks[filename])
						sink=bin.stream(net.aft.sinks[filename],false)
					else
						bin.new():tofile(filename)
						sink=bin.stream(filename,false)
					end
				end
				net.aft.transfers[FID]={}
				net.aft.transfers[FID].name=sink.file
				net.aft.transfers[FID].sink=sink
				net.aft.transfers[FID].currentPiece=1
				net.aft.transfers[FID].piecesRecieved=0
				net.aft.transfers[FID].numpieces=tonumber(pieces)
				c:requestPiece(FID,1)
			elseif cmd=="DONE" then
				local FID=pieces
				print(net.aft.transfers.UPLOADS[FID].name.." has Finished Uploading!")
				self.OnTransferCompleted:Fire(self,net.aft.transfers[FID].name,"U")
				net.aft.transfers[FID]=nil -- clean up
			elseif cmd=="PIECE" then -- Server is asking for a piece to some file
				local pieces=tonumber(pieces)
				local pp=pieces-1
				local unpackedDATA=net.aft.transfers.UPLOADS[FID].sink:sub((pp*net.aft.pieceSize)+1,(pp+1)*net.aft.pieceSize)
				local num=#unpackedDATA
				if num<384 then
					self:send("!aft! TRANS "..FID.."|"..pieces.." "..net.normalize(unpackedDATA))
				else
					local unpackedDATA1=unpackedDATA:sub(1,384)
					local unpackedDATA2=unpackedDATA:sub(385)
					local packedDATA=net.normalize(unpackedDATA1)..net.normalize(unpackedDATA2)
					self:send("!aft! TRANS "..FID.."|"..pieces.." "..packedDATA)
				end
			elseif cmd=="TRANS" then-- self,data,FID,piecenum,hash
				if self.autoNormalization==false then -- if we already handled normalization in the main data packet then don't redo
					local ddata
					if #arg2<512 then
						ddata=net.denormalize(arg2)
					else
						ddata=net.denormalize(arg2:sub(1,512))..net.denormalize(arg2:sub(513))
					end
					struct={
						data=ddata,
						FID=FID,
						piecenum=tonumber(pieces),
						numpieces=net.aft.transfers[FID].numpieces,
						hash=arg1,
						name=net.aft.transfers[FID].name,
					}
				else
					struct={
						data=arg2,
						FID=FID,
						piecenum=tonumber(pieces),
						numpieces=net.aft.transfers[FID].numpieces,
						hash=arg1,
						name=net.aft.transfers[FID].name,
					}
				end
				net.aft.transfers[FID].currentPiece=tonumber(pieces)
				self.OnPieceRecieved:Fire(self,struct)
				local data,FID,piecenum,hash=struct.data,struct.FID,struct.piecenum,struct.hash
				net.aft.transfers[FID].sink:tackE(data)
				net.aft.transfers[FID].piecesRecieved=net.aft.transfers[FID].piecesRecieved+1
				if net.aft.transfers[FID].numpieces==net.aft.transfers[FID].piecesRecieved then
					print(net.aft.transfers[FID].name.." has finished downloading!")
					net.aft.transfers[FID].sink:close()
					self:send("!aft! COMPLETE "..FID.." NIL") -- for clean up purposes
					self.OnTransferCompleted:Fire(self,net.aft.transfers[FID].name)
				else
					self:requestPiece(FID,piecenum+1) -- get next piece
				end
			elseif cmd=="DOWNLOAD" then
				local msg=FID
				self.OnFileRequestFailed:Fire(msg)
				print("Download Error!",msg)
			elseif cmd=="UPLOAD" then
				local msg=FID
				self.OnFileUploadFailed:Fire(msg)
				print("Upload Error!",msg)
			end
		end,"aft")
		function c:requestFile(filename,sink) -- sinks data through a bin-stream sink if the filename you want otherwise the filename is used instead
			self:send("!aft! REQUEST "..filename.." NIL")
			if sink then
				net.aft.sinks[filename]=sink
			end
		end
		function c:requestUpload(filename)
			if io.fileExists(filename) then
				local FID=bin.new(filename):getRandomHash(16) -- We need this, but its not as important for client as it is for servers
				local file=bin.stream(filename)
				if not net.aft.transfers.UPLOADS then
					net.aft.transfers.UPLOADS={}
				end
				if not net.aft.transfers.UPLOADS[FID] then
					net.aft.transfers.UPLOADS[FID]={}
				end
				net.aft.transfers.UPLOADS[FID].sink=file -- client file management is much simpler since we only have to worry about 1 reciever/sender
				net.aft.transfers.UPLOADS[FID].name=filename
				net.aft.transfers.UPLOADS[FID].size=file:getSize()
				net.aft.transfers.UPLOADS[FID].pieces=math.ceil(net.aft.transfers.UPLOADS[FID].size/net.aft.pieceSize)
				self:send("!aft! UPLOAD "..FID.."|"..filename.." "..net.aft.transfers.UPLOADS[FID].pieces)-- Lets send the FID we will be using and the number of pieces the server should look out for
			else
				self.OnFileUploadFailed:Fire("File specified not found! "..filename.." does not exist!")
			end
		end
		function c:requestPiece(FID,piecenum)
			self:send("!aft! PIECE "..FID.." "..piecenum)
		end
	end)
end
if net.autoInit then
	net.aft.init()
end
