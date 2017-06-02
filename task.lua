require("multi")
function multi:newTask(func)
	table.insert(self.Tasks,func)
end