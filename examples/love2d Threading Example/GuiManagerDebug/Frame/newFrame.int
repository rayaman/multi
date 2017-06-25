function gui:newFrame(name,x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("Frame",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.WasBeingDragged=false
	c.IsBeingDragged=false
	c.Draggable=false
    return c
end