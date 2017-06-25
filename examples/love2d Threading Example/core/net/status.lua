print([[
the 'admin' 	module STATUS: 0
the 'aft' 		module STATUS: 9
the 'chatting'	module STATUS: 5
the 'db'		module STATUS: 1
the 'email' 	module STATUS: 2
the 'identity' 	module STATUS: 7
the 'inbox' 	module STATUS: 1
the 'init'	 	module STATUS: 9 Not a module, but the core of the program
the 'logging' 	module STATUS: 8
the 'p2p' 		module STATUS: 1
the 'settings' 	module STATUS: 3
the 'sft'		module STATUS: 10
the 'status'	module STATUS: 5
the 'threading' module STATUS: 1
the 'users' 	module STATUS: 1
the 'version' 	module STATUS: 2

STATUS:
0: The idea is there but no progress to actual coding has been made
1: The idea has been coded and thoughts well defined. However only a frame is existing atm
2: The module has limited functionality, but gets its basic function through
3: The module has decent functionality, but needs much more
4: The module functions are stable and works great, however not all of the original idea has been completed
5: The module functions are stable and works great, most of the functions have been fleshed out aside for a few minor ones
6: The module has all features completed and is stable for average use, minor bugs are present.
7: The module has few to no bugs, and is currently being made more secure
8: The module is very secure and odds are it wont crash unless they were implemented wrong
9: The module has most if not all exception handled so even incorrect implementation will be 'error free' Probably wont change, but if it does it will be a huge change!
10: The module is never going to change from its current status! It is done.

NOTE: once a module reaches a status of 4, it will always be backward compatable. server-client relations will be safe!

Each module has a version
1.0.0
A.M.m
addition.Major.minor
whenever a new addition is added the A is increased... You must update to make use of that feature
When a major addition or change Major is incresed. This can be code breaking... However I will try my best to make at least client side code compatible with future changes
when a minor addition or change is made minor in incresed

Why client side stabality in code changes?
Until the update module can seamless update your modules I will ensure that client code can work regardless of server version starting from this version
]])
