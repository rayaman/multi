package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL,THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
local a
local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end
master = multi:newMaster{
	name = "Main", -- the name of the master
	noBroadCast = true, -- if using the node manager, set this to true to avoid double connections
	managerDetails = {"192.168.1.4",12345}, -- the details to connect to the node manager (ip,port)
}
master.OnError(function(name,err)
	print(name.." has encountered an error: "..err)
end)
local connlist = {}
multi:newThread("NodeUpdater",function()
	while true do
		thread.sleep(1)
		for i=1,#connlist do
			conn = master:execute("TASK_MAN",connlist[i], multi:getTasksDetails())
		end
	end
end)
master.OnNodeConnected(function(name)
	table.insert(connlist,name)
end)
multi.OnError(function(...)
	print(...)
end)


local conncount = 0
function multi:newSystemThreadedConnection(name,protect)
	conncount = conncount + 1
	local c={}
	c.name = name or error("You must provide a name for the connection object!")
	c.protect = protect or false
	c.idle = nil
	local sThread=multi.integration.THREAD
	local GLOBAL=multi.integration.GLOBAL
	local connSync = multi:newSystemThreadedQueue(c.name.."_CONN_SYNC")
	local connFire = multi:newSystemThreadedQueue(c.name.."_CONN_FIRE")
	function c:init()
		local multi = require("multi")
		if love then -- lets make sure we don't reference up-values if using love2d
			GLOBAL=_G.GLOBAL
			sThread=_G.sThread
		end
		local conn = {}
		conn.obj = multi:newConnection()
		setmetatable(conn,{
			__call=function(self,...)
				return self:connect(...)
			end
		})
		local ID = sThread.getID()
		local sync = sThread.waitFor(self.name.."_CONN_SYNC"):init()
		local fire = sThread.waitFor(self.name.."_CONN_FIRE"):init()
		local connections = {}
		if not multi.isMainThread then
			connections = {0}
		end
		sync:push{"INIT",ID} -- Register this as an active connection!
		function conn:connect(func)
			return self.obj(func)
		end
		function conn:holdUT(n)
			self.obj:holdUT(n)
		end
		function conn:Remove()
			self.obj:Remove()
		end
		function conn:Fire(...)
			for i = 1,#connections do
				fire:push{connections[i],ID,{...}}
			end
		end
		-- FIRE {TO,FROM,{ARGS}}
		local data
		multi:newLoop(function()
			data = fire:peek()
			if type(data)=="table" and data[1]==ID then
				if data[2]==ID and conn.IgnoreSelf then
					fire:pop()
					return
				end
				fire:pop()
				conn.obj:Fire(unpack(data[3]))
			end
			-- We need to hangle syncs here as well
			data = sync:peek()
			if data~=nil and data[1]=="SYNCA" and data[2]==ID then
				sync:pop()
				table.insert(connections,data[3])
			end
			if type(data)=="table" and data[1]=="SYNCR" and data[2]==ID then
				sync:pop()
				for i=1,#connections do
					if connections[i] == data[3] then
						table.remove(connections,i)
					end
				end
			end
		end)
		return conn
	end
	local cleanUp = {}
	multi.OnSystemThreadDied(function(ThreadID)
		for i=1,#syncs do
			connSync:push{"SYNCR",syncs[i],ThreadID}
		end
		cleanUp[ThreadID] = true
	end)
	multi:newThread(c.name.." Connection Handler",function()
		local data
		local clock = os.clock
		local syncs = {}
		while true do
			if not c.idle then
				thread.sleep(.1)
			else
				if clock() - c.idle >= 15 then
					c.idle = nil
				end
				thread.skip()
			end
			data = connSync:peek()
			if data~= nil and data[1]=="INIT" then
				connSync:pop()
				c.idle = clock()
				table.insert(syncs,data[2])
				for i=1,#syncs do
					connSync:push{"SYNCA",syncs[i],data[2]}
				end
			end
			data = connFire:peek()
			if data~=nil and cleanUp[data[1]] then
				local meh = data[1]
				connFire:pop() -- lets remove dead thread stuff
				multi:newAlarm(15):OnRing(function(a)
					cleanUp[meh] = nil
				end)
			end
		end
	end)
	GLOBAL[c.name]=c
	return c
end


local conn = multi:newSystemThreadedConnection("conn"):init()
conn(function(...)
	print("MAIN",...)
end)
conn.IgnoreSelf = true
multi:newSystemThread("meh",function()
	local multi = require("multi")
	local conn = THREAD.waitFor("conn"):init()
	conn.IgnoreSelf = true
	conn(function(...)
		print("THREAD:",...)
	end)
	multi:newAlarm(1):OnRing(function(a)
		conn:Fire("Does this work?")
		a:Destroy()
	end)
	multi.OnError(function(...)
		print(...)
	end)
	multi:mainloop()
end).OnError(function(...)
	print(...)
end)
multi:newAlarm(2):OnRing(function(a)
	conn:Fire("What about this one?")
	a:Destroy()
end)
multi:mainloop{
	protect = false,
--~ 	print = true
}
