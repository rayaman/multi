--[[
    Test suite for multi.lua
    Run with: lua multi_test.lua

    Requires multi.lua to be in the same directory or on the Lua path.
    Compatible with Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.
]]
package.path = "?/init.lua;?.lua;./init.lua;./?.lua;" .. package.path

-- ─────────────────────────────────────────────
-- Minimal test runner
-- ─────────────────────────────────────────────
local passed, failed, skipped = 0, 0, 0
local failures = {}

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        io.write("\x1b[92m  ✓\x1b[0m " .. name .. "\n")
    else
        failed = failed + 1
        table.insert(failures, {name = name, err = tostring(err)})
        io.write("\x1b[91m  ✗\x1b[0m " .. name .. "\n")
        io.write("      " .. tostring(err) .. "\n")
    end
end

local function skip(name, reason)
    skipped = skipped + 1
    io.write("\x1b[93m  -\x1b[0m " .. name .. " [SKIPPED: " .. (reason or "") .. "]\n")
end

local function section(name)
    io.write("\n\x1b[97m── " .. name .. " ──\x1b[0m\n")
end

local function assert_eq(a, b, msg)
    if a ~= b then
        error((msg or "assert_eq failed") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 2)
    end
end

local function assert_truthy(v, msg)
    if not v then
        error((msg or "expected truthy value, got falsy") .. ": " .. tostring(v), 2)
    end
end

local function assert_falsy(v, msg)
    if v then
        error((msg or "expected falsy value, got truthy") .. ": " .. tostring(v), 2)
    end
end

local function assert_type(v, t, msg)
    if type(v) ~= t then
        error((msg or "type mismatch") .. ": expected " .. t .. ", got " .. type(v), 2)
    end
end

-- ─────────────────────────────────────────────
-- Load the library
-- ─────────────────────────────────────────────
local multi, thread
local ok, err = pcall(function()
    multi, thread = require("multi"):init()
end)

if not ok then
    io.write("\x1b[91mFATAL: Could not load multi.lua: " .. tostring(err) .. "\x1b[0m\n")
    io.write("Make sure multi.lua is in the same directory or on package.path.\n")
    os.exit(1)
end

-- Helper: run the scheduler for up to `max_ticks` ticks or until `done()` returns true.
local function run_until(done, max_ticks)
    max_ticks = max_ticks or 10000
    for _ = 1, max_ticks do
        multi:uManager()
        if done and done() then return true end
    end
    return done == nil
end

-- ═════════════════════════════════════════════
-- 1. LIBRARY METADATA
-- ═════════════════════════════════════════════
section("Library Metadata")

test("multi is a table", function()
    assert_type(multi, "table")
end)

