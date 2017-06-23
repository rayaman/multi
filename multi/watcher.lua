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
require("multi")
function multi:newWatcher(namespace,name)
	local function WatcherObj(ns,n)
		if self.Type=='queue' then
			print("Cannot create a watcher on a queue! Creating on 'multi' instead!")
			self=multi
		end
		local c=self:newBase()
		c.Type='watcher'
		c.ns=ns
		c.n=n
		c.cv=ns[n]
		function c:OnValueChanged(func)
			table.insert(self.func,func)
		end
		function c:Act()
			if self.cv~=self.ns[self.n] then
				for i=1,#self.func do
					self.func[i](self,self.cv,self.ns[self.n])
				end
				self.cv=self.ns[self.n]
			end
		end
		self:create(c)
		return c
	end
	if type(namespace)~='table' and type(namespace)=='string' then
		return WatcherObj(_G,namespace)
	elseif type(namespace)=='table' and (type(name)=='string' or 'number') then
		return WatcherObj(namespace,name)
	else
		print('Warning, invalid arguments! Nothing returned!')
	end
end