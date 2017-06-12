package.path="?/init.lua;"..package.path
require("multi.tloop")
a=0
inc=1 -- change to 0 to see it not met at all, 1 if you want to see the first condition not met but the second and 2 if you want to see it meet the condition on the first go.
loop=multi:newTLoop(function(self)
	print("Looping...")
	a=a+inc
	if a==14 then
		self:ResolveTimer("1","2","3") -- ... any number of arguments can be passed to the resolve handler
		-- this will also automatically pause the object that it is binded to
	end
end,.1)
loop:SetTime(1)
loop:OnTimerResolved(function(self,a,b,c) -- the handler will return the self and the passed arguments
	print("We did it!",a,b,c)
end)
loop:OnTimedOut(function(self)
	if not TheSecondTry then
		print("Loop timed out!",self.Type,"Trying again...")
		self:ResetTime(2)
		self:Resume()
		TheSecondTry=true
	else
		print("We just couldn't do it!") -- print if we don't get anything working
	end
end)
multi:mainloop()
