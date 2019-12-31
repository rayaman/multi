--[[
MIT License

Copyright (c) 2020 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
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
local multi, thread = require("multi").init()
os.sleep = love.timer.sleep
multi.drawF = {}
function multi:onDraw(func, i)
	i = i or 1
	table.insert(self.drawF, i, func)
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
multi.OnQuit = multi:newConnection()
multi.OnPreLoad(function()
	local function Hook(func, conn)
		if love[func] ~= nil then
			love[func] = Library.convert(love[func])
			love[func]:inject(function(...)
				conn:Fire(...)
				return {...}
			end,1)
		elseif love[func] == nil then
			love[func] = function(...)
				conn:Fire(...)
			end
		end
	end
	Hook("quit", multi.OnQuit)
	Hook("keypressed", multi.OnKeyPressed)
	Hook("keyreleased", multi.OnKeyReleased)
	Hook("mousepressed", multi.OnMousePressed)
	Hook("mousereleased", multi.OnMouseReleased)
	Hook("wheelmoved", multi.OnMouseWheelMoved)
	Hook("mousemoved", multi.OnMouseMoved)
	Hook("draw", multi.OnDraw)
	Hook("textinput", multi.OnTextInput)
	Hook("update", multi.OnUpdate)
	multi.OnDraw(function()
		for i = 1, #multi.drawF do
			love.graphics.setColor(255, 255, 255, 255)
			multi.drawF[i]()
		end
	end)
end)
multi.OnQuit(function()
	multi.Stop()
	love.event.quit()
end)
return multi
