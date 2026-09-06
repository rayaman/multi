# multi — Lua Cooperative Multitasking Library
### Version 16.3.0 · MIT License · by Ryan Ward

---

## Table of Contents

1. [Overview](#overview)
2. [Core Concepts](#core-concepts)
3. [Getting Started](#getting-started)
4. [The Main Loop](#the-main-loop)
5. [Task Types (Actors)](#task-types-actors)
   - [newLoop](#newloop)
   - [newTLoop](#newtloop)
   - [newAlarm](#newalarm)
   - [newStep](#newstep)
   - [newTStep](#newtstep)
   - [newEvent](#newevent)
   - [newUpdater](#newupdater)
   - [newTimer](#newtimer)
   - [newTimeout](#newtimeout)
6. [Threads](#threads)
   - [thread.newThread](#threadnewthread)
   - [thread.sleep / thread.hold](#threadsleep--threadhold)
   - [thread.yield / thread.skip](#threadyield--threadskip)
   - [thread.holdFor / thread.holdWithin](#threadholdfor--threadholdwithin)
   - [thread.newISOThread](#threadnewisothreads)
   - [thread.newFunction](#threadnewfunction)
7. [Connections (Events)](#connections-events)
   - [newConnection](#newconnection)
   - [Fire / Connect / Unconnect](#fire--connect--unconnect)
   - [Connection Operators](#connection-operators)
   - [Destroying Connections](#destroying-connections)
8. [Processors](#processors)
   - [newProcessor](#newprocessor)
   - [Processor Options](#processor-options)
   - [Running a Processor](#running-a-processor)
9. [Priority System](#priority-system)
10. [Services](#services)
11. [Tasks (Deferred Work)](#tasks-deferred-work)
12. [Scheduled Jobs](#scheduled-jobs)
13. [Global Variables & Thread Communication](#global-variables--thread-communication)
14. [Type System](#type-system)
15. [Utility Functions](#utility-functions)
16. [Settings & Initialization](#settings--initialization)
17. [System Events](#system-events)
18. [UUID Utilities](#uuid-utilities)
19. [Advanced Patterns](#advanced-patterns)
20. [Quick Reference Card](#quick-reference-card)

---

## Overview

`multi` is a cooperative multitasking library for Lua. It provides a structured event loop, coroutine-based threads, typed connections (event emitters), and a rich set of timer and scheduling primitives — all without requiring OS threads or external dependencies.

The library is built around a single shared **main loop** that drives every actor (loop, alarm, step, thread, etc.) in turn. Because Lua is single-threaded, all concurrency is *cooperative*: tasks must yield control to let other tasks run.

**Key design principles:**

- All objects share a common interface (Pause, Resume, Destroy, setPriority, etc.).
- Connections decouple event producers from consumers.
- Threads are coroutines managed by the scheduler; `thread.sleep` and `thread.hold` yield without blocking the loop.
- Processors are isolated sub-schedulers that can be run inside threads or independently.

---

## Core Concepts

| Concept | Description |
|---|---|
| **Actor** | Any object placed in the main loop that has an `Act()` method (loop, alarm, step, etc.). |
| **Connection** | An event channel. Producers call `:Fire(...)`, consumers call `:Connect(func)`. |
| **Thread** | A coroutine managed by the scheduler. Uses `thread.sleep` / `thread.hold` to yield. |
| **Processor** | An isolated scheduler with its own actor list and thread pool. |
| **Priority** | A numeric weight controlling how often an actor is executed in priority-mode mainloops. |
| **Task** | A one-shot deferred function queued via `:newTask(func)`. |

---

## Getting Started

```lua
local multi, thread = require("multi"):init()

-- Create a loop that fires every iteration
multi:newLoop(function(self, elapsed)
    print("Elapsed:", elapsed)
end)

-- Create a timed loop that fires every 1 second
multi:newTLoop(function(self, ticks)
    print("Tick:", ticks)
end, 1)

-- Start the scheduler (blocks until multi.Stop() is called)
multi:mainloop()
```

### Initializing with Settings

```lua
local multi, thread = require("multi"):init({
    print      = true,    -- enable multi.print() output
    warn       = true,    -- enable multi.warn() output
    debugging  = false,   -- enable multi.debug() output + debug manager
    error      = false,   -- if true, hard-errors on runtime errors
    priority   = false,   -- enable priority-based scheduling
    findopt    = false,   -- enable optimization hints
})
```

`init()` returns `multi` and `thread` — always destructure both.

---

## The Main Loop

The main loop drives every actor. There are two variants:

### `multi:mainloop()`

Standard round-robin scheduler. Every actor is visited once per loop iteration in reverse insertion order.

```lua
multi:mainloop()
```

### `multi:p_mainloop()`

Priority-based scheduler. Actors with higher priority are executed more frequently. Enable it via `init({ priority = true })`.

### `multi:uManager(dt?)`

Runs a **single pass** of the loop manually. Useful when embedding `multi` inside another game loop or framework.

```lua
-- Inside LÖVE2D update callback:
function love.update(dt)
    multi:uManager(dt)
end
```

### `multi.Stop()`

Stops the main loop.

```lua
multi.Stop()
```

---

## Task Types (Actors)

All actors are created on `multi` or on a **processor**. Every actor shares these common methods:

| Method | Description |
|---|---|
| `:Pause()` | Suspends the actor (its `Act()` is replaced with a no-op). |
| `:Resume()` | Resumes a paused actor. |
| `:Destroy()` | Removes the actor from the loop permanently. |
| `:setPriority(s)` | Sets the priority. Accepts string or number (see [Priority System](#priority-system)). |
| `:setName(name)` | Sets a human-readable name. |
| `:isPaused()` | Returns `true` if the actor is paused. |
| `:isActive()` | Returns `true` if the actor is active. |

---

### newLoop

A loop that fires **every scheduler iteration**.

```lua
local loop = multi:newLoop(func?, notime?)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `func` | function | nil | Connected to `OnLoop` immediately |
| `notime` | boolean | false | If `true`, `elapsed` is always `nil` |

**Callback signature:** `function(self, elapsed, dt)`

- `self` — the loop object
- `elapsed` — seconds since the loop was created (or `nil` if `notime = true`)
- `dt` — delta time passed from the scheduler

**Connections:**

| Connection | Fires When |
|---|---|
| `OnLoop` | Every scheduler iteration |

```lua
local loop = multi:newLoop(function(self, elapsed, dt)
    if elapsed > 5 then
        print("5 seconds have passed!")
        self:Destroy()
    end
end)
```

---

### newTLoop

A **timed loop** that fires at a fixed interval.

```lua
local tloop = multi:newTLoop(func?, interval?)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `func` | function | nil | Connected to `OnLoop` immediately |
| `interval` | number | 0 | Seconds between firings |

**Callback signature:** `function(self, ticks, dt)`

- `ticks` — total number of times `OnLoop` has fired

**Methods:**

| Method | Description |
|---|---|
| `:Set(n)` | Change the interval |
| `:Pause()` | Pauses and freezes the internal timer |
| `:Resume()` | Resumes and unfreezes the internal timer |

```lua
-- Fire every 2 seconds
multi:newTLoop(function(self, ticks)
    print("Tick #" .. ticks)
    if ticks >= 10 then self:Destroy() end
end, 2)
```

---

### newAlarm

A **one-shot timer** that fires after a delay and then pauses itself.

```lua
local alarm = multi:newAlarm(seconds?, func?)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `seconds` | number | 0 | Delay in seconds |
| `func` | function | nil | Connected to `OnRing` immediately |

**Connections:**

| Connection | Fires When |
|---|---|
| `OnRing` | When the alarm expires |

**Callback signature:** `function(self, dt)`

**Methods:**

| Method | Description |
|---|---|
| `:Reset(n?)` | Restarts the alarm; optionally sets a new duration |
| `:Pause()` | Pauses (freezes remaining time) |
| `:Resume()` | Resumes from where it was paused |

```lua
multi:newAlarm(3, function(self)
    print("3 seconds elapsed!")
    self:Reset(3)  -- reset for another 3 seconds
end)
```

---

### newStep

A **counter** that steps through a range of values.

```lua
local step = multi:newStep(start?, reset?, count?, skip?)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `start` | number | 1 | Starting value |
| `reset` | number | math.huge | Ending value (inclusive) |
| `count` | number | 1 | Increment per step |
| `skip` | number | 0 | Number of loop iterations to skip between steps |

**Connections:**

| Connection | Fires When |
|---|---|
| `OnStart` | When the step position is at `start` |
| `OnStep` | Every step; receives `(self, position, dt)` |
| `OnEnd` | When `position` reaches `reset` |

**Methods:**

| Method | Description |
|---|---|
| `:Update(start, reset, count, skip)` | Update parameters and resume |
| `:Count(n)` | Change the step increment |
| `:Break()` | Hard-stop (sets `Active = nil`) |

```lua
multi:newStep(1, 5, 1):OnStep(function(self, pos, dt)
    print("Step:", pos)
end)
```

---

### newTStep

A **timed step** — same as `newStep` but advances on a time interval rather than every loop iteration.

```lua
local tstep = multi:newTStep(start?, reset?, count?, interval?)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `interval` | number | 1 | Seconds between steps |

**Methods:** Same as `newStep`, plus:

| Method | Description |
|---|---|
| `:Set(n)` | Change the interval |
| `:Reset(n?)` | Restart and optionally update interval |

```lua
-- Count from 1 to 10, one step per second
multi:newTStep(1, 10, 1, 1):OnStep(function(self, pos)
    print("Position:", pos)
end)
```

---

### newEvent

An actor that polls a function and fires when it returns a truthy value.

```lua
local event = multi:newEvent(task?, func?)
```

| Parameter | Type | Description |
|---|---|---|
| `task` | function | Polled every iteration; should return a value when "done" |
| `func` | function | Connected to `OnEvent` immediately |

**Connections:**

| Connection | Fires When |
|---|---|
| `OnEvent` | When `task()` returns a truthy value |

**Callback signature:** `function(self, dt)`  
The return value of `task()` is stored in `self.returns`.

**Methods:**

| Method | Description |
|---|---|
| `:SetTask(func)` | Replace the polling function |

```lua
local flag = false

multi:newEvent(function() return flag end, function(self)
    print("Flag was set!")
end)

-- Somewhere else in the code:
flag = true
```

---

### newUpdater

An actor that fires on every N-th loop iteration (frame skip).

```lua
local updater = multi:newUpdater(skip?, func?)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `skip` | number | 1 | Fire every `skip` iterations |
| `func` | function | nil | Connected to `OnUpdate` |

**Connections:**

| Connection | Fires When |
|---|---|
| `OnUpdate` | Every `skip` iterations |

**Methods:**

| Method | Description |
|---|---|
| `:SetSkip(n)` | Change the skip interval |

```lua
-- Fire every 10 iterations
multi:newUpdater(10, function(self, dt)
    print("Every 10 ticks")
end)
```

---

### newTimer

A **utility timer** object (not an actor — does not run in the main loop).

```lua
local timer = multi:newTimer()
```

**Methods:**

| Method | Returns | Description |
|---|---|---|
| `:Start()` | self | Start (or restart) the timer |
| `:Get()` | number | Elapsed seconds |
| `:Pause()` | self | Freeze elapsed time |
| `:Resume()` | self | Continue from frozen time |
| `:isPaused()` | bool | Whether the timer is paused |

`:Reset()` is an alias for `:Start()`.

```lua
local t = multi:newTimer()
t:Start()

multi:newLoop(function()
    if t:Get() > 5 then
        print("5 seconds passed")
        t:Stop()
    end
end)
```

---

### newTimeout

Creates a one-shot connection that fires after a delay, then destroys the receiving object.

```lua
local timeout = multi:newTimeout(seconds)
```

Returns a connection-modifier function. Used in combination with connection chaining.

```lua
-- This pattern pauses self after 5 seconds
multi:newTimeout(5)(function(self)
    print("Timed out!")
end)
```

---

## Threads

Threads are coroutines managed by the scheduler. They are created with `thread:newThread` and run cooperatively alongside all other actors.

### thread.newThread

```lua
local th = thread:newThread(name?, func, ...)
```

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Optional display name |
| `func` | function | The coroutine body |
| `...` | any | Arguments passed to `func` on first resume |

**Connections on the returned thread:**

| Connection | Fires When |
|---|---|
| `OnDeath` | Thread function returns normally; receives return values |
| `OnError` | Thread function throws an error; receives `(self, errorMsg)` |

**Methods:**

| Method | Description |
|---|---|
| `:Pause()` | Pause the thread at its next yield point |
| `:Resume()` | Resume a paused thread |
| `:Kill()` | Kill the thread at its next yield point |
| `:Sleep(n)` | Request the thread sleep for `n` seconds at next yield |
| `:Hold(func, opt?)` | Request the thread hold until `func` returns true |
| `:getName()` | Returns the thread's name |
| `:isPaused()` | Returns `true` if paused |

```lua
thread:newThread("MyThread", function(a, b)
    print("Got:", a, b)
    thread.sleep(1)
    print("1 second later")
    return "done"
end, "hello", "world"):OnDeath(function(result)
    print("Result:", result)  -- "done"
end)
```

---

### thread.sleep / thread.hold

These are the primary yield mechanisms **inside** threads.

#### `thread.sleep(seconds)`

Yields the thread for a fixed duration.

```lua
thread:newThread("Waiter", function()
    print("Before sleep")
    thread.sleep(2)
    print("After 2 seconds")
end)
```

#### `thread.hold(condition, opts?)`

Yields until a condition is true. The condition is polled every scheduler pass.

```lua
-- Hold until a flag is set
local ready = false
thread:newThread("Holder", function()
    thread.hold(function() return ready end)
    print("Ready!")
end)

-- Hold until a connection fires
local conn = multi:newConnection()
thread:newThread("ConnHolder", function()
    local value = thread.hold(conn)
    print("Connection fired with:", value)
end)

-- Hold with a numeric timeout
thread:newThread("WithTimeout", function()
    local result, timeout = thread.hold(function()
        return someCondition()
    end, { sleep = 5 })
    if multi.isTimeout(timeout) then
        print("Timed out!")
    end
end)
```

**`opts` table fields:**

| Field | Description |
|---|---|
| `sleep` | Max seconds to wait before returning `nil, TIMEOUT` |
| `cycles` | Max loop iterations to wait before returning `nil, TIMEOUT` |
| `skip` | Skip N iterations between condition checks |
| `interval` | Minimum seconds between condition checks |

---

### thread.yield / thread.skip

#### `thread.yield()`

Yields for exactly one scheduler pass (minimum possible pause).

```lua
thread:newThread("Yielder", function()
    for i = 1, 1000 do
        doSomeWork(i)
        thread.yield()  -- give other threads a turn each iteration
    end
end)
```

#### `thread.skip(n)`

Yields for exactly `n` scheduler passes.

```lua
thread.skip(5)  -- pause for 5 iterations
```

---

### thread.holdFor / thread.holdWithin

#### `thread.holdFor(seconds, condition?)`

Hold for up to `seconds` seconds, optionally with a condition function.

```lua
thread.holdFor(3, function() return isReady() end)
```

#### `thread.holdWithin(cycles, condition?)`

Hold for up to `cycles` iterations with an optional condition.

```lua
thread.holdWithin(100, function() return isReady() end)
```

---

### thread.newISOThread

Creates an **isolated thread** with its own environment (useful for sandboxing).

```lua
local th = thread:newISOThread(name?, func, env?, ...)
```

| Parameter | Type | Description |
|---|---|---|
| `env` | table | The environment table. `thread` and `multi` are injected unless already present. |

```lua
thread:newISOThread("Isolated", function()
    thread.sleep(1)
    print("This runs in isolation")
end, { print = print })
```

---

### thread.newFunction

Wraps a function as a **threaded callable** — calling it spawns a thread and optionally waits for its result.

```lua
local tfunc = thread:newFunction(func, holdme?)
```

| Parameter | Type | Description |
|---|---|---|
| `func` | function | The function body |
| `holdme` | boolean | If `true`, calling the TFunc blocks until it returns |

**Returns a TFunc object.** Calling the TFunc spawns a thread and returns a handle.

**Handle methods:**

| Method | Description |
|---|---|
| `:wait()` | Block (or hold in a thread) until the function returns |
| `:connect(func)` | Call `func` with the return values when done |
| `.OnReturn` | Connection that fires when done |
| `.OnError` | Connection that fires on error |
| `.OnStatus` | Connection for `thread.pushStatus(...)` values |

```lua
local fetchData = thread:newFunction(function(url)
    thread.sleep(1)  -- simulate async work
    return "data from " .. url
end)

-- Non-blocking call:
local handle = fetchData("http://example.com")
handle:connect(function(result)
    print(result)
end)

-- Blocking call (holdme = true):
local fetchSync = thread:newFunction(function(url)
    thread.sleep(1)
    return "sync data"
end, true)

thread:newThread("caller", function()
    local result = fetchSync("http://example.com")
    print(result)
end)
```

---

## Connections (Events)

Connections are the event system of `multi`. They decouple event producers from consumers.

### newConnection

```lua
local conn = obj:newConnection(protect?, func?, kill?)
```

| Parameter | Type | Description |
|---|---|---|
| `protect` | boolean | If `true`, each callback is wrapped in `pcall` |
| `func` | function | Immediately connected callback |
| `kill` | boolean | If `true`, callbacks are removed after first call (one-shot) |

---

### Fire / Connect / Unconnect

#### `:Fire(...)`

Broadcasts values to all connected callbacks.

```lua
local onClick = multi:newConnection()
onClick:Fire("button1", 42)
```

#### `:Connect(func, name?)`

Subscribes a function. Returns a **connection handle**.

```lua
local handle = onClick:Connect(function(button, value)
    print(button, value)
end)
```

Connections can also be subscribed by calling the connection object directly:

```lua
onClick(function(button, value)
    print(button, value)
end)
```

**Connection handle methods:**

| Method | Description |
|---|---|
| `:Unconnect()` | Remove this specific subscription |

#### `:Unconnect(handle)`

Remove a subscription using its handle.

```lua
local handle = conn:Connect(myFunc)
-- later:
conn:Unconnect(handle)
```

#### `:hasConnections()`

Returns `true` if there is at least one subscriber.

#### `:Lock(conn?)` / `:Unlock(conn?)`

Lock/unlock the connection globally (blocking all fires) or per individual subscription handle.

```lua
conn:Lock()    -- block all subscribers
conn:Unlock()  -- unblock
```

---

### Connection Operators

Connections support operator overloads for composing event pipelines.

#### `+` — OR (merge two connections)

```lua
local merged = connA + connB
-- fires whenever either connA or connB fires
merged(function(...) print("Either fired", ...) end)
```

#### `*` — AND (requires all to fire)

```lua
local both = connA * connB
-- fires only after both connA AND connB have fired (then resets)
both(function(...) print("Both fired") end)
```

#### `%` — Map (transform values)

```lua
local mapped = transform_func % sourceConn
-- fires with transform_func applied to each emission
mapped(function(result) print(result) end)
```

#### `/` — Filter (conditional forward)

```lua
local filtered = filter_func / sourceConn
-- fires only when filter_func returns truthy (first return value is the guard)
filtered(function(...) print("Passed filter", ...) end)
```

#### `..` — Gate / Split

```lua
-- Gate: filter_func .. targetConn
-- Forwards to targetConn only when filter_func returns true
local gated = filter_func .. targetConn

-- Split: sourceConn .. sideEffect_func
-- Fires both sourceConn and sideEffect_func; returns modified conn
local split = sourceConn .. sideEffect_func
```

#### `forwardConnection`

Forwards all emissions from one connection to another:

```lua
multi.forwardConnection(source, destination)
```

---

### Destroying Connections

```lua
conn:Destroy()
-- or
conn:destroy()
```

This:
- Removes all subscriptions
- Recursively destroys all child connections created by operators
- Nulls back-references
- Replaces methods with no-ops to prevent stale calls

---

## Processors

A processor is an isolated scheduler with its own actor list and thread pool.

### newProcessor

```lua
local proc = multi:newProcessor(name?, opts?, priority?)
```

**Simple form:**
```lua
local proc = multi:newProcessor("MyProc")
proc:Start()
```

**With options table:**
```lua
local proc = multi:newProcessor("MyProc", {
    Start      = false,       -- start immediately?
    Priority   = nil,         -- enable priority scheduling?
    MaxThreads = -1,          -- max concurrent threads (-1 = unlimited)
    MaxObjects = -1,          -- max actors (-1 = unlimited)
    TaskDelay  = 0,           -- delay between task handler executions
    Attach     = false,       -- attach as a loop to parent (auto-driven)
    TaskHandler = true,       -- create the built-in task handler thread
})
```

---

### Processor Options

| Option | Type | Default | Description |
|---|---|---|---|
| `Start` | boolean | false | Whether to start the processor immediately |
| `Priority` | boolean | nil | Enable priority scheduling for this processor |
| `MaxThreads` | number | -1 | Thread cap (-1 = unlimited) |
| `MaxObjects` | number | -1 | Actor cap (-1 = unlimited) |
| `TaskDelay` | number/function | 0 | Delay between deferred task executions |
| `Attach` | boolean | false | If true, drives itself as a loop inside the parent |
| `TaskHandler` | boolean | true | Whether to spawn the built-in task handler thread |

---

### Running a Processor

If `Attach = false`, you must drive the processor manually by calling `proc.run(dt?)` each frame, or inside a thread:

```lua
local proc = multi:newProcessor("Worker")
proc:Start()

thread:newThread("ProcDriver", function()
    while true do
        proc.run()
        thread.yield()
    end
end)
```

If `Attach = true (default)`, a `newLoop` is created on the parent and drives the processor automatically.

```lua
local proc = multi:newProcessor("AutoProc", { Attach = true, Start = true })
-- No extra thread needed; proc runs as part of the parent loop
```

**Key methods on a processor:**

| Method | Description |
|---|---|
| `proc:Start()` | Activate the processor |
| `proc:Stop()` | Deactivate (still exists, just stops ticking) |
| `proc:Destroy()` | Destroy the processor and its attached loop |
| `proc:newThread(name, func, ...)` | Spawn a thread inside this processor |
| `proc:newFunction(func, holdme?)` | Create a TFunc inside this processor |
| `proc:getThreads()` | Returns the thread list |
| `proc:getHandler()` | Returns the internal coroutine handler |
| `proc:setMaxThreads(n)` | Change the thread cap at runtime |
| `proc:setMaxObjects(n)` | Change the object cap at runtime |
| `proc:boost(n)` | Run `n` handler passes per `run()` call |
| `proc:setTaskDelay(n)` | Change the task delay at runtime |
| `proc:isActive()` | Returns `true` if active |
| `proc:getFullName()` | Returns `"parent.procName"` |

**Creating actors inside a processor:**

All standard constructors work on processors:

```lua
proc:newLoop(func)
proc:newTLoop(func, interval)
proc:newAlarm(seconds, func)
-- etc.
```

---

## Priority System

Priorities control how frequently an actor is run when `priority = true` is set in `init()` or on a processor.

### Priority Constants

| Constant | Value | Description |
|---|---|---|
| `multi.Priority_Core` | 1 | Runs every iteration (highest) |
| `multi.Priority_Very_High` | 4 | Runs every 4 iterations |
| `multi.Priority_High` | 16 | Runs every 16 iterations |
| `multi.Priority_Above_Normal` | 64 | Runs every 64 iterations |
| `multi.Priority_Normal` | 256 | Default |
| `multi.Priority_Below_Normal` | 1024 | |
| `multi.Priority_Low` | 4096 | |
| `multi.Priority_Very_Low` | 16384 | |
| `multi.Priority_Idle` | 65536 | Runs very rarely |

### Setting Priority

```lua
actor:setPriority("normal")        -- by name
actor:setPriority("high")
actor:setPriority("core")
actor:setPriority(multi.Priority_High)  -- by constant
```

**Accepted string shortcuts:**

`core` / `c`, `very high` / `vh`, `high` / `h`, `above` / `a`, `normal` / `n`, `below` / `b`, `low` / `l`, `very low` / `vl`, `idle` / `i`

### Resolving Priority

```lua
print(multi.PriorityResolve[multi.Priority_High])  -- "High"
```

### Resetting Priority

```lua
actor:ResetPriority()  -- restore to the value set at creation
```

---

## Services

A service is a priority-managed background thread designed for long-running tasks.

```lua
local svc = multi:newService(function(self, data)
    -- runs continuously while active
    print("Service running, data:", data)
end)

svc.Start()
```

**Methods:**

| Method | Description |
|---|---|
| `svc.Start()` | Start the service |
| `svc.Stop()` | Stop and clear service data |
| `svc.Pause()` | Pause (freeze timer) |
| `svc.Resume()` | Resume |
| `svc.Destroy()` | Kill thread and stop |
| `svc.GetUpTime()` | Seconds since start |
| `svc:SetPriority(n)` | Set scheduling priority |
| `svc:SetScheme(n)` | Change the sleep/skip scheme (1, 2, or 3) |

**Connections:**

| Connection | Fires When |
|---|---|
| `OnStarted` | Service is started |
| `OnStopped` | Service is stopped |
| `OnError` | Service thread errors |

**Schemes:**

| Scheme | Behavior |
|---|---|
| 1 (default) | Uses `thread.sleep` with priority-derived delay |
| 2 | Uses `thread.skip` with priority-derived skip count |
| 3 | Not yet implemented time based scheme which bases on how long each loop of the service takes

---

## Tasks (Deferred Work)

Tasks are one-shot functions queued for execution by the processor's **Task Handler** thread.

```lua
multi:newTask(function()
    print("I run asynchronously in the task queue")
end)
```

Or on a specific processor:

```lua
proc:newTask(function()
    print("Task on proc")
end)
```

Tasks run in FIFO order. The built-in task handler thread processes them one at a time.

**Configuring task delay:**

```lua
multi:setTaskDelay(0.1)  -- wait 0.1s between tasks
-- or a function:
multi:setTaskDelay(function() return someCondition() end)
```

---

## Scheduled Jobs

Schedule a function to run when a specific time matches. Uses `os.date` patterns.

```lua
multi:scheduleJob(timeTable, func)
```

`timeTable` is a table of `os.date("*t")` fields. The job fires whenever **all** specified fields match the current time.

```lua
-- Run at 14:30:00 every day
multi:scheduleJob({ hour = 14, min = 30, sec = 0 }, function()
    print("It's 2:30 PM!")
end)
```

The scheduler checks every second using an internal thread.

---

## Global Variables & Thread Communication

Threads can communicate via a shared global variables table.

```lua
thread.set("myKey", someValue)
local v = thread.get("myKey")
```

#### `thread.waitFor(name)`

Blocks the current thread until a global variable is set.

```lua
thread:newThread("Consumer", function()
    local value = thread.waitFor("resultReady")
    print("Got:", value)
end)

thread:newThread("Producer", function()
    thread.sleep(2)
    thread.set("resultReady", 42)
end)
```

#### `thread.pushStatus(...)`

Fire the `OnStatus` connection of the current thread (or the connection thread that triggered this call).

```lua
thread:newThread("StatusPusher", function()
    thread.sleep(1)
    thread.pushStatus("halfway done")
    thread.sleep(1)
    return "final result"
end):OnStatus(function(msg)
    print("Status:", msg)
end)
```

---

## Type System

`multi` uses a simple string-based type registry.

### Registering Types

```lua
local myType = multi.registerType("myObject", "myObjects")
-- Returns the type string "myObject"
-- multi.$MYOBJECT is set as a constant
```

### Checking Types

```lua
obj:isType(multi.registerType("loop"))   -- true if obj is a loop
multi.hasType("loop")                    -- returns the registered name or nil
multi.isMulitObj(obj)                    -- true if obj has a registered Type
```

### Built-in Types

| Type String | Access Constant |
|---|---|
| `"rootprocess"` | `multi.$ROOTPROCESS` |
| `"process"` | `multi.$PROCESS` |
| `"loop"` | `multi.$LOOP` |
| `"tloop"` | `multi.$TLOOP` |
| `"alarm"` | `multi.$ALARM` |
| `"step"` | `multi.$STEP` |
| `"tstep"` | `multi.$TSTEP` |
| `"event"` | `multi.$EVENT` |
| `"updater"` | `multi.$UPDATER` |
| `"timer"` | `multi.$TIMER` |
| `"thread"` | `multi.$THREAD` |
| `"connector"` | `multi.$CONNECTOR` |
| `"service"` | `multi.$SERVICE` |
| `"function"` | `multi.$FUNCTION` |
| `"timemaster"` | `multi.$TIMEMASTER` |

### Destroyed Objects

When an object is fully destroyed via `multi.setType(obj, multi.DestroyedObj)`, all field accesses return a dead sentinel object that silently absorbs all operations.

```lua
if getmetatable(obj) == multi.DestroyedObj then
    print("Object is destroyed")
end
```

---

## Utility Functions

### Logging

```lua
multi.print(...)    -- prints INFO (only if settings.print = true)
multi.warn(...)     -- prints WARNING (only if settings.warn = true)
multi.debug(...)    -- prints DEBUG with traceback (only if settings.debugging = true)
multi.error(self?, msg)  -- prints ERROR; hard-errors if settings.error = true
multi.success(...)  -- always prints SUCCESS
```

All use ANSI color codes.

### Math & Tables

```lua
multi.Round(num, decimalPlaces?)  -- round to N decimal places
multi.AlignTable(tab)             -- format a 2D table as aligned columns
table.merge(t1, t2)               -- deep-merge t2 into t1, returns t1
```

### Misc

```lua
multi.randomString(n)             -- returns a random alphanumeric string of length n
multi.ForEach(tab, func)          -- calls func(tab[i]) for each element
multi.timer(func, ...)            -- runs func(...), returns elapsed time and return values
multi.isTimeout(val)              -- true if val is a TIMEOUT sentinel
multi.isMulitObj(obj)             -- true if obj has a registered multi type
os.getOS()                        -- returns "windows" or "unix"
os.sleep(n)                       -- blocking OS sleep (avoid; prefer thread.sleep)
```

### Benchmarking

```lua
local bench = multi:benchMark(seconds, priority?, label?)
bench.OnBench(function(time, steps)
    print("Completed", steps, "iterations in", time, "seconds")
end)
```

### Getting Active Information

```lua
multi.getCurrentProcess()    -- returns the currently executing processor
multi.getCurrentTask()       -- returns the currently executing actor
multi:getChildren()          -- returns the Mainloop array of this processor
multi:getRunners()           -- returns non-internal actors in Mainloop
multi:getThreads()           -- returns the thread list
multi:getProcessors()        -- returns all registered sub-processors
multi:getStats()             -- returns a stats table for all processors
```

---

## Settings & Initialization

```lua
local multi, thread = require("multi"):init({
    print      = false,  -- enable multi.print()
    warn       = false,  -- enable multi.warn()
    debugging  = false,  -- enable multi.debug() and debugManager
    error      = false,  -- hard-error on runtime errors
    priority   = false,  -- priority-based scheduling
    findopt    = false,  -- anonymize function optimization hints
})
```

`init()` can be called multiple times but only applies settings on the first call. Subsequent calls just return `multi` and `thread`.

### Default Settings

```lua
multi.defaultSettings  -- table defining what the default settings are
```

---

## System Events

These connections are available on the `multi` root object and fire at specific lifecycle points.

| Connection | Fires When |
|---|---|
| `multi.OnObjectCreated` | Any actor is created via `:create()` |
| `multi.OnObjectDestroyed` | Any actor is destroyed |
| `multi.OnLoad` | Just before the main loop starts (or on first thread creation) |
| `multi.OnPreLoad` | Just before each `uManager` pass |
| `multi.OnExit` | When `os.exit()` is called |
| `multi.OnError` | Global error handler |
| `multi.enableOptimization` | When optimization mode is enabled |
| `multi.settingsHook` | When `init()` is called with settings |

```lua
multi.OnObjectCreated(function(obj, parent)
    print("Created:", obj.Type, "on", parent.Name)
end)

multi.OnExit(function(code)
    print("Exiting with code:", code)
end)
```

---

## UUID Utilities

`multi` includes a UUID v7 generator (timestamp-based).

```lua
local uuid = multi.generate_uuid7()
-- e.g. "018fdb62-1a00-7abc-8def-012345678901"
```

### Extracting Timestamps

```lua
local info = multi.extract_uuid7_timestamp(uuid)
-- info.milliseconds  -- Unix timestamp in ms
-- info.seconds       -- Unix timestamp in seconds
-- info.date          -- "YYYY-MM-DD HH:MM:SS"
-- info.iso8601       -- "YYYY-MM-DDTHH:MM:SS.mmmZ"
```

### Object Creation Timestamps

Every actor created via `:create()` receives a UID. The creation timestamp can be retrieved:

```lua
local ts = actor:GetCreationTimestamp()
-- returns an ISO 8601 string
```

---

## Advanced Patterns

### Chaining with SetTime / ResolveTimer

`SetTime` adds a timeout to any actor. If the actor doesn't call `ResolveTimer` within the specified duration, `OnTimedOut` fires and the actor is paused.

```lua
local myLoop = multi:newLoop(function(self, t)
    if someCondition() then
        self:ResolveTimer("success")
    end
end)

myLoop:SetTime(5)
myLoop.OnTimedOut(function(self)
    print("Timed out after 5 seconds!")
end)
myLoop.OnTimerResolved(function(self, reason)
    print("Resolved with:", reason)
end)
```

---

### Reallocating Actors Between Processors

An actor can be moved from one processor to another at runtime.

```lua
local proc1 = multi:newProcessor("P1"):Start()
local proc2 = multi:newProcessor("P2"):Start()

local loop = proc1:newLoop(function() print("running") end)

-- Move to proc2:
loop:reallocate(proc2)
```

---

### `multi.hold()` Outside Threads

`multi.hold()` can be called from outside a thread. It spins the main loop internally until the condition resolves.

```lua
-- Block main script execution until a connection fires:
local result = multi.hold(someConnection)
```

This is useful for top-level async patterns before `mainloop()` is started.

---

### thread.defer

Registers a function to run when the current thread dies or errors.

```lua
thread:newThread("WithCleanup", function()
    thread.defer(function(th)
        print("Thread died, cleaning up")
    end)
    -- do work ...
end)
```

---

### thread.chain

Runs a sequence of hold conditions one after another.

```lua
thread:newThread("Sequencer", function()
    thread.chain(
        function() return conditionA() end,
        connB,
        function() return conditionC() end
    )
    print("All three conditions satisfied in order")
end)
```

---

### Optimization Detection

When `findopt = true` is passed to `init()`, `multi` detects anonymous functions passed repeatedly to `thread.hold` and emits a warning.

```lua
multi.optConn(function(msg)
    print("OPT HINT:", msg)
end)
```

---

## Quick Reference Card

```
ACTORS (created on multi or processor)
  multi:newLoop(func?)              -- fires every iteration
  multi:newTLoop(func?, interval?)  -- fires every N seconds
  multi:newAlarm(secs?, func?)      -- one-shot after N seconds
  multi:newStep(s,e,c?,skip?)       -- counter s→e by c
  multi:newTStep(s,e,c?,interval?)  -- timed counter
  multi:newEvent(task?, func?)      -- fires when task() is truthy
  multi:newUpdater(skip?, func?)    -- fires every N iterations
  multi:newTimer()                  -- utility timer (not an actor)

ALL ACTORS SHARE
  :Pause()  :Resume()  :Destroy()
  :setPriority(s)  :setName(s)
  :isPaused()  :isActive()  :isDone()
  OnBreak  OnPriorityChanged

CONNECTIONS
  conn = obj:newConnection(protect?, func?, kill?)
  conn:Fire(...)           -- emit
  conn:Connect(func)       -- subscribe → handle
  conn(func)               -- shorthand Connect
  handle:Unconnect()       -- unsubscribe
  conn:Destroy()           -- teardown
  conn + conn2             -- OR merge
  conn * conn2             -- AND gate
  func % conn              -- map transform
  func / conn              -- filter
  func .. conn             -- gate/split

THREADS
  thread:newThread(name?, func, ...)
  thread:newFunction(func, holdme?)
  thread:newISOThread(name?, func, env?, ...)
  -- inside threads:
  thread.sleep(n)
  thread.hold(cond, opts?)
  thread.yield()
  thread.skip(n)
  thread.holdFor(secs, cond?)
  thread.holdWithin(cycles, cond?)
  thread.set(k,v) / thread.get(k) / thread.waitFor(k)
  thread.pushStatus(...)
  thread.isThread()

PROCESSORS
  proc = multi:newProcessor(name?, opts?)
  proc:Start() / proc:Stop() / proc:Destroy()
  proc.run(dt?)             -- manual tick
  proc:newThread(...)       -- spawn thread inside proc
  proc:setMaxThreads(n)
  proc:boost(n)

PRIORITIES
  "core"/"c"  "very high"/"vh"  "high"/"h"
  "above"/"a"  "normal"/"n"  "below"/"b"
  "low"/"l"  "very low"/"vl"  "idle"/"i"

UTILITIES
  multi.isTimeout(v)
  multi.Round(n, dec?)
  multi.randomString(n)
  multi.timer(func, ...)
  multi:benchMark(secs)
  multi.generate_uuid7()
  multi.extract_uuid7_timestamp(uuid)

LOGGING (controlled by init settings)
  multi.print(...)   -- INFO (blue)
  multi.warn(...)    -- WARNING (yellow)
  multi.debug(...)   -- DEBUG (white)
  multi.error(...)   -- ERROR (red)
  multi.success(...) -- SUCCESS (green)
```

---

*Documentation generated for multi v16.3.0-testing.*
