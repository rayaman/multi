package.path = "./?/init.lua;?.lua;lua5.2/share/lua/5.2/?/init.lua;lua5.2/share/lua/5.2/?.lua;"
package.cpath = "lua5.2/lib/lua/5.2/?/core.dll;"
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

function multi:newSystemThreadedConnection(name)
	local name = name or multi.randomString(16)
	local c = {}
	c.CONN = 0x00
	c.TRIG = 0x01
	c.PING = 0x02
	c.PONG = 0x03
	local function remove(a, b)
		local ai = {}
		local r = {}
		for k,v in pairs(a) do ai[v]=true end
		for k,v in pairs(b) do 
			if ai[v]==nil then table.insert(r,a[k]) end
		end
		return r
	end
	c.Name = name
	c.links = {} -- All triggers sent from main connection. When a connection is triggered on another thread, they speak to the main then send stuff out.
	local ping
	ping = thread:newFunction(function(self)
		ping:Pause() -- Don't allow this function to be called until the first instance is done
		local pings = {}
		local count = #self.links
		multi.ForEach(self.links, function(link) -- Sync new connections
			link:push{self.PING}
		end)
		thread.hold(function()
			item = self.subscribe:peek()
			if item ~= nil and item[1] == self.PONG then
				table.insert(pings,item[2])
			end
			if #pings==count then
				return true -- If we get all pings give control back
			end
		end,{sleep=3}) -- Give all threads time to respond to the ping
		-- We waited long enough for a response, anything that did not respond gets removed
		self.links = remove(self.links, pings)
		ping:Resume()
	end,false)

	thread:newThread("STC_SUB_MAN"..name,function()
		local item
		while true do
			thread.yield()
			-- We need to check on broken connections
			ping() -- Should return instantlly and process this in another thread
			thread.hold(function()
				item = c.subscribe:peek()
				if item ~= nil and item[1] == c.CONN then
					c.subscribe:pop()
					multi.ForEach(c.links, function(link) -- Sync new connections
						item[2]:push{c.CONN, link}
					end)
					c.links[#c.links+1] = item
				end
				-- Nil return keeps this hold going until timeout
			end,{cycles=multi.Priority_Normal})
			-- Usually a bunch of threads subscribe close to the same time.
		end
	end)

	function c:Fire(...)
		self.proxy_conn:Fire(...)
		local args = {...}
		multi.ForEach(self.links, function(link) -- Sync new connections
			print(link[2]) -- Bugs everywhere
			for i,v in pairs(link[2]) do print(i,v) end
			link[2]:push{self.TRIG, args}
		end)
	end

	function c:init()
		self.links = {}
		self.proxy_conn = multi:newConnection()
		setmetatable(self, {__index = self.proxy_conn})
		self.subscribe = multi:newSystemThreadedQueue("SUB_STC_"..self.Name):init() -- Incoming subscriptions
		thread:newThread("STC_CONN_MAN"..name,function()
			local item
			local link_self_ref = multi:newSystemThreadedQueue()
			self.subscribe:push{self.CONN,link_self_ref}
			while true do
				item = thread.hold(function()
					return self.subscribe:peek()
				end)
				if item[1] == self.PING then
					self.subscribe:push{self.PONG, link_self_ref}
				elseif item[1] == self.CONN then
					if item[2] ~= link_self_ref then
						table.insert(self.links, item[2])
					end
				elseif item[1] == self.TRIG then
					self.proxy_conn:Fire(unpack(item[2]))
				else
					-- This shouldn't be the case
				end
			end
		end)
		return self
	end

	GLOBAL[name] = c

	return c
end

local conn = multi:newSystemThreadedConnection("conn"):init()
multi:newSystemThread("Test",function()
	local multi, thread = require("multi"):init()
	local conn = THREAD.waitFor("conn"):init()
	conn(function()
		print("Thread was triggered!")
	end)
	multi:mainloop()
end)
-- conn(function()
-- 	print("Mainloop conn got triggered!")
-- end)

alarm = multi:newAlarm(1)
alarm:OnRing(function() 
	print("Ring") 
	conn:Fire() 
end)

multi:mainloop()