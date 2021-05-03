# Multi Version: 15.1.0 LÖVR Integration
**Key Changes**
- Emulating system threading on a single thread
    - Purpose to allow consistant code that can scale when threading is available. Check out the changelog for more details
- Proper support for lua versions above 5.1 (More testing is needed, a full test suite is being developed and should be made available soon)

Found an issue? Please [submit it](https://github.com/rayaman/multi/issues) and I'll look into it!

My multitasking library for lua. It is a pure lua binding, with exceptions of the integrations and the love2d compat. If you find any bugs or have any issues, please [let me know](https://github.com/rayaman/multi/issues) and I'll look into it!.

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
- [ ] Fix some bugs

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
