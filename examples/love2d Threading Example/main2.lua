require("core.Library")
GLOBAL,sThread=require("multi.integration.loveManager").init() -- load the love2d version of the lanesManager and requires the entire multi library
--IMPORTANT
-- Do not make the above local, this is the one difference that the lanesManager does not have
-- If these are local the functions will have the upvalues put into them that do not exist on the threaded side
-- You will need to ensure that the function does not refer to any upvalues in its code. It will print an error if it does though
-- Also each thread has a .1 second delay! This is used to generate a random values for each thread!
require("core.GuiManager")
gui.ff.Color=Color.Black
function multi:newSystemThreadedQueue(name) -- in love2d this will spawn a channel on both ends
	local c={}
	c.name=name
	if love then
		if love.thread then
			function c:init()
				self.chan=love.thread.getChannel(self.name)
				function self:push(v)
					self.chan:push(v)
				end
				function self:pop()
					return self.chan:pop()
				end
				GLOBAL[self.name]=self
				return self
			end
			return c
		else
			error("Make sure you required the love.thread module!")
		end
	else
		c.linda=lanes.linda()
		function c:push(v)
			self.linda:send("Q",v)
		end
		function c:pop()
			return ({self.linda:receive(0,"Q")})[2]
		end
		function c:init()
			return self
		end
		GLOBAL[name]=c
	end
	return c
end
queue=multi:newSystemThreadedQueue("QUEUE"):init()
queue:push("This is a test")
queue:push("This is a test2")
queue:push("This is a test3")
queue:push("This is a test4")
multi:newSystemThread("test2",function()
	queue=sThread.waitFor("QUEUE"):init()
	data=queue:pop()
	while data do
		print(data)
		data=queue:pop()
	end
	queue:push("DONE!")
end)
multi:newThread("test!",function()
	thread.hold(function() return queue:pop() end)
	t.text="Done!"
end)
t=gui:newTextLabel("no done yet!",0,0,300,100)
t:centerX()
t:centerY()
