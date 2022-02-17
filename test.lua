package.path = "./?/init.lua;"..package.path
multi, thread = require("multi"):init()

function multi:getTaskStats()
	local stats = {}
end

multi:mainloop()