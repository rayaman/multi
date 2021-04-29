# Multi Version: 14.2.0 Documentation Complete, Bloat removed!

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
Have a question that you need asking? Or need realtime assistance? Feel free to join the discord!</br>
https://discord.gg/U8UspuA</br>

Planned features/TODO
---------------------
- [x] ~~Finish Documentation~~ Finished
- [ ] Network Parallelism rework
- [ ] Fix some bugs

Usage: [Check out the documentation for more info](https://github.com/rayaman/multi/blob/master/Documentation.md)</br>
-----
```lua
local multi, thread = require("multi").init()
mutli:newThread("Example",function()
    while true do
        thread.sleep(1)
        print("Hello!")
    end
end)
multi:lightloop()
--multi:mainloop()
--[[
while true do
    multi:uManager()
end
]]
```

Known Bugs/Issues
-----------------
Check the [Issues tab](https://github.com/rayaman/multi/issues) for issues
