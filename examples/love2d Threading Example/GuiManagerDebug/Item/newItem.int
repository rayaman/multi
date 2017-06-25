function gui:newItem(t,i,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("TextImageButtonFrame",name, x, y, w, h, sx ,sy ,sw ,sh)
	if type(i)=="string" then
		c.Image=love.graphics.newImage(i)
	else
		c.Image=i
	end
	c.rotation=0
	c.ImageVisibility=1
	c.Draggable=false
	if c.Image~=nil then
		c.ImageHeigth=c.Image:getHeight()
		c.ImageWidth=c.Image:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.ImageWidth,c.ImageHeigth)
	end
	c.Tween=0
	c.XTween=0
	c.text = t
	c.AutoScaleText=false
	c.FontHeight=_defaultfont:getHeight()
	c.Font=_defaultfont
	c.FontSize=15
	c.TextFormat="center"
	c.TextVisibility=1 -- 0=invisible,1=solid (self.TextVisibility*254+1)
    c.TextColor = {0, 0, 0}
    return c
end