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