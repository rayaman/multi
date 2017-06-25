function gui:getTile(i,x,y,w,h)-- returns imagedata
	if type(i)=="string" then
		i=love.graphics.newImage(i)
	elseif type(i)=="userdata" then
		-- do nothing
	elseif string.find(self.Type,"Image",1,true) then
		local i,x,y,w,h=self.Image,i,x,y,w
	else
		error("getTile invalid args!!! Usage: ImageElement:getTile(x,y,w,h) or gui:getTile(imagedata,x,y,w,h)")
	end
	local iw,ih=i:getDimensions()
	local id,_id=i:getData(),love.image.newImageData(w,h)
	for _x=x,w+x-1 do
		for _y=y,h+y-1 do
			--
			_id:setPixel(_x-x,_y-y,id:getPixel(_x,_y))
		end
	end
	return love.graphics.newImage(_id)
end