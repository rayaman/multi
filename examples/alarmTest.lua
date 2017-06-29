-- Tick Tock Example
require("multi")
alarm=multi:newAlarm(1)
alarm.state=-1 -- set the state to -1
alarm.sounds={[-1]="Tick",[1]="Tock"} -- this makes changing between states easy and fast
alarm:OnRing(function(self)
	print(self.sounds[self.state])
	self.state=self.state*-1 -- change the state in one line
	self:Reset() -- Reset the alarm so it runs again
end)
multi:mainloop()
