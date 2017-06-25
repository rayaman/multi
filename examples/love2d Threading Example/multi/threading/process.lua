--[[
MIT License

Copyright (c) 2017 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
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
require("multi.threading")
function multi:newThreadedProcess(name)
	local c = {}
	setmetatable(c, multi)
	function c:newBase(ins)
		local ct = {}
		setmetatable(ct, self.Parent)
		ct.Active=true
		ct.func={}
		ct.ender={}
		ct.Id=0
		ct.PId=0
		ct.Act=function() end
		ct.Parent=self
		ct.held=false
		ct.ref=self.ref
		table.insert(self.Mainloop,ct)
		return ct
	end
	c.Parent=self
	c.Active=true
	c.func={}
	c.Id=0
	c.Type='process'
	c.Mainloop={}
	c.Tasks={}
	c.Tasks2={}
	c.Garbage={}
	c.Children={}
	c.Paused={}
	c.Active=true
	c.Id=-1
	c.Rest=0
	c.updaterate=.01
	c.restRate=.1
	c.Jobs={}
	c.queue={}
	c.jobUS=2
	c.rest=false
	function c:getController()
		return nil
	end
	function c:Start()
		self.rest=false
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	function c:Remove()
		self.ref:kill()
	end
	function c:kill()
		err=coroutine.yield({"_kill_"})
		if err then
			error("Failed to kill a thread! Exiting...")
		end
	end
	function c:sleep(n)
		if type(n)=="function" then
			ret=coroutine.yield({"_hold_",n})
		elseif type(n)=="number" then
			n = tonumber(n) or 0
			ret=coroutine.yield({"_sleep_",n})
		else
			error("Invalid Type for sleep!")
		end
	end
	c.hold=c.sleep
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				ref:Sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				c:uManager()
				ref:sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	return c
end
