function gui:newPart(x, y,w ,h , sx ,sy ,sw ,sh)
	local c = {}
    setmetatable(c, gui)
	if self==gui then
		c.Parent=_GuiPro
	else
		c.Parent=self
	end
	c.funcs={}
	c.funcs2={}
	c.funcs3={}
	c.funcs4={}
	c.funcs5={}
	c.func6={}
	c.func7={}
	c.func8={}
	c.func9={}
	c.func10={}
	c.form="rectangle"
    c.Color = {255, 255, 255}
	c.scale={}
	c.scale.size={}
	c.scale.size.x=sw or 0
	c.scale.size.y=sh or 0
	c.offset={}
	c.offset.size={}
	c.offset.size.x=w or 0
	c.offset.size.y=h or 0
	c.scale.pos={}
	c.scale.pos.x=sx or 0
	c.scale.pos.y=sy or 0
	c.offset.pos={}
	c.offset.pos.x=x or 0
	c.offset.pos.y=y or 0
	c.VIS=true
	c.Visible=true
	c.Visibility=1
	c.BorderColor={0,0,0}
	c.BorderSize=0
	c.Type="Part"
	c.Name="GuiPart"
	_GuiPro.count=_GuiPro.count+1
	c.x=(c.Parent.width*c.scale.pos.x)+c.offset.pos.x+c.Parent.x
	c.y=(c.Parent.height*c.scale.pos.y)+c.offset.pos.y+c.Parent.y
	c.width=(c.Parent.width*c.scale.size.x)+c.offset.size.x
	c.height=(c.Parent.height*c.scale.size.y)+c.offset.size.y
	table.insert(c.Parent.Children,c)
	return c
end