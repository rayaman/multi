# multi Version: 14.1.0 System threaded functions and more? (See changes.md for detailed changes)

Found an issue? Please [submit it](https://github.com/rayaman/multi/issues) and I'll look into it!

My multitasking library for lua. It is a pure lua binding, if you ignore the integrations and the love2d compat. If you find any bugs or have any issues, please let me know.

INSTALLING
----------
Links to dependicies:
[bin](https://github.com/rayaman/bin)
[net](https://github.com/rayaman/net)
[lanes](https://github.com/LuaLanes/lanes)

To install copy the multi folder into your environment and you are good to go</br>
If you want to use the system threads, then you'll need to install lanes!
**or** use luarocks

~~Because of a codependency in net libaray, if using the networkmanager you will need to install the net library sepertly~~ The networkManager is currently being reworked. As of right now the net library is not required.
Going forward I will include a Release zip for love2d. I do not know why I haven't done this yet
**The Network Manager rework is currently being worked on and the old version is not included in this version. It will be released in 15.0.0**

```
luarocks install multi
luarocks install lnet   (If planning on using the networkManager)
```

Discord
-------
Have a question that you need asking? Or need realtime assistance? Feel free to join the discord!</br>
https://discord.gg/U8UspuA</br>

Planned features/TODO
---------------------
- [ ] Finish Documentation
- [ ] Network Parallelism rework

Usage:</br>
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
Check the Issue tab for issues
