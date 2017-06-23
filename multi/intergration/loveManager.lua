--[[
This is going to be fun. With love2d channels are easy to get but the way they work are very different from lanes'
Channels work like a queue so in order to recreate the global table we would have to do some very weird things...

First off every thread can share a channel thats the same, but once one thread eats the value it isn't availible for the rest... You can peek but then you would have to convey that to the other threads
The way the structure of threading works in love2d makes you not want to have a thread that is constantly running because data passing in a nice way is tricky.

The idea that love took prevents data errors, but a global table is something that needs to be implemted so basic libraries
that use the multi library threading ablities are cross platform.

Idea 1:
One method could be to have a read channel that all data is sent through.
The first thread that gets it using Channel:performAtomic() takes that data keeps a copy for its Global then sends a copy to the other threads individual global channel
basically an updater that updates a local table.
]]
