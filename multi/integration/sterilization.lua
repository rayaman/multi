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
local bin = pcall(require,"bin")
if not bin then return error("The bin library is required to use sterilization!") end
local multi,thread = require("multi"):init()
local sterilizer = {}
---------------------
-- State Saving Stuff
---------------------
multi.OnObjectCreated(function(obj)
	print(obj.Type)
end)

function IngoreObject()
	-- Tells system to not sterilize this object
end
function sterilizer:ToString()
	-- Turns the object into a string
end
function sterilizer:newFromString(str)
	-- Creates an object from string
end
function sterilizer:ToFile(path)
	-- Turns multi object into a string
end
function sterilizer:fromFile(path)
	-- Loads multi object form file
end
function sterilizer:SetStateFlag(opt)
	-- manage the states
end
function sterilizer:quickStateSave(b)
	-- enables quick state saving
end
function sterilizer:saveState(path,opt)
	-- Saves entire state to file
end
function sterilizer:loadState(path)
	-- Loads entire state from file
end
function sterilizer:setDefualtStateFlag(opt)
	-- sets the default flags for managing states
end
return sterilizer