if not ISTHREAD then
	multi, thread = require("multi").init()
	GLOBAL = multi.integration.GLOBAL
	THREAD = multi.integration.THREAD
end

function multi:newSystemThreadedQueue(name)
	local name = name or multi.randomString(16)

	local c = {}

	c.Name = name
	c.Type = multi.registerType("s_queue")
    c.chan = love.thread.getChannel(name)

    function c:push(dat)
        self.chan:push(THREAD.packValue(dat))
    end

    function c:pop()
		return THREAD.unpackValue(self.chan:pop())
    end

    function c:peek()
		return THREAD.unpackValue(self.chan:peek())
    end

    function c:init()
		self.chan = love.thread.getChannel(self.Name)
        return self
    end

    function c:Hold(opt)
		local multi, thread = require("multi"):init()
        if opt.peek then
            return thread.hold(function()
                return self:peek()
            end)
        else
            return thread.hold(function()
                return self:pop()
            end)
        end
	end

    GLOBAL[name] = c

	self:create(c)

	return c
end

function multi:newSystemThreadedTable(name)
	local name = name or multi.randomString(16)
    
	local c = {}

    c.Name = name
	c.Type = multi.registerType("s_table")
    c.tab = THREAD.createTable(name)

    function c:init()
        self.tab = THREAD.createTable(self.Name)
        setmetatable(self,{
            __index = function(t, k)
                return self.tab[k]
            end,
            __newindex = function(t,k,v)
                self.tab[k] = v
            end
        })
        return self
    end

	c.__init = c.init

    function c:Hold(opt)
		local multi, thread = require("multi"):init()
        if opt.key then
            return thread.hold(function()
                return self.tab[opt.key]
            end)
        else
            multi.error("Must provide a key to check opt.key = 'key'")
        end
    end

    setmetatable(c,{
        __index = function(t, k)
            return c.tab[k]
        end,
        __newindex = function(t,k,v)
            c.tab[k] = v
        end
    })

    GLOBAL[name] = c

	self:create(c)

	return c
end

local jqc = 1
function multi:newSystemThreadedJobQueue(n)
	local c = {}

	c.cores = n or THREAD.getCores()
	c.registerQueue = {}
	c.Type = multi.registerType("s_jobqueue")
	c.funcs = THREAD.createTable("__JobQueue_"..jqc.."_table")
	c.queue = multi:newSystemThreadedQueue("__JobQueue_"..jqc.."_queue")
	c.queueReturn = multi:newSystemThreadedQueue("__JobQueue_"..jqc.."_queueReturn")
	c.queueAll = multi:newSystemThreadedQueue("__JobQueue_"..jqc.."_queueAll")
	c.id = 0
	c.OnJobCompleted = multi:newConnection()

	local allfunc = 0

	function c:doToAll(func)
		for i = 1, self.cores do
			self.queueAll:push({allfunc, func})
		end
		allfunc = allfunc + 1
	end
	function c:registerFunction(name, func)
		if self.funcs[name] then
			multi.error("A function by the name "..name.." has already been registered!") 
		end
		self.funcs[name] = func
	end
	function c:pushJob(name,...)
		self.id = self.id + 1
		self.queue:push{name,self.id,...}
		return self.id
	end
	function c:isEmpty()
        return queueJob:peek()==nil
    end
	local nFunc = 0
    function c:newFunction(name,func,holup) -- This registers with the queue
        if type(name)=="function" then
            holup = func
            func = name
            name = "JQ_Function_"..nFunc
        end
        nFunc = nFunc + 1
        c:registerFunction(name,func)
        return thread:newFunction(function(...)
            local id = c:pushJob(name,...)
            local link
            local rets
            link = c.OnJobCompleted(function(jid,...)
                if id==jid then
                    rets = multi.pack(...)
                end
            end)
            return thread.hold(function()
                if rets then
                    return multi.unpack(rets) or multi.NIL
                end
            end)
        end,holup),name
    end
	thread:newThread("jobManager",function()
		while true do
			thread.yield()
			local dat = c.queueReturn:pop()
			if dat then
				c.OnJobCompleted:Fire(multi.unpack(dat))
			end
		end
	end)
	for i=1,c.cores do
		multi:newSystemThread("JobQueue_"..jqc.."_worker_"..i,function(jqc)
			local multi, thread = require("multi"):init()
			require("love.timer")
			love.timer.sleep(1)
			local clock = os.clock
			local funcs = THREAD.createTable("__JobQueue_"..jqc.."_table")
			local queue = THREAD.waitFor("__JobQueue_"..jqc.."_queue")
			local queueReturn = THREAD.waitFor("__JobQueue_"..jqc.."_queueReturn")
			local lastProc = clock()
			local queueAll = THREAD.waitFor("__JobQueue_"..jqc.."_queueAll")
			local registry = {}
			_G["__QR"] = queueReturn
			setmetatable(_G,{__index = funcs})
			thread:newThread("startUp",function()
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						queueAll:pop()[2]()
					end
				end
			end)
			thread:newThread("runner",function()
				thread.sleep(.1)
				while true do
					thread.yield()
					local all = queueAll:peek()
					if all and not registry[all[1]] then
						lastProc = os.clock()
						queueAll:pop()[2]()
					end
					local dat = thread.hold(queue)
					if dat then
						multi:newThread("Test",function()
							lastProc = os.clock()
							local name = table.remove(dat,1)
							local id = table.remove(dat,1)
							local tab = {funcs[name](multi.unpack(dat))}
							table.insert(tab,1,id)
							--local test = queueReturn.push
							queueReturn:push(tab)
						end)
					end
				end
			end)
			thread:newThread("Idler",function()
				while true do
					thread.yield()
					if clock()-lastProc> 2 then
						THREAD.sleep(.05)
					else
						THREAD.sleep(.001)
					end
				end
			end)
			multi:mainloop()
		end,jqc)
	end

    function c:Hold(opt)
        return thread.hold(self.OnJobCompleted)
    end

	jqc = jqc + 1

	self:create(c)

	return c
end