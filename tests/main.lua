package.path = "../?/init.lua;../?.lua;"..package.path

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

GLOBAL, THREAD = require("multi.integration.loveManager"):init()

require("runtests")
require("threadtests")
