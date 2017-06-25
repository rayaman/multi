_GuiPro.mousedownfunc=love.mouse.isDown
function love.mouse.isDown(b)
	if not(b) then
		return false
	end
	return _GuiPro.mousedownfunc(({["l"]=1,["r"]=2,["m"]=3})[b] or b)
end