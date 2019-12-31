--[[
MIT License

Copyright (c) 2020 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
function multi:newSystemThreadedConnection(name, protect)
	local c = {}
	c.name = name or error("You must provide a name for the connection object!")
	c.protect = protect or false
	c.idle = nil
	local sThread = multi.integration.THREAD
	local GLOBAL = multi.integration.GLOBAL
	local connSync = multi:newSystemThreadedQueue(c.name .. "_CONN_SYNC")
	local connFire = multi:newSystemThreadedQueue(c.name .. "_CONN_FIRE")
	function c:init()
		local multi = require("multi")
		if love then -- lets make sure we don't reference up-values if using love2d
			GLOBAL = _G.GLOBAL
			sThread = _G.sThread
		end
		local conn = {}
		conn.obj = multi:newConnection()
		setmetatable(
			conn,
			{
				__call = function(self, ...)
					return self:connect(...)
				end
			}
		)
		local ID = sThread.getID()
		local sync = sThread.waitFor(self.name .. "_CONN_SYNC"):init()
		local fire = sThread.waitFor(self.name .. "_CONN_FIRE"):init()
		local connections = {}
		if not multi.isMainThread then
			connections = {0}
		end
		sync:push {"INIT", ID} -- Register this as an active connection!
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
			for i = 1, #connections do
				fire:push {connections[i], ID, {...}}
			end
		end
		function conn:FireTo(to, ...)
			local good = false
			for i = 1, #connections do
				if connections[i] == to then
					good = true
					break
				end
			end
			if not good then
				return multi.print("NonExisting Connection!")
			end
			fire:push {to, ID, {...}}
		end
		-- FIRE {TO,FROM,{ARGS}}
		local data
		local clock = os.clock
		conn.OnConnectionAdded = multi:newConnection()
		multi:newLoop(
			function()
				data = fire:peek()
				if type(data) == "table" and data[1] == ID then
					if data[2] == ID and conn.IgnoreSelf then
						fire:pop()
						return
					end
					fire:pop()
					conn.obj:Fire(unpack(data[3]))
				end
				data = sync:peek()
				if data ~= nil and data[1] == "SYNCA" and data[2] == ID then
					sync:pop()
					multi.nextStep(
						function()
							conn.OnConnectionAdded:Fire(data[3])
						end
					)
					table.insert(connections, data[3])
				end
				if type(data) == "table" and data[1] == "SYNCR" and data[2] == ID then
					sync:pop()
					for i = 1, #connections do
						if connections[i] == data[3] then
							table.remove(connections, i)
						end
					end
				end
			end
		):setName("STConn.syncer")
		return conn
	end
	local cleanUp = {}
	multi.OnSystemThreadDied(
		function(ThreadID)
			for i = 1, #syncs do
				connSync:push {"SYNCR", syncs[i], ThreadID}
			end
			cleanUp[ThreadID] = true
		end
	)
	multi:newThread(
		c.name .. " Connection-Handler",
		function()
			local data
			local clock = os.clock
			local syncs = {}
			while true do
				if not c.idle then
					thread.sleep(.5)
				else
					if clock() - c.idle >= 15 then
						c.idle = nil
					end
					thread.skip()
				end
				data = connSync:peek()
				if data ~= nil and data[1] == "INIT" then
					connSync:pop()
					c.idle = clock()
					table.insert(syncs, data[2])
					for i = 1, #syncs do
						connSync:push {"SYNCA", syncs[i], data[2]}
					end
				end
				data = connFire:peek()
				if data ~= nil and cleanUp[data[1]] then
					local meh = data[1]
					connFire:pop() -- lets remove dead thread stuff
					multi:newAlarm(15):OnRing(
						function(a)
							cleanUp[meh] = nil
						end
					)
				end
			end
		end
	)
	GLOBAL[c.name] = c
	return c
end
function multi:SystemThreadedBenchmark(n)
	n = n or 1
	local cores = multi.integration.THREAD.getCores()
	local queue = multi:newSystemThreadedQueue("THREAD_BENCH_QUEUE"):init()
	local sThread = multi.integration.THREAD
	local GLOBAL = multi.integration.GLOBAL
	local c = {}
	for i = 1, cores do
		multi:newSystemThread(
			"STHREAD_BENCH",
			function(n)
				local multi = require("multi")
				if multi:getPlatform() == "love2d" then
					GLOBAL = _G.GLOBAL
					sThread = _G.sThread
				end -- we cannot have upvalues... in love2d globals, not locals must be used
				queue = sThread.waitFor("THREAD_BENCH_QUEUE"):init() -- always wait for when looking for a variable at the start of the thread!
				multi:benchMark(n):OnBench(
					function(self, count)
						queue:push(count)
						sThread.kill()
						error("Thread was killed!")
					end
				)
				multi:mainloop()
			end,
			n
		)
	end
	multi:newThread(
		"THREAD_BENCH",
		function()
			local count = 0
			local cc = 0
			while true do
				thread.skip(1)
				local dat = queue:pop()
				if dat then
					cc = cc + 1
					count = count + dat
					if cc == cores then
						c.OnBench:Fire(count)
						thread.kill()
					end
				end
			end
		end
	)
	c.OnBench = multi:newConnection()
	return c
end
function multi:newSystemThreadedConsole(name)
	local c = {}
	c.name = name
	local sThread = multi.integration.THREAD
	local GLOBAL = multi.integration.GLOBAL
	function c:init()
		_G.__Needs_Multi = true
		local multi = require("multi")
		if multi:getPlatform() == "love2d" then
			GLOBAL = _G.GLOBAL
			sThread = _G.sThread
		end
		local cc = {}
		if multi.isMainThread then
			if GLOBAL["__SYSTEM_CONSOLE__"] then
				cc.stream = sThread.waitFor("__SYSTEM_CONSOLE__"):init()
			else
				cc.stream = multi:newSystemThreadedQueue("__SYSTEM_CONSOLE__"):init()
				multi:newLoop(
					function()
						local data = cc.stream:pop()
						if data then
							local dat = table.remove(data, 1)
							if dat == "w" then
								io.write(unpack(data))
							elseif dat == "p" then
								print(unpack(data))
							end
						end
					end
				):setName("ST.consoleSyncer")
			end
		else
			cc.stream = sThread.waitFor("__SYSTEM_CONSOLE__"):init()
		end
		function cc:write(msg)
			self.stream:push({"w", tostring(msg)})
		end
		function cc:print(...)
			local tab = {...}
			for i = 1, #tab do
				tab[i] = tostring(tab[i])
			end
			self.stream:push({"p", unpack(tab)})
		end
		return cc
	end
	GLOBAL[c.name] = c
	return c
end
function multi:newSystemThreadedExecute(cmd)
	local c = {}
	local GLOBAL = multi.integration.GLOBAL -- set up locals incase we are using lanes
	local sThread = multi.integration.THREAD -- set up locals incase we are using lanes
	local name = "Execute_Thread" .. multi.randomString(16)
	c.name = name
	GLOBAL[name .. "CMD"] = cmd
	multi:newSystemThread(
		name,
		function()
			if love then -- lets make sure we don't reference upvalues if using love2d
				GLOBAL = _G.GLOBAL
				sThread = _G.sThread
				name = __THREADNAME__ -- global data same as the name we used in this functions creation
			end -- Lanes should take the local upvalues ^^^
			cmd = sThread.waitFor(name .. "CMD")
			local ret = os.execute(cmd)
			GLOBAL[name .. "R"] = ret
		end
	)
	c.OnCMDFinished = multi:newConnection()
	c.looper =
		multi:newLoop(
		function(self)
			local ret = GLOBAL[self.link.name .. "R"]
			if ret then
				self.link.OnCMDFinished:Fire(ret)
				self:Destroy()
			end
		end
	)
	c.looper.link = c
	return c
end
