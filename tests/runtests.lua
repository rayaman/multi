package.path="../?.lua;../?/init.lua;../?.lua;../?/?/init.lua;"..package.path
--[[
    This file runs all tests.
    Format:
        Expected:
            ...
            ...
            ...
        Actual:
            ...
            ...
            ...
    
    Each test that is ran should have a 5 second pause after the test is complete
    The expected and actual should "match" (Might be impossible when playing with threads)
    This will be pushed directly to the master as tests start existing.
]]