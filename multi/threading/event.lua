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
function multi:newThreadedEvent(name,task)
	local c=self:newTBase()
	c.Type='eventThread'
	c.Task=task or function() end
	function c:OnEvent(func)
		table.insert(self.func,func)
	end
	function c:tofile(path)
		local m=bin.new()
		m:addBlock(self.Type)
		m:addBlock(self.Task)
		m:addBlock(self.func)
		m:addBlock(self.Active)
		m:tofile(path)
	end
	function c:Resume()
		self.rest=false
	end
	function c:Pause()
		self.rest=true
	end
	c.rest=false
	c.updaterate=0
	c.restRate=1
	multi:newThread(name,function(ref)
		while true do
			if c.rest then
				ref:sleep(c.restRate) -- rest a bit more when a thread is paused
			else
				if c.Task(self) then
					for _E=1,#c.func do
						c.func[_E](c)
					end
					c:Pause()
				end
				ref:sleep(c.updaterate) -- lets rest a bit
			end
		end
	end)
	self:create(c)
	return c
end
