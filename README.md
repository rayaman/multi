# Multi Version: 15.3.0 A world of Connections
**Key Changes**
- SystemThreadedConnections
- Restructured the directory structure of the repo (Allows for keeping multi as a submodule and being able to require it as is)
- Bug fixes

Found an issue? Please [submit it](https://github.com/rayaman/multi/issues) and someone will look into it!

My multitasking library for lua. It is a pure lua binding, with exceptions of the integrations.

</br>

Progress is being made in [v16.0.0](https://github.com/rayaman/multi/tree/v16.0.0)
---

</br>

INSTALLING
----------
Link to optional dependencies:
- [lanes](https://github.com/LuaLanes/lanes)

- [love2d](https://love2d.org/)

To install copy the multi folder into your environment and you are good to go</br>
If you want to use the system threads, then you'll need to install lanes or love2d game engine!

```
luarocks install multi
```

Discord
-------
Have a question or need realtime assistance? Feel free to join the discord!</br>
https://discord.gg/U8UspuA

Planned features/TODO
---------------------
- [ ] Create test suite (In progress, mostly done)
- [ ] Network Parallelism rework

Usage: [Check out the documentation for more info](https://github.com/rayaman/multi/blob/master/Documentation.md)
-----

```lua
local multi, thread = require("multi"):init()
GLOBAL, THREAD = require("multi.integration.threading"):init()

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
