--[[
MIT License

Copyright (c) 2020 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local multi,thread = require("multi"):init()
---------------------
-- State Saving Stuff
---------------------
function multi:IngoreObject()
	-- Tells system to not sterilize this object
end
function multi:ToString()
	-- Turns the object into a string
end
function multi:newFromString(str)
	-- Creates an object from string
end
function multi:ToFile(path)
	-- Turns multi object into a string
end
function multi:fromFile(path)
	-- Loads multi object form file
end
function multi:SetStateFlag(opt)
	-- manage the states
end
function multi:quickStateSave(b)
	-- enables quick state saving
end
function multi:saveState(path,opt)
	-- Saves entire state to file
end
function multi:loadState(path)
	-- Loads entire state from file
end
function multi:setDefualtStateFlag(opt)
	-- sets the default flags for managing states
end