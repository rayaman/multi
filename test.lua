package.path = "./?/init.lua;?.lua;lua5.4/share/lua/?/init.lua;lua5.4/share/lua/?.lua;"..package.path
package.cpath = "lua5.4/lib/lua/?/core.dll;"..package.cpath
multi, thread = require("multi"):init{print=true}
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()

function multi:newSystemThreadedConnection()
	--
end

multi:mainloop()