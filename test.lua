package.path = "./?/init.lua;?.lua;lua5.4/share/lua/?/init.lua;lua5.4/share/lua/?.lua;"..package.path
package.cpath = "lua5.4/lib/lua/?/core.dll;"..package.cpath
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

function multi:newSystemThreadedConnection(name,...)
	local c = {}
	c.CONN = 0x00
	c.TRIG = 0x01
	c.PING = 0x02
	c.PONG = 0x03
	c.proxy_conn = multi:newConnection(...)
	local function remove(a, b)
		local ai = {}
		local r = {}
		for k,v in pairs(a) do ai[v]=true end
		for k,v in pairs(b) do 
			if ai[v]==nil then table.insert(r,a[k]) end
		end
		return r
	end
	local name = name or multi.randomString(16)
	c.Name = name
	local connections = {} -- All triggers sent from main connection. When a connection is triggered on another thread, they speak to the main then send stuff out.
	local funcs = {}
	setmetatable(c,master_conn) -- A different approach will be taken for the non main connection objects
	c.subscribe = multi:newSystemThreadedQueue("SUB_STC_"..name):init() -- Incoming subscriptions
	multi:newThread("STC_SUB_MAN"..name,function()
		local item
		while true do
			thread.yield()
			-- We need to check on broken connections
			c:Ping() -- Should return instantlly and process this in another thread
			thread.hold(function()
				item = c.subscribe:peek()
				if item ~= nil and item[1] == c.CONN then
					c.subscribe:pop()
					connections[#connections+1] = item
					multi.ForEach(funcs, function(link) -- Sync new connections
						item:push{c.CONN, link}
					end)
				end
				-- Nil return keeps this hold going until timeout
			end,{cycles=multi.Priority_Normal})
			-- Usually a bunch of threads subscribe close to the same time.
			-- Give those threads some time to ready up.
		end
	end)
	c.Ping = thread:newFunction(function(self)
		c.Ping:Pause() -- Don't allow this function to be called more than once
		local pings = {}
		multi.ForEach(funcs, function(link) -- Sync new connections
			link:push{self.PING}
		end)
		thread.hold(function()
			item = self.subscribe:peek()
			if item ~= nil and item[1] == self.PONG then
				table.insert(pings,item[2])
			end
		end,{sleep=3}) -- Give all threads time to respond to the ping
		-- We waited long enough for a response, anything that did not respond gets removed
		remove(funcs, pings)
		c.Ping:Resume()
	end,false)
	function c:Fire(...)
		master_conn:Fire(...)
		multi.ForEach(funcs, function(link) -- Sync new connections
			link:push{self.TRIG,{...}}
		end)
	end
	function c:Sync(link)
		--
	end
	function c:Connect(func)
		local conn_func = func
		self.proxy_conn(func)
		proxy_conn(function()
			funcs[#funcs+1] = func -- Used for syncing new connections to this connection later on
			multi.ForEach(self.connections, function(link)
				link:push{CONN, func}
			end)
		end)
	end
	function c:init()
		self.proxy_conn 
		return self
	end
	GLOBAL[name] = c
	return c
end

multi:mainloop()