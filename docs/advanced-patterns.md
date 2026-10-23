# Advanced Patterns & Recipes

Part of the [Multi documentation suite](Documentation.md). Practical recipes, architecture patterns, and the sharp edges worth knowing.

---

## Table of Contents

1. [Structuring an Application](#structuring-an-application)
2. [Event Pipelines](#event-pipelines)
3. [Async Sequences & Coordination](#async-sequences--coordination)
4. [Service-Backed Job Queue](#service-backed-job-queue)
5. [Parallel TFunc Fan-Out](#parallel-tfunc-fan-out)
6. [Cross-Thread Producer/Consumer](#cross-thread-producerconsumer)
7. [Performance & Tuning](#performance--tuning)
8. [Optimization Hints (findopt)](#optimization-hints-findopt)
9. [Gotchas & Pitfalls](#gotchas--pitfalls)

---

## Structuring an Application

Use one processor per subsystem. Stopping a feature is then a single call, and errors/cap limits are contained.

```lua
local audio  = multi:newProcessor("Audio",  { Start = true, Attach = true, MaxObjects = 50 })
local net    = multi:newProcessor("Net",    { Start = true, Attach = true, MaxThreads = 4 })
local gameUI = multi:newProcessor("UI",     { Start = true, Attach = true })

audio:newTLoop(updateMixer, 0.02)
net:newThread("RecvLoop", receiveLoop)

-- feature flag off:
net.Stop()          -- everything inside idles instantly
-- teardown:
net:Destroy()
```

Move an actor between subsystems at runtime with `actor:reallocate(otherProc, index?)` — useful when a task outgrows its budget.

---

## Event Pipelines

Compose connections instead of writing glue code:

```lua
-- Validate → transform → branch
local valid   = function(p) return p.x >= 0 and p.y >= 0, p end / inputConn
local scaled  = function(p) p.x = p.x * scale; p.y = p.y * scale; return p end % valid
local saved   = function(p) return p.save end .. storageConn   -- gate
scaled(function(p) if p.save then storageConn:Fire(p) end end)

-- "either button fired"
local anyKey = keyA.OnPress + keyB.OnPress
anyKey(function() playSound() end)

-- "both players ready"
local go = p1.OnReady * p2.OnReady
go(startMatch)
```

```mermaid
flowchart LR
    IN["inputConn"] -- "/ guard" --> V["valid"] -- "% map" --> S["scaled"] -- ".. gate" --> ST["storageConn"]
```

Keep ownership clear: the connection that created an operator-child destroys it. `conn:Destroy()` cascades through everything built with `+ * % / ..`.

---

## Async Sequences & Coordination

**Sequential waits** — `thread.chain` runs holds in order:

```lua
multi:newThread("Boot", function()
    thread.chain(
        configLoadedConn,                 -- wait for signal
        function() return saveExists() end, -- wait for condition
        function() return audioReady end
    )
    startGame()
end)
```

**Racing a deadline against an event** — `hold` with `{sleep=…}`:

```lua
local ok, why = thread.hold(serverGoneConn, { sleep = 5 })
if multi.isTimeout(why) then
    reconnect()
end
```

**Actor deadline** — `SetTime`/`ResolveTimer` when the waiter *is* an actor:

```lua
local handshake = multi:newEvent(function() return helloAck end)
handshake:SetTime(10)
handshake.OnTimedOut(function() retry() end)
handshake.OnTimerResolved(function() proceed() end)
```

---

## Service-Backed Job Queue

The canonical service example — a named job queue with cancellation:

```lua
multi.Jobs = multi:newService(function(self, jobs)
    local job = table.remove(jobs, 1)
    if job and job.removed == nil then job.func() end
end)

multi.Jobs.OnStarted(function(self, jobs)
    function self:newJob(func, name)
        table.insert(jobs, { func = func, name = name,
            removeJob = function(j) j.removed = true end })
    end
    function self:getJobs(name)
        if not name then return jobs end
        local out = {}
        for i = 1, #jobs do
            if jobs[i].name == name then out[#out+1] = jobs[i] end
        end
        return out
    end
    function self:removeJobs(name)
        for i = 1, #jobs do
            if not name or jobs[i].name == name then jobs[i]:removeJob() end
        end
    end
end)

multi.Jobs.SetPriority(multi.Priority_Normal)
multi.Jobs.Start()

multi.Jobs:newJob(importLevel, "loading")
multi.Jobs:getJobs("loading")[1]:removeJob()
```

Tune throughput with `SetScheme(1)` (time-paced) vs `SetScheme(2)` (cycle-paced) and the priority constant.

---

## Parallel TFunc Fan-Out

Fire several TFuncs, then wait for all with an AND-merged connection:

```lua
local work = thread:newFunction(function(n)
    thread.sleep(math.random())
    return n * n
end)

multi:newThread("Fan", function()
    local a, b, c = work(2), work(3), work(5)
    thread.hold(a.OnReturn + b.OnReturn + c.OnReturn)
    print(a.getReturns(), b.getReturns(), c.getReturns())   -- 4 9 25
end)
```

Collect with status streaming for progress bars — see [TFunc progress example](threading-api.md#progress-reporting-example).

---

## Cross-Thread Producer/Consumer

```lua
GLOBAL, THREAD = require("multi.integration.threading"):init()
local q = multi:newSystemThreadedQueue("work"):init()

for i = 1, 100 do q:push({ file = "level_" .. i .. ".dat" }) end

for w = 1, 4 do
    multi:newSystemThread("Worker" .. w, function()
        local q = THREAD.waitFor("work"):init()
        local job = q:pop()
        while job do
            compile(job.file)                    -- real OS parallelism
            job = q:pop()
        end
    end)
end

multi:newEvent(function() return not q:peek() end)
     :OnEvent(function() print("all compiled") os.exit() end)

multi:mainloop()
```

For fixed function-shaped work prefer the [job queue](integrations.md#systemthreadedjobqueue) — it handles pooling, ids, and result marshalling.

---

## Performance & Tuning

- **Yield granularity.** `newLoop` actors run every pass; give heavy ones `setPriority("low")` (with the priority runner) or wrap them as `newUpdater(skip)`.
- **Poll cheap.** `thread.hold(cond, {interval=0.05})` avoids running the condition every pass.
- **Processor caps.** `MaxObjects`/`MaxThreads` turn runaway spawning into a status string in `proc.Status` instead of a death spiral.
- **Boosting.** `proc:boost(n)` amortizes per-pass overhead when a detached processor has many cheap threads.
- **Clock.** `multi.setClock(chronos.nanotime)` gives sub-microsecond timers for hold/interval logic.
- **Load metering.** `multi:getLoad()` returns an estimated 0–100 load percentage (benchmarks against a learned `maxSpd`).
- **notime loops.** `multi:newLoop(f, true)` skips elapsed-time math on hot loops.

### findopt

`init{findopt=true}` swaps in an instrumented `thread.hold` that detects the anti-pattern of rebuilding an anonymous closure for every poll:

```lua
-- BAD: new closure each call; findopt flags it
while true do thread.hold(function() return flag end) end

-- GOOD: hoist it
local check = function() return flag end
while true do thread.hold(check) end
```

Hints land on `multi.optConn` and in `multi:getOptimizationStats()`.

---

## Gotchas & Pitfalls

| Area | Trap | Guidance |
|---|---|---|
| Runner | System thread results only arrive while a runner is active | Keep `mainloop`/`uManager` alive; `OnDeath` is polled, not pushed |
| Runner | `mainloop()` while already running | returns `nil, "Already Running!"` — don't nest |
| Threads | Never-yielding thread body freezes every other task | sprinkle `thread.yield()`/`sleep`; OS parallelism needs system threads |
| Threads | `th:Kill()`/`Pause()` are *requests* honored at the next yield | design loop bodies with control points |
| Threads | `thread.hold` treats a falsy first return as "not ready" | return `multi.NIL` to pass a real nil (holds only!) |
| Connections | `conditional` (2nd ctor arg) both guards Fires and is the immediate-callback slot in sugar paths | prefer explicit `:Connect` when using guards |
| Connections | `:Fire` on a locked connection silently no-ops | pair `Lock`/`Unlock` in `pcall` when in doubt |
| Connections | destroying a connection you don't own | operator results are owned by the creator; `Destroy` cascades |
| Operators | `a * b` AND-gate counts chained operands; args come from the *last* firing | combine with `+` if you need all args |
| System threads | Upvalues don't cross Lua states | pass args, use `GLOBAL`, or `THREAD.setENV` |
| System threads | locals in LÖVE thread bodies | keep referenced helpers global (README advice) |
| Priority | `setPriority` does nothing unless the priority runner is active | `init{priority=true}` or processor `Priority` |
| Priority | `newEvent` calls `setPriority("core")` on the creator, which no-ops on processors | the event keeps default priority; set it explicitly if needed |
| Processors | Detached processor forgotten → never runs | drive `proc.run()` or use `Attach=true` |
| Steps | `skip` semantics: `spos` cycles `0..skip-1` | `skip=1` fires every pass (counter resets at ≥1) — verify empirically for your build |
| scheduleJob | no cancellation API | guard the callback with your own flag |
| debugManager | destruction hooks may not attach on processors (misspelled local in this build) | prefer `multi.OnObjectDestroyed` directly |
| networkManager | WIP, API will change | do not depend on it |
