ISTHREAD = true
THREAD = require("multi.integration.loveManager.threads") -- order is important!
scratchpad = require("multi.integration.loveManager.scratchpad")
STATUS = require("multi.integration.loveManager.status")
__IMPORTS = {...}
__FUNC__=table.remove(__IMPORTS,1)
__THREADID__=table.remove(__IMPORTS,1)
__THREADNAME__=table.remove(__IMPORTS,1)
pad=table.remove(__IMPORTS,1)
globalhpad=table.remove(__IMPORTS,1)
GLOBAL = THREAD.getGlobal()
multi, thread = require("multi").init()
THREAD.loadDump(__FUNC__)(unpack(__IMPORTS))