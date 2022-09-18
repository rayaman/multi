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
	local proxy_conn = multi:newConnection(...)
	local name = name or multi.randomString(16)
	local connections = {} -- All triggers sent from main connection. When a connection is triggered on another thread, they speak to the main then send stuff out.
	local funcs = {}
	setmetatable(c,master_conn) -- A different approach will be taken for the non main connection objects
	c.subscribe = multi:newSystemThreadedQueue("Subscribe_"..name):init() -- Incoming subscriptions
	multi:newThread("STC_"..name,function()
		while true do
			thread.yield()
			local item = c.subscribe:pop()
			-- We need to check on broken connections
			-- c:Ping()
			--
			if item ~= nil then
				connections[#connections+1] = item
				multi.ForEach(funcs, function(link) -- Sync new connections
					item:push{c.CONN, link}
				end)
				thread.skip(multi.Priority_Normal) -- Usually a bunch of threads subscribe close to the same time. Process those by ensuring that they come alive around the same time
				-- I'm using these "Constants" since they may change with other releases and this should allow these functions to adjust with them.
			end
		end
	end)
	function c:Ping() -- Threaded Function call, can use thread.*
		--
	end
	function c:Fire(...)
		--
	end
	function c:Sync(link)
		--
	end
	function c:Connect(func)
		local conn_func = func
		proxy_conn(function()
			funcs[#funcs+1] = func -- Used for syncing new connections to this connection later on
			multi.ForEach(c.connections, function(link)
				link:push{CONN, func}
			end)
		end)
	end
	function c:init()
		return self
	end
	GLOBAL[name or "_"] = c
	return c
end

multi:mainloop()