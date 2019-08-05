# multi Version: 13.1.0 Bug fixes and a few features added (See changes.md)


Found an issue? Please submit it and ill look into it!

My multitasking library for lua. It is a pure lua binding, if you ignore the integrations and the love2d compat. If you find any bugs or have any issues, please let me know . **If you don't see a table of contents try using the ReadMe.html file. It is easier to navigate than readme**</br>

INSTALLING
----------
Note: The latest version of Lua lanes is required if you want to make use of system threads on lua 5.1+. I will update the dependencies for Lua rocks since this library should work fine on lua 5.1+ You also need the lua-net library and the bin library. all installed automatically using luarocks. however you can do this manually if lanes and luasocket are installed. Links:
https://github.com/rayaman/bin
https://github.com/rayaman/multi
https://github.com/rayaman/net

To install copy the multi folder into your environment and you are good to go</br>
If you want to use the system threads, then you'll need to install lanes!
**or** use luarocks

Because of a codependency in net libaray, if using the networkmanager you will need to install the net library sepertly
Going forward I will include a Release zip for love2d. I do not know why I haven't done this yet
```
luarocks install multi
luarocks install lnet
```

Discord
-------
For real-time assistance with my libraries! A place where you can ask questions and get help with any of my libraries. Also, you can request features and stuff there as well.</br>
https://discord.gg/U8UspuA</br>

Planned features/TODO
---------------------
- [ ] Finish Documentation
- [ ] Test for unknown bugs -- This is always going on
- [x] ~~Network Parallelism~~ This was fun, I have some more plans for this as well

Usage:</br>
-----
```lua
-- Basic usage Alarms: Have been moved to the core of the library require("multi") would work as well
local multi = require("multi") -- gets the entire library
alarm=multi:newAlarm(3) -- in seconds can go to .001 uses the built in os.clock()
alarm:OnRing(function(a)
  print("3 Seconds have passed!")
  a:Reset(n) -- if n were nil it will reset back to 3, or it would reset to n seconds
end)
multi:mainloop() -- the main loop of the program, multi:umanager() exists as well to allow integration in other loops Ex: love2d love.update function. More on this binding in the wiki!
```

Known Bugs/Issues
-----------------
Currently no bugs that I know of :D
