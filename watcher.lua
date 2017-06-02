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