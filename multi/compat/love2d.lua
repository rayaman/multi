local multi = require("multi")
os.sleep=love.timer.sleep
multi.drawF={}
function multi:onDraw(func,i)
	i=i or 1
	table.insert(self.drawF,i,func)
end
multi.OnKeyPressed = multi:newConnection()
multi.OnKeyReleased = multi:newConnection()
multi.OnMousePressed = multi:newConnection()
multi.OnMouseReleased = multi:newConnection()
multi.OnMouseWheelMoved = multi:newConnection()
multi.OnMouseMoved = multi:newConnection()
multi.OnDraw = multi:newConnection()
multi.OnTextInput = multi:newConnection()
multi.OnUpdate = multi:newConnection()
multi.OnPreLoad(function()
	local function Hook(func,conn)
		if love[func]~=nil then
			love[func] = Library.convert(love[func])
			love[func]:inject(function(...)
				conn:Fire(...)
				return {...}
			end,1)
		elseif love[func]==nil then
			love[func] = function(...)
				conn:Fire(...)
			end
		end
	end
	Hook("keypressed",multi.OnKeyPressed)
	Hook("keyreleased",multi.OnKeyReleased)
	Hook("mousepressed",multi.OnMousePressed)
	Hook("mousereleased",multi.OnMouseReleased)
	Hook("wheelmoved",multi.OnMouseWheelMoved)
	Hook("mousemoved",multi.OnMouseMoved)
	Hook("draw",multi.OnDraw)
	Hook("textinput",multi.OnTextInput)
	Hook("update",multi.OnUpdate)
	multi.OnDraw(function()
		for i=1,#multi.drawF do
			love.graphics.setColor(255,255,255,255)
			multi.drawF[i]()
		end
	end)
end)
return multi