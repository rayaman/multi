# Multi Version: 15.2.0 Upgrade Complete
**Key Changes**
- All objects now use connections internally
- Connections now about 23x faster! 
- Updated getTasksDetails() to handle the new method of managing threads and processors

Found an issue? Please [submit it](https://github.com/rayaman/multi/issues) and someone will look into it!

My multitasking library for lua. It is a pure lua binding, with exceptions of the integrations and the love2d compat.

INSTALLING
----------
Link to dependencies:
[lanes](https://github.com/LuaLanes/lanes)

To install copy the multi folder into your environment and you are good to go</br>
If you want to use the system threads, then you'll need to install lanes!
**or** use luarocks `luarocks install multi`

Discord
-------
Have a question or need realtime assistance? Feel free to join the discord!</br>
https://discord.gg/U8UspuA

Planned features/TODO
---------------------
- [ ] Create test suite
- [ ] Network Parallelism rework

Usage: [Check out the documentation for more info](https://github.com/rayaman/multi/blob/master/Documentation.md)
-----

```lua
local multi, thread = require("multi"):init()
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()
multi:newSystemThread("System Thread",function()
	while true do
		THREAD.sleep(.1)
		io.write(" World")
		THREAD.kill()
	end
end)
multi:newThread("Coroutine Based Thread",function()
	while true do
		io.write("Hello")
		thread.sleep(.1)
		thread.kill()
	end
end)
multi:newTLoop(function(loop)
	print("!")
	loop:Destroy()
	os.exit()
end,.3)
multi:mainloop()
--[[
while true do
	multi:uManager()
end
]]
```

Known Bugs/Issues
-----------------
Check the [Issues tab](https://github.com/rayaman/multi/issues) for issues
