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
os.sleep=love.timer.sleep
function love.run()
	if love.math then
		love.math.setRandomSeed(os.time())
	end
	if love.event then
		love.event.pump()
	end
	if love.load then love.load(arg) end
	if love.timer then love.timer.step() end
	local dt = 0
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for e,a,b,c,d in love.event.poll() do
				if e == "quit" then
					if not love.quit or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
					end
				end
				love.handlers[e](a,b,c,d)
			end
		end
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end
		if love.update then love.update(dt) end
		if multi.boost then
			for i=1,multi.boost-1 do
				multi:uManager(dt)
			end
		end
		multi:uManager(dt)
		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			multi.dManager()
			love.graphics.setColor(255,255,255,255)
			if multi.draw then multi.draw() end
			love.graphics.present()
		end
	end
end
multi.drawF={}
function multi:dManager()
	for ii=1,#multi.drawF do
		multi.drawF[ii]()
	end
end
function multi:onDraw(func,i)
	i=i or 1
	table.insert(self.drawF,i,func)
end
function multi:lManager()
	if love.event then
		love.event.pump()
		for e,a,b,c,d in love.event.poll() do
			if e == "quit" then
				if not love.quit or not love.quit() then
					if love.audio then
						love.audio.stop()
					end
					return nil
				end
			end
			love.handlers[e](a,b,c,d)
		end
	end
	if love.timer then
		love.timer.step()
		dt = love.timer.getDelta()
	end
	if love.update then love.update(dt) end
	multi:uManager(dt)
	if love.window and love.graphics and love.window.isCreated() then
		love.graphics.clear()
		love.graphics.origin()
		if love.draw then love.draw() end
		multi.dManager()
		love.graphics.setColor(255,255,255,255)
		if multi.draw then multi.draw() end
		love.graphics.present()
	end
end