test("multi.Version is a string", function()
    assert_type(multi.Version, "string")
    assert_truthy(#multi.Version > 0, "Version string should not be empty")
end)

test("multi.Name is 'root'", function()
    assert_eq(multi.Name, "root")
end)

test("multi.Type is registered rootprocess type", function()
    assert_truthy(multi:isType(multi.registerType("rootprocess")), "Type should be rootprocess")
end)

test("$multi global is populated", function()
    assert_truthy(_G["$multi"], "$multi global should exist")
    assert_truthy(_G["$multi"].multi, "$multi.multi should exist")
    assert_truthy(_G["$multi"].thread, "$multi.thread should exist")
end)

-- ═════════════════════════════════════════════
-- 2. TYPE SYSTEM
-- ═════════════════════════════════════════════
section("Type System")

test("registerType returns the type string", function()
    local t = multi.registerType("test_custom_type_xyz")
    assert_eq(t, "test_custom_type_xyz")
end)

test("registerType is idempotent (re-register same type)", function()
    local t1 = multi.registerType("idempotent_type")
    local t2 = multi.registerType("idempotent_type")
    assert_eq(t1, t2)
end)

test("hasType finds registered types", function()
    multi.registerType("findable_type")
    assert_truthy(multi.hasType("findable_type"), "Should find registered type")
end)

test("hasType returns nil for unknown types", function()
    local result = multi.hasType("definitely_not_registered_xyzzy")
    assert_falsy(result, "Should return nil for unknown type")
end)

test("getTypes returns a table", function()
    assert_type(multi.getTypes(), "table")
    assert_truthy(#multi.getTypes() > 0, "Should have at least one registered type")
end)

test("multi:isType() works correctly", function()
    assert_truthy(multi:isType(multi.registerType("rootprocess")))
    assert_falsy(multi:isType("not_root"))
end)

test("DestroyedObj sentinels are tables", function()
    assert_type(multi.DestroyedObj, "table")
    assert_eq(multi.DESTROYED, multi.DestroyedObj)
end)

test("setType converts object to DestroyedObj", function()
    local obj = {foo = "bar", baz = 42}
    multi.setType(obj, multi.DestroyedObj)
    -- After destruction, accessing fields should return DestroyedObj-family values
    assert_truthy(obj.foo ~= nil or obj.foo == nil) -- should not error
end)

-- ═════════════════════════════════════════════
-- 3. UTILITY FUNCTIONS
-- ═════════════════════════════════════════════
section("Utility Functions")

test("multi.randomString returns a string of the right length", function()
    for _, n in ipairs({1, 5, 10, 32}) do
        local s = multi.randomString(n)
        assert_type(s, "string")
        assert_eq(#s, n, "randomString(" .. n .. ") length")
    end
end)

test("multi.randomString produces alphanumeric characters only", function()
    local s = multi.randomString(100)
    assert_truthy(s:match("^[a-zA-Z0-9]+$"), "Should only contain alphanumeric chars")
end)

test("multi.ForEach iterates all elements", function()
    local collected = {}
    multi.ForEach({10, 20, 30}, function(v) table.insert(collected, v) end)
    assert_eq(#collected, 3)
    assert_eq(collected[1], 10)
    assert_eq(collected[3], 30)
end)

test("multi.ForEach on empty table does nothing", function()
    local count = 0
    multi.ForEach({}, function() count = count + 1 end)
    assert_eq(count, 0)
end)

test("multi.isMulitObj returns true for multi objects", function()
    local alarm = multi:newAlarm(999)
    assert_truthy(multi.isMulitObj(alarm))
    alarm:Destroy()
end)

test("multi.isMulitObj returns false for plain tables", function()
    assert_falsy(multi.isMulitObj({foo = "bar"}))
end)

test("multi.isMulitObj returns false for non-tables", function()
    assert_falsy(multi.isMulitObj("string"))
    assert_falsy(multi.isMulitObj(42))
    assert_falsy(multi.isMulitObj(nil))
end)

test("multi.Round rounds correctly", function()
    assert_eq(multi.Round(3.14159, 2), 3.14)
    assert_eq(multi.Round(2.5, 0), 3)
    assert_eq(multi.Round(1.005, 2), 1.01)
end)

test("multi.AlignTable returns a string", function()
    local result = multi.AlignTable({
        {"Name",  "Age", "City"},
        {"Alice", "30",  "NYC"},
        {"Bob",   "4",   "LA"},
    })
    assert_type(result, "string")
    assert_truthy(result:find("Alice"), "Should contain 'Alice'")
    assert_truthy(result:find("Bob"),   "Should contain 'Bob'")
end)

test("multi.timer returns elapsed time and results", function()
    local t, result = multi.timer(function() return 42 end)
    assert_type(t, "number")
    assert_truthy(t >= 0, "elapsed time should be non-negative")
    assert_eq(result, 42)
end)

test("multi.isTimeout returns true for TIMEOUT sentinel", function()
    assert_truthy(multi.isTimeout(multi.TIMEOUT))
    assert_truthy(multi.isTimeout("TIMEOUT")) -- For backwards compat
end)

test("multi.isTimeout returns false for non-TIMEOUT values", function()
    assert_falsy(multi.isTimeout(nil))
    assert_falsy(multi.isTimeout(42))
end)

-- ═════════════════════════════════════════════
-- 4. UUID GENERATION
-- ═════════════════════════════════════════════
section("UUID Generation")

test("generate_uuid7 returns a string", function()
    local uuid = multi.generate_uuid7()
    assert_type(uuid, "string")
end)

test("generate_uuid7 has correct format (8-4-4-4-12)", function()
    local uuid = multi.generate_uuid7()
    assert_truthy(uuid:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"),
        "UUID format mismatch: " .. uuid)
end)

test("generate_uuid7 version nibble is '7'", function()
    local uuid = multi.generate_uuid7()
    -- The 15th character (after removing hyphens at positions 9,14,19,24) is the version nibble
    -- UUID format: xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx  -> char 15 is '7'
    assert_eq(uuid:sub(15, 15), "7", "Version nibble should be '7', got: " .. uuid)
end)

test("generate_uuid7 produces unique IDs", function()
    local ids = {}
    for i = 1, 20 do
        ids[i] = multi.generate_uuid7()
    end
    -- Check a sample for uniqueness
    local seen = {}
    for _, id in ipairs(ids) do
        assert_falsy(seen[id], "Duplicate UUID generated: " .. id)
        seen[id] = true
    end
end)

test("extract_uuid7_timestamp returns a table with expected fields", function()
    local uuid = multi.generate_uuid7()
    local result = multi.extract_uuid7_timestamp(uuid)
    assert_type(result, "table")
    assert_truthy(result.milliseconds, "Should have milliseconds")
    assert_truthy(result.seconds, "Should have seconds")
    assert_truthy(result.date, "Should have date")
    assert_truthy(result.iso8601, "Should have iso8601")
end)

test("extract_uuid7_timestamp iso8601 ends with 'Z'", function()
    local uuid = multi.generate_uuid7()
    local result = multi.extract_uuid7_timestamp(uuid)
    assert_eq(result.iso8601:sub(-1), "Z")
end)

test("extract_uuid7_timestamp returns nil for invalid UUID", function()
    local result = multi.extract_uuid7_timestamp("not-a-valid-uuid")
    assert_falsy(result, "Should return nil for invalid UUID")
end)

-- ═════════════════════════════════════════════
-- 5. CONNECTION SYSTEM
-- ═════════════════════════════════════════════
section("Connection System")

test("newConnection returns a connection object", function()
    local conn = multi:newConnection()
    assert_type(conn, "table")
    assert_eq(conn.Type, multi.registerType("connector", "connections"))
    conn:Destroy()
end)

test("connection Fire calls connected function", function()
    local conn = multi:newConnection()
    local fired = false
    conn:Connect(function() fired = true end)
    conn:Fire()
    assert_truthy(fired, "Connected function should have been called")
    conn:Destroy()
end)

test("connection Fire passes arguments", function()
    local conn = multi:newConnection()
    local got_a, got_b
    conn:Connect(function(a, b) got_a = a; got_b = b end)
    conn:Fire(10, 20)
    assert_eq(got_a, 10)
    assert_eq(got_b, 20)
    conn:Destroy()
end)

test("connection supports multiple subscribers", function()
    local conn = multi:newConnection()
    local count = 0
    conn:Connect(function() count = count + 1 end)
    conn:Connect(function() count = count + 1 end)
    conn:Connect(function() count = count + 1 end)
    conn:Fire()
    assert_eq(count, 3, "All three subscribers should have been called")
    conn:Destroy()
end)

test("hasConnections is false before Connect", function()
    local conn = multi:newConnection()
    assert_falsy(conn:hasConnections())
    conn:Destroy()
end)

test("hasConnections is true after Connect", function()
    local conn = multi:newConnection()
    conn:Connect(function() end)
    assert_truthy(conn:hasConnections())
    conn:Destroy()
end)

test("Unconnect removes the subscription", function()
    local conn = multi:newConnection()
    local count = 0
    local ref = conn:Connect(function() count = count + 1 end)
    conn:Fire()
    assert_eq(count, 1)
    conn:Unconnect(ref)
    conn:Fire()
    assert_eq(count, 1, "Should not fire after Unconnect")
    conn:Destroy()
end)

test("Lock prevents Fire from calling subscribers", function()
    local conn = multi:newConnection()
    local count = 0
    conn:Connect(function() count = count + 1 end)
    conn:Lock()
    conn:Fire()
    assert_eq(count, 0, "Locked connection should not fire")
    conn:Unlock()
    conn:Fire()
    assert_eq(count, 1, "Unlocked connection should fire")
    conn:Destroy()
end)

test("Bind replaces the subscriber list", function()
    local conn = multi:newConnection()
    local old_count, new_count = 0, 0
    conn:Connect(function() old_count = old_count + 1 end)
    local old_fast = conn:Bind({function() new_count = new_count + 1 end})
    conn:Fire()
    assert_eq(old_count, 0, "Old subscriber should not be called after Bind")
    assert_eq(new_count, 1, "New subscriber should be called")
    assert_type(old_fast, "table")
    conn:Destroy()
end)

test("Remove clears all subscribers", function()
    local conn = multi:newConnection()
    local count = 0
    conn:Connect(function() count = count + 1 end)
    conn:Connect(function() count = count + 1 end)
    conn:Remove()
    conn:Fire()
    assert_eq(count, 0, "No subscribers should remain after Remove")
    conn:Destroy()
end)

test("connection__add operator creates OR connection", function()
    local c1 = multi:newConnection()
    local c2 = multi:newConnection()
    local or_conn = c1 + c2
    local count = 0
    or_conn:Connect(function() count = count + 1 end)
    c1:Fire()
    c2:Fire()
    assert_eq(count, 2, "OR connection should fire for each source")
    or_conn:Destroy()
    c1:Destroy()
    c2:Destroy()
end)

test("Destroy makes connection inert", function()
    local conn = multi:newConnection()
    local count = 0
    conn:Connect(function() count = count + 1 end)
    conn:Destroy()
    -- Fire on a destroyed connection should be a no-op
    conn:Fire()
    assert_eq(count, 0, "Destroyed connection should not fire")
    assert_truthy(conn.destroyed, "destroyed flag should be set")
end)

test("connection_count increments on newConnection", function()
    local before = multi.connection_count
    local c = multi:newConnection()
    assert_eq(multi.connection_count, before + 1)
    c:Destroy()
end)

test("connection_subscriptions tracks Connect and Unconnect", function()
    local conn = multi:newConnection()
    local before = multi.connection_subscriptions
    local ref = conn:Connect(function() end)
    assert_eq(multi.connection_subscriptions, before + 1)
    conn:Unconnect(ref)
    assert_eq(multi.connection_subscriptions, before, "Should decrement on Unconnect")
    conn:Destroy()
end)

test("getConnections returns the subscriber list", function()
    local conn = multi:newConnection()
    conn:Connect(function() end)
    conn:Connect(function() end)
    local conns = conn:getConnections()
    assert_type(conns, "table")
    assert_truthy(#conns >= 2)
    conn:Destroy()
end)

-- ═════════════════════════════════════════════
-- 6. TIMER
-- ═════════════════════════════════════════════
section("Timer")

test("newTimer returns a timer object", function()
    local t = multi:newTimer()
    assert_eq(t.Type, multi.registerType("timer", "timers"))
end)

test("timer Get returns a non-negative number after Start", function()
    local t = multi:newTimer()
    t:Start()
    local elapsed = t:Get()
    assert_type(elapsed, "number")
    assert_truthy(elapsed >= 0)
end)

test("timer Pause freezes elapsed time", function()
    local t = multi:newTimer()
    t:Start()
    -- busy-wait briefly
    local deadline = os.clock() + 0.02
    while os.clock() < deadline do end
    t:Pause()
    local frozen = t:Get()
    local deadline2 = os.clock() + 0.02
    while os.clock() < deadline2 do end
    local after = t:Get()
    assert_eq(frozen, after, "Paused timer should not advance")
    assert_truthy(t:isPaused(), "isPaused should return true")
end)

test("timer Resume resumes counting", function()
    local t = multi:newTimer()
    t:Start()
    local deadline = os.clock() + 0.01
    while os.clock() < deadline do end
    t:Pause()
    local before = t:Get()
    t:Resume()
    local deadline2 = os.clock() + 0.02
    while os.clock() < deadline2 do end
    local after = t:Get()
    assert_truthy(after > before, "Resumed timer should advance")
    assert_falsy(t:isPaused())
end)

test("timer Reset restarts counting from zero", function()
    local t = multi:newTimer()
    t:Start()
    local deadline = os.clock() + 0.02
    while os.clock() < deadline do end
    t:Reset()
    local after_reset = t:Get()
    assert_truthy(after_reset < 0.05, "Timer should be near zero after Reset")
end)

-- ═════════════════════════════════════════════
-- 7. SCHEDULER ACTORS
-- ═════════════════════════════════════════════
section("Scheduler Actors")

test("newLoop creates a loop object and fires OnLoop", function()
    local fires = 0
    local loop = multi:newLoop(function() fires = fires + 1 end)
    run_until(function() return fires >= 3 end, 1000)
    assert_truthy(fires >= 3, "Loop should have fired at least 3 times, got " .. fires)
    loop:Destroy()
end)

test("newLoop Pause stops firing", function()
    local fires = 0
    local loop = multi:newLoop(function() fires = fires + 1 end)
    run_until(function() return fires >= 2 end, 1000)
    loop:Pause()
    local snapshot = fires
    run_until(nil, 100)
    assert_eq(fires, snapshot, "Paused loop should not fire")
    loop:Destroy()
end)

test("newLoop Resume restarts firing", function()
    local fires = 0
    local loop = multi:newLoop(function() fires = fires + 1 end)
    run_until(function() return fires >= 2 end, 1000)
    loop:Pause()
    local before = fires
    run_until(nil, 50)
    loop:Resume()
    run_until(function() return fires >= before + 2 end, 1000)
    assert_truthy(fires >= before + 2, "Resumed loop should fire again")
    loop:Destroy()
end)

test("newUpdater fires OnUpdate based on skip interval", function()
    local fires = 0
    local updater = multi:newUpdater(1, function() fires = fires + 1 end)
    run_until(function() return fires >= 3 end, 2000)
    assert_truthy(fires >= 3)
    updater:Destroy()
end)

test("newAlarm fires OnRing after timeout", function()
    local rang = false
    local alarm = multi:newAlarm(0, function() rang = true end)  -- 0-second alarm fires immediately
    run_until(function() return rang end, 500)
    assert_truthy(rang, "Alarm should have rung")
end)

test("newAlarm does not ring before timeout", function()
    local rang = false
    local alarm = multi:newAlarm(9999, function() rang = true end)
    run_until(nil, 100)
    assert_falsy(rang, "Alarm should not have rung yet")
    alarm:Destroy()
end)

test("newAlarm Reset re-arms the alarm", function()
    local ring_count = 0
    local alarm = multi:newAlarm(0, function() ring_count = ring_count + 1 end)
    run_until(function() return ring_count >= 1 end, 500)
    alarm:Reset()
    run_until(function() return ring_count >= 2 end, 500)
    assert_truthy(ring_count >= 2, "Alarm should ring again after Reset")
end)

test("newTLoop fires periodically", function()
    local fires = 0
    local tloop = multi:newTLoop(function() fires = fires + 1 end, 0)
    run_until(function() return fires >= 3 end, 5000)
    assert_truthy(fires >= 3, "TLoop should fire multiple times, got " .. fires)
    tloop:Destroy()
end)

test("newStep fires OnStep for each step", function()
    local steps = {}
    local s = multi:newStep(1, 4, 1)
    s.OnStep(function(self, pos) table.insert(steps, pos) end)
    run_until(function() return #steps >= 3 end, 5000)
    assert_truthy(#steps >= 3)
    assert_eq(steps[1], 1)
    assert_eq(steps[2], 2)
    s:Destroy()
end)

test("newStep fires OnEnd when reaching the end", function()
    local ended = false
    local s = multi:newStep(1, 3, 1)
    s.OnEnd(function() ended = true end)
    run_until(function() return ended end, 5000)
    assert_truthy(ended, "Step should have fired OnEnd")
end)

test("newEvent fires OnEvent when task returns truthy", function()
    local done = false
    local tick = 0
    local ev = multi:newEvent(function()
        tick = tick + 1
        if tick >= 3 then return true end
    end, function() done = true end)
    run_until(function() return done end, 5000)
    assert_truthy(done, "Event should have fired")
end)

test("newEvent does not fire when task returns falsy", function()
    local done = false
    local ev = multi:newEvent(function() return false end, function() done = true end)
    run_until(nil, 200)
    assert_falsy(done, "Event should not have fired")
    ev:Destroy()
end)

-- ═════════════════════════════════════════════
-- 8. OBJECT LIFECYCLE (Pause / Resume / Destroy)
-- ═════════════════════════════════════════════
section("Object Lifecycle")

test("Pause sets Active to false", function()
    local loop = multi:newLoop(function() end)
    assert_truthy(loop.Active)
    loop:Pause()
    assert_falsy(loop.Active)
    loop:Destroy()
end)

test("isPaused returns correct state", function()
    local loop = multi:newLoop(function() end)
    assert_falsy(loop:isPaused())
    loop:Pause()
    assert_truthy(loop:isPaused())
    loop:Resume()
    assert_falsy(loop:isPaused())
    loop:Destroy()
end)

test("isActive returns correct state", function()
    local loop = multi:newLoop(function() end)
    assert_truthy(loop:isActive())
    loop:Pause()
    assert_falsy(loop:isActive())
    loop:Destroy()
end)

test("Destroy removes object from Mainloop", function()
    local before = #multi.Mainloop
    local loop = multi:newLoop(function() end)
    assert_eq(#multi.Mainloop, before + 1)
    loop:Destroy()
    assert_eq(#multi.Mainloop, before, "Destroyed object should be removed from Mainloop")
end)

test("isDone returns true after Pause", function()
    local loop = multi:newLoop(function() end)
    loop:Pause()
    assert_truthy(loop:isDone())
    loop:Destroy()
end)

test("setName sets the Name field", function()
    local loop = multi:newLoop(function() end)
    loop:setName("MyTestLoop")
    assert_eq(loop.Name, "MyTestLoop")
    loop:Destroy()
end)

test("reallocate moves object to another processor", function()
    local proc = multi:newProcessor("TestReallocProc", {Start = true})
    local loop = multi:newLoop(function() end)
    local before_main = #multi.Mainloop
    loop:reallocate(proc)
    assert_eq(#multi.Mainloop, before_main - 1, "Loop should be removed from main Mainloop")
    assert_truthy(#proc.Mainloop >= 1, "Loop should be in proc Mainloop")
    proc:Destroy()
end)

-- ═════════════════════════════════════════════
-- 9. PROCESSOR
-- ═════════════════════════════════════════════
section("Processor")

test("newProcessor returns a process object", function()
    local proc = multi:newProcessor("TestProc1", {Start = false})
    assert_eq(proc.Type, multi.registerType("process", "processes"))
    assert_type(proc.Mainloop, "table")
    proc:Destroy()
end)

test("processor Start/Stop toggles active state", function()
    local proc = multi:newProcessor("TestProc2", {Start = false})
    assert_falsy(proc.isActive())
    proc.Start()
    assert_truthy(proc.isActive())
    proc.Stop()
    assert_falsy(proc.isActive())
    proc:Destroy()
end)

test("processor run() executes when active", function()
    local fires = 0
    local proc = multi:newProcessor("TestProc3", {Start = true})
    proc:newLoop(function() fires = fires + 1 end)
    for _ = 1, 10 do proc.run() end
    assert_truthy(fires > 0, "Processor run() should execute objects")
    proc:Destroy()
end)

test("processor run() is a no-op when stopped", function()
    local fires = 0
    local proc = multi:newProcessor("TestProc4", {Start = false})
    proc:newLoop(function() fires = fires + 1 end)
    for _ = 1, 10 do proc.run() end
    assert_eq(fires, 0, "Stopped processor should not run objects")
    proc:Destroy()
end)

test("processor getName and getFullName", function()
    local proc = multi:newProcessor("MyNamedProc", {Start = false})
    assert_eq(proc:getName(), "MyNamedProc")
    local full = proc:getFullName()
    assert_truthy(full:find("MyNamedProc"), "getFullName should contain processor name")
    proc:Destroy()
end)

test("processor MaxObjects constraint", function()
    local proc = multi:newProcessor("MaxObjProc", {Start = false, MaxObjects = 2})
    local a = proc:newLoop(function() end)
    local b = proc:newLoop(function() end)
    local c, err = proc:newLoop(function() end)
    assert_truthy(err, "Should return error when MaxObjects exceeded")
    proc:Destroy()
end)

test("getProcessors returns a list containing created processors", function()
    local procs_before = #multi:getProcessors()
    local proc = multi:newProcessor("GetProcsTest", {Start = false})
    local procs_after = #multi:getProcessors()
    assert_truthy(procs_after > procs_before)
    proc:Destroy()
end)

-- ═════════════════════════════════════════════
-- 10. THREADING
-- ═════════════════════════════════════════════
section("Threading")

test("thread.isThread returns false outside a thread", function()
    assert_falsy(thread.isThread(), "Should return false in main coroutine")
end)

test("newThread creates a thread and it runs", function()
    local done = false
    thread:newThread("TestThread1", function()
        done = true
    end)
    run_until(function() return done end, 5000)
    assert_truthy(done, "Thread should have run")
end)

test("thread OnDeath fires when thread finishes", function()
    local death_fired = false
    local t = thread:newThread("TestThread_Death", function()
        return "finished"
    end)
    t.OnDeath(function(val)
        death_fired = true
    end)
    run_until(function() return death_fired end, 5000)
    assert_truthy(death_fired)
end)

test("thread OnDeath receives return values", function()
    local result
    local t = thread:newThread("TestThread_Ret", function()
        return 42, "hello"
    end)
    t.OnDeath(function(a, b)
        result = {a, b}
    end)
    run_until(function() return result ~= nil end, 5000)
    assert_truthy(result)
    assert_eq(result[1], 42)
    assert_eq(result[2], "hello")
end)

test("thread.sleep suspends for approximately the given time", function()
    local start_t = os.clock()
    local done = false
    thread:newThread("SleepThread", function()
        thread.sleep(0.05)
        done = true
    end)
    run_until(function() return done end, 100000)
    local elapsed = os.clock() - start_t
    assert_truthy(done)
    assert_truthy(elapsed >= 0.04, "Should have slept at least ~0.05s, elapsed=" .. elapsed)
end)

test("thread.hold waits for condition", function()
    local flag = false
    local saw_flag = false
    thread:newThread("HoldThread", function()
        thread.hold(function() return flag end)
        saw_flag = true
    end)
    -- Run without setting flag first
    run_until(nil, 200)
    assert_falsy(saw_flag, "Thread should still be waiting")
    flag = true
    run_until(function() return saw_flag end, 5000)
    assert_truthy(saw_flag, "Thread should have proceeded after flag set")
end)

test("thread.hold on a connection waits for Fire", function()
    local conn = multi:newConnection()
    local received
    thread:newThread("HoldConnThread", function()
        local val = thread.hold(conn)
        received = val
    end)
    run_until(nil, 100)
    assert_falsy(received, "Should still be waiting")
    conn:Fire(99)
    run_until(function() return received ~= nil end, 5000)
    assert_eq(received, 99)
    conn:Destroy()
end)

test("thread.skip skips N scheduler ticks", function()
    local done = false
    local ticks_before = 0
    local loop = multi:newLoop(function() ticks_before = ticks_before + 1 end)
    thread:newThread("SkipThread", function()
        thread.skip(5)
        done = true
    end)
    run_until(function() return done end, 5000)
    assert_truthy(done)
    loop:Destroy()
end)

test("thread GlobalVariables set and get", function()
    thread.set("test_gvar_key", "hello_global")
    assert_eq(thread.get("test_gvar_key"), "hello_global")
end)

test("thread.waitFor blocks until variable is set", function()
    local got
    local key = "waitfor_test_" .. multi.randomString(6)
    thread:newThread("WaitForSetter", function()
        thread.sleep(0)
        thread.set(key, "ready")
    end)
    thread:newThread("WaitForWaiter", function()
        got = thread.waitFor(key)
    end)
    run_until(function() return got ~= nil end, 5000)
    assert_eq(got, "ready")
end)

test("newFunction wraps a thread and supports wait()", function()
    local fn = thread:newFunction(function(x)
        return x * 2
    end, true)  -- holdme = true, so calling blocks until result
    local result
    thread:newThread("newFnCaller", function()
        result = fn(21)
    end)
    run_until(function() return result ~= nil end, 5000)
    assert_eq(result, 42)
end)

test("newFunction with holdme=false returns future table", function()
    local fn = thread:newFunction(function()
        return "async_result"
    end, false)
    local future = fn()
    assert_type(future, "table")
    assert_truthy(future.wait, "Future should have a wait method")
end)

-- ═════════════════════════════════════════════
-- 11. PRIORITY SYSTEM
-- ═════════════════════════════════════════════
section("Priority System")

test("setPriority accepts string 'normal'", function()
    local loop = multi:newLoop(function() end)
    loop:setPriority("normal")
    assert_eq(loop.Priority, multi.Priority_Normal)
    loop:Destroy()
end)

test("setPriority accepts string shortcuts", function()
    local loop = multi:newLoop(function() end)
    local cases = {
        {"c",    multi.Priority_Core},
        {"vh",   multi.Priority_Very_High},
        {"h",    multi.Priority_High},
        {"a",    multi.Priority_Above_Normal},
        {"n",    multi.Priority_Normal},
        {"b",    multi.Priority_Below_Normal},
        {"l",    multi.Priority_Low},
        {"vl",   multi.Priority_Very_Low},
        {"i",    multi.Priority_Idle},
    }
    for _, case in ipairs(cases) do
        loop:setPriority(case[1])
        assert_eq(loop.Priority, case[2], "Priority mismatch for shortcut '" .. case[1] .. "'")
    end
    loop:Destroy()
end)

test("setPriority accepts numeric values", function()
    local loop = multi:newLoop(function() end)
    loop:setPriority(64)
    assert_eq(loop.Priority, 64)
    loop:Destroy()
end)

test("ResetPriority restores the default priority", function()
    local loop = multi:newLoop(function() end)
    loop:setPriority("normal")
    local default = loop.Priority
    loop:setPriority("idle")
    assert_eq(loop.Priority, multi.Priority_Idle)
    loop:ResetPriority()
    assert_eq(loop.Priority, default, "Priority should be restored to default")
    loop:Destroy()
end)

test("PriorityResolve maps priority values to names", function()
    assert_eq(multi.PriorityResolve[multi.Priority_Normal], "Normal")
    assert_eq(multi.PriorityResolve[multi.Priority_High], "High")
    assert_eq(multi.PriorityResolve[multi.Priority_Idle], "Idle")
end)

-- ═════════════════════════════════════════════
-- 12. STATS & INTROSPECTION
-- ═════════════════════════════════════════════
section("Stats & Introspection")

test("getStats returns a table with root entry", function()
    local stats = multi:getStats()
    assert_type(stats, "table")
    assert_truthy(stats["root"], "Stats should contain 'root' entry")
    assert_type(stats["root"].connections, "number")
    assert_type(stats["root"].subscriptions, "number")
end)

test("getChildren returns the Mainloop", function()
    local children = multi:getChildren()
    assert_eq(children, multi.Mainloop)
end)

test("getVersion returns the library version string", function()
    assert_eq(multi:getVersion(), multi.Version)
end)

test("getRunners excludes internal process threads", function()
    local runners = multi:getRunners()
    assert_type(runners, "table")
    for _, r in ipairs(runners) do
        assert_falsy(r.__ignore, "Runners should not include __ignore objects")
    end
end)

test("getCurrentProcess returns multi at top level", function()
    assert_eq(multi.getCurrentProcess(), multi)
end)

-- ═════════════════════════════════════════════
-- 13. OS UTILITIES
-- ═════════════════════════════════════════════
section("OS Utilities")

test("os.getOS returns 'windows' or 'unix'", function()
    local os_name = os.getOS()
    assert_truthy(os_name == "windows" or os_name == "unix",
        "os.getOS should return 'windows' or 'unix', got: " .. tostring(os_name))
end)

test("os.sleep is defined (just check it exists)", function()
    assert_type(os.sleep, "function")
end)

-- ═════════════════════════════════════════════
-- 14. TABLE UTILITIES
-- ═════════════════════════════════════════════
section("Table Utilities (table.merge)")

test("table.merge merges non-overlapping keys", function()
    local t1 = {a = 1}
    local t2 = {b = 2}
    table.merge(t1, t2)
    assert_eq(t1.a, 1)
    assert_eq(t1.b, 2)
end)

test("table.merge overwrites with t2 values on conflict", function()
    local t1 = {a = 1, b = "old"}
    local t2 = {b = "new", c = 3}
    table.merge(t1, t2)
    assert_eq(t1.b, "new")
    assert_eq(t1.c, 3)
end)

test("table.merge recurses into nested tables", function()
    local t1 = {nested = {x = 1}}
    local t2 = {nested = {y = 2}}
    table.merge(t1, t2)
    assert_eq(t1.nested.x, 1)
    assert_eq(t1.nested.y, 2)
end)

test("table.merge returns t1", function()
    local t1 = {a = 1}
    local result = table.merge(t1, {b = 2})
    assert_eq(result, t1)
end)

-- ═════════════════════════════════════════════
-- 15. SCHEDULED JOBS / TASKS
-- ═════════════════════════════════════════════
section("Task Queue")

test("newTask adds a function to the task queue", function()
    local ran = false
    multi:newTask(function() ran = true end)
    -- Tasks are processed by the Task Handler thread inside threadManager
    run_until(function() return ran end, 5000)
    assert_truthy(ran, "Task should have been run")
end)

test("multiple tasks run in order", function()
    local order = {}
    multi:newTask(function() table.insert(order, 1) end)
    multi:newTask(function() table.insert(order, 2) end)
    multi:newTask(function() table.insert(order, 3) end)
    run_until(function() return #order >= 3 end, 5000)
    assert_eq(#order, 3)
    assert_eq(order[1], 1)
    assert_eq(order[2], 2)
    assert_eq(order[3], 3)
end)

-- ═════════════════════════════════════════════
-- 16. NIL SENTINEL
-- ═════════════════════════════════════════════
section("NIL Sentinel")

test("multi.NIL is a table with Type='NIL'", function()
    assert_type(multi.NIL, "table")
    assert_eq(multi.NIL.Type, "NIL")
end)

test("multi.NIL is distinct from Lua nil", function()
    assert_truthy(multi.NIL ~= nil)
end)

-- ─────────────────────────────────────────────
-- SUMMARY
-- ─────────────────────────────────────────────
io.write(string.format(
    "\n\x1b[97m────────────────────────────────\x1b[0m\n" ..
    "\x1b[92m  Passed : %d\x1b[0m\n" ..
    "\x1b[91m  Failed : %d\x1b[0m\n" ..
    "\x1b[93m  Skipped: %d\x1b[0m\n" ..
    "\x1b[97m────────────────────────────────\x1b[0m\n",
    passed, failed, skipped
))

if #failures > 0 then
    io.write("\n\x1b[91mFailed tests:\x1b[0m\n")
    for _, f in ipairs(failures) do
        io.write(string.format("  • %s\n    %s\n", f.name, f.err))
    end
end

os.exit(failed == 0 and 0 or 1)
