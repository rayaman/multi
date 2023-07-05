package.path = "../?/init.lua;../?.lua;"..package.path
require("runtests")
require("threadtests")
-- Allows you to run "love tests" which runs the tests

function love.update()
    multi:uManager()
end