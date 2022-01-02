lanes = require("lanes").configure({allocator="protected",verbose_errors=""})
local multi,thread = require("multi"):init()
function sleep(n)
	if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end

lanes.gen("*",function()
	print("Hello!")
end)()

multi:newThread("Test thread",function()
	while true do
		thread.sleep(1)
		print("...")
	end
end)
multi:mainloop()