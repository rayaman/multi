--[[
    Test suite for multi.lua
    Run with: lua multi_test.lua

    Requires multi.lua to be in the same directory or on the Lua path.
    Compatible with Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.
]]
package.path = "?/init.lua;?.lua;../?/init.lua;../?.lua;" .. package.path

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

section("Initialization")

test("lanesManager init returns GLOBAL and THREAD", function()
    local GLOBAL, THREAD = require("multi.integration.lanesManager"):init()
    assert_type(GLOBAL, "table")
    assert_type(THREAD, "table")
end)

test("lanesManager sets integration table", function()
    assert_type(multi.integration.GLOBAL, "table")
    assert_type(multi.integration.THREAD, "table")
end)

-- initialize once for rest of tests
local GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

-- ─────────────────────────────────────────────
section("SystemThreadedQueue")

test("queue push/pop", function()
    local q = multi:newSystemThreadedQueue("testQ1")

    q:push(42)
    local val = q:pop()

    assert_eq(val, 42)
end)

test("queue peek does not remove", function()
    local q = multi:newSystemThreadedQueue("testQ2")

    q:push("hello")

    assert_eq(q:peek(), "hello")
    assert_eq(q:pop(), "hello")
end)

test("queue empty returns nil", function()
    local q = multi:newSystemThreadedQueue("testQ3")

    assert_eq(q:pop(), nil)
end)

-- ─────────────────────────────────────────────
section("SystemThreadedTable")

test("table set/get", function()
    local t = multi:newSystemThreadedTable("testT1")

    t.foo = "bar"
    assert_eq(t.foo, "bar")
end)

test("table overwrite", function()
    local t = multi:newSystemThreadedTable("testT2")

    t.x = 1
    t.x = 2

    assert_eq(t.x, 2)
end)

-- ─────────────────────────────────────────────
section("THREAD API")

test("THREAD set/get", function()
    THREAD.set("abc", 123)
    assert_eq(THREAD.get("abc"), 123)
end)

test("THREAD getCores > 0", function()
    assert_truthy(THREAD.getCores() > 0)
end)

-- ─────────────────────────────────────────────
section("SystemThreadedConnection")

test("connection fires event", function()
    local conn = multi:newSystemThreadedConnection("conn1"):init()

    local received = nil

    conn(function(v)
        received = v
    end)

    conn:Fire("ping")

    run_until(function()
        return received ~= nil
    end, 5000)

    assert_eq(received, "ping")
end)

-- ─────────────────────────────────────────────
section("SystemThreadedJobQueue")

test("job queue executes function", function()
    local jq = multi:newSystemThreadedJobQueue(1)

    jq:registerFunction("add", function(a, b)
        return a + b
    end)

    local result = nil

    jq.OnJobCompleted(function(_, val)
        result = val
    end)

    jq:pushJob("add", 2, 3)

    run_until(function()
        return result ~= nil
    end, 10000)

    assert_eq(result, 5)
end)

-- ─────────────────────────────────────────────
section("JobQueue newFunction")

test("newFunction returns correct result", function()
    local jq = multi:newSystemThreadedJobQueue(1)

    local fn = jq:newFunction(function(a, b)
        return a * b
    end,true)

    local result = nil

    result = fn(3, 4)

    run_until(function()
        return result ~= nil
    end, 10000)

    assert_eq(result, 12)
end)

-- ─────────────────────────────────────────────
-- Summary
-- ─────────────────────────────────────────────
section("Results")

io.write("\n")
io.write("Passed:  " .. passed .. "\n")
io.write("Failed:  " .. failed .. "\n")
io.write("Skipped: " .. skipped .. "\n")

if failed > 0 then
    io.write("\nFailures:\n")
    for _, f in ipairs(failures) do
        io.write(" - " .. f.name .. "\n")
        io.write("   " .. f.err .. "\n")
    end
    os.exit(1)
end