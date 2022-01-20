# Multi Version: 15.1.0 Hold the thread
**Key Changes**
- thread.hold has been updated to allow all variants to work as well as some new features. Check the changelog or documentation for more info.
- multi:newProccesor() Creates a process that acts like the multi namespace that can be managed independently from the mainloop.
- Connections can be added together

Found an issue? Please [submit it](https://github.com/rayaman/multi/issues) and someone will look into it!

My multitasking library for lua. It is a pure lua binding, with exceptions of the integrations.

</br>

Progress is being made in [v15.2.0](https://github.com/rayaman/multi/tree/v15.2.0)
---

</br>

INSTALLING
----------
Links to dependencies:
[lanes](https://github.com/LuaLanes/lanes)

To install copy the multi folder into your environment and you are good to go</br>
If you want to use the system threads, then you'll need to install lanes!
**or** use luarocks `luarocks install multi`

Going forward I will include a Release zip for love2d.
**The Network Manager rework is currently being worked on and the old version is not included in this version.**

Discord
-------
Have a question? Or need realtime assistance? Feel free to join the discord!</br>
https://discord.gg/U8UspuA</br>

Planned features/TODO
---------------------
- [x] ~~Finish Documentation~~ Finished
- [ ] Create test suite
- [ ] Network Parallelism rework

Usage: [Check out the documentation for more info](https://github.com/rayaman/multi/blob/master/Documentation.md)</br>
-----

```lua
package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
local multi, thread = require("multi"):init()
GLOBAL, THREAD = require("multi.integration.threading"):init()
multi:newSystemThread("System Thread",function()
    while true do
        THREAD.sleep(1)
        print("World!")
    end
end)
multi:newThread("Coroutine Based Thread",function()
    while true do
        print("Hello")
        thread.sleep(1)
    end
end)
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
