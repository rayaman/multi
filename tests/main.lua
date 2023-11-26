package.path = "../?/init.lua;../?.lua;"..package.path
require("runtests")
require("threadtests")
-- Allows you to run "love tests" which runs the tests

multi, thread = require("multi"):init()
GLOBAL, THREAD = require("multi.integration.loveManager"):init()


function love.update()
    multi:uManager()
end