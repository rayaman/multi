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
local function init(multi,thread)
    if table.unpack and not unpack then
        unpack=table.unpack
    end
    multi.DestroyedObj = {
        Type = "destroyed",
    }
    
    local function uni()
        return multi.DestroyedObj
    end

    local function uniN() end
    function multi.setType(obj,t)
        if t == multi.DestroyedObj then
            for i,v in pairs(obj) do
                obj[i] = nil
            end
            setmetatable(obj, {
                __index = function(t,k)
                    return setmetatable({},{__index = uni,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni})
                end,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni
            })
        end
    end
    setmetatable(multi.DestroyedObj, {
        __index = function(t,k)
            return setmetatable({},{__index = uni,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni})
        end,__newindex = uni,__call = uni,__metatable = multi.DestroyedObj,__tostring = function() return "destroyed" end,__unm = uni,__add = uni,__sub = uni,__mul = uni,__div = uni,__mod = uni,__pow = uni,__concat = uni
    })
    math.randomseed(os.time())
    multi.defaultSettings = {
        priority = 0,
        protect = false,
    }
    
    function multi:enableLoadDetection()
        if multi.maxSpd then return end
        -- here we are going to run a quick benchMark solo
        local temp = multi:newProcessor()
        temp:Start()
        local t = os.clock()
        local stop = false
        temp:benchMark(.01):OnBench(function(time,steps)
            stop = steps
        end)
        while not stop do
            temp:uManager()
        end
        temp:Destroy()
        multi.maxSpd = stop
    end
    
    local busy = false
    local lastVal = 0
    local bb = 0
    
    function multi:getLoad()
        if not multi.maxSpd then multi:enableLoadDetection() end
        if busy then return lastVal end
        local val = nil
        if thread.isThread() then
            local bench
            multi:benchMark(.01):OnBench(function(time,steps)
                bench = steps
                bb = steps
            end)
            thread.hold(function()
                return bench
            end)
            bench = bench^1.5
            val = math.ceil((1-(bench/(multi.maxSpd/2.2)))*100)
        else
            busy = true
            local bench
            multi:benchMark(.01):OnBench(function(time,steps)
                bench = steps
                bb = steps
            end)
            while not bench do
                multi:uManager()
            end
            bench = bench^1.5
            val = math.ceil((1-(bench/(multi.maxSpd/2.2)))*100)
            busy = false
        end
        if val<0 then val = 0 end
        if val > 100 then val = 100 end
        lastVal = val
        return val,bb*100
    end

    function multi:setPriority(s)
        if type(s)==number then
            self.Priority=s
        elseif type(s)=='string' then
            if s:lower()=='core' or s:lower()=='c' then
                self.Priority=self.Priority_Core
            elseif s:lower()=="very high" or s:lower()=="vh" then
                self.Priority=self.Priority_Very_High
            elseif s:lower()=='high' or s:lower()=='h' then
                self.Priority=self.Priority_High
            elseif s:lower()=='above' or s:lower()=='a' then
                self.Priority=self.Priority_Above_Normal
            elseif s:lower()=='normal' or s:lower()=='n' then
                self.Priority=self.Priority_Normal
            elseif s:lower()=='below' or s:lower()=='b' then
                self.Priority=self.Priority_Below_Normal
            elseif s:lower()=='low' or s:lower()=='l' then
                self.Priority=self.Priority_Low
            elseif s:lower()=="very low" or s:lower()=="vl" then
                self.Priority=self.Priority_Very_Low
            elseif s:lower()=='idle' or s:lower()=='i' then
                self.Priority=self.Priority_Idle
            end
            self.solid = true
        end
        if not self.PrioritySet then
            self.defPriority = self.Priority
            self.PrioritySet = true
        end
    end
    
    function multi:ResetPriority()
        self.Priority = self.defPriority
    end

    function os.getOS()
        if package.config:sub(1,1)=='\\' then
            return 'windows'
        else
            return 'unix'
        end
    end
    
    if os.getOS()=='windows' then
        function os.sleep(n)
            if n > 0 then os.execute('ping -n ' .. tonumber(n+1) .. ' localhost > NUL') end
        end
    else
        function os.sleep(n)
            os.execute('sleep ' .. tonumber(n))
        end
    end
    
    function multi.randomString(n)
        local str = ''
        local strings = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','1','2','3','4','5','6','7','8','9','0','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
        for i=1,n do
            str = str..''..strings[math.random(1,#strings)]
        end
        return str
    end
    
    function multi:getParentProcess()
        return self.Mainloop[self.CID]
    end

    function multi:getChildren()
        return self.Mainloop
    end
    
    function multi:getVersion()
        return multi.Version
    end
    
    function multi:getPlatform()
        if love then
            if love.thread then
                return "love2d"
            end
        else
            return "lanes"
        end
    end
    
    function multi:canSystemThread()
        return false
    end

    function multi:getError()
        if self.error then
            return self.error
        end
    end

    function multi:benchMark(sec,p,pt)
        local c = 0
        local temp=self:newLoop(function(self,t)
            if t>sec then
                if pt then
                    multi.print(pt.." "..c.." Steps in "..sec.." second(s)!")
                end
                self.tt(sec,c)
                self:Destroy()
            else
                c=c+1
            end
        end)
        temp:setPriority(p or 1)
        function temp:OnBench(func)
            self.tt=func
        end
        self.tt=function() end
        return temp
    end

    function multi.Round(num, numDecimalPlaces)
        local mult = 10^(numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end
      
    function multi.AlignTable(tab)
        local longest = {}
        local columns = #tab[1]
        local rows = #tab
        for i=1, columns do
            longest[i] = -math.huge
        end
        for i = 1,rows do
            for j = 1,columns do
                tab[i][j] = tostring(tab[i][j])
                if #tab[i][j]>longest[j] then
                    longest[j] = #tab[i][j]
                end
            end
        end
        for i = 1,rows do
            for j = 1,columns do
                if tab[i][j]~=nil and #tab[i][j]<longest[j] then
                    tab[i][j]=tab[i][j]..string.rep(" ",longest[j]-#tab[i][j])
                end
            end
        end
        local str = {}
        for i = 1,rows do
            str[#str+1] = table.concat(tab[i]," ")
        end
        return table.concat(str,"\n")
    end

    function multi:endTask(TID)
        self.Mainloop[TID]:Destroy()
        return self
    end

    function multi:IsAnActor()
        return self.Act~=nil
    end

    function multi:reallocate(o,n)
        n=n or #o.Mainloop+1
        local int=self.Parent
        self:Destroy()
        self.Parent=o
        table.insert(o.Mainloop,n,self)
        self.Active=true
    end

    function multi.timer(func,...)
        local timer=multi:newTimer()
        timer:Start()
        args={func(...)}
        local t = timer:Get()
        timer = nil
        return t,unpack(args)
    end
    
    function multi:OnMainConnect(func)
        table.insert(self.func,func)
        return self
    end
    
    function multi:FreeMainEvent()
        self.func={}
    end
    
    function multi:connectFinal(func)
        if self.Type=='event' then
            self:OnEvent(func)
        elseif self.Type=='alarm' then
            self:OnRing(func)
        elseif self.Type=='step' or self.Type=='tstep' then
            self:OnEnd(func)
        else
            multi.print("Warning!!! "..self.Type.." doesn't contain a Final Connection State! Use "..self.Type..":Break(func) to trigger it's final event!")
            self:OnBreak(func)
        end
    end

    if os.getOS()=="windows" then
        thread.__CORES=tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
    else
        thread.__CORES=tonumber(io.popen("nproc --all"):read("*n"))
    end
    thread.requests = {}

    multi.GetType=multi.getType
    multi.IsPaused=multi.isPaused
    multi.IsActive=multi.isActive
    multi.Reallocate=multi.Reallocate
    multi.GetParentProcess=multi.getParentProcess
    multi.ConnectFinal=multi.connectFinal
    multi.ResetTime=multi.SetTime
    multi.IsDone=multi.isDone
    multi.SetName = multi.setName

    -- Special Events
    local _os = os.exit
    function os.exit(n)
        multi.OnExit:Fire(n or 0)
        _os(n)
    end
    multi.OnError=multi:newConnection()
    multi.OnPreLoad = multi:newConnection()
    multi.OnExit = multi:newConnection(nil,nil,true)
    multi.m = {onexit = function() multi.OnExit:Fire() end}
    if _VERSION >= "Lua 5.2" then
        setmetatable(multi.m, {__gc = multi.m.onexit})
    else
        multi.m.sentinel = newproxy(true)
        getmetatable(multi.m.sentinel).__gc = multi.m.onexit
    end
end
return {init=init}