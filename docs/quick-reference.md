# Quick Reference

One-page cheat sheet. Details live in [Core API](core-api.md), [Threading API](threading-api.md), [Integrations](integrations.md), [Advanced Patterns](advanced-patterns.md).

```text
SETUP
  package.path = "?/init.lua;?.lua;" .. package.path
  multi, thread = require("multi"):init{ print=, warn=, debugging=, error=, priority=, findopt= }
  GLOBAL, THREAD = require("multi.integration.threading"):init()   -- love→lanes→pseudo

RUNNERS
  multi:mainloop()          -- blocking (priority-aware if init{priority=true})
  multi:uManager(dt)        -- one pass; for host loops (love.update)
  multi.Stop()              -- end mainloop

ACTORS  (multi or any processor; return actor, err)
  newLoop(func?, notime?)                     OnLoop(self, elapsed, dt)
  newTLoop(func?, interval?)                  OnLoop(self, life, dt)
  newAlarm(secs?, func?)                      OnRing(self, dt)   :Reset(n?)
  newStep(start?, end?, count?, skip?)        OnStart / OnStep(self,pos,dt) / OnEnd
  newTStep(start?, end?, count?, interval?)   like step, time-paced
  newEvent(task?, func?)                      OnEvent(self, dt); self.returns
  newUpdater(skip?, func?)                    OnUpdate(self, dt)
  newTimer()                                  Start/Get/Pause/Resume/Reset (not an actor)
  setTimeout(func, secs)

EVERY ACTOR
  :Pause() :Resume() :Destroy() :Break() :Reset(n?)
  :isPaused() :isActive() :isDone() :IsAnActor()
  :setPriority(s) :ResetPriority() :reallocate(proc, i?)
  :setName(n) :getName() :getFullName() :getType() :GetCreationTimestamp()
  OnBreak  OnPriorityChanged

TIMEOUTS ON ACTORS
  actor:SetTime(secs)  actor:ResolveTimer(...)
  actor.OnTimedOut(self, dt)   actor.OnTimerResolved(self, ...)

CONNECTIONS
  conn = proc:newConnection(protect?, conditional?, kill?)
  conn:Fire(...)             conn:Connect(func, name?) -> handle      conn(func) == Connect
  handle:Unconnect()         conn:Unconnect(handle)
  conn:hasConnections()      conn:getConnection(name):Fire(...)
  conn:Get()  :Bind(t)  :Remove()  :Hold(opt?)
  conn:Lock()/Unlock()       conn:Lock(handle)/Unlock(handle)
  conn:Destroy()  (alias :destroy)
  a + b  OR        a * b  AND        f % conn  MAP        f / conn  FILTER
  f .. conn  GATE  conn .. f  SPLIT  -conn  RAW
  multi.forwardConnection(src, dst)

PRIORITIES
  Core 1 | VeryHigh 4 | High 16 | Above 64 | Normal 256 | Below 1024
  Low 4096 | VeryLow 16384 | Idle 65536      (higher number = runs less)
  strings: core/c  very high/vh  high/h  above/a  normal/n  below/b  low/l  very low/vl  idle/i
  active only with init{priority=true} or processor {Priority=…}

THREADS (coroutines)
  th = multi:newThread(name?, func, ...)      th = proc:newThread(...)
  multi:newISOThread(name?, func, env?, ...)  -- upvalues stripped
  th.OnDeath(returns...)   th.OnError(self, err)
  th:Pause() :Resume() :Kill() :Sleep(n) :Hold(n, opt)   -- requests, honored at yield
  INSIDE threads:
    thread.sleep(n)   thread.yield()   thread.skip(n)
    thread.hold(fn|conn|obj|number, {interval=, sleep=, cycles=, skip=})
    thread.holdFor(sec, cond?)  thread.holdWithin(cycles, cond?)  thread.chain(...)
    thread.set(k,v) get(k) waitFor(k)  thread.pushStatus(...)  thread.defer(fn)
    thread.isThread()  thread.getRunningThread()  thread.kill(msg)
  multi.hold(cond, opt?)    -- outside threads: spins uManager

THREADED FUNCTIONS
  tf = thread:newFunction(func, holdme?)      tf = proc:newFunction(...)
  h = tf(args)  ->  h:wait()  h:connect(f)  h.getReturns()
                 h.OnReturn h.OnError h.OnStatus
  tf:Pause() tf:Resume() tf:holdMe(b)
  timeout = thread.hold(cond, {sleep=5});  multi.isTimeout(timeout)

PROCESSORS
  p = multi:newProcessor(name?, {Start=, Priority=, MaxThreads=, MaxObjects=,
                                 TaskDelay=, Attach=, TaskHandler=})
  p.Start() p.Stop() p:Destroy() p.isActive() p.run(dt) p:boost(n)
  p:newThread/newFunction/newTask/all actor ctors
  p:getThreads() getHandler() getMaxThreads() setMaxThreads(n) setTaskDelay(d)
  p.OnError  p.OnObjectCreated  p.Status

SERVICES
  s = multi:newService(fn(self, data))
  s.Start Stop Pause Resume Destroy GetUpTime SetPriority(p) SetScheme(1|2)
  s.OnStarted s.OnStopped s.OnError

TASKS & JOBS
  proc:newTask(fn)                      FIFO one-shot, task-handler thread
  multi:scheduleJob({sec=,min=,hour=,day=,wday=,month=,year=}, fn)

SYSTEM THREADS (after integration init)
  st = multi:newSystemThread(name?, func, ...)   st.OnDeath st.OnError st:kill()
  tf = THREAD:newFunction(func, holdme?)         -- TFunc on OS threads
  GLOBAL[k]=v  GLOBAL[k]  THREAD.set/get/waitFor/getCores/getName/getID
  THREAD.sleep/hold/kill/pushStatus/getConsole/setENV/getENV/exposeENV/defer
  q   = multi:newSystemThreadedQueue(name):init()      push/pop/peek, hold(q)
  t   = multi:newSystemThreadedTable(name):init()      t[k]=v / t[k], :Hold{key=}
  jq  = multi:newSystemThreadedJobQueue(cores?)        cores isEmpty doToAll
         registerFunction pushJob OnJobCompleted newFunction(:wait/:connect) Hold
  conn= multi:newSystemThreadedConnection(name):init() cross-thread Fire
  multi:chop(obj)  multi:newProxy(list)  multi:newSystemThreadedProcessor(cores)

TYPE SYSTEM
  multi.registerType(t, plural?)   multi.hasType(t)   multi.getTypes()
  multi.isMulitObj(obj)            obj:isType(t) obj:getType()
  multi.DestroyedObj / DESTROYED   multi.setType(obj, multi.DestroyedObj)
  multi.NIL   multi.TIMEOUT   multi.$LOOP etc.

LOGGING (gated by settings)
  multi.print warn debug error success      -- ANSI colors
  settings: print warn debugging error priority findopt

UTILITIES
  multi.Round(n, p?)  multi.AlignTable(t)  multi.ForEach(t, f)
  multi.randomString(n)  multi.isTimeout(v)  multi.timer(fn, ...)
  multi.setClock(f)  multi.getStats()  multi:getChildren() getRunners()
  multi:getThreads() getProcessors() getVersion() getPlatform() canSystemThread()
  multi:benchMark(secs, pri?, label?).OnBench(time, steps)
  multi:enableLoadDetection()  multi:getLoad(loops?) -> percent, steps
  multi.generate_uuid7()  multi.extract_uuid7_timestamp(uuid)
  table.merge(t1,t2)  os.getOS()  os.sleep(n)  multi.setEnv(fn, env)

SYSTEM CONNECTIONS
  multi.OnObjectCreated OnObjectDestroyed OnLoad OnPreLoad OnError OnExit
  multi.settingsHook  multi.enableOptimization  multi.optConn
```
