require("net.identity")
require("net.aft")
require("net.users")
require("net.db")
net:registerModule("inbox",{1,0,0})
--self.OnUserLoggedIn:Fire(user,cid,ip,port,bin.ToStr(handle))
--allows the storing of messages that the user can recieve and view whenever. Allows user to also send messeges to users that are even offline!
--requires an account setup and nick name to be set at account creation
if not io.dirExists("INBOX") then
	io.mkDir("INBOX")
end
net.inbox.dbfmt=db.format([=[
[INBOX]{
	string MSG 0x800 -- contents of the message
}
[MAIL]{
	string NAME 0x20 -- username
	string UID 	0x10 -- User ID
	string NICK 0x20 -- Nickname
	number[3] DATE -- list of numbers
	table INBO INBOX -- Inbox
}
]=])
net.OnServerCreated:connect(function(s)
	s.OnUserLoggedIn(function(user,cid,ip,port,dTable)
		if not io.dirExists("INBOX/"..self:getUSERID(cid)) then -- Make sure inbox stuff is set up
			io.mkDir("INBOX/"..self:getUSERID(cid))
			bin.new():tofile("info.dat")
		end
	end)
	s.OnDataRecieved(function(self,data,CID_OR_HANDLE,IP_OR_HANDLE,PORT_OR_IP)
		if self:userLoggedIn(cid) then -- If the user is logged in we do the tests
			local cmd,arg1,arg2=data:match("!inbox! (%S+) (%S+) (%S+)")
			if cmd=="SEND" then
				--
			elseif cmd=="LIST" then
				--
			elseif cmd=="OPEN" then
				--
			elseif cmd=="DELETE" then
				--
			elseif cmd=="CLEAR" then
				--
			end
		else
			return
		end
	end,"inbox")
end)
net.OnClientCreated:connect(function(c)
	c.OnDataRecieved(function(self,data)
		--
	end,"inbox")
	function c:sendMessage(USERID,msg) -- USERID who, msg being sent. Server handles time stamps
		self:send("!inbox! SEND "..USERID.." "..msg)
	end
	function c:checkInbox() -- returns list of msgIDs
		self:send("!inbox! LIST NIL NIL")
	end
	function c:checkMsg(msgId)
		self:send("!inbox! OPEN "..msgId.." NIL") -- server sends back msg content as a file
	end
	function c:deleteMessage(msgID)
		self:send("!inbox! DELETE "..msgId.." NIL")
	end
	function c:clearInbox()
		self:send("!inbox! CLEAR NIL NIL")
	end
	--
end)
