os.sleep=love.timer.sleep
function bin.load(file,s,r)
	content, size = love.filesystem.read(file)
	local temp=bin.new(content)
	temp.filepath=file
    return temp
end
function bin:tofile(filename)
	if not(filename) or self.Stream then return nil end
	love.filesystem.write(filename,self.data)
end
function bin.stream(file,l)
	error("Sorry streaming is not available when using love2d :(, I am looking for a solution though :)")
end
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
