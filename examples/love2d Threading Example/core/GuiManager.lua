utf8 = require("utf8")
_defaultfont = love.graphics.getFont()
gui = {}
gui.__index = gui
gui.TB={}
gui.Version="8.0.0" -- Is it really ready for release?
_GuiPro={GBoost=true,hasDrag=false,DragItem={},Children={},Visible=true,count=0,x=0,y=0,height=0,width=0,update=function(self) local things=GetAllChildren2(self) UpdateThings(things) end,draw=function(self) local things=GetAllChildren(self) DrawThings(things) end,getChildren=function(self) return self.Children end}
_GuiPro.Clips={}
_GuiPro.rotate=0
setmetatable(_GuiPro, gui)
function gui:LoadInterface(file)
	local add=".int"
	if string.find(file,".",1,true) then add="" end
	if love.filesystem.exists(file..add) then
    a,b=pcall(love.filesystem.load(file..add))
		if a then
			print("Loaded: "..file)
		else
			print("Error loading file: "..file)
      print(a,b)
		end
	else
		print("File does not exist!")
		return false
	end
end
function gui.LoadAll(dir)
	files=love.filesystem.getDirectoryItems(dir)
	for i=1,#files do
		if string.sub(files[i],-4)==".int" then
			gui:LoadInterface(dir.."/"..files[i])
		end
	end
end

function gui:Clickable()
	local x,y,w,h=love.graphics.getScissor()
	local mx=love.mouse.getX()
	local my=love.mouse.getY()
	if _GuiPro.HasStencel then
		local obj=_GuiPro.StencelHolder
		if self:isDescendant(obj) then
			return math.sqrt((mx-obj.x)^2+(my-obj.y)^2)<=(obj.offset.size.x or 0)
		end
	end
	if not(x) then
		return true
	end
	return not(mx>x+w or mx<x or my>y+h or my<y)
end
Color={
new=function(r,g,b)
	mt = {
		__add = function (c1,c2)
			return Color.new(c1[1]+c2[1],c1[2]+c2[2],c1[2]+c2[2])
		end,
		__sub = function (c1,c2)
			return Color.new(c1[1]-c2[1],c1[2]-c2[2],c1[2]-c2[2])
		end,
		__mul = function (c1,c2)
			return Color.new(c1[1]*c2[1],c1[2]*c2[2],c1[2]*c2[2])
		end,
		__div = function (c1,c2)
			return Color.new(c1[1]/c2[1],c1[2]/c2[2],c1[2]/c2[2])
		end,
		__mod = function (c1,c2)
			return Color.new(c1[1]%c2[1],c1[2]%c2[2],c1[2]%c2[2])
		end,
		__pow = function (c1,c2)
			return Color.new(c1[1]^c2[1],c1[2]^c2[2],c1[2]^c2[2])
		end,
		__unm = function (c1)
			return Color.new(-c1[1],-c1[2],-c1[2])
		end,
		__tostring = function(c)
			return "("..c[1]..","..c[2]..","..c[3]..")"
		end,
		__eq = Color.EQ,
		__lt = Color.LT,
		__le = Color.LE,
	}
	local temp = {r,g,b,255}
	setmetatable(temp, mt)
	return temp
end,
Random=function()
	return Color.new(math.random(0,255),math.random(0,255),math.random(0,255))
end,
EQ = function (c1,c2)
	return (c1[1]==c2[1] and c1[2]==c2[2] and c1[2]==c2[2])
end,
LT = function (c1,c2)
	return (c1[1]<c2[1] and c1[2]<c2[2] and c1[2]<c2[2])
end,
LE = function (c1,c2)
	return (c1[1]<=c2[1] and c1[2]<=c2[2] and c1[2]<=c2[2])
end,
IndexColor=function(name,r,b,g)
	if type(r)=="string" then
		r,b,g=tonumber(string.sub(r,1,2),16),tonumber(string.sub(r,3,4),16),tonumber(string.sub(r,5,6),16)
	end
	Color[string.lower(name)]=Color.new(r,b,g)
	Color[string.upper(name)]=Color.new(r,b,g)
	Color[string.upper(string.sub(name,1,1))..string.lower(string.sub(name,2))]=Color.new(r,b,g)
end,
Darken=function(color,v)
	currentR=color[1]
	currentG=color[2]
	currentB=color[3]
	return Color.new(currentR * (1 - v),currentG * (1 - v),currentB * (1 - v))
end,
Lighten=function(color,v)
	currentR=color[1]
	currentG=color[2]
	currentB=color[3]

	return Color.new(currentR + (255 - currentR) * v,currentG + (255 - currentG) * v,currentB + (255 - currentB) * v)
end
}
Color.IndexColor("Black",20,20,20)
Color.IndexColor("WHITE",255,255,255)
Color.IndexColor("MAROON",128,20,20)
Color.IndexColor("DARK_RED",139,20,20)
Color.IndexColor("BROWN",165,42,42)
Color.IndexColor("FIREBRICK",178,34,34)
Color.IndexColor("CRIMSON",220,20,60)
Color.IndexColor("RED",255,20,20)
Color.IndexColor("TOMATO",255,99,71)
Color.IndexColor("CORAL",255,127,80)
Color.IndexColor("INDIAN_RED",205,92,92)
Color.IndexColor("LIGHT_CORAL",240,128,128)
Color.IndexColor("DARK_SALMON",233,150,122)
Color.IndexColor("SALMON",250,128,114)
Color.IndexColor("LIGHT_SALMON",255,160,122)
Color.IndexColor("ORANGE_RED",255,69,20)
Color.IndexColor("DARK_ORANGE",255,140,20)
Color.IndexColor("ORANGE",255,165,20)
Color.IndexColor("GOLD",255,215,20)
Color.IndexColor("DARK_GOLDEN_ROD",184,134,11)
Color.IndexColor("GOLDEN_ROD",218,165,32)
Color.IndexColor("PALE_GOLDEN_ROD",238,232,170)
Color.IndexColor("DARK_KHAKI",189,183,107)
Color.IndexColor("KHAKI",240,230,140)
Color.IndexColor("OLIVE",128,128,20)
Color.IndexColor("YELLOW",255,255,20)
Color.IndexColor("YELLOW_GREEN",154,205,50)
Color.IndexColor("DARK_OLIVE_GREEN",85,107,47)
Color.IndexColor("OLIVE_DRAB",107,142,35)
Color.IndexColor("LAWN_GREEN",124,252,20)
Color.IndexColor("CHART_REUSE",127,255,20)
Color.IndexColor("GREEN_YELLOW",173,255,47)
Color.IndexColor("DARK_GREEN",20,100,20)
Color.IndexColor("GREEN",20,128,20)
Color.IndexColor("FOREST_GREEN",34,139,34)
Color.IndexColor("LIME",20,255,20)
Color.IndexColor("LIME_GREEN",50,205,50)
Color.IndexColor("LIGHT_GREEN",144,238,144)
Color.IndexColor("PALE_GREEN",152,251,152)
Color.IndexColor("DARK_SEA_GREEN",143,188,143)
Color.IndexColor("MEDIUM_SPRING_GREEN",20,250,154)
Color.IndexColor("SPRING_GREEN",20,255,127)
Color.IndexColor("SEA_GREEN",46,139,87)
Color.IndexColor("MEDIUM_AQUA_MARINE",102,205,170)
Color.IndexColor("MEDIUM_SEA_GREEN",60,179,113)
Color.IndexColor("LIGHT_SEA_GREEN",32,178,170)
Color.IndexColor("DARK_SLATE_GRAY",47,79,79)
Color.IndexColor("TEAL",20,128,128)
Color.IndexColor("DARK_CYAN",20,139,139)
Color.IndexColor("LIGHT_CYAN",224,255,255)
Color.IndexColor("DARK_TURQUOISE",20,206,209)
Color.IndexColor("TURQUOISE",64,224,208)
Color.IndexColor("MEDIUM_TURQUOISE",72,209,204)
Color.IndexColor("PALE_TURQUOISE",175,238,238)
Color.IndexColor("AQUA_MARINE",127,255,212)
Color.IndexColor("POWDER_BLUE",176,224,230)
Color.IndexColor("CADET_BLUE",95,158,160)
Color.IndexColor("STEEL_BLUE",70,130,180)
Color.IndexColor("CORN_FLOWER_BLUE",100,149,237)
Color.IndexColor("DEEP_SKY_BLUE",20,191,255)
Color.IndexColor("DODGER_BLUE",30,144,255)
Color.IndexColor("LIGHT_BLUE",173,216,230)
Color.IndexColor("SKY_BLUE",135,206,235)
Color.IndexColor("LIGHT_SKY_BLUE",135,206,250)
Color.IndexColor("MIDNIGHT_BLUE",25,25,112)
Color.IndexColor("NAVY",20,20,128)
Color.IndexColor("DARK_BLUE",20,20,139)
Color.IndexColor("MEDIUM_BLUE",20,20,205)
Color.IndexColor("BLUE",20,20,255)
Color.IndexColor("ROYAL_BLUE",65,105,225)
Color.IndexColor("BLUE_VIOLET",138,43,226)
Color.IndexColor("INDIGO",75,20,130)
Color.IndexColor("DARK_SLATE_BLUE",72,61,139)
Color.IndexColor("SLATE_BLUE",106,90,205)
Color.IndexColor("MEDIUM_SLATE_BLUE",123,104,238)
Color.IndexColor("MEDIUM_PURPLE",147,112,219)
Color.IndexColor("DARK_MAGENTA",139,20,139)
Color.IndexColor("DARK_VIOLET",148,20,211)
Color.IndexColor("DARK_ORCHID",153,50,204)
Color.IndexColor("MEDIUM_ORCHID",186,85,211)
Color.IndexColor("PURPLE",128,20,128)
Color.IndexColor("THISTLE",216,191,216)
Color.IndexColor("PLUM",221,160,221)
Color.IndexColor("VIOLET",238,130,238)
Color.IndexColor("MAGENTA",255,20,255)
Color.IndexColor("ORCHID",218,112,214)
Color.IndexColor("MEDIUM_VIOLET_RED",199,21,133)
Color.IndexColor("PALE_VIOLET_RED",219,112,147)
Color.IndexColor("DEEP_PINK",255,20,147)
Color.IndexColor("HOT_PINK",255,105,180)
Color.IndexColor("LIGHT_PINK",255,182,193)
Color.IndexColor("PINK",255,192,203)
Color.IndexColor("ANTIQUE_WHITE",250,235,215)
Color.IndexColor("BEIGE",245,245,220)
Color.IndexColor("BISQUE",255,228,196)
Color.IndexColor("BLANCHED_ALMOND",255,235,205)
Color.IndexColor("WHEAT",245,222,179)
Color.IndexColor("CORN_SILK",255,248,220)
Color.IndexColor("LEMON_CHIFFON",255,250,205)
Color.IndexColor("LIGHT_GOLDEN_ROD_YELLOW",250,250,210)
Color.IndexColor("LIGHT_YELLOW",255,255,224)
Color.IndexColor("SADDLE_BROWN",139,69,19)
Color.IndexColor("SEXY_PURPLE",85,85,127)
Color.IndexColor("SIENNA",160,82,45)
Color.IndexColor("CHOCOLATE",210,105,30)
Color.IndexColor("PERU",205,133,63)
Color.IndexColor("SANDY_BROWN",244,164,96)
Color.IndexColor("BURLY_WOOD",222,184,135)
Color.IndexColor("TAN",210,180,140)
Color.IndexColor("ROSY_BROWN",188,143,143)
Color.IndexColor("MOCCASIN",255,228,181)
Color.IndexColor("NAVAJO_WHITE",255,222,173)
Color.IndexColor("PEACH_PUFF",255,218,185)
Color.IndexColor("MISTY_ROSE",255,228,225)
Color.IndexColor("LAVENDER_BLUSH",255,240,245)
Color.IndexColor("LINEN",250,240,230)
Color.IndexColor("OLD_LACE",253,245,230)
Color.IndexColor("PAPAYA_WHIP",255,239,213)
Color.IndexColor("SEA_SHELL",255,245,238)
Color.IndexColor("MINT_CREAM",245,255,250)
Color.IndexColor("SLATE_GRAY",112,128,144)
Color.IndexColor("LIGHT_SLATE_GRAY",119,136,153)
Color.IndexColor("LIGHT_STEEL_BLUE",176,196,222)
Color.IndexColor("LAVENDEr(",230,230,250)
Color.IndexColor("FLORAL_WHITE",255,250,240)
Color.IndexColor("ALICE_BLUE",240,248,255)
Color.IndexColor("GHOST_WHITE",248,248,255)
Color.IndexColor("HONEYDEW",240,255,240)
Color.IndexColor("IVORY",255,255,240)
Color.IndexColor("AZURE",240,255,255)
Color.IndexColor("SNOW",255,250,250)
Color.IndexColor("DIM_GRAY",105,105,105)
Color.IndexColor("GRAY",128,128,128)
Color.IndexColor("DARK_GRAY",169,169,169)
Color.IndexColor("SILVEr(",192,192,192)
Color.IndexColor("LIGHT_GRAY",211,211,211)
Color.IndexColor("GAINSBORO",220,220,220)
Color.IndexColor("WHITE_SMOKE",245,245,245)
Color.IndexColor("AliceBlue","f0f8ff")
Color.IndexColor("AntiqueWhite","faebd7")
Color.IndexColor("AntiqueWhite1","ffefdb")
Color.IndexColor("AntiqueWhite2","eedfcc")
Color.IndexColor("AntiqueWhite3","cdc0b0")
Color.IndexColor("AntiqueWhite4","8b8378")
Color.IndexColor("aquamarine1","7fffd4")
Color.IndexColor("aquamarine2","76eec6")
Color.IndexColor("aquamarine4","458b74")
Color.IndexColor("azure1","f0ffff")
Color.IndexColor("azure2","e0eeee")
Color.IndexColor("azure3","c1cdcd")
Color.IndexColor("azure4","838b8b")
Color.IndexColor("beige","f5f5dc")
Color.IndexColor("bisque1","ffe4c4")
Color.IndexColor("bisque2","eed5b7")
Color.IndexColor("bisque3","cdb79e")
Color.IndexColor("bisque4","8b7d6b")
Color.IndexColor("BlanchedAlmond","ffebcd")
Color.IndexColor("blue1","0000ff")
Color.IndexColor("blue2","0000ee")
Color.IndexColor("blue4","00008b")
Color.IndexColor("BlueViolet","8a2be2")
Color.IndexColor("brown","a52a2a")
Color.IndexColor("brown1","ff4040")
Color.IndexColor("brown2","ee3b3b")
Color.IndexColor("brown3","cd3333")
Color.IndexColor("brown4","8b2323")
Color.IndexColor("burlywood","deb887")
Color.IndexColor("burlywood1","ffd39b")
Color.IndexColor("burlywood2","eec591")
Color.IndexColor("burlywood3","cdaa7d")
Color.IndexColor("burlywood4","8b7355")
Color.IndexColor("CadetBlue","5f9ea0")
Color.IndexColor("CadetBlue1","98f5ff")
Color.IndexColor("CadetBlue2","8ee5ee")
Color.IndexColor("CadetBlue3","7ac5cd")
Color.IndexColor("CadetBlue4","53868b")
Color.IndexColor("chartreuse1","7fff00")
Color.IndexColor("chartreuse2","76ee00")
Color.IndexColor("chartreuse3","66cd00")
Color.IndexColor("chartreuse4","458b00")
Color.IndexColor("chocolate","d2691e")
Color.IndexColor("chocolate1","ff7f24")
Color.IndexColor("chocolate2","ee7621")
Color.IndexColor("chocolate3","cd661d")
Color.IndexColor("coral","ff7f50")
Color.IndexColor("coral1","ff7256")
Color.IndexColor("coral2","ee6a50")
Color.IndexColor("coral3","cd5b45")
Color.IndexColor("coral4","8b3e2f")
Color.IndexColor("CornflowerBlue","6495ed")
Color.IndexColor("cornsilk1","fff8dc")
Color.IndexColor("cornsilk2","eee8cd")
Color.IndexColor("cornsilk3","cdc8b1")
Color.IndexColor("cornsilk4","8b8878")
Color.IndexColor("cyan1","00ffff")
Color.IndexColor("cyan2","00eeee")
Color.IndexColor("cyan3","00cdcd")
Color.IndexColor("cyan4","008b8b")
Color.IndexColor("DarkGoldenrod","b8860b")
Color.IndexColor("DarkGoldenrod1","ffb90f")
Color.IndexColor("DarkGoldenrod2","eead0e")
Color.IndexColor("DarkGoldenrod3","cd950c")
Color.IndexColor("DarkGoldenrod4","8b6508")
Color.IndexColor("DarkGreen","006400")
Color.IndexColor("DarkKhaki","bdb76b")
Color.IndexColor("DarkOliveGreen","556b2f")
Color.IndexColor("DarkOliveGreen1","caff70")
Color.IndexColor("DarkOliveGreen2","bcee68")
Color.IndexColor("DarkOliveGreen3","a2cd5a")
Color.IndexColor("DarkOliveGreen4","6e8b3d")
Color.IndexColor("DarkOrange","ff8c00")
Color.IndexColor("DarkOrange1","ff7f00")
Color.IndexColor("DarkOrange2","ee7600")
Color.IndexColor("DarkOrange3","cd6600")
Color.IndexColor("DarkOrange4","8b4500")
Color.IndexColor("DarkOrchid","9932cc")
Color.IndexColor("DarkOrchid1","bf3eff")
Color.IndexColor("DarkOrchid2","b23aee")
Color.IndexColor("DarkOrchid3","9a32cd")
Color.IndexColor("DarkOrchid4","68228b")
Color.IndexColor("DarkSalmon","e9967a")
Color.IndexColor("DarkSeaGreen","8fbc8f")
Color.IndexColor("DarkSeaGreen1","c1ffc1")
Color.IndexColor("DarkSeaGreen2","b4eeb4")
Color.IndexColor("DarkSeaGreen3","9bcd9b")
Color.IndexColor("DarkSeaGreen4","698b69")
Color.IndexColor("DarkSlateBlue","483d8b")
Color.IndexColor("DarkSlateGray","2f4f4f")
Color.IndexColor("DarkSlateGray1","97ffff")
Color.IndexColor("DarkSlateGray2","8deeee")
Color.IndexColor("DarkSlateGray3","79cdcd")
Color.IndexColor("DarkSlateGray4","528b8b")
Color.IndexColor("DarkTurquoise","00ced1")
Color.IndexColor("DarkViolet","9400d3")
Color.IndexColor("DeepPink1","ff1493")
Color.IndexColor("DeepPink2","ee1289")
Color.IndexColor("DeepPink3","cd1076")
Color.IndexColor("DeepPink4","8b0a50")
Color.IndexColor("DeepSkyBlue1","00bfff")
Color.IndexColor("DeepSkyBlue2","00b2ee")
Color.IndexColor("DeepSkyBlue3","009acd")
Color.IndexColor("DeepSkyBlue4","00688b")
Color.IndexColor("DimGray","696969")
Color.IndexColor("DodgerBlue1","1e90ff")
Color.IndexColor("DodgerBlue2","1c86ee")
Color.IndexColor("DodgerBlue3","1874cd")
Color.IndexColor("DodgerBlue4","104e8b")
Color.IndexColor("firebrick","b22222")
Color.IndexColor("firebrick1","ff3030")
Color.IndexColor("firebrick2","ee2c2c")
Color.IndexColor("firebrick3","cd2626")
Color.IndexColor("firebrick4","8b1a1a")
Color.IndexColor("FloralWhite","fffaf0")
Color.IndexColor("ForestGreen","228b22")
Color.IndexColor("gainsboro","dcdcdc")
Color.IndexColor("GhostWhite","f8f8ff")
Color.IndexColor("gold1","ffd700")
Color.IndexColor("gold2","eec900")
Color.IndexColor("gold3","cdad00")
Color.IndexColor("gold4","8b7500")
Color.IndexColor("goldenrod","daa520")
Color.IndexColor("goldenrod1","ffc125")
Color.IndexColor("goldenrod2","eeb422")
Color.IndexColor("goldenrod3","cd9b1d")
Color.IndexColor("goldenrod4","8b6914")
Color.IndexColor("gray","bebebe")
Color.IndexColor("gray1","030303")
Color.IndexColor("gray10","1a1a1a")
Color.IndexColor("gray11","1c1c1c")
Color.IndexColor("gray12","1f1f1f")
Color.IndexColor("gray13","212121")
Color.IndexColor("gray14","242424")
Color.IndexColor("gray15","262626")
Color.IndexColor("gray16","292929")
Color.IndexColor("gray17","2b2b2b")
Color.IndexColor("gray18","2e2e2e")
Color.IndexColor("gray19","303030")
Color.IndexColor("gray2","050505")
Color.IndexColor("gray20","333333")
Color.IndexColor("gray21","363636")
Color.IndexColor("gray22","383838")
Color.IndexColor("gray23","3b3b3b")
Color.IndexColor("gray24","3d3d3d")
Color.IndexColor("gray25","404040")
Color.IndexColor("gray26","424242")
Color.IndexColor("gray27","454545")
Color.IndexColor("gray28","474747")
Color.IndexColor("gray29","4a4a4a")
Color.IndexColor("gray3","080808")
Color.IndexColor("gray30","4d4d4d")
Color.IndexColor("gray31","4f4f4f")
Color.IndexColor("gray32","525252")
Color.IndexColor("gray33","545454")
Color.IndexColor("gray34","575757")
Color.IndexColor("gray35","595959")
Color.IndexColor("gray36","5c5c5c")
Color.IndexColor("gray37","5e5e5e")
Color.IndexColor("gray38","616161")
Color.IndexColor("gray39","636363")
Color.IndexColor("gray4","0a0a0a")
Color.IndexColor("gray40","666666")
Color.IndexColor("gray41","696969")
Color.IndexColor("gray42","6b6b6b")
Color.IndexColor("gray43","6e6e6e")
Color.IndexColor("gray44","707070")
Color.IndexColor("gray45","737373")
Color.IndexColor("gray46","757575")
Color.IndexColor("gray47","787878")
Color.IndexColor("gray48","7a7a7a")
Color.IndexColor("gray49","7d7d7d")
Color.IndexColor("gray5","0d0d0d")
Color.IndexColor("gray50","7f7f7f")
Color.IndexColor("gray51","828282")
Color.IndexColor("gray52","858585")
Color.IndexColor("gray53","878787")
Color.IndexColor("gray54","8a8a8a")
Color.IndexColor("gray55","8c8c8c")
Color.IndexColor("gray56","8f8f8f")
Color.IndexColor("gray57","919191")
Color.IndexColor("gray58","949494")
Color.IndexColor("gray59","969696")
Color.IndexColor("gray6","0f0f0f")
Color.IndexColor("gray60","999999")
Color.IndexColor("gray61","9c9c9c")
Color.IndexColor("gray62","9e9e9e")
Color.IndexColor("gray63","a1a1a1")
Color.IndexColor("gray64","a3a3a3")
Color.IndexColor("gray65","a6a6a6")
Color.IndexColor("gray66","a8a8a8")
Color.IndexColor("gray67","ababab")
Color.IndexColor("gray68","adadad")
Color.IndexColor("gray69","b0b0b0")
Color.IndexColor("gray7","121212")
Color.IndexColor("gray70","b3b3b3")
Color.IndexColor("gray71","b5b5b5")
Color.IndexColor("gray72","b8b8b8")
Color.IndexColor("gray73","bababa")
Color.IndexColor("gray74","bdbdbd")
Color.IndexColor("gray75","bfbfbf")
Color.IndexColor("gray76","c2c2c2")
Color.IndexColor("gray77","c4c4c4")
Color.IndexColor("gray78","c7c7c7")
Color.IndexColor("gray79","c9c9c9")
Color.IndexColor("gray8","141414")
Color.IndexColor("gray80","cccccc")
Color.IndexColor("gray81","cfcfcf")
Color.IndexColor("gray82","d1d1d1")
Color.IndexColor("gray83","d4d4d4")
Color.IndexColor("gray84","d6d6d6")
Color.IndexColor("gray85","d9d9d9")
Color.IndexColor("gray86","dbdbdb")
Color.IndexColor("gray87","dedede")
Color.IndexColor("gray88","e0e0e0")
Color.IndexColor("gray89","e3e3e3")
Color.IndexColor("gray9","171717")
Color.IndexColor("gray90","e5e5e5")
Color.IndexColor("gray91","e8e8e8")
Color.IndexColor("gray92","ebebeb")
Color.IndexColor("gray93","ededed")
Color.IndexColor("gray94","f0f0f0")
Color.IndexColor("gray95","f2f2f2")
Color.IndexColor("gray97","f7f7f7")
Color.IndexColor("gray98","fafafa")
Color.IndexColor("gray99","fcfcfc")
Color.IndexColor("green1","00ff00")
Color.IndexColor("green2","00ee00")
Color.IndexColor("green3","00cd00")
Color.IndexColor("green4","008b00")
Color.IndexColor("GreenYellow","adff2f")
Color.IndexColor("honeydew1","f0fff0")
Color.IndexColor("honeydew2","e0eee0")
Color.IndexColor("honeydew3","c1cdc1")
Color.IndexColor("honeydew4","838b83")
Color.IndexColor("HotPink","ff69b4")
Color.IndexColor("HotPink1","ff6eb4")
Color.IndexColor("HotPink2","ee6aa7")
Color.IndexColor("HotPink3","cd6090")
Color.IndexColor("HotPink4","8b3a62")
Color.IndexColor("IndianRed","cd5c5c")
Color.IndexColor("IndianRed1","ff6a6a")
Color.IndexColor("IndianRed2","ee6363")
Color.IndexColor("IndianRed3","cd5555")
Color.IndexColor("IndianRed4","8b3a3a")
Color.IndexColor("ivory1","fffff0")
Color.IndexColor("ivory2","eeeee0")
Color.IndexColor("ivory3","cdcdc1")
Color.IndexColor("ivory4","8b8b83")
Color.IndexColor("khaki","f0e68c")
Color.IndexColor("khaki1","fff68f")
Color.IndexColor("khaki2","eee685")
Color.IndexColor("khaki3","cdc673")
Color.IndexColor("khaki4","8b864e")
Color.IndexColor("lavender","e6e6fa")
Color.IndexColor("LavenderBlush1","fff0f5")
Color.IndexColor("LavenderBlush2","eee0e5")
Color.IndexColor("LavenderBlush3","cdc1c5")
Color.IndexColor("LavenderBlush4","8b8386")
Color.IndexColor("LawnGreen","7cfc00")
Color.IndexColor("LemonChiffon1","fffacd")
Color.IndexColor("LemonChiffon2","eee9bf")
Color.IndexColor("LemonChiffon3","cdc9a5")
Color.IndexColor("LemonChiffon4","8b8970")
Color.IndexColor("light","eedd82")
Color.IndexColor("LightBlue","add8e6")
Color.IndexColor("LightBlue1","bfefff")
Color.IndexColor("LightBlue2","b2dfee")
Color.IndexColor("LightBlue3","9ac0cd")
Color.IndexColor("LightBlue4","68838b")
Color.IndexColor("LightCoral","f08080")
Color.IndexColor("LightCyan1","e0ffff")
Color.IndexColor("LightCyan2","d1eeee")
Color.IndexColor("LightCyan3","b4cdcd")
Color.IndexColor("LightCyan4","7a8b8b")
Color.IndexColor("LightGoldenrod1","ffec8b")
Color.IndexColor("LightGoldenrod2","eedc82")
Color.IndexColor("LightGoldenrod3","cdbe70")
Color.IndexColor("LightGoldenrod4","8b814c")
Color.IndexColor("LightGoldenrodYellow","fafad2")
Color.IndexColor("LightGray","d3d3d3")
Color.IndexColor("LightPink","ffb6c1")
Color.IndexColor("LightPink1","ffaeb9")
Color.IndexColor("LightPink2","eea2ad")
Color.IndexColor("LightPink3","cd8c95")
Color.IndexColor("LightPink4","8b5f65")
Color.IndexColor("LightSalmon1","ffa07a")
Color.IndexColor("LightSalmon2","ee9572")
Color.IndexColor("LightSalmon3","cd8162")
Color.IndexColor("LightSalmon4","8b5742")
Color.IndexColor("LightSeaGreen","20b2aa")
Color.IndexColor("LightSkyBlue","87cefa")
Color.IndexColor("LightSkyBlue1","b0e2ff")
Color.IndexColor("LightSkyBlue2","a4d3ee")
Color.IndexColor("LightSkyBlue3","8db6cd")
Color.IndexColor("LightSkyBlue4","607b8b")
Color.IndexColor("LightSlateBlue","8470ff")
Color.IndexColor("LightSlateGray","778899")
Color.IndexColor("LightSteelBlue","b0c4de")
Color.IndexColor("LightSteelBlue1","cae1ff")
Color.IndexColor("LightSteelBlue2","bcd2ee")
Color.IndexColor("LightSteelBlue3","a2b5cd")
Color.IndexColor("LightSteelBlue4","6e7b8b")
Color.IndexColor("LightYellow1","ffffe0")
Color.IndexColor("LightYellow2","eeeed1")
Color.IndexColor("LightYellow3","cdcdb4")
Color.IndexColor("LightYellow4","8b8b7a")
Color.IndexColor("LimeGreen","32cd32")
Color.IndexColor("linen","faf0e6")
Color.IndexColor("magenta","ff00ff")
Color.IndexColor("magenta2","ee00ee")
Color.IndexColor("magenta3","cd00cd")
Color.IndexColor("magenta4","8b008b")
Color.IndexColor("maroon","b03060")
Color.IndexColor("maroon1","ff34b3")
Color.IndexColor("maroon2","ee30a7")
Color.IndexColor("maroon3","cd2990")
Color.IndexColor("maroon4","8b1c62")
Color.IndexColor("medium","66cdaa")
Color.IndexColor("MediumAquamarine","66cdaa")
Color.IndexColor("MediumBlue","0000cd")
Color.IndexColor("MediumOrchid","ba55d3")
Color.IndexColor("MediumOrchid1","e066ff")
Color.IndexColor("MediumOrchid2","d15fee")
Color.IndexColor("MediumOrchid3","b452cd")
Color.IndexColor("MediumOrchid4","7a378b")
Color.IndexColor("MediumPurple","9370db")
Color.IndexColor("MediumPurple1","ab82ff")
Color.IndexColor("MediumPurple2","9f79ee")
Color.IndexColor("MediumPurple3","8968cd")
Color.IndexColor("MediumPurple4","5d478b")
Color.IndexColor("MediumSeaGreen","3cb371")
Color.IndexColor("MediumSlateBlue","7b68ee")
Color.IndexColor("MediumSpringGreen","00fa9a")
Color.IndexColor("MediumTurquoise","48d1cc")
Color.IndexColor("MediumVioletRed","c71585")
Color.IndexColor("MidnightBlue","191970")
Color.IndexColor("MintCream","f5fffa")
Color.IndexColor("MistyRose1","ffe4e1")
Color.IndexColor("MistyRose2","eed5d2")
Color.IndexColor("MistyRose3","cdb7b5")
Color.IndexColor("MistyRose4","8b7d7b")
Color.IndexColor("moccasin","ffe4b5")
Color.IndexColor("NavajoWhite1","ffdead")
Color.IndexColor("NavajoWhite2","eecfa1")
Color.IndexColor("NavajoWhite3","cdb38b")
Color.IndexColor("NavajoWhite4","8b795e")
Color.IndexColor("NavyBlue","000080")
Color.IndexColor("OldLace","fdf5e6")
Color.IndexColor("OliveDrab","6b8e23")
Color.IndexColor("OliveDrab1","c0ff3e")
Color.IndexColor("OliveDrab2","b3ee3a")
Color.IndexColor("OliveDrab4","698b22")
Color.IndexColor("orange1","ffa500")
Color.IndexColor("orange2","ee9a00")
Color.IndexColor("orange3","cd8500")
Color.IndexColor("orange4","8b5a00")
Color.IndexColor("OrangeRed1","ff4500")
Color.IndexColor("OrangeRed2","ee4000")
Color.IndexColor("OrangeRed3","cd3700")
Color.IndexColor("OrangeRed4","8b2500")
Color.IndexColor("orchid","da70d6")
Color.IndexColor("orchid1","ff83fa")
Color.IndexColor("orchid2","ee7ae9")
Color.IndexColor("orchid3","cd69c9")
Color.IndexColor("orchid4","8b4789")
Color.IndexColor("pale","db7093")
Color.IndexColor("PaleGoldenrod","eee8aa")
Color.IndexColor("PaleGreen","98fb98")
Color.IndexColor("PaleGreen1","9aff9a")
Color.IndexColor("PaleGreen2","90ee90")
Color.IndexColor("PaleGreen3","7ccd7c")
Color.IndexColor("PaleGreen4","548b54")
Color.IndexColor("PaleTurquoise","afeeee")
Color.IndexColor("PaleTurquoise1","bbffff")
Color.IndexColor("PaleTurquoise2","aeeeee")
Color.IndexColor("PaleTurquoise3","96cdcd")
Color.IndexColor("PaleTurquoise4","668b8b")
Color.IndexColor("PaleVioletRed","db7093")
Color.IndexColor("PaleVioletRed1","ff82ab")
Color.IndexColor("PaleVioletRed2","ee799f")
Color.IndexColor("PaleVioletRed3","cd6889")
Color.IndexColor("PaleVioletRed4","8b475d")
Color.IndexColor("PapayaWhip","ffefd5")
Color.IndexColor("PeachPuff1","ffdab9")
Color.IndexColor("PeachPuff2","eecbad")
Color.IndexColor("PeachPuff3","cdaf95")
Color.IndexColor("PeachPuff4","8b7765")
Color.IndexColor("pink","ffc0cb")
Color.IndexColor("pink1","ffb5c5")
Color.IndexColor("pink2","eea9b8")
Color.IndexColor("pink3","cd919e")
Color.IndexColor("pink4","8b636c")
Color.IndexColor("plum","dda0dd")
Color.IndexColor("plum1","ffbbff")
Color.IndexColor("plum2","eeaeee")
Color.IndexColor("plum3","cd96cd")
Color.IndexColor("plum4","8b668b")
Color.IndexColor("PowderBlue","b0e0e6")
Color.IndexColor("purple","a020f0")
Color.IndexColor("purple1","9b30ff")
Color.IndexColor("purple2","912cee")
Color.IndexColor("purple3","7d26cd")
Color.IndexColor("purple4","551a8b")
Color.IndexColor("red1","ff0000")
Color.IndexColor("red2","ee0000")
Color.IndexColor("red3","cd0000")
Color.IndexColor("red4","8b0000")
Color.IndexColor("RosyBrown","bc8f8f")
Color.IndexColor("RosyBrown1","ffc1c1")
Color.IndexColor("RosyBrown2","eeb4b4")
Color.IndexColor("RosyBrown3","cd9b9b")
Color.IndexColor("RosyBrown4","8b6969")
Color.IndexColor("RoyalBlue","4169e1")
Color.IndexColor("RoyalBlue1","4876ff")
Color.IndexColor("RoyalBlue2","436eee")
Color.IndexColor("RoyalBlue3","3a5fcd")
Color.IndexColor("RoyalBlue4","27408b")
Color.IndexColor("SaddleBrown","8b4513")
Color.IndexColor("salmon","fa8072")
Color.IndexColor("salmon1","ff8c69")
Color.IndexColor("salmon2","ee8262")
Color.IndexColor("salmon3","cd7054")
Color.IndexColor("salmon4","8b4c39")
Color.IndexColor("SandyBrown","f4a460")
Color.IndexColor("SeaGreen1","54ff9f")
Color.IndexColor("SeaGreen2","4eee94")
Color.IndexColor("SeaGreen3","43cd80")
Color.IndexColor("SeaGreen4","2e8b57")
Color.IndexColor("seashell1","fff5ee")
Color.IndexColor("seashell2","eee5de")
Color.IndexColor("seashell3","cdc5bf")
Color.IndexColor("seashell4","8b8682")
Color.IndexColor("sienna","a0522d")
Color.IndexColor("sienna1","ff8247")
Color.IndexColor("sienna2","ee7942")
Color.IndexColor("sienna3","cd6839")
Color.IndexColor("sienna4","8b4726")
Color.IndexColor("SkyBlue","87ceeb")
Color.IndexColor("SkyBlue1","87ceff")
Color.IndexColor("SkyBlue2","7ec0ee")
Color.IndexColor("SkyBlue3","6ca6cd")
Color.IndexColor("SkyBlue4","4a708b")
Color.IndexColor("SlateBlue","6a5acd")
Color.IndexColor("SlateBlue1","836fff")
Color.IndexColor("SlateBlue2","7a67ee")
Color.IndexColor("SlateBlue3","6959cd")
Color.IndexColor("SlateBlue4","473c8b")
Color.IndexColor("SlateGray","708090")
Color.IndexColor("SlateGray1","c6e2ff")
Color.IndexColor("SlateGray2","b9d3ee")
Color.IndexColor("SlateGray3","9fb6cd")
Color.IndexColor("SlateGray4","6c7b8b")
Color.IndexColor("snow1","fffafa")
Color.IndexColor("snow2","eee9e9")
Color.IndexColor("snow3","cdc9c9")
Color.IndexColor("snow4","8b8989")
Color.IndexColor("SpringGreen1","00ff7f")
Color.IndexColor("SpringGreen2","00ee76")
Color.IndexColor("SpringGreen3","00cd66")
Color.IndexColor("SpringGreen4","008b45")
Color.IndexColor("SteelBlue","4682b4")
Color.IndexColor("SteelBlue1","63b8ff")
Color.IndexColor("SteelBlue2","5cacee")
Color.IndexColor("SteelBlue3","4f94cd")
Color.IndexColor("SteelBlue4","36648b")
Color.IndexColor("tan","d2b48c")
Color.IndexColor("tan1","ffa54f")
Color.IndexColor("tan2","ee9a49")
Color.IndexColor("tan3","cd853f")
Color.IndexColor("tan4","8b5a2b")
Color.IndexColor("thistle","d8bfd8")
Color.IndexColor("thistle1","ffe1ff")
Color.IndexColor("thistle2","eed2ee")
Color.IndexColor("thistle3","cdb5cd")
Color.IndexColor("thistle4","8b7b8b")
Color.IndexColor("tomato1","ff6347")
Color.IndexColor("tomato2","ee5c42")
Color.IndexColor("tomato3","cd4f39")
Color.IndexColor("tomato4","8b3626")
Color.IndexColor("turquoise","40e0d0")
Color.IndexColor("turquoise1","00f5ff")
Color.IndexColor("turquoise2","00e5ee")
Color.IndexColor("turquoise3","00c5cd")
Color.IndexColor("turquoise4","00868b")
Color.IndexColor("violet","ee82ee")
Color.IndexColor("VioletRed","d02090")
Color.IndexColor("VioletRed1","ff3e96")
Color.IndexColor("VioletRed2","ee3a8c")
Color.IndexColor("VioletRed3","cd3278")
Color.IndexColor("VioletRed4","8b2252")
Color.IndexColor("wheat","f5deb3")
Color.IndexColor("wheat1","ffe7ba")
Color.IndexColor("wheat2","eed8ae")
Color.IndexColor("wheat3","cdba96")
Color.IndexColor("wheat4","8b7e66")
Color.IndexColor("WhiteSmoke","f5f5f5")
Color.IndexColor("yellow1","ffff00")
Color.IndexColor("yellow2","eeee00")
Color.IndexColor("yellow3","cdcd00")
Color.IndexColor("yellow4","8b8b00")
Color.IndexColor("YellowGreen","9acd32")
Color.IndexColor("purple","7e1e9c")
Color.IndexColor("green","15b01a")
Color.IndexColor("blue","0343df")
Color.IndexColor("pink","ff81c0")
Color.IndexColor("brown","653700")
Color.IndexColor("red","e50000")
Color.IndexColor("light_blue","95d0fc")
Color.IndexColor("teal","029386")
Color.IndexColor("orange","f97306")
Color.IndexColor("light_green","96f97b")
Color.IndexColor("magenta","c20078")
Color.IndexColor("yellow","ffff14")
Color.IndexColor("sky_blue","75bbfd")
Color.IndexColor("grey","929591")
Color.IndexColor("lime_green","89fe05")
Color.IndexColor("light_purple","bf77f6")
Color.IndexColor("violet","9a0eea")
Color.IndexColor("dark_green","033500")
Color.IndexColor("turquoise","06c2ac")
Color.IndexColor("lavender","c79fef")
Color.IndexColor("dark_blue","00035b")
Color.IndexColor("tan","d1b26f")
Color.IndexColor("cyan","00ffff")
Color.IndexColor("aqua","13eac9")
Color.IndexColor("forest_green","06470c")
Color.IndexColor("mauve","ae7181")
Color.IndexColor("dark_purple","35063e")
Color.IndexColor("bright_green","01ff07")
Color.IndexColor("maroon","650021")
Color.IndexColor("olive","6e750e")
Color.IndexColor("salmon","ff796c")
Color.IndexColor("beige","e6daa6")
Color.IndexColor("royal_blue","0504aa")
Color.IndexColor("navy_blue","001146")
Color.IndexColor("lilac","cea2fd")
Color.IndexColor("black","000000")
Color.IndexColor("hot_pink","ff028d")
Color.IndexColor("light_brown","ad8150")
Color.IndexColor("pale_green","c7fdb5")
Color.IndexColor("peach","ffb07c")
Color.IndexColor("olive_green","677a04")
Color.IndexColor("dark_pink","cb416b")
Color.IndexColor("periwinkle","8e82fe")
Color.IndexColor("sea_green","53fca1")
Color.IndexColor("lime","aaff32")
Color.IndexColor("indigo","380282")
Color.IndexColor("mustard","ceb301")
Color.IndexColor("light_pink","ffd1df")
Color.IndexColor("rose","cf6275")
Color.IndexColor("bright_blue","0165fc")
Color.IndexColor("neon_green","0cff0c")
Color.IndexColor("burnt_orange","c04e01")
Color.IndexColor("aquamarine","04d8b2")
Color.IndexColor("navy","01153e")
Color.IndexColor("grass_green","3f9b0b")
Color.IndexColor("pale_blue","d0fefe")
Color.IndexColor("dark_red","840000")
Color.IndexColor("bright_purple","be03fd")
Color.IndexColor("yellow_green","c0fb2d")
Color.IndexColor("baby_blue","a2cffe")
Color.IndexColor("gold","dbb40c")
Color.IndexColor("mint_green","8fff9f")
Color.IndexColor("plum","580f41")
Color.IndexColor("royal_purple","4b006e")
Color.IndexColor("brick_red","8f1402")
Color.IndexColor("dark_teal","014d4e")
Color.IndexColor("burgundy","610023")
Color.IndexColor("khaki","aaa662")
Color.IndexColor("blue_green","137e6d")
Color.IndexColor("seafoam_green","7af9ab")
Color.IndexColor("kelly_green","02ab2e")
Color.IndexColor("puke_green","9aae07")
Color.IndexColor("pea_green","8eab12")
Color.IndexColor("taupe","b9a281")
Color.IndexColor("dark_brown","341c02")
Color.IndexColor("deep_purple","36013f")
Color.IndexColor("chartreuse","c1f80a")
Color.IndexColor("bright_pink","fe01b1")
Color.IndexColor("light_orange","fdaa48")
Color.IndexColor("mint","9ffeb0")
Color.IndexColor("pastel_green","b0ff9d")
Color.IndexColor("sand","e2ca76")
Color.IndexColor("dark_orange","c65102")
Color.IndexColor("spring_green","a9f971")
Color.IndexColor("puce","a57e52")
Color.IndexColor("seafoam","80f9ad")
Color.IndexColor("grey_blue","6b8ba4")
Color.IndexColor("army_green","4b5d16")
Color.IndexColor("dark_grey","363737")
Color.IndexColor("dark_yellow","d5b60a")
Color.IndexColor("goldenrod","fac205")
Color.IndexColor("slate","516572")
Color.IndexColor("light_teal","90e4c1")
Color.IndexColor("rust","a83c09")
Color.IndexColor("deep_blue","040273")
Color.IndexColor("pale_pink","ffcfdc")
Color.IndexColor("cerulean","0485d1")
Color.IndexColor("light_red","ff474c")
Color.IndexColor("mustard_yellow","d2bd0a")
Color.IndexColor("ochre","bf9005")
Color.IndexColor("pale_yellow","ffff84")
Color.IndexColor("crimson","8c000f")
Color.IndexColor("fuchsia","ed0dd9")
Color.IndexColor("hunter_green","0b4008")
Color.IndexColor("blue_grey","607c8e")
Color.IndexColor("slate_blue","5b7c99")
Color.IndexColor("pale_purple","b790d4")
Color.IndexColor("sea_blue","047495")
Color.IndexColor("pinkish_purple","d648d7")
Color.IndexColor("puke","a5a502")
Color.IndexColor("light_grey","d8dcd6")
Color.IndexColor("leaf_green","5ca904")
Color.IndexColor("light_yellow","fffe7a")
Color.IndexColor("eggplant","380835")
Color.IndexColor("steel_blue","5a7d9a")
Color.IndexColor("moss_green","658b38")
Color.IndexColor("robin's_egg_blue","98eff9")
Color.IndexColor("white","ffffff")
Color.IndexColor("grey_green","789b73")
Color.IndexColor("sage","87ae73")
Color.IndexColor("brick","a03623")
Color.IndexColor("burnt_sienna","b04e0f")
Color.IndexColor("reddish_brown","7f2b0a")
Color.IndexColor("cream","ffffc2")
Color.IndexColor("coral","fc5a50")
Color.IndexColor("ocean_blue","03719c")
Color.IndexColor("greenish","40a368")
Color.IndexColor("dark_magenta","960056")
Color.IndexColor("red_orange","fd3c06")
Color.IndexColor("bluish_purple","703be7")
Color.IndexColor("midnight_blue","020035")
Color.IndexColor("light_violet","d6b4fc")
Color.IndexColor("dusty_rose","c0737a")
Color.IndexColor("medium_blue","2c6fbb")
Color.IndexColor("greenish_yellow","cdfd02")
Color.IndexColor("yellowish_green","b0dd16")
Color.IndexColor("purplish_blue","601ef9")
Color.IndexColor("greyish_blue","5e819d")
Color.IndexColor("grape","6c3461")
Color.IndexColor("light_olive","acbf69")
Color.IndexColor("cornflower_blue","5170d7")
Color.IndexColor("pinkish_red","f10c45")
Color.IndexColor("bright_red","ff000d")
Color.IndexColor("azure","069af3")
Color.IndexColor("blue_purple","5729ce")
Color.IndexColor("dark_turquoise","045c5a")
Color.IndexColor("electric_blue","0652ff")
Color.IndexColor("off_white","ffffe4")
Color.IndexColor("powder_blue","b1d1fc")
Color.IndexColor("wine","80013f")
Color.IndexColor("dull_green","74a662")
Color.IndexColor("apple_green","76cd26")
Color.IndexColor("light_turquoise","7ef4cc")
Color.IndexColor("neon_purple","bc13fe")
Color.IndexColor("cobalt","1e488f")
Color.IndexColor("pinkish","d46a7e")
Color.IndexColor("olive_drab","6f7632")
Color.IndexColor("dark_cyan","0a888a")
Color.IndexColor("purple_blue","632de9")
Color.IndexColor("dark_violet","34013f")
Color.IndexColor("dark_lavender","856798")
Color.IndexColor("forrest_green","154406")
Color.IndexColor("vomit","a2a415")
Color.IndexColor("pale_orange","ffa756")
Color.IndexColor("greenish_blue","0b8b87")
Color.IndexColor("dark_tan","af884a")
Color.IndexColor("green_blue","06b48b")
Color.IndexColor("bluish_green","10a674")
Color.IndexColor("pastel_blue","a2bffe")
Color.IndexColor("moss","769958")
Color.IndexColor("grass","5cac2d")
Color.IndexColor("deep_pink","cb0162")
Color.IndexColor("blood_red","980002")
Color.IndexColor("sage_green","88b378")
Color.IndexColor("aqua_blue","02d8e9")
Color.IndexColor("terracotta","ca6641")
Color.IndexColor("pastel_purple","caa0ff")
Color.IndexColor("sienna","a9561e")
Color.IndexColor("dark_olive","373e02")
Color.IndexColor("green_yellow","c9ff27")
Color.IndexColor("scarlet","be0119")
Color.IndexColor("greyish_green","82a67d")
Color.IndexColor("chocolate","3d1c02")
Color.IndexColor("blue_violet","5d06e9")
Color.IndexColor("cornflower","6a79f7")
Color.IndexColor("baby_pink","ffb7ce")
Color.IndexColor("charcoal","343837")
Color.IndexColor("pine_green","0a481e")
Color.IndexColor("pumpkin","e17701")
Color.IndexColor("greenish_brown","696112")
Color.IndexColor("red_brown","8b2e16")
Color.IndexColor("brownish_green","6a6e09")
Color.IndexColor("tangerine","ff9408")
Color.IndexColor("salmon_pink","fe7b7c")
Color.IndexColor("aqua_green","12e193")
Color.IndexColor("raspberry","b00149")
Color.IndexColor("greyish_purple","887191")
Color.IndexColor("rose_pink","f7879a")
Color.IndexColor("neon_pink","fe019a")
Color.IndexColor("cobalt_blue","030aa7")
Color.IndexColor("orange_brown","be6400")
Color.IndexColor("deep_red","9a0200")
Color.IndexColor("orange_red","fd411e")
Color.IndexColor("dirty_yellow","cdc50a")
Color.IndexColor("orchid","c875c4")
Color.IndexColor("reddish_pink","fe2c54")
Color.IndexColor("reddish_purple","910951")
Color.IndexColor("yellow_orange","fcb001")
Color.IndexColor("light_cyan","acfffc")
Color.IndexColor("sky","82cafc")
Color.IndexColor("light_magenta","fa5ff7")
Color.IndexColor("pale_red","d9544d")
Color.IndexColor("emerald","01a049")
Color.IndexColor("dark_beige","ac9362")
Color.IndexColor("ugly_green","7a9703")
Color.IndexColor("jade","1fa774")
Color.IndexColor("greenish_grey","96ae8d")
Color.IndexColor("dark_salmon","c85a53")
Color.IndexColor("purplish_pink","ce5dae")
Color.IndexColor("dark_aqua","05696b")
Color.IndexColor("brownish_orange","cb7723")
Color.IndexColor("light_olive_green","a4be5c")
Color.IndexColor("light_aqua","8cffdb")
Color.IndexColor("clay","b66a50")
Color.IndexColor("medium_green","39ad48")
Color.IndexColor("burnt_umber","a0450e")
Color.IndexColor("dull_blue","49759c")
Color.IndexColor("pale_brown","b1916e")
Color.IndexColor("emerald_green","028f1e")
Color.IndexColor("brownish","9c6d57")
Color.IndexColor("mud","735c12")
Color.IndexColor("dark_rose","b5485d")
Color.IndexColor("brownish_red","9e3623")
Color.IndexColor("pink_purple","db4bda")
Color.IndexColor("pinky_purple","c94cbe")
Color.IndexColor("camo_green","526525")
Color.IndexColor("faded_green","7bb274")
Color.IndexColor("dusty_pink","d58a94")
Color.IndexColor("purple_pink","e03fd8")
Color.IndexColor("vomit_green","89a203")
Color.IndexColor("deep_green","02590f")
Color.IndexColor("reddish_orange","f8481c")
Color.IndexColor("mahogany","4a0100")
Color.IndexColor("aubergine","3d0734")
Color.IndexColor("dull_pink","d5869d")
Color.IndexColor("evergreen","05472a")
Color.IndexColor("dark_sky_blue","448ee4")
Color.IndexColor("very_light_green","d1ffbd")
Color.IndexColor("pastel_pink","ffbacd")
Color.IndexColor("grey_purple","826d8c")
Color.IndexColor("very_light_blue","d5ffff")
Color.IndexColor("dark_mauve","874c62")
Color.IndexColor("cadet_blue","4e7496")
Color.IndexColor("ice_blue","d7fffe")
Color.IndexColor("light_tan","fbeeac")
Color.IndexColor("dirty_green","667e2c")
Color.IndexColor("neon_blue","04d9ff")
Color.IndexColor("wine_red","7b0323")
Color.IndexColor("chocolate_brown","411900")
Color.IndexColor("dull_purple","84597e")
Color.IndexColor("yellow_brown","b79400")
Color.IndexColor("denim","3b638c")
Color.IndexColor("eggshell","ffffd4")
Color.IndexColor("jungle_green","048243")
Color.IndexColor("dark_peach","de7e5d")
Color.IndexColor("poop","7f5e00")
Color.IndexColor("umber","b26400")
Color.IndexColor("light_lavender","dfc5fe")
Color.IndexColor("bright_yellow","fffd01")
Color.IndexColor("golden_yellow","fec615")
Color.IndexColor("dusty_blue","5a86ad")
Color.IndexColor("electric_green","21fc0d")
Color.IndexColor("lighter_green","75fd63")
Color.IndexColor("slate_grey","59656d")
Color.IndexColor("teal_green","25a36f")
Color.IndexColor("marine_blue","01386a")
Color.IndexColor("avocado","90b134")
Color.IndexColor("terra_cotta","c9643b")
Color.IndexColor("dusty_purple","825f87")
Color.IndexColor("light_maroon","a24857")
Color.IndexColor("reddish","c44240")
Color.IndexColor("dark_lilac","9c6da5")
Color.IndexColor("dark_periwinkle","665fd1")
Color.IndexColor("bluish_grey","748b97")
Color.IndexColor("puke_yellow","c2be0e")
Color.IndexColor("purplish","94568c")
Color.IndexColor("ultramarine","2000b1")
Color.IndexColor("barney_purple","a00498")
Color.IndexColor("forest","0b5509")
Color.IndexColor("pea_soup","929901")
Color.IndexColor("brownish_yellow","c9b003")
Color.IndexColor("bright_teal","01f9c6")
Color.IndexColor("bluegreen","017a79")
Color.IndexColor("green_brown","544e03")
Color.IndexColor("blurple","5539cc")
Color.IndexColor("light_sky_blue","c6fcff")
Color.IndexColor("periwinkle_blue","8f99fb")
Color.IndexColor("pale_violet","ceaefa")
Color.IndexColor("darker_green","087804")
Color.IndexColor("true_blue","010fcc")
Color.IndexColor("green_grey","77926f")
Color.IndexColor("grey_brown","7f7053")
Color.IndexColor("dark_olive_green","3c4d03")
Color.IndexColor("apricot","ffb16d")
Color.IndexColor("faded_purple","916e99")
Color.IndexColor("darker_blue","011288")
Color.IndexColor("cerise","de0c62")
Color.IndexColor("khaki_green","728639")
Color.IndexColor("burnt_red","9f2305")
Color.IndexColor("light_forest_green","4f9153")
Color.IndexColor("violet_blue","510ac9")
Color.IndexColor("pale_lavender","eecffe")
Color.IndexColor("acid_green","8ffe09")
Color.IndexColor("purple_grey","866f85")
Color.IndexColor("lemon","fdff52")
Color.IndexColor("bright_orange","ff5b00")
Color.IndexColor("soft_green","6fc276")
Color.IndexColor("blush","f29e8e")
Color.IndexColor("yellowish_brown","9b7a01")
Color.IndexColor("fluorescent_green","08ff08")
Color.IndexColor("electric_purple","aa23ff")
Color.IndexColor("steel","738595")
Color.IndexColor("dull_orange","d8863b")
Color.IndexColor("muddy_green","657432")
Color.IndexColor("marigold","fcc006")
Color.IndexColor("ocean","017b92")
Color.IndexColor("light_mauve","c292a1")
Color.IndexColor("bordeaux","7b002c")
Color.IndexColor("light_blue_green","7efbb3")
Color.IndexColor("yellowish","faee66")
Color.IndexColor("snot_green","9dc100")
Color.IndexColor("light_lime_green","b9ff66")
Color.IndexColor("drab_green","749551")
Color.IndexColor("faded_blue","658cbb")
Color.IndexColor("dark_forest_green","002d04")
Color.IndexColor("hot_purple","cb00f5")
Color.IndexColor("dark_maroon","3c0008")
Color.IndexColor("brown_green","706c11")
Color.IndexColor("swamp_green","748500")
Color.IndexColor("light_indigo","6d5acf")
Color.IndexColor("purpley_blue","5f34e7")
Color.IndexColor("lightish_blue","3d7afd")
Color.IndexColor("teal_blue","01889f")
Color.IndexColor("denim_blue","3b5b92")
Color.IndexColor("dark_lime_green","7ebd01")
Color.IndexColor("dull_yellow","eedc5b")
Color.IndexColor("pistachio","c0fa8b")
Color.IndexColor("lemon_yellow","fdff38")
Color.IndexColor("red_violet","9e0168")
Color.IndexColor("dusky_pink","cc7a8b")
Color.IndexColor("dirt","8a6e45")
Color.IndexColor("very_dark_green","062e03")
Color.IndexColor("medium_purple","9e43a2")
Color.IndexColor("shit","7f5f00")
Color.IndexColor("dark_mustard","a88905")
Color.IndexColor("pea_soup_green","94a617")
Color.IndexColor("bubblegum_pink","fe83cc")
Color.IndexColor("barbie_pink","fe46a5")
Color.IndexColor("military_green","667c3e")
Color.IndexColor("pale_teal","82cbb2")
Color.IndexColor("bronze","a87900")
Color.IndexColor("pinky_red","fc2647")
Color.IndexColor("dull_red","bb3f3f")
Color.IndexColor("darkish_blue","014182")
Color.IndexColor("bluish","2976bb")
Color.IndexColor("dark_gold","b59410")
Color.IndexColor("yellowy_green","bff128")
Color.IndexColor("pine","2b5d34")
Color.IndexColor("dark_blue_green","005249")
Color.IndexColor("dirty_pink","ca7b80")
Color.IndexColor("slate_green","658d6d")
Color.IndexColor("prussian_blue","004577")
Color.IndexColor("bright_violet","ad0afd")
Color.IndexColor("lighter_purple","a55af4")
Color.IndexColor("steel_grey","6f828a")
Color.IndexColor("russet","a13905")
Color.IndexColor("vermillion","f4320c")
Color.IndexColor("greyish_brown","7a6a4f")
Color.IndexColor("red_purple","820747")
Color.IndexColor("red_pink","fa2a55")
Color.IndexColor("bright_turquoise","0ffef9")
Color.IndexColor("golden_brown","b27a01")
Color.IndexColor("cerulean_blue","056eee")
Color.IndexColor("soft_blue","6488ea")
Color.IndexColor("easter_green","8cfd7e")
Color.IndexColor("amber","feb308")
Color.IndexColor("mid_blue","276ab3")
Color.IndexColor("shit_brown","7b5804")
Color.IndexColor("hospital_green","9be5aa")
Color.IndexColor("purpleish_blue","6140ef")
Color.IndexColor("purply_blue","661aee")
Color.IndexColor("silver","c5c9c7")
Color.IndexColor("sickly_green","94b21c")
Color.IndexColor("melon","ff7855")
Color.IndexColor("dusky_rose","ba6873")
Color.IndexColor("brown_orange","b96902")
Color.IndexColor("darkish_green","287c37")
Color.IndexColor("cranberry","9e003a")
Color.IndexColor("purpleish","98568d")
Color.IndexColor("ecru","feffca")
Color.IndexColor("darker_purple","5f1b6b")
Color.IndexColor("mocha","9d7651")
Color.IndexColor("bright_magenta","ff08e8")
Color.IndexColor("coffee","a6814c")
Color.IndexColor("sepia","985e2b")
Color.IndexColor("faded_red","d3494e")
Color.IndexColor("canary_yellow","fffe40")
Color.IndexColor("bluey_purple","6241c7")
Color.IndexColor("pastel_yellow","fffe71")
Color.IndexColor("pale_turquoise","a5fbd5")
Color.IndexColor("greyish_pink","c88d94")
Color.IndexColor("marine","042e60")
Color.IndexColor("purplish_grey","7a687f")
Color.IndexColor("camel","c69f59")
Color.IndexColor("brownish_grey","86775f")
Color.IndexColor("burnt_yellow","d5ab09")
Color.IndexColor("cherry_red","f7022a")
Color.IndexColor("orangey_brown","b16002")
Color.IndexColor("soft_pink","fdb0c0")
Color.IndexColor("dark_sea_green","11875d")
Color.IndexColor("aqua_marine","2ee8bb")
Color.IndexColor("robin_egg_blue","8af1fe")
Color.IndexColor("light_sea_green","98f6b0")
Color.IndexColor("mud_brown","60460f")
Color.IndexColor("sandstone","c9ae74")
Color.IndexColor("british_racing_green","05480d")
Color.IndexColor("faded_pink","de9dac")
Color.IndexColor("maize","f4d054")
Color.IndexColor("ocre","c69c04")
Color.IndexColor("orange_yellow","ffad01")
Color.IndexColor("dark_khaki","9b8f55")
Color.IndexColor("light_lime","aefd6c")
Color.IndexColor("bright_light_blue","26f7fd")
Color.IndexColor("jade_green","2baf6a")
Color.IndexColor("barney","ac1db8")
Color.IndexColor("adobe","bd6c48")
Color.IndexColor("minty_green","0bf77d")
Color.IndexColor("light_navy_blue","2e5a88")
Color.IndexColor("dusty_green","76a973")
Color.IndexColor("very_dark_blue","000133")
Color.IndexColor("ocean_green","3d9973")
Color.IndexColor("mustard_green","a8b504")
Color.IndexColor("poop_brown","7a5901")
Color.IndexColor("olive_brown","645403")
Color.IndexColor("pink_red","f5054f")
Color.IndexColor("light_navy","155084")
Color.IndexColor("very_light_purple","f6cefc")
Color.IndexColor("ivory","ffffcb")
Color.IndexColor("bright_lavender","c760ff")
Color.IndexColor("bright_aqua","0bf9ea")
Color.IndexColor("robin's_egg","6dedfd")
Color.IndexColor("muted_green","5fa052")
Color.IndexColor("medium_brown","7f5112")
Color.IndexColor("copper","b66325")
Color.IndexColor("dark_lime","84b701")
Color.IndexColor("strawberry","fb2943")
Color.IndexColor("dirt_brown","836539")
Color.IndexColor("celery","c1fd95")
Color.IndexColor("bright_sky_blue","02ccfe")
Color.IndexColor("poo_brown","885f01")
Color.IndexColor("pinkish_brown","b17261")
Color.IndexColor("celadon","befdb7")
Color.IndexColor("bright_lime_green","65fe08")
Color.IndexColor("auburn","9a3001")
Color.IndexColor("shocking_pink","fe02a2")
Color.IndexColor("mulberry","920a4e")
Color.IndexColor("carolina_blue","8ab8fe")
Color.IndexColor("lightish_green","61e160")
Color.IndexColor("light_lilac","edc8ff")
Color.IndexColor("pale_olive","b9cc81")
Color.IndexColor("pumpkin_orange","fb7d07")
Color.IndexColor("yellow_ochre","cb9d06")
Color.IndexColor("fire_engine_red","fe0002")
Color.IndexColor("deep_sky_blue","0d75f8")
Color.IndexColor("watermelon","fd4659")
Color.IndexColor("bottle_green","044a05")
Color.IndexColor("very_dark_purple","2a0134")
Color.IndexColor("wheat","fbdd7e")
Color.IndexColor("murky_green","6c7a0e")
Color.IndexColor("brownish_purple","76424e")
Color.IndexColor("kermit_green","5cb200")
Color.IndexColor("primary_blue","0804f9")
Color.IndexColor("orangey_red","fa4224")
Color.IndexColor("pale_lilac","e4cbff")
Color.IndexColor("rust_red","aa2704")
Color.IndexColor("dirty_orange","c87606")
Color.IndexColor("pinkish_grey","c8aca9")
Color.IndexColor("light_plum","9d5783")
Color.IndexColor("greeny_blue","42b395")
Color.IndexColor("dark_navy","000435")
Color.IndexColor("pink/purple","ef1de7")
Color.IndexColor("irish_green","019529")
Color.IndexColor("baby_poop","937c00")
Color.IndexColor("slime_green","99cc04")
Color.IndexColor("purplish_red","b0054b")
Color.IndexColor("rouge","ab1239")
Color.IndexColor("light_rose","ffc5cb")
Color.IndexColor("drab","828344")
Color.IndexColor("dark_navy_blue","00022e")
Color.IndexColor("light_yellow_green","ccfd7f")
Color.IndexColor("easter_purple","c071fe")
Color.IndexColor("snot","acbb0d")
Color.IndexColor("light_salmon","fea993")
Color.IndexColor("purpley_pink","c83cb9")
Color.IndexColor("poo","8f7303")
Color.IndexColor("berry","990f4b")
Color.IndexColor("medium_grey","7d7f7c")
Color.IndexColor("brown_red","922b05")
Color.IndexColor("blood","770001")
Color.IndexColor("soft_purple","a66fb5")
Color.IndexColor("grey_pink","c3909b")
Color.IndexColor("bluey_green","2bb179")
Color.IndexColor("midnight","03012d")
Color.IndexColor("dark_indigo","1f0954")
Color.IndexColor("warm_grey","978a84")
Color.IndexColor("sandy_brown","c4a661")
Color.IndexColor("cherry","cf0234")
Color.IndexColor("blue/purple","5a06ef")
Color.IndexColor("gunmetal","536267")
Color.IndexColor("deep_violet","490648")
Color.IndexColor("tree_green","2a7e19")
Color.IndexColor("orangish_brown","b25f03")
Color.IndexColor("shamrock_green","02c14d")
Color.IndexColor("orangish_red","f43605")
Color.IndexColor("greeny_yellow","c6f808")
Color.IndexColor("ugly_yellow","d0c101")
Color.IndexColor("french_blue","436bad")
Color.IndexColor("dusky_purple","895b7b")
Color.IndexColor("butter_yellow","fffd74")
Color.IndexColor("light_beige","fffeb6")
Color.IndexColor("golden","f5bf03")
Color.IndexColor("dusky_blue","475f94")
Color.IndexColor("lightblue","7bc8f6")
Color.IndexColor("purply_pink","f075e6")
Color.IndexColor("off_green","6ba353")
Color.IndexColor("ocher","bf9b0c")
Color.IndexColor("milk_chocolate","7f4e1e")
Color.IndexColor("light_peach","ffd8b1")
Color.IndexColor("deep_magenta","a0025c")
Color.IndexColor("caramel","af6f09")
Color.IndexColor("greenish_teal","32bf84")
Color.IndexColor("pale_lime","befd73")
Color.IndexColor("purple_red","990147")
Color.IndexColor("blueberry","464196")
Color.IndexColor("asparagus","77ab56")
Color.IndexColor("pale_grey","fdfdfe")
Color.IndexColor("light_grey_blue","9dbcd4")
Color.IndexColor("pale_lime_green","b1ff65")
Color.IndexColor("grassy_green","419c03")
Color.IndexColor("mossy_green","638b27")
Color.IndexColor("earth","a2653e")
Color.IndexColor("deep_orange","dc4d01")
Color.IndexColor("pale_aqua","b8ffeb")
Color.IndexColor("rose_red","be013c")
Color.IndexColor("stone","ada587")
Color.IndexColor("rusty_orange","cd5909")
Color.IndexColor("pea","a4bf20")
Color.IndexColor("sick_green","9db92c")
Color.IndexColor("darker_pink","c4387f")
Color.IndexColor("chestnut","742802")
Color.IndexColor("blue/green","0f9b8e")
Color.IndexColor("amethyst","9b5fc0")
Color.IndexColor("dark_mint_green","20c073")
Color.IndexColor("pale_rose","fdc1c5")
Color.IndexColor("muted_blue","3b719f")
Color.IndexColor("fawn","cfaf7b")
Color.IndexColor("buff","fef69e")
Color.IndexColor("turquoise_green","04f489")
Color.IndexColor("muddy_brown","886806")
Color.IndexColor("sea","3c9992")
Color.IndexColor("tomato","ef4026")
Color.IndexColor("carnation_pink","ff7fa7")
Color.IndexColor("banana","ffff7e")
Color.IndexColor("neon_yellow","cfff04")
Color.IndexColor("greyish","a8a495")
Color.IndexColor("mid_green","50a747")
Color.IndexColor("muted_purple","805b87")
Color.IndexColor("electric_pink","ff0490")
Color.IndexColor("sandy","f1da7a")
Color.IndexColor("ugly_pink","cd7584")
Color.IndexColor("turquoise_blue","06b1c4")
Color.IndexColor("light_burgundy","a8415b")
Color.IndexColor("greenish_tan","bccb7a")
Color.IndexColor("dark_mint","48c072")
Color.IndexColor("light_urple","b36ff6")
Color.IndexColor("midnight_purple","280137")
Color.IndexColor("pinkish_orange","ff724c")
Color.IndexColor("pear","cbf85f")
Color.IndexColor("dark_plum","3f012c")
Color.IndexColor("tealish","24bca8")
Color.IndexColor("perrywinkle","8f8ce7")
Color.IndexColor("yellowish_orange","ffab0f")
Color.IndexColor("pastel_orange","ff964f")
Color.IndexColor("iris","6258c4")
Color.IndexColor("ultramarine_blue","1805db")
Color.IndexColor("navy_green","35530a")
Color.IndexColor("seaweed","18d17b")
Color.IndexColor("kiwi","9cef43")
Color.IndexColor("fluro_green","0aff02")
Color.IndexColor("bright_light_green","2dfe54")
Color.IndexColor("vivid_green","2fef10")
Color.IndexColor("frog_green","58bc08")
Color.IndexColor("dull_brown","876e4b")
Color.IndexColor("dusk","4e5481")
Color.IndexColor("mustard_brown","ac7e04")
Color.IndexColor("leafy_green","51b73b")
Color.IndexColor("cool_blue","4984b8")
Color.IndexColor("almost_black","070d0d")
Color.IndexColor("yellow/green","c8fd3d")
Color.IndexColor("heliotrope","d94ff5")
Color.IndexColor("green_apple","5edc1f")
Color.IndexColor("baby_poop_green","8f9805")
Color.IndexColor("apple","6ecb3c")
Color.IndexColor("purpleish_pink","df4ec8")
Color.IndexColor("night_blue","040348")
Color.IndexColor("merlot","730039")
Color.IndexColor("lightgreen","76ff7b")
Color.IndexColor("tomato_red","ec2d01")
Color.IndexColor("key_lime","aeff6e")
Color.IndexColor("pale_cyan","b7fffa")
Color.IndexColor("vomit_yellow","c7c10c")
Color.IndexColor("purplish_brown","6b4247")
Color.IndexColor("bubblegum","ff6cb5")
Color.IndexColor("shamrock","01b44c")
Color.IndexColor("mango","ffa62b")
Color.IndexColor("lime_yellow","d0fe1d")
Color.IndexColor("hot_green","25ff29")
Color.IndexColor("grape_purple","5d1451")
Color.IndexColor("faded_orange","f0944d")
Color.IndexColor("avocado_green","87a922")
Color.IndexColor("peacock_blue","016795")
Color.IndexColor("weird_green","3ae57f")
Color.IndexColor("bright_lilac","c95efb")
Color.IndexColor("fern_green","548d44")
Color.IndexColor("dirty_blue","3f829d")
Color.IndexColor("rust_orange","c45508")
Color.IndexColor("heather","a484ac")
Color.IndexColor("deep_teal","00555a")
Color.IndexColor("dark_seafoam","1fb57a")
Color.IndexColor("baby_poo","ab9004")
Color.IndexColor("yellowgreen","bbf90f")
Color.IndexColor("light_sage","bcecac")
Color.IndexColor("light_aquamarine","7bfdc7")
Color.IndexColor("spearmint","1ef876")
Color.IndexColor("bright_lime","87fd05")
Color.IndexColor("vibrant_green","0add08")
Color.IndexColor("very_pale_green","cffdbc")
Color.IndexColor("faded_yellow","feff7f")
Color.IndexColor("bile","b5c306")
Color.IndexColor("viridian","1e9167")
Color.IndexColor("very_light_pink","fff4f2")
Color.IndexColor("puke_brown","947706")
Color.IndexColor("medium_pink","f36196")
Color.IndexColor("ugly_purple","a442a0")
Color.IndexColor("sunshine_yellow","fffd37")
Color.IndexColor("seaweed_green","35ad6b")
Color.IndexColor("light_periwinkle","c1c6fc")
Color.IndexColor("lemon_green","adf802")
Color.IndexColor("greeny_brown","696006")
Color.IndexColor("dark_grey_blue","29465b")
Color.IndexColor("bright_olive","9cbb04")
Color.IndexColor("turtle_green","75b84f")
Color.IndexColor("pale_sky_blue","bdf6fe")
Color.IndexColor("light_mustard","f7d560")
Color.IndexColor("diarrhea","9f8303")
Color.IndexColor("dark_aquamarine","017371")
Color.IndexColor("brownish_pink","c27e79")
Color.IndexColor("baby_shit_green","889717")
Color.IndexColor("purpley","8756e4")
Color.IndexColor("greyblue","77a1b5")
Color.IndexColor("hot_magenta","f504c9")
Color.IndexColor("blue/grey","758da3")
Color.IndexColor("pale","fff9d0")
Color.IndexColor("cool_green","33b864")
Color.IndexColor("sandy_yellow","fdee73")
Color.IndexColor("eggshell_blue","c4fff7")
Color.IndexColor("barf_green","94ac02")
Color.IndexColor("baby_green","8cff9e")
Color.IndexColor("vibrant_purple","ad03de")
Color.IndexColor("brown_grey","8d8468")
Color.IndexColor("water_blue","0e87cc")
Color.IndexColor("lipstick_red","c0022f")
Color.IndexColor("banana_yellow","fafe4b")
Color.IndexColor("wisteria","a87dc2")
Color.IndexColor("purple_brown","673a3f")
Color.IndexColor("brown_yellow","b29705")
Color.IndexColor("purple/pink","d725de")
Color.IndexColor("lemon_lime","bffe28")
Color.IndexColor("grey/blue","647d8e")
Color.IndexColor("dusty_red","b9484e")
Color.IndexColor("deep_rose","c74767")
Color.IndexColor("dark_seafoam_green","3eaf76")
Color.IndexColor("muddy_yellow","bfac05")
Color.IndexColor("carnation","fd798f")
Color.IndexColor("yellowy_brown","ae8b0c")
Color.IndexColor("violet_red","a50055")
Color.IndexColor("twilight_blue","0a437a")
Color.IndexColor("pure_blue","0203e2")
Color.IndexColor("lightish_red","fe2f4a")
Color.IndexColor("brick_orange","c14a09")
Color.IndexColor("velvet","750851")
Color.IndexColor("sunflower","ffc512")
Color.IndexColor("light_mint_green","a6fbb2")
Color.IndexColor("light_grass_green","9af764")
Color.IndexColor("lavender_blue","8b88f8")
Color.IndexColor("rusty_red","af2f0d")
Color.IndexColor("lightish_purple","a552e6")
Color.IndexColor("dried_blood","4b0101")
Color.IndexColor("light_blue_grey","b7c9e2")
Color.IndexColor("leaf","71aa34")
Color.IndexColor("orangish","fc824a")
Color.IndexColor("pale_olive_green","b1d27b")
Color.IndexColor("off_yellow","f1f33f")
Color.IndexColor("dusty_orange","f0833a")
Color.IndexColor("butter","ffff81")
Color.IndexColor("royal","0c1793")
Color.IndexColor("petrol","005f6a")
Color.IndexColor("greenish_cyan","2afeb7")
Color.IndexColor("duck_egg_blue","c3fbf4")
Color.IndexColor("bubble_gum_pink","ff69af")
Color.IndexColor("bluegrey","85a3b2")
Color.IndexColor("warm_brown","964e02")
Color.IndexColor("twilight","4e518b")
Color.IndexColor("saffron","feb209")
Color.IndexColor("purple/blue","5d21d0")
Color.IndexColor("dark_sand","a88f59")
Color.IndexColor("vibrant_blue","0339f8")
Color.IndexColor("putty","beae8a")
Color.IndexColor("lawn_green","4da409")
Color.IndexColor("camouflage_green","4b6113")
Color.IndexColor("blush_pink","fe828c")
Color.IndexColor("reddy_brown","6e1005")
Color.IndexColor("darkish_red","a90308")
Color.IndexColor("algae_green","21c36f")
Color.IndexColor("dark_coral","cf524e")
Color.IndexColor("bright_cyan","41fdfe")
Color.IndexColor("piss_yellow","ddd618")
Color.IndexColor("pastel_red","db5856")
Color.IndexColor("greenish_turquoise","00fbb0")
Color.IndexColor("dark","1b2431")
Color.IndexColor("ruby","ca0147")
Color.IndexColor("poop_green","6f7c00")
Color.IndexColor("orangered","fe420f")
Color.IndexColor("dandelion","fedf08")
Color.IndexColor("claret","680018")
Color.IndexColor("pale_mauve","fed0fc")
Color.IndexColor("lipstick","d5174e")
Color.IndexColor("rosa","fe86a4")
Color.IndexColor("darkblue","030764")
Color.IndexColor("tan_brown","ab7e4c")
Color.IndexColor("shit_green","758000")
Color.IndexColor("red_wine","8c0034")
Color.IndexColor("pinky","fc86aa")
Color.IndexColor("mud_green","606602")
Color.IndexColor("light_greenish_blue","63f7b4")
Color.IndexColor("dull_teal","5f9e8f")
Color.IndexColor("deep_lavender","8d5eb7")
Color.IndexColor("vivid_blue","152eff")
Color.IndexColor("raw_umber","a75e09")
Color.IndexColor("light_mint","b6ffbb")
Color.IndexColor("light_light_blue","cafffb")
Color.IndexColor("highlighter_green","1bfc06")
Color.IndexColor("greeny_grey","7ea07a")
Color.IndexColor("bluey_grey","89a0b0")
Color.IndexColor("algae","54ac68")
Color.IndexColor("sap_green","5c8b15")
Color.IndexColor("pale_salmon","ffb19a")
Color.IndexColor("metallic_blue","4f738e")
Color.IndexColor("ice","d6fffa")
Color.IndexColor("gross_green","a0bf16")
Color.IndexColor("dodger_blue","3e82fc")
Color.IndexColor("warm_pink","fb5581")
Color.IndexColor("light_green_blue","56fca2")
Color.IndexColor("flat_green","699d4c")
Color.IndexColor("dark_blue_grey","1f3b4d")
Color.IndexColor("clay_brown","b2713d")
Color.IndexColor("sand_yellow","fce166")
Color.IndexColor("grapefruit","fd5956")
Color.IndexColor("blood_orange","fe4b03")
Color.IndexColor("very_pale_blue","d6fffe")
Color.IndexColor("old_pink","c77986")
Color.IndexColor("neon_red","ff073a")
Color.IndexColor("golden_rod","f9bc08")
Color.IndexColor("plum_purple","4e0550")
Color.IndexColor("pale_peach","ffe5ad")
Color.IndexColor("green_again","16d43f")
Color.IndexColor("dark_yellow_green","728f02")
Color.IndexColor("carmine","9d0216")
Color.IndexColor("deep_sea_blue","015482")
Color.IndexColor("dark_hot_pink","d90166")
Color.IndexColor("warm_blue","4b57db")
Color.IndexColor("light_khaki","e6f2a2")
Color.IndexColor("icky_green","8fae22")
Color.IndexColor("greenblue","23c48b")
Color.IndexColor("dirty_purple","734a65")
Color.IndexColor("rich_blue","021bf9")
Color.IndexColor("mushroom","ba9e88")
Color.IndexColor("flat_blue","3c73a8")
Color.IndexColor("dark_slate_blue","214761")
Color.IndexColor("dark_sage","598556")
Color.IndexColor("coral_pink","ff6163")
Color.IndexColor("true_green","089404")
Color.IndexColor("darkish_purple","751973")
Color.IndexColor("dark_taupe","7f684e")
Color.IndexColor("cool_grey","95a3a6")
Color.IndexColor("canary","fdff63")
Color.IndexColor("booger_green","96b403")
Color.IndexColor("muted_pink","d1768f")
Color.IndexColor("hazel","8e7618")
Color.IndexColor("dark_royal_blue","02066f")
Color.IndexColor("vivid_purple","9900fa")
Color.IndexColor("racing_green","014600")
Color.IndexColor("leather","ac7434")
Color.IndexColor("green/blue","01c08d")
Color.IndexColor("sunflower_yellow","ffda03")
Color.IndexColor("rich_purple","720058")
Color.IndexColor("pale_magenta","d767ad")
Color.IndexColor("light_yellowish_green","c2ff89")
Color.IndexColor("indigo_blue","3a18b1")
Color.IndexColor("dark_fuchsia","9d0759")
Color.IndexColor("yellow_tan","ffe36e")
Color.IndexColor("wintergreen","20f986")
Color.IndexColor("violet_pink","fb5ffc")
Color.IndexColor("topaz","13bbaf")
Color.IndexColor("seafoam_blue","78d1b6")
Color.IndexColor("light_gold","fddc5c")
Color.IndexColor("grey/green","86a17d")
Color.IndexColor("foam_green","90fda9")
Color.IndexColor("creme","ffffb6")
Color.IndexColor("clear_blue","247afd")
Color.IndexColor("ugly_blue","31668a")
Color.IndexColor("terracota","cb6843")
Color.IndexColor("very_dark_brown","1d0200")
Color.IndexColor("straw","fcf679")
Color.IndexColor("parchment","fefcaf")
Color.IndexColor("orangey_yellow","fdb915")
Color.IndexColor("greyish_teal","719f91")
Color.IndexColor("sapphire","2138ab")
Color.IndexColor("nice_blue","107ab0")
Color.IndexColor("browny_orange","ca6b02")
Color.IndexColor("washed_out_green","bcf5a6")
Color.IndexColor("tiffany_blue","7bf2da")
Color.IndexColor("light_seafoam","a0febf")
Color.IndexColor("light_neon_green","4efd54")
Color.IndexColor("light_bright_green","53fe5c")
Color.IndexColor("light_bluish_green","76fda8")
Color.IndexColor("rosy_pink","f6688e")
Color.IndexColor("peachy_pink","ff9a8a")
Color.IndexColor("pale_light_green","b1fc99")
Color.IndexColor("old_rose","c87f89")
Color.IndexColor("fern","63a950")
Color.IndexColor("dusk_blue","26538d")
Color.IndexColor("camo","7f8f4e")
Color.IndexColor("burnt_siena","b75203")
Color.IndexColor("tealish_green","0cdc73")
Color.IndexColor("swamp","698339")
Color.IndexColor("sand_brown","cba560")
Color.IndexColor("rust_brown","8b3103")
Color.IndexColor("orangeish","fd8d49")
Color.IndexColor("light_royal_blue","3a2efe")
Color.IndexColor("cocoa","875f42")
Color.IndexColor("baby_purple","ca9bf7")
Color.IndexColor("raw_sienna","9a6200")
Color.IndexColor("radioactive_green","2cfa1f")
Color.IndexColor("light_pea_green","c4fe82")
Color.IndexColor("cinnamon","ac4f06")
Color.IndexColor("squash","f2ab15")
Color.IndexColor("charcoal_grey","3c4142")
Color.IndexColor("bright_yellow_green","9dff00")
Color.IndexColor("baby_puke_green","b6c406")
Color.IndexColor("poison_green","40fd14")
Color.IndexColor("light_lavendar","efc0fe")
Color.IndexColor("indian_red","850e04")
Color.IndexColor("dark_cream","fff39a")
Color.IndexColor("toupe","c7ac7d")
Color.IndexColor("butterscotch","fdb147")
Color.IndexColor("burple","6832e3")
Color.IndexColor("tan_green","a9be70")
Color.IndexColor("sun_yellow","ffdf22")
Color.IndexColor("pale_gold","fdde6c")
Color.IndexColor("light_light_green","c8ffb0")
Color.IndexColor("lichen","8fb67b")
Color.IndexColor("green/yellow","b5ce08")
Color.IndexColor("darkgreen","054907")
Color.IndexColor("azul","1d5dec")
Color.IndexColor("sunny_yellow","fff917")
Color.IndexColor("sickly_yellow","d0e429")
Color.IndexColor("kelley_green","009337")
Color.IndexColor("bruise","7e4071")
Color.IndexColor("browny_green","6f6c0a")
Color.IndexColor("battleship_grey","6b7c85")
Color.IndexColor("off_blue","5684ae")
Color.IndexColor("manilla","fffa86")
Color.IndexColor("greenish_beige","c9d179")
Color.IndexColor("deep_brown","410200")
Color.IndexColor("darkish_pink","da467d")
Color.IndexColor("custard","fffd78")
Color.IndexColor("ugly_brown","7d7103")
Color.IndexColor("stormy_blue","507b9c")
Color.IndexColor("liliac","c48efd")
Color.IndexColor("baby_shit_brown","ad900d")
Color.IndexColor("reddish_grey","997570")
Color.IndexColor("powder_pink","ffb2d0")
Color.IndexColor("eggplant_purple","430541")
Color.IndexColor("egg_shell","fffcc4")
Color.IndexColor("very_light_brown","d3b683")
Color.IndexColor("tea_green","bdf8a3")
Color.IndexColor("orange_pink","ff6f52")
Color.IndexColor("light_grey_green","b7e1a1")
Color.IndexColor("kiwi_green","8ee53f")
Color.IndexColor("boring_green","63b365")
Color.IndexColor("light_pastel_green","b2fba5")
Color.IndexColor("candy_pink","ff63e9")
Color.IndexColor("purply","983fb2")
Color.IndexColor("purpley_grey","947e94")
Color.IndexColor("dusty_lavender","ac86a8")
Color.IndexColor("desert","ccad60")
Color.IndexColor("deep_lilac","966ebd")
Color.IndexColor("pig_pink","e78ea5")
Color.IndexColor("olive_yellow","c2b709")
Color.IndexColor("light_seafoam_green","a7ffb5")
Color.IndexColor("light_moss_green","a6c875")
Color.IndexColor("lavender_pink","dd85d7")
Color.IndexColor("deep_aqua","08787f")
Color.IndexColor("bland","afa88b")
Color.IndexColor("strong_pink","ff0789")
Color.IndexColor("green_teal","0cb577")
Color.IndexColor("deep_turquoise","017374")
Color.IndexColor("dark_green_blue","1f6357")
Color.IndexColor("bright_sea_green","05ffa6")
Color.IndexColor("booger","9bb53c")
Color.IndexColor("blue_with_a_hint_of_purple","533cc6")
Color.IndexColor("blue_blue","2242c7")
Color.IndexColor("windows_blue","3778bf")
Color.IndexColor("toxic_green","61de2a")
Color.IndexColor("strong_blue","0c06f7")
Color.IndexColor("spruce","0a5f38")
Color.IndexColor("pinkish_tan","d99b82")
Color.IndexColor("macaroni_and_cheese","efb435")
Color.IndexColor("grey_teal","5e9b8a")
Color.IndexColor("dusty_teal","4c9085")
Color.IndexColor("dark_grass_green","388004")
Color.IndexColor("cement","a5a391")
Color.IndexColor("yellowish_tan","fcfc81")
Color.IndexColor("warm_purple","952e8f")
Color.IndexColor("tea","65ab7c")
Color.IndexColor("really_light_blue","d4ffff")
Color.IndexColor("nasty_green","70b23f")
Color.IndexColor("light_eggplant","894585")
Color.IndexColor("fresh_green","69d84f")
Color.IndexColor("electric_lime","a8ff04")
Color.IndexColor("dust","b2996e")
Color.IndexColor("dark_pastel_green","56ae57")
Color.IndexColor("cloudy_blue","acc2d9")
for i=0,255 do
	Color.IndexColor("Gray"..i,i,i,i)
end


function DrawThings(items)
	for i=1,#items do
		items[i]:draw()
	end
end
function gui:eventable()
	if self.important then
		return true
	end
	if _GuiPro.Hierarchy then
		if _GuiPro.TopHovered~=nil then
			return self:isDescendant(_GuiPro.TopHovered) or _GuiPro.TopHovered==self
		else
			return true
		end
	else
		return true
	end
end
function gui:OnClicked(func)
	table.insert(self.funcs,func)
end
function gui:OnReleased(func)
	table.insert(self.funcs2,func)
end
function gui:OnEnter(func)
	table.insert(self.funcs3,func)
end
function gui:OnExit(func)
	table.insert(self.funcs4,func)
end
function gui:OnUpdate(func)
	table.insert(self.funcs5,func)
end
function gui:OnDragStart(func)
	table.insert(self.func8,func)
end
function gui:OnDragging(func)
	table.insert(self.func6,func)
end
function gui:OnDragEnd(func)
	table.insert(self.func7,func)
end
function gui:WhileHovering(func)
	table.insert(self.func9,func)
end
function gui:OnMouseMoved(func)
	table.insert(self.func10,func)
end
function gui:getChildren()
	return self.Children
end
function gui:LClicked()
	return self.lclicked
end
function gui:RClicked()
	return self.rclicked
end
function gui:MClicked()
	return self.mclicked
end
function gui:Clicked()
	return (self.lclicked or self.rclicked)
end
function gui:Hovering()
	return self.hovering
end
function gui:FreeConnections()
	self.funcs={function(b,self) if b=="l" then self.LRE=true end end,function(b,self) if b=="r" then self.RRE=true end end,function(b,self) if b=="m" then self.MRE=true end end}
	self.funcs2={function(b,self) if b=="l" then self.LRE=false end end,function(b,self) if b=="r" then self.RRE=false end end,function(b,self) if b=="m" then self.MRE=false end end}
	self.funcs3={function(self) self.HE=true end}
	self.funcs4={function(self) self.HE=false end}
	self.funcs5={function(self) self.x=(self.Parent.width*self.scale.pos.x)+self.offset.pos.x+self.Parent.x self.y=(self.Parent.height*self.scale.pos.y)+self.offset.pos.y+self.Parent.y self.width=(self.Parent.width*self.scale.size.x)+self.offset.size.x self.height=(self.Parent.height*self.scale.size.y)+self.offset.size.y end}
end
function gui:LClick()
	for i=1,#self.funcs do
		self.funcs[i]("l",self)
	end
end
function gui:RClick()
	for i=1,#self.funcs do
		self.funcs[i]("r",self)
	end
end
function gui:MClick()
	for i=1,#self.funcs do
		self.funcs[i]("m",self)
	end
end
function gui:LRelease()
	for i=1,#self.funcs2 do
		self.funcs2[i]("l",self)
	end
end
function gui:RRelease()
	for i=1,#self.funcs2 do
		self.funcs2[i]("r",self)
	end
end
function gui:MRelease()
	for i=1,#self.funcs2 do
		self.funcs2[i]("m",self)
	end
end
function gui:full()
  self:SetDualDim(nil,nil,nil,nil,nil,nil,1,1)
end
function gui.enableAutoWindowScaling(b)
  _GuiPro.DPI_ENABLED=b or true
  _defaultfont=love.graphics.newFont(12*love.window.getPixelScale())
end
function filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	if type(name)~="string" then
		sh=sw
		sw=sy
		sy=sx
		sx=h
		h=w
		w=y
		y=x
		x=name
	end
	return x,y,w,h,sx,sy,sw,sh
end
function gui:newBase(tp,name, x, y, w, h, sx ,sy ,sw ,sh)
	_GuiPro.count=_GuiPro.count+1
    local c = {}
    setmetatable(c, gui)
	if self==gui then
		c.Parent=_GuiPro
	else
		c.Parent=self
	end
  c.segments=nil
  c.ry=nil
  c.rx=nil
  c.DPI=1
  if _GuiPro.DPI_ENABLED then
    c.DPI=love.window.getPixelScale()
    x, y, w, h=c.DPI*x,c.DPI*y,c.DPI*w,c.DPI*h
  end
  c.centerFontY=true
	c.FormFactor="rectangle"
	c.Type=tp
	c.Active=true
	c.form="rectangle"
	c.Draggable=false
	c.Name=name or "Gui"..tp
	c:SetName(name)
	c.BorderSize=1
	c.BorderColor={0,0,0}
	c.VIS=true
	c.Visible=true
	c.oV=true
	c.Children={}
	c.hovering=false
	c.rclicked=false
	c.lclicked=false
	c.mclicked=false
	c.clicked=false
	c.Visibility=1
	c.ClipDescendants=false
	c.TextWrap=true
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
    c.width = 0
    c.height = 0
	c.LRE=false
	c.RRE=false
	c.MRE=false
	c.Color = {255, 255, 255}
  function c:setRoundness(rx,ry,segments)
    self.segments=segments
    self.ry=ry
    self.rx=rx
  end
  function c.stfunc()
    love.graphics.rectangle("fill", c.x, c.y, c.width, c.height,c.rx,c.ry,c.segments)
  end
  function c:hasRoundness()
    return (self.ry or self.rx)
  end
	c.funcs={function(b,self)
		if b=="l" then
			self.LRE=true
		end
	end,
	function(b,self)
		if b=="r" then
			self.RRE=true
		end
	end,
	function(b,self)
		if b=="m" then
			self.MRE=true
		end
	end}
	c.funcs2={function(b,self)
		if b=="l" then
			self.LRE=false
		end
	end,
	function(b,self)
		if b=="r" then
			self.RRE=false
		end
	end,
	function(b,self)
		if b=="m" then
			self.MRE=false
		end
	end}
	c.HE=false
	c.funcs3={function(self)
		self.HE=true
	end}
	c.funcs4={function(self)
		self.HE=false
	end}
	c.funcs5={}
	c.tid={}
	c.touchcount=0
	c.x=(c.Parent.width*c.scale.pos.x)+c.offset.pos.x+c.Parent.x
	c.y=(c.Parent.height*c.scale.pos.y)+c.offset.pos.y+c.Parent.y
	c.width=(c.Parent.width*c.scale.size.x)+c.offset.size.x
	c.height=(c.Parent.height*c.scale.size.y)+c.offset.size.y
	c.func6={}
	c.func7={function() _GuiPro.DragItem={} end}
	c.func8={function(self) _GuiPro.DragItem=self end}
	c.func9={}
	c.func10={}
	function c:ImageRule()
		if self.Image then
			local sx=self.width/self.ImageWidth
			local sy=self.height/self.ImageHeigth
			love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.ImageVisibility*255)
			if self.width~=self.ImageWidth and self.height~=self.ImageHeigth then
				love.graphics.draw(self.Image,self.x,self.y,math.rad(self.rotation),sx,sy)
			else
				love.graphics.draw(self.Image,self.Quad,self.x,self.y,math.rad(self.rotation),sx,sy)
			end
		end
	end
	function c:VideoRule()
		if self.Video then
			local sx=self.width/self.VideoWidth
			local sy=self.height/self.VideoHeigth
			love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.VideoVisibility*255)
			if self.width~=self.VideoWidth and self.height~=self.VideoHeigth then
				love.graphics.draw(self.Video,self.x,self.y,math.rad(self.rotation),sx,sy)
			else
				love.graphics.draw(self.Video,self.Quad,self.x,self.y,math.rad(self.rotation),sx,sy)
			end
		end
	end
	function c:repeatImage(b,b2)
		if b then
			self.Image:setWrap(b,b2 or "repeat")
			function self:ImageRule()
				love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.ImageVisibility*255)
				love.graphics.draw(self.Image,self.Quad,self.x,self.y,math.rad(self.rotation))
			end
		else
			sx=self.width/self.ImageWidth
			sy=self.height/self.ImageHeigth
			love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.ImageVisibility*255)
			love.graphics.draw(self.Image,self.Quad,self.x,self.y,math.rad(self.rotation),sx,sy)
		end
	end
	function c:Mutate(t)
		for i,v in pairs(t) do
			_GuiPro.self=self
			if type(i)=="number" then
				loadstring("_GuiPro.self:"..v)()
			else
				self[i]=v
			end
		end
		return self
	end
	c:WhileHovering(function(self)
		self.omx=self.nmx
		self.omy=self.nmy
		self.nmx=love.mouse.getX()
		self.nmy=love.mouse.getY()
		if self.omx~=self.nmx or self.omy~=self.nmy then
			for i=1,#self.func10 do
				if self and self.nmx and self.nmy and self.omx and self.omy then
					self.func10[i](self,self.nmx,self.nmy,self.omx,self.omy)
				end
			end
		end
		if self.WasBeingDragged==true and love.mouse.isDown(self.dragbut or "m")==false and self.Type~="TextImageButtonFrameDrag" then
			for i=1,#self.func7 do
				self.func7[i](self,(love.mouse.getX())-self.width/2,(love.mouse.getY())-self.height/2)
			end
		end
		if _GuiPro.hasDrag==false and love.mouse.isDown(self.dragbut or "m") then
			for i=1,#self.func8 do
				self.func8[i](self,(love.mouse.getX())-self.width/2,(love.mouse.getY())-self.height/2)
			end
		end
		if self.IsBeingDragged==true then
			_GuiPro.hasDrag=true
			self.WasBeingDragged=true
		elseif self.WasBeingDragged==true and self.IsBeingDragged==false then
			self.WasBeingDragged=false
			_GuiPro.hasDrag=false
		end
		if self.Draggable==true and love.mouse.isDown(self.dragbut or "m") and _GuiPro.hasDrag==false then
			for i=1,#self.func6 do
				self.func6[i](self,(love.mouse.getX())-self.width/2,(love.mouse.getY())-self.height/2)
			end
			_GuiPro.hasDrag=true
			if self.FormFactor:lower()=="circle" or self.FormFactor:lower()=="c" or self.FormFactor:lower()=="cir" then
				self.IsBeingDragged=true
				x=(love.mouse.getX()-self.x)
				y=(love.mouse.getY()-self.y)
				self:Move(x,y)
			elseif self.FormFactor:lower()=="rectangle" or self.FormFactor:lower()=="r" or self.FormFactor:lower()=="rect" then
				self.IsBeingDragged=true
				x=(love.mouse.getX()-self.x)-self.width/2
				y=(love.mouse.getY()-self.y)-self.height/2
				self:Move(x,y)
			end
		else
			self.IsBeingDragged=false
		end
	end)
	table.insert(c.Parent.Children,c)
	return c
end
_GuiPro.mousedownfunc=love.mouse.isDown
function love.mouse.isDown(b)
	if not(b) then
		return false
	end
	return _GuiPro.mousedownfunc(({["l"]=1,["r"]=2,["m"]=3})[b] or b)
end
--[[WORKING ON
doubleTap - UnFinished!
touchRendering - Broken
]]
function gui:TClickable(mx,my)
	local x,y,w,h=love.graphics.getScissor()
	if _GuiPro.HasStencel then
		local obj=_GuiPro.StencelHolder
		if self:isDescendant(obj) then
			return math.sqrt((mx-obj.x)^2+(my-obj.y)^2)<=(obj.offset.size.x or 0)
		end
	end
	if not(x) then
		return true
	end
	return not(mx>x+w or mx<x or my>y+h or my<y)
end
function gui:touchable(t)
	local touches = love.touch.getTouches()
	local x,y=0,0
	for i, id in ipairs(touches) do
		if self.id==id then
			x, y = love.touch.getPosition(id)
			return (x > self.x and x < self.x+self.width and y > self.y and y < self.y+self.height and self:TClickable(x,y) and self:eventable())
		end
	end
	self.id=-1
end
multi:newTask(function() -- A bit of post-loading haha
	gui.touchpressed=multi:newConnection()
	gui.touchreleased=multi:newConnection()
	gui.touchmoved=multi:newConnection()
	love.touchpressed=Library.convert(love.touchpressed or function() end)
	love.touchreleased=Library.convert(love.touchreleased or function() end)
	love.touchmoved=Library.convert(love.touchmoved or function() end)
	love.touchpressed:inject(function(id, x, y, dx, dy, pressure) gui.touchpressed:Fire(id, x, y, dx, dy, pressure) return {id, x, y, dx, dy, pressure} end,1)
	love.touchreleased:inject(function(id, x, y, dx, dy, pressure) gui.touchreleased:Fire(id, x, y, dx, dy, pressure) return {id, x, y, dx, dy, pressure} end,1)
	love.touchmoved:inject(function(id, x, y, dx, dy, pressure) gui.touchmoved:Fire(id, x, y, dx, dy, pressure) return {id, x, y, dx, dy, pressure} end,1)
	_GuiPro.TouchReady=true
	_GuiPro.TouchRegister={}
	gui.touchpressed:connect(function(id, x, y, dx, dy, pressure)
		for i,v in pairs(_GuiPro.TouchRegister) do
			if #v.tid==0 then
				if (x > v.x and x < v.x+v.width and y > v.y and y < v.y+v.height and v:TClickable(x,y) and v:eventable()) then 
					v:addTID(id)
					v.touchcount=1
					for i=1,#v.ToFuncP do
						v.ToFuncP[i](v,id, x-v.x, y-v.y, dx, dy or 0, pressure or 1)
					end
				end
			elseif not(v:hasTID(id)) then
				if (x > v.x and x < v.x+v.width and y > v.y and y < v.y+v.height and v:TClickable(x,y) and v:eventable()) then
					v:addTID(id)
					v.touchcount=v.touchcount+1
					for i=1,#v.ToFuncP do
						v.ToFuncP[i](v,id, x-v.x, y-v.y, dx, dy or 0, pressure or 1)
					end
				end
			end
		end
	end)
	gui.touchreleased:connect(function(id, x, y, dx, dy, pressure)
		for i,v in pairs(_GuiPro.TouchRegister) do
			if v:hasTID(id) then
				v:removeTID(id)
				for i=1,#v.ToFuncR do
					v.ToFuncR[i](v,id, x-v.x, y-v.y, dx, dy or 0, pressure or 1)
				end
			end
		end
	end)
	gui.touchmoved:connect(function(id, x, y, dx, dy, pressure)
		for i,v in pairs(_GuiPro.TouchRegister) do
			if v:hasTID(id) and (x > v.x and x < v.x+v.width and y > v.y and y < v.y+v.height and v:TClickable(x,y) and v:eventable()) then 
				for i=1,#v.ToFuncM do
					v.ToFuncM[i](v,id, x-v.x, y-v.y, dx, dy or 0, pressure or 1)
				end
			elseif v:hasTID(id) and not((x > v.x and x < v.x+v.width and y > v.y and y < v.y+v.height and v:TClickable(x,y) and v:eventable())) then 
				v:removeTID(id)
				for i=1,#v.ToFuncR do
					v.ToFuncR[i](v,id, x-v.x, y-v.y, dx, dy or 0, pressure or 1)
				end
			end
		end
	end)
end)
-- now that that is done lets set up some more post loading checks
_GuiPro.int=multi:newProcess()
_GuiPro.int:Start()
_GuiPro.int:setJobSpeed(.001)
_GuiPro.EXACT=0
_GuiPro.LAX=.01
_GuiPro.LAZY=.05
-- now lets define the reg function
function gui.Compare(a,b,v,tp)
	if tp==">" then
		if (a+v>b or a-v>b) then
			return true
		end
	elseif tp=="<" then
		if (a+v<b or a-v<b) then
			return true
		end
	elseif tp=="<=" then
		if (a+v<=b or a-v<=b) then
			return true
		end
	elseif tp==">=" then
		if (a+v>=b or a-v>=b) then
			return true
		end
	elseif tp=="==" then -- this one is gonna be tricky
		if (a>=b-v and a<=b+v) or (b>=a-v and b<=a+v) then
			return true
		end
	end
	return false
end
function gui:regesterTouch()
	local obj=self
	obj.ToFuncP={}
	obj.ToFuncM={}
	obj.ToFuncR={}
	obj.To2Func={}
	obj.ToDTFunc={}
	obj.touchRendering =_GuiPro.EXACT -- exact(0), lax(), #
	function obj:removeTID(id)
		for i=1,#self.tid do
			if self.tid[i]==id then
				table.remove(self.tid,i)
				self.touchcount=self.touchcount-1
				return
			end
		end
	end
	function obj:hasTID(id)
		for i=1,#self.tid do
			if self.tid[i]==id then
				return true
			end
		end
		return false
	end
	obj.txl1=0
	obj.tyl1=0
	obj.txl2=0
	obj.tyl2=0
	obj.LS=0
	obj:OnUpdate(function(self)
		if self.touchcount==2 then
			local x1,y1=love.touch.getPosition( self.tid[1] )
			local x2,y2=love.touch.getPosition( self.tid[2] )
			local CS=math.sqrt((x2-x1)^2+(y2-y1)^2)
			if gui.Compare(CS,self.LS,self.touchRendering,">") then
				for i=1,#self.To2Func do
					self.To2Func[i](self,CS,x1-self.x,y1-self.y,x2-self.x,y2-self.y)
				end
			elseif gui.Compare(CS,self.LS,self.touchRendering,"<") then
				for i=1,#self.To2Func do
					self.To2Func[i](self,-CS,x1-self.x,y1-self.y,x2-self.x,y2-self.y)
				end
			elseif gui.Compare(CS,self.LS,self.touchRendering,"==") then
				for i=1,#self.To2Func do
					self.To2Func[i](self,0,x1-self.x,y1-self.y,x2-self.x,y2-self.y)
				end
			end
			-- if self.txl1~=x1 or self.txl2~=x2 or self.tyl1~=y1 or self.tyl2~=y2 then
				-- for i=1,#self.To2Func do
					-- self.To2Func[i](self,0,x1-self.x,y1-self.y,x2-self.x,y2-self.y)
				-- end
			-- end
			self.LS=CS
			self.txl1=x1
			self.txl2=x2
			self.tyl1=y1
			self.tyl2=y2
		end
	end)
	function obj:OnDoubleTap(func)
		table.insert(self.ToDTFunc,func)
	end
	function obj:On2TouchMoved(func)
		table.insert(self.To2Func,func)
	end
	function obj:addTID(id)
		table.insert(self.tid,id)
	end
	function obj:OnTouchPressed(func)
		table.insert(self.ToFuncP,func) -- event for touches
	end
	function obj:OnTouchReleased(func) -- event for touches
		table.insert(self.ToFuncR,func)
	end
	function obj:OnTouchMoved(func) -- event for touches
		table.insert(self.ToFuncM,func)
	end
	if _GuiPro.TouchReady then -- my sneaky test
		print("Registred: "..tostring(obj))
		table.insert(_GuiPro.TouchRegister,obj)
	else
		print("Attempting to register: "..tostring(obj))
		_GuiPro.int:newJob(function() table.insert(_GuiPro.TouchRegister,obj) end) -- a sneaky way to ensure that your object gets registered eventually, even if you call the method before the touch patch was activated. 
	end
end

function UpdateThings(items)
	for i=#items,1,-1 do
		if items[i]:LClicked() then
			for g=1,#items[i].funcs do
				items[i].funcs[g]("l",items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		elseif items[i]:RClicked() then
			for g=1,#items[i].funcs do
				items[i].funcs[g]("r",items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		elseif items[i]:MClicked() then
			for g=1,#items[i].funcs do
				items[i].funcs[g]("m",items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		end
		if not(items[i]:LClicked()) and items[i].LRE then
			for g=1,#items[i].funcs2 do
				items[i].funcs2[g]("l",items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		elseif not(items[i]:RClicked()) and items[i].RRE then
			for g=1,#items[i].funcs2 do
				items[i].funcs2[g]("r",items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		elseif not(items[i]:MClicked()) and items[i].MRE then
			for g=1,#items[i].funcs2 do
				items[i].funcs2[g]("m",items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		end
		if items[i]:Hovering() and items[i].HE==false then
			for g=1,#items[i].funcs3 do
				items[i].funcs3[g](items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		elseif not(items[i]:Hovering()) and items[i].HE==true then
			for g=1,#items[i].funcs4 do
				items[i].funcs4[g](items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		elseif items[i]:Hovering() then
			for g=1,#items[i].func9 do
				items[i].func9[g](items[i],love.mouse.getX()-items[i].x,love.mouse.getY()-items[i].y)
			end
		end
		for g=1,#items[i].funcs5 do
			items[i].funcs5[g](items[i])
		end
	end
end
function GetAllChildren(Object)
	local Stuff = {}
	function Seek(Items)
		for i=1,#Items do
			if Items[i].Visible==true then
				table.insert(Stuff,Items[i])
				local NItems = Items[i]:getChildren()
				if NItems ~= nil then
					Seek(NItems)
				end
			end
		end
	end
	local Objs = Object:getChildren()
	for i=1,#Objs do
		if Objs[i].Visible==true then
			table.insert(Stuff,Objs[i])
			local Items = Objs[i]:getChildren()
			if Items ~= nil then
				Seek(Items)
			end
		end
	end
	return Stuff
end
function GetAllChildren2(Object)
	local Stuff = {}
	function Seek(Items)
		for i=1,#Items do
			table.insert(Stuff,Items[i])
			local NItems = Items[i]:getChildren()
			if NItems ~= nil then
				Seek(NItems)
			end
		end
	end
	local Objs = Object:getChildren()
	for i=1,#Objs do
		table.insert(Stuff,Objs[i])
		local Items = Objs[i]:getChildren()
		if Items ~= nil then
			Seek(Items)
		end
	end
	return Stuff
end
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
function gui:newAnim(file,delay, x, y, w, h, sx ,sy ,sw ,sh)
	local x,y,w,h,sx,sy,sw,sh=filter(file, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("ImageAnimation",file, x, y, w, h, sx ,sy ,sw ,sh)
	c.Visibility=0
	c.ImageVisibility=1
	c.delay=delay or .05
	c.files={}
	c.AnimStart={}
	c.AnimEnd={}
	local _files=alphanumsort(love.filesystem.getDirectoryItems(file))
	for i=1,#_files do
		if string.sub(_files[i],-1,-1)~="b" then
			table.insert(c.files,love.graphics.newImage(file.."/".._files[i]))
		end
	end
	c.step=multi:newTStep(1,#c.files,1,c.delay)
	c.step.parent=c
	c.rotation=0
	c.step:OnStart(function(step)
		for i=1,#step.parent.AnimStart do
			step.parent.AnimStart[i](step.parent)
		end
	end)
	c.step:OnStep(function(pos,step)
		step.parent:SetImage(step.parent.files[pos])
	end)
	c.step:OnEnd(function(step)
		for i=1,#step.parent.AnimEnd do
			step.parent.AnimEnd[i](step.parent)
		end
	end)
	function c:OnAnimStart(func)
		table.insert(self.AnimStart,func)
	end
	function c:OnAnimEnd(func)
		table.insert(self.AnimEnd,func)
	end
	function c:Pause()
		self.step:Pause()
	end
	function c:Resume()
		self.step:Resume()
	end
	function c:Reset()
		self.step.pos=1
	end
	function c:getFrames()
		return #self.files
	end
	function c:getFrame()
		return self.step.pos
	end
	function c:setFrame(n)
		return self:SetImage(self.files[n])
	end
	return c
end
function gui:newAnimFromData(data,delay, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("ImageAnimation","FromFile", x, y, w, h, sx ,sy ,sw ,sh)
	c.Visibility=0
	c.ImageVisibility=1
	c.delay=delay or .05
	c.files=data
	c.AnimStart={}
	c.AnimEnd={}
	c:SetImage(c.files[1])
	c.step=multi:newTStep(1,#c.files,1,c.delay)
	c.step.parent=c
	c.rotation=0
	c.step:OnStart(function(step)
		for i=1,#step.parent.AnimStart do
			step.parent.AnimStart[i](step.parent)
		end
	end)
	c.step:OnStep(function(pos,step)
		step.parent:SetImage(step.parent.files[pos])
	end)
	c.step:OnEnd(function(step)
		for i=1,#step.parent.AnimEnd do
			step.parent.AnimEnd[i](step.parent)
		end
	end)
	function c:OnAnimStart(func)
		table.insert(self.AnimStart,func)
	end
	function c:OnAnimEnd(func)
		table.insert(self.AnimEnd,func)
	end
	function c:Pause()
		self.step:Pause()
	end
	function c:Resume()
		self.step:Resume()
	end
	function c:Reset()
		self.step.pos=1
	end
	function c:getFrames()
		return #self.files
	end
	function c:getFrame()
		return self.step.pos
	end
	function c:setFrame(n)
		return self:SetImage(self.files[n])
	end
	return c
end
function gui:newAnimFromTiles(file,xd,yd,delay, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(file, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("ImageAnimation",file, x, y, w, h, sx ,sy ,sw ,sh)
	local im=love.graphics.newImage(file)
	local _x,_y=im:getDimensions()
	c.Visibility=0
	c.ImageVisibility=1
	c.delay=delay or .05
	c.files={}
	c.AnimStart={}
	c.AnimEnd={}
	for i=0,_y/yd-1 do
		for j=0,_x/xd-1 do
			table.insert(c.files,gui:getTile(im,j*xd,i*yd,xd,yd))
		end
	end
	c:SetImage(c.files[1])
	c.step=multi:newTStep(1,#c.files,1,c.delay)
	c.step.parent=c
	c.rotation=0
	c.step:OnStart(function(step)
		for i=1,#step.parent.AnimStart do
			step.parent.AnimStart[i](step.parent)
		end
	end)
	c.step:OnStep(function(pos,step)
		step.parent:SetImage(step.parent.files[pos])
	end)
	c.step:OnEnd(function(step)
		for i=1,#step.parent.AnimEnd do
			step.parent.AnimEnd[i](step.parent)
		end
	end)
	function c:OnAnimStart(func)
		table.insert(self.AnimStart,func)
	end
	function c:OnAnimEnd(func)
		table.insert(self.AnimEnd,func)
	end
	function c:Pause()
		self.step:Pause()
	end
	function c:Resume()
		self.step:Resume()
	end
	function c:Reset()
		self.step.pos=1
	end
	function c:getFrames()
		return #self.files
	end
	function c:getFrame()
		return self.step.pos
	end
	function c:setFrame(n)
		return self:SetImage(self.files[n])
	end
	return c
end
function gui:newFullImageLabel(i,name)
  return self:newImageLabel(i,name,0,0,0,0,0,0,1,1)
end
function gui:newImageButton(i,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("ImageButton",name, x, y, w, h, sx ,sy ,sw ,sh)
	if type(i)=="string" then
		c.Image=love.graphics.newImage(i)
	else
		c.Image=i
	end
	c.Visibility=0
	c.ImageVisibility=1
	c.rotation=0
	if c.Image~=nil then
		c.ImageHeigth=c.Image:getHeight()
		c.ImageHeight=c.Image:getHeight()
		c.ImageWidth=c.Image:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.ImageWidth,c.ImageHeigth)
	end
	c:OnEnter(function()
		--love.mouse.setCursor(_GuiPro.CursorH)
	end)
	c:OnExit(function()
		--love.mouse.setCursor(_GuiPro.CursorN)
	end)
    return c
end
function gui:newImageLabel(i,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("ImageLabel",name, x, y, w, h, sx ,sy ,sw ,sh)
	if type(i)=="string" then
		c.Image=love.graphics.newImage(i)
	else
		c.Image=i
	end
	c.Visibility=0
	c.ImageVisibility=1
	c.rotation=0
	if c.Image~=nil then
		c.ImageHeigth=c.Image:getHeight()
		c.ImageWidth=c.Image:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.ImageWidth,c.ImageHeigth)
	end
  return c
end
function gui:newVideo(name,i,x,y,w,h,sx,sy,sw,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("Video",name, x, y, w, h, sx ,sy ,sw ,sh)
	if type(i)=="string" then
		c.Video=love.graphics.newVideo(i)
	else
		c.Video=i
	end
	c.Visibility=0
	c.VideoVisibility=1
	c.rotation=0
	if c.Video~=nil then
		c.VideoHeigth=c.Video:getHeight()
		c.VideoWidth=c.Video:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.VideoWidth,c.VideoHeigth)
	end
	c.funcV={}
	function c:Play()
		self.handStart=true
		self.Video:play()
	end
    function c:Pause()
		self.Video:pause()
	end
	c.Resume=c.Play
	function c:Stop()
		self.handStart=false
		self:Pause()
		self:Rewind()
		for i=1,# self.funcV do
			self.funcV[i](self)
		end
	end
	function c:OnVideoStopped(func)
		table.insert(self.funcV,func)
	end
    function c:Rewind()
		self.Video:rewind()
	end
	function c:Restart()
		self:Rewind()
		self:Play()
	end
    function c:Seek(o)
		self.Video:seek(o)
	end
    function c:Tell()
		self.Video:tell()
	end
    function c:SetFilter(min, mag, anisotropy)
		self.Video:setFilter(min, mag, anisotropy)
	end
	function c:IsPlaying()
		return self.Video:isPlaying()
	end
	c:OnUpdate(function(self)
		if self.Video:isPlaying()==false and self.handStart == true then
			self:Stop()
		end
	end)
    return c
end
function gui:SetImage(i)
	if type(i)=="string" then
		self.Image=love.graphics.newImage(i)
	else
		self.Image=i
	end
	if self.Image~=nil then
		self.ImageHeigth=self.Image:getHeight()
		self.ImageWidth=self.Image:getWidth()
		self.Quad=love.graphics.newQuad(0,0,self.width,self.height,self.ImageWidth,self.ImageHeigth)
	end
	return self.ImageWidth,self.ImageHeigth
end
function gui:UpdateImage()
	self.ImageHeigth=self.Image:getHeight()
	self.ImageWidth=self.Image:getWidth()
	self.Quad=love.graphics.newQuad(0,0,self.width,self.height,self.ImageWidth,self.ImageHeigth)
end
function gui:newDropFrame(name,x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("DropFrame",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.WasBeingDragged=false
	c.IsBeingDragged=false
	c.Draggable=false
	c.funcD={}
	function c:GetDroppedItems()
		local t=self:getChildren()
		local tab={}
		for i=1,#t do
			if t[i].Type=="TextImageButtonFrameDrag" then
				table.insert(tab,t[i])
			end
		end
		return tab
	end
	function c:OnDropped(func)
		table.insert(self.funcD,func)
	end
	c:OnUpdate(function(self)
		if _GuiPro.DragItem then
			if _GuiPro.DragItem.Type=="TextImageButtonFrameDrag" and love.mouse.isDown(_GuiPro.DragItem.dragbut or "m")==false and self:IsHovering() then
				local t=_GuiPro.DragItem
				_GuiPro.DragItem={}
				for i=1,#t.funcD do
					t.funcD[i](self,t)
				end
				for i=1,#self.funcD do
					self.funcD[i](self,t)
				end
				_GuiPro.hasDrag=false
			end
		end
	end)
    return c
end
function gui:newFrame(name,x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("Frame",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.WasBeingDragged=false
	c.IsBeingDragged=false
	c.Draggable=false
    return c
end
function gui:newFullFrame(name)
    name=name or ""
    return self:newFrame(name,0,0,0,0,0,0,1,1)
end

function gui:newTabFrame(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=gui:newFrame(name, x, y, w, h, sx ,sy ,sw ,sh)
	c.tabheight=20
	c.Holder=c:newFrame("Holder",0,c.tabheight,0,0,0,0,1,1)
	c.TabHolder=c:newFrame("TabHolder",0,0,0,c.tabheight,0,0,1)
	function c:setTabHeight(n)
		self.tabheight=n
		self.Holder:SetDualDim(0,-self.tabheight,0,0,0,0,1,1)
	end
	function c:addTab(name,colorT,colorH)
		if colorT and not(colorH) then
			colorH=colorT
		end
		local tab=self.TabHolder:newTextButton(name,name,0,0,0,0,0,0,0,1)
		tab.Tween=-3
		if colorT then
			tab.Color=colorT
		end
		local holder=self.Holder:newFrame(name,0,0,0,0,0,0,1,1)
		if colorH then
			holder.Color=colorH
		end
		tab.frame=holder
		tab:OnReleased(function(b,self)
			if b=="l" then
				local tt=self.Parent:getChildren()
				local th=self.Parent.Parent.Holder:getChildren()
				for i=1,#th do
					th[i].Visible=false
				end
				for i=1,#tt do
					tt[i].frame.Visible=false
					tt[i].BorderSize=1
				end
				self.BorderSize=0
				self.frame.Visible=true
			end
		end)
		local tt=self.TabHolder:getChildren()
		for i=1,#tt do
			tt[i].frame.Visible=false
			tt[i].BorderSize=1
		end
		tab.frame.Visible=true
		tab.BorderSize=0
		return tab,holder
	end
	c:OnUpdate(function(self)
		local th=self.TabHolder:getChildren()
		local l=self.width/#th
		for i=1,#th do
			th[i]:SetDualDim(l*(i-1),0,l)
		end
		if #th==0 then
			self:Destroy()
		end
	end)
	return c
end
function gui:newDragItem(t,i,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("TextImageButtonFrameDrag",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.WasBeingDragged=false
	c.IsBeingDragged=false
	c.Draggable=true
	c.funcD={}
	if type(i)=="string" then
		c.Image=love.graphics.newImage(i)
		c.ImageVisibility=1
		c.ImageHeigth=c.Image:getHeight()
		c.ImageWidth=c.Image:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.ImageWidth,c.ImageHeigth)
	elseif type(i)=="image" then
		c.Image=i
		c.ImageVisibility=1
		c.ImageHeigth=c.Image:getHeight()
		c.ImageWidth=c.Image:getWidth()
		c.Quad=love.graphics.newQuad(0,0,w,h,c.ImageWidth,c.ImageHeigth)
	end
	c:OnDragStart(function(self,x,y)
		if _GuiPro.hasDrag==false then
			self:setParent(_GuiPro)
			self:SetDualDim(x,y)
			self:TopStack()
		end
	end)
	c.rotation=0
	c.Tween=0
	c.XTween=0
	c.text = t
	c.AutoScaleText=false
	c.FontHeight=_defaultfont:getHeight()
	c.Font=_defaultfont
	c.FontSize=15
	c.TextFormat="center"
	c.TextVisibility=1
    c.TextColor = {0, 0, 0}
	function c:OnDropped(func)
		table.insert(self.funcD,func)
	end
	c:OnUpdate(function(self)
		if love.mouse.isDown("m" or self.dragbut)==false and self==_GuiPro.DragItem and self.hovering==false then
			_GuiPro.DragItem={}
			for i=1,#self.func7 do
				self.func7[i](self,(love.mouse.getX())-self.width/2,(love.mouse.getY())-self.height/2)
			end
		end
	end)
    return c
end
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
function gui:addDominance()
	_GuiPro.TopHovered=self
end
function gui:addHotKey(key)
	local temp=self:newFrame(0,0,0,0)
	temp.Visible=false
	temp:setHotKey(key)
	return temp
end
function gui:AdvTextBox(txt,x,y,w,h,sx,sy,sw,sh)
	name="AdvTextBox"
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("AdvTextBoxFrame",name, x, y, w, 30, sx ,sy ,sw ,sh)
	c.Draggable=true
	c.dragbut="r"
	c.BorderSize=0
	c:ApplyGradient{Color.Blue,Color.sexy_purple}
	c:newTextLabel(txt,"Holder",0,0,0,h-30,0,1,1,0).Color=Color.sexy_purple
	c.funcO={}
	c.funcX={}
	c:OnDragStart(function(self)
		self:TopStack()
	end)
	--local temp = c:newTextButton("X","Close",-25,5,20,20,1)
	--temp.Tween=-5
	--temp.XTween=-2
	--temp:OnReleased(function(b,self) for i=1,#self.Parent.funcX do self.Parent.funcX[i](self.Parent) end end)
	--temp.Color=Color.Red
	c.tLink=c:newTextBox("puttext","TextBox",5,h-95,-40,30,0,1,1,1)
	c.tLink.Color=Color.light_gray
	c.tLink.ClearOnFocus=true
	c.tLink:OnFocus(function(self) self.ClearOnFocus=false end)
	local temp=c:newTextButton("OK","Ok",-35,h-65,30,30,1,1)
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcO do self.Parent.funcO[i](self.Parent,self.Parent.tLink.text) end end)
	temp.Color=Color.Green
	temp.XTween=-2
	local temp=c:newTextButton("X","Cancel",-35,h-95,30,30,1,1)
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcX do self.Parent.funcX[i](self.Parent,self.Parent.tLink.text) end end)
	temp.Color=Color.Red
	temp.XTween=-2
	function c:Close()
		self.Visible=false
	end
	function c:Open()
		self.Visible=true
	end
	function c:OnOk(func)
		table.insert(self.funcO,func)
	end
	function c:OnX(func)
		table.insert(self.funcX,func)
	end
	return c
end
function alphanumsort(o)
	local function padnum(d) local dec, n = string.match(d, "(%.?)0*(.+)")
		return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n)
	end
	table.sort(o, function(a,b) return tostring(a):gsub("%.?%d+",padnum)..("%3d"):format(#b)< tostring(b):gsub("%.?%d+",padnum)..("%3d"):format(#a) end)
	return o
end
function gui:anchorRight(n)
	self:SetDualDim(-(self.width+n),nil,nil,nil,1)
end
function _GuiPro.gradient(colors)
    local direction = colors.direction or "horizontal"
	colors.direction=nil
	trans = colors.trans or 255
	trans=math.floor(trans)
    if direction == "horizontal" then
        direction = true
    elseif direction == "vertical" then
        direction = false
    else
        error("Invalid direction '" .. tostring(direction) "' for gradient.  Horizontal or vertical expected.")
    end
    local result = love.image.newImageData(direction and 1 or #colors, direction and #colors or 1)
    for __i, color in ipairs(colors) do
        local x, y
        if direction then
            x, y = 0, __i - 1
        else
            x, y = __i - 1, 0
        end
        result:setPixel(x, y, color[1], color[2], color[3], trans)
    end
    result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    return result
end
function _GuiPro.drawinrect(img, x, y, w, h, r, ox, oy, kx, ky)
    love.graphics.draw(img, x, y, r, w / img:getWidth(), h / img:getHeight(), ox, oy, kx, ky)
end
function gui:ApplyGradient(rules)
	self.Image=nil
	self.Type=self.Type.."w/GradImage"
	self.rotation=0
	self.ImageVisibility=rules.visibility or 1
	self:SetImage(_GuiPro.gradient(rules))
end
function gui:BottomStack()
	childs=self.Parent:getChildren()
	for i=1,#childs do
		if childs[i]==self then
			table.remove(self.Parent.Children,i)
			table.insert(self.Parent.Children,1,self)
			break
		end
	end
end
function gui:Center()
	local x,y=self:getFullSize()
	self:SetDualDim(-math.floor(x/2),-math.floor(y/2),nil,nil,.5,.5)
end
function gui:centerX()
	self:SetDualDim(-(self.width/2),nil,nil,nil,.5)
end
function gui:centerY()
	self:SetDualDim(nil,-(self.height/2),nil,nil,nil,.5)
end
function gui:Destroy()
	check=self.Parent:getChildren()
	local cc=0
	for cc=1,#check do
		if check[cc]==self then
			table.remove(self.Parent.Children,cc)
		end
	end
end
function gui:disrespectHierarchy()
	_GuiPro.Hierarchy=false
end
function gui:GetAllChildren()
	local Stuff = {}
	function Seek(Items)
		for i=1,#Items do
			if Items[i].Visible==true then
				table.insert(Stuff,Items[i])
				local NItems = Items[i]:getChildren()
				if NItems ~= nil then
					Seek(NItems)
				end
			end
		end
	end
	local Objs = self:getChildren()
	for i=1,#Objs do
		if Objs[i].Visible==true then
			table.insert(Stuff,Objs[i])
			local Items = Objs[i]:getChildren()
			if Items ~= nil then
				Seek(Items)
			end
		end
	end
	return Stuff
end
function gui:GetChild(name)
	return self.Children[name] or self
end
function gui:getChildren()
	return self.Children
end
function gui:getColor(cindex)
	return Color[cindex]
end
function gui:getFullSize()
	local maxx,maxy=-math.huge,-math.huge
	local temp = self:GetAllChildren()
	for i=1,#temp do
		if temp[i].width>maxx then
			maxx=temp[i].width+temp[i].offset.pos.x
		elseif temp[i].height>maxy then
			maxy=temp[i].height+temp[i].offset.pos.y
		end
	end
	return maxx,maxy
end
function gui:getHighest()
	if self.Children[#self.Children]~=nil then
		return self.Children[#self.Children]
	end
end
function gui:getLowest()
	if self.Children[1]~=nil then
		return self.Children[1]
	end
end
function InGrid(i,x,y,s)
	return math.floor((i-1)/x)*s,(i-1)*s-(math.floor((i-1)/y)*(s*x))
end
function InGridX(i,w,h,xs,ys)
	local xc,yc=math.floor(w/xs),math.floor(h/ys)
	local xi,yi=(i-1)%xc,math.floor((i-1)/xc)
	return xi*xs,yi*ys
end
function InGridY(i,w,h,xs,ys)
	local xc,yc=math.floor(w/xs),math.floor(h/ys)
	local xi,yi=math.floor((i-1)/yc),(i-1)%yc
	return xi*xs,yi*ys
end
function gui:isDescendant(obj)
	local things=obj:GetAllChildren()
	for i=1,#things do
		if things[i]==self then
			return true
		end
	end
	return false
end
function gui:isHighest()
	return (self==self.Parent:getHighest())
end
function gui:IsHovering()
	return (love.mouse.getX() > self.x and love.mouse.getX() < self.x+self.width and love.mouse.getY() > self.y and love.mouse.getY() < self.y+self.height)
end
function gui:isLowest()
	return (self==self.Parent:getLowest())
end
function gui.massMutate(t,...)
	local mut={...}
	for i=1,#mut do
		mut[i]:Mutate(t)
	end
end
function gui:Move(x,y)
	self.offset.pos.x=self.offset.pos.x+x
	self.offset.pos.y=self.offset.pos.y+y
end
if love.filesystem.exists("CheckBoxes.png") then
	_GuiPro.UC=gui:getTile("CheckBoxes.png",0,0,16,16)
	_GuiPro.C=gui:getTile("CheckBoxes.png",16,0,16,16)
	_GuiPro.UCH=gui:getTile("CheckBoxes.png",0,16,16,16)
	_GuiPro.CH=gui:getTile("CheckBoxes.png",16,16,16,16)
end
function gui:newCheckBox(name,x,y)
	if not(_GuiPro.UC) then error("CheckBoxes.png not found! Cannot currently use checkbox without the data") end
	if type(name)~="String" then
		x,y,name=name,x,"CheckBox"
	end
	local c=self:newImageLabel(_GuiPro.UC,name, x, y, 16,16)
	c.Visibility=0
	c.check=false
	c:OnEnter(function(self)
		if self.check then
			self:SetImage(_GuiPro.CH)
		else
			self:SetImage(_GuiPro.UCH)
		end
	end)
	function c:isChecked()
		return self.check
	end
	c:OnExit(function(self)
		if self.check then
			self:SetImage(_GuiPro.C)
		else
			self:SetImage(_GuiPro.UC)
		end
	end)
	c:OnReleased(function(b,self)
		self.check=not(self.check)
		if self.check then
			self:SetImage(_GuiPro.CH)
		else
			self:SetImage(_GuiPro.UCH)
		end
	end)
    return c
end
function gui:newMessageBox(txt,x,y,w,h,sx,sy,sw,sh)
	name="MessageBox"
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("MessageBoxFrame",name, x, y, w, 30, sx ,sy ,sw ,sh)
	c.Draggable=true
	c.dragbut="r"
	c:ApplyGradient{Color.Blue,Color.sexy_purple}
	c.BorderSize=0
	c:newTextLabel(txt,"Holder",0,0,0,h-30,0,1,1,0).Color=Color.sexy_purple
	c.funcO={}
	c.funcX={}
	c:OnDragStart(function(self)
		self:TopStack()
	end)
	local temp = c:newTextButton("X","Close",-25,5,20,20,1)
	temp.Tween=-5
	temp.XTween=-2
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcX do self.Parent.funcX[i](self.Parent) end end)
	temp.Color=Color.Red
	local temp=c:newTextButton("OK","Ok",0,h-65,0,30,.25,1,.5)
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcO do self.Parent.funcO[i](self.Parent) end end)
	temp.Color=Color.Green
	function c:Close()
		self.Visible=false
	end
	function c:Open()
		self.Visible=true
	end
	function c:OnOk(func)
		table.insert(self.funcO,func)
	end
	function c:OnX(func)
		table.insert(self.funcX,func)
	end
	return c
end
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
function gui:newProgressBar(txt,x,y,w,h,sx,sy,sw,sh)
	name="newProgressBar"
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("newProgressBarFrame",name, x, y, w, 30, sx ,sy ,sw ,sh)
	c.Draggable=true
	c.dragbut="r"
	c.BorderSize=0
	c:ApplyGradient{Color.Blue,Color.sexy_purple}
	c:newTextLabel(txt,"Holder",0,0,0,h-30,0,1,1,0).Color=Color.sexy_purple
	c.funcO={}
	c.funcX={}
	c:OnDragStart(function(self)
		self:TopStack()
	end)
	local temp = c:newTextButton("X","Close",-25,5,20,20,1)
	temp.Tween=-5
	temp.XTween=-2
	temp:OnReleased(function(b,self) for i=1,#self.Parent.funcX do self.Parent.funcX[i](self.Parent) end end)
	temp.Color=Color.Red
	c.BarBG=c:newTextButton("",5,h-65,-10,30,0,1,1)
	c.BarBG:ApplyGradient{Color.Red,Color.light_red}
	c.Bar=c.BarBG:newTextLabel("",0,0,0,0,0,0,0,1)
	c.Bar:ApplyGradient{Color.Green,Color.light_green}
	c.BarDisp=c.BarBG:newTextLabel("0%","0%",0,0,0,0,0,0,1,1)
	c.BarDisp.Visibility=0
	c.BarDisp.Link=c.Bar
	c.BarDisp:OnUpdate(function(self)
		self.text=self.Link.scale.size.x*100 .."%"
	end)
	c.Func1={}
	function c:On100(func)
		table.insert(self.Func1,func)
	end
	c:OnUpdate(function(self)
		if self.Bar.scale.size.x*100>=100 then
			for P=1,#self.Func1 do
				self.Func1[P](self)
			end
		end
	end)
	function c:SetPercentage(n)
		self.Bar:SetDualDim(0,0,0,0,0,0,n/100,1)
	end
	return c
end
function gui:newScrollBar(color1,color2)
	local scrollbar=self:newFrame(-20,0,20,0,1,0,0,1)
	scrollbar.funcS={}
	scrollbar.Color=color1 or Color.saddle_brown
	scrollbar:OnClicked(function(b,self,x,y)
		love.mouse.setX(self.x+10)
		if y>=10 and y<=self.height-10 then
			self.mover:SetDualDim(0,y-10)
		end
		if y<10 then
			love.mouse.setY(10+self.y)
		end
		if y>self.height-10 then
			love.mouse.setY((self.height-10)+self.y)
		end
		for i=1,#self.funcS do
			self.funcS[i](self,self:getPosition())
		end
	end)
	scrollbar:OnEnter(function(self)
		self:addDominance()
	end)
	scrollbar:OnExit(function(self)
		self:removeDominance()
	end)
	scrollbar.mover=scrollbar:newTextButton("","",0,0,20,20)
	scrollbar.mover.Color=color2 or Color.light_brown
	function scrollbar:getPosition()
		return ((self.mover.offset.pos.y)/(self.height-20))*100
	end
	function scrollbar:setPosition(n)
		print((self.height-20),n)
		self.mover.offset.pos.y=((self.height-20)/(100/n))
		for i=1,#self.funcS do
			self.funcS[i](self,self:getPosition())
		end
	end
	function scrollbar:OnScroll(func)
		table.insert(self.funcS,func)
	end
	return scrollbar
end
function gui:newScrollMenu(title,tabN,onloop,x, y, w, h, sx ,sy ,sw ,sh)
	local Main = self:newFrame(x, y, w, h, sx ,sy ,sw ,sh)
	local Title=Main:newTextButton(title,"Title",0,0,0,20,0,0,1)
	Title.Tween=-4
	Title.FontSize=12
	Title:OnReleased(function(b,self)
		self.Parent.Tick=not(self.Parent.Tick)
	end)
	local scroll=Main:newTextButton("","Scroll",-20,20,20,-20,1,0,0,1)
	scroll:OnClicked(function(b,self,x,y)
		self.Parent.Mover:SetDualDim(0,y-10,20,20)
		if self.Parent.Mover.offset.pos.y<0 then
			self.Parent.Mover:SetDualDim(0,0,20,20)
		end
		if self.Parent.Mover.offset.pos.y>self.Parent.height-40 then
			self.Parent.Mover:SetDualDim(0,self.Parent.height-40,20,20)
		end
		local temp = #self.Parent.TList
		self.Parent.pos=(math.floor((temp*self.Parent.Mover.offset.pos.y)/self.height))+1
	end)
	Main:OnUpdate(function(self)
		if self.Tick==false then
			self.Visibility=0
		end
	end)
	scroll:OnUpdate(function(self)
		self.Visible=self.Parent.Tick
	end)
	local Mover=scroll:newTextLabel("",0,0,20,20)
	Main.Mover=Mover
	Main.TList=tabN
	Main.pos=1
	Main.Tick=true
	function Main:Update(title,tabN,onloop)
		ch=self:getChildren()
		for i=#ch,1,-1 do
			ch[i]:Destroy()
		end
		Title=Main:newTextButton(title,"Title",0,0,0,20,0,0,1)
		Title.Tween=-4
		Title.FontSize=12
		Title:OnReleased(function(b,self)
			self.Parent.Tick=not(self.Parent.Tick)
		end)
		scroll=Main:newTextButton("","Scroll",-20,20,20,-20,1,0,0,1)
		scroll:OnClicked(function(b,self,x,y)
			self.Parent.Mover:SetDualDim(0,y-10,20,20)
			if self.Parent.Mover.offset.pos.y<0 then
				self.Parent.Mover:SetDualDim(0,0,20,20)
			end
			if self.Parent.Mover.offset.pos.y>self.Parent.height-40 then
				self.Parent.Mover:SetDualDim(0,self.Parent.height-40,20,20)
			end
			local temp = #self.Parent.TList
			self.Parent.pos=(math.floor((temp*self.Parent.Mover.offset.pos.y)/self.height))+1
		end)
		local Mover=scroll:newTextLabel("",0,0,20,20)
		Main.Mover=Mover
		Main.TList=tabN
		Main.pos=1
		Main.Tick=true
		scroll:OnUpdate(function(self)
			self.Visible=self.Parent.Tick
		end)
		for i=1,math.floor(Main.height/20)-1 do
			local temp=Main:newTextButton("","Item"..i,0,i*20,-20,20,0,0,1)
			temp.FontSize=10
			temp.Tween=-4
			temp.pos=i
			temp:OnUpdate(function(self)
				self.text=self.Parent.TList[(self.Parent.pos+self.pos)-1]
				self.Visible=self.Parent.Tick
			end)
			if onloop then
				onloop(temp,i)
			end
		end
	end
	io.write(tostring(Main.height).."\n")
	for i=1,math.floor(Main.height/20)-1 do
		local temp=Main:newTextButton("Item"..i,0,i*20,-20,20,0,0,1)
		temp.FontSize=10
		temp.Tween=-4
		temp.pos=i
		temp:OnUpdate(function(self)
			if self.Parent.TList[(self.Parent.pos+self.pos)-1]~=nil then
				self.text=self.Parent.TList[(self.Parent.pos+self.pos)-1]
			else
				self.text=""
			end
			self.Visible=self.Parent.Tick
		end)
		if onloop then
			onloop(temp,i)
		end
	end
	return Main
end
function gui:destroyAllChildren()
	local c=self.Children
	for i=1,#c do
		c[i]:Destroy()
	end
end
function gui:removeDominance()
	_GuiPro.TopHovered=nil
end
function gui:respectHierarchy()
	_GuiPro.Hierarchy=true
end
function gui.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end
function gui.setBG(i)
	gui.ff:SetImage(i)
end
function gui:setColor(a,b,c)
	if type(a)=="string" then
		self.Color=Color[a]
	elseif type(a)=="number" then
		self.Color=Color.new(a,b,c)
	end
end
function gui:setTextColor(a,b,c)
	if type(a)=="string" then
		self.TextColor=Color[a]
	elseif type(a)=="number" then
		self.TextColor=Color.new(a,b,c)
	end
end
function gui:setDefualtFont(font)
  _defaultfont = font
end
function gui:SetDualDim(x, y, w, h, sx ,sy ,sw ,sh)
	if _GuiPro.DPI_ENABLED then
		if x then
			x=self.DPI*x
		end
		if y then
			y=self.DPI*y
		end
		if w then
			w=self.DPI*w
		end
		if h then
			h=self.DPI*h
		end
	end
	if sx then
		self.scale.pos.x=sx
	end
	if sy then
		self.scale.pos.y=sy
	end
	if x then
		self.offset.pos.x=x
	end
	if y then
		self.offset.pos.y=y
	end
	if sw then
		self.scale.size.x=sw
	end
	if sh then
		self.scale.size.y=sh
	end
	if w then
		self.offset.size.x=w
	end
	if h then
		self.offset.size.y=h
	end
	if self.Image then
		self:SetImage(self.Image)
	end
end
function gui:setDualDim(...)
  self:SetDualDim(...)
end
function gui:setText(txt)
	self.text=txt
end
function gui:getText(txt)
	return self.text
end
--_GuiPro.CursorN=love.mouse.getSystemCursor("arrow")
--_GuiPro.CursorH=love.mouse.getSystemCursor("hand")
function gui:SetHand(img,x,y)
	--_GuiPro.CursorN=love.mouse.newCursor(img,x,y)
end
function gui:setHotKey(key)
	local tab=key:split("+")
	self.hotkeys=tab
	self.cooldown=false
	self.Alarm=multi:newAlarm(1)
	self.Alarm.parent=self
	self.args={}
	self.funcHK=multi:newConnection()
	self.Alarm:OnRing(function(alarm) alarm.parent.cooldown=false end)
	function self:OnHotKey(func)
		self.funcHK:connect(func)
	end
	self:OnUpdate(function(self)
		if self.cooldown then return end
		for i=1,#self.hotkeys do
			if not(love.keyboard.isDown(self.hotkeys[i])) then
				return
			end
		end
		self.cooldown=true
		self.funcHK:Fire(self)
		self.Alarm:Reset()
	end)
end
function gui:SetHover(img,x,y)
	--_GuiPro.CursorH=love.mouse.newCursor(img,x,y)
end
function gui:SetName(name)
	self.Parent.Children[name]=self
	self.Name=name
end
function gui:setNewFont(FontSize)
	self.Font=love.graphics.setNewFont(tonumber(FontSize))
end
function gui:setParent(parent,name)-- Needs fixing!!!
	local temp=self.Parent:getChildren()
	for i=1,#temp do
		if temp[i]==self then
			table.remove(self.Parent.Children,i)
			break
		end
	end
	table.insert(parent.Children,self)
	self.Parent=parent
	if name then
		self:SetName(name)
	end
end
function gui:setVisiblity(val)
	self.Visible=val
	self.oV=val
	doto=self:GetAllChildren()
	if val==false then
		for i=1,#doto do
			doto[i].Visible=val
		end
	else
		for i=1,#doto do
			doto[i].Visible=doto[i].oV
		end
	end
end
function gui:TopStack()
	childs=self.Parent:getChildren()
	for i=1,#childs do
		if childs[i]==self then
			table.remove(self.Parent.Children,i)
			table.insert(self.Parent.Children,self)
			break
		end
	end
end
function string:insert(p,s)
    return ("%s%s%s"):format(self:sub(1,p), s, self:sub(p+1))
end
function string:remove(p,l)
	l=l or 1
    return ("%s%s"):format(self:sub(1,p-1), self:sub(p+l))
end
function gui:newTextBox(t,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("TextBox",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.ClearOnFocus=false
	c.LoseFocusOnEnter=true
	c.Tween=0
	c.XTween=0
	c.FontHeight=_defaultfont:getHeight()
	c.Font=_defaultfont
	c.FontSize=15
	c.TextFormat="center"
    c.text = t
	c.ttext= t
	c.AutoScaleText=false
	c.TextVisibility=1
    c.Color = {220, 220, 220}
    c.TextColor = {0, 0, 0}
	c.Active=false
	c.hidden=false
	c.cursor={0,1}
	c.mark=nil
	c.arrowkeys=false
	c.funcF={function()
		love.keyboard.setTextInput(true)
	end}
	c.cooldown=false
	c.cooldown2=false
	c.funcE={function()
		love.keyboard.setTextInput(false)
	end}
	function c:triggerEnter()
		for cc=1,#self.funcE do
			self.funcE[cc](self,self.ttext)
		end
		self.text=""
		self.ttext=""
	end
	c.Enter=true
	c.Alarm=multi:newAlarm(.1)
	c.Alarm.parent=c
	c.Alarm:OnRing(function(alarm) alarm.parent.cooldown=false end)
	c.Alarm2=multi:newAlarm(.5)
	c.Alarm2.parent=c
	c.Alarm2:OnRing(function(alarm) alarm.parent.cooldown2=false end)
	c.ArrowAlarm=multi:newAlarm(.1)
	c.ArrowAlarm.parent=c
	c.ArrowAlarm:OnRing(function(alarm) alarm.parent.arrowkeys=false end)
	function c:OnFocus(func)
		table.insert(self.funcF,func)
	end
	function c:OnEnter(func)
		table.insert(self.funcE,func)
	end
	c:OnClicked(function(b,self)
		for cc=1,#self.funcF do
			self.funcF[cc](self)
		end
		if self.Active==false then
			if self.ClearOnFocus==true then
				self.text=""
				self.ttext=""
			end
			for tb=1,#gui.TB do
				if gui.TB[tb]~=nil then
					gui.TB[tb].Active=false
				end
			end
			self.Active=true
		end
	end)
	c:OnClicked(function(b,self,x,y)
		local dwidth, wrappedtext = _defaultfont:getWrap(self.text:sub(1,self.cursor[1]), self.width)
		local height = _defaultfont:getHeight()
		if #wrappedtext>=1 then
			width= _defaultfont:getWidth(wrappedtext[#wrappedtext])
			self.cursor[2]=#wrappedtext
		else
			self.cursor[2]=1
			width=0
		end
		yc=math.ceil(((y/self.DPI)-(self.FontHeight/2)+self.Tween-self.y)/height)
		xc=math.floor(x)
	end)
	c:AddDrawRuleE(function(self)
		if self.Active then
			local dwidth, wrappedtext = _defaultfont:getWrap(self.text:sub(1,self.cursor[1]), self.width)
			local height = _defaultfont:getHeight()
			if #wrappedtext>=1 then
				width= _defaultfont:getWidth(wrappedtext[#wrappedtext])
				self.cursor[2]=#wrappedtext
			else
				self.cursor[2]=1
				width=0
			end
			x1=width+2+self.x+self.XTween
			y1=(self.y+(height*(self.cursor[2]-1))+(self.FontHeight/2)+self.Tween)*self.DPI
			x2=width+2+self.x+self.XTween
			y2=(self.y+(self.FontHeight/2)+self.Tween*self.DPI)+height*self.cursor[2]
			love.graphics.line(x1,y1,x2,y2)
			end
	end)
	c:OnUpdate(function(self)
		if love.keyboard.isDown("backspace") and self.Active and self.cooldown==false then
			if #self.text>0 then
				self.text = self.text:remove(self.cursor[1])
				self.ttext = self.ttext:remove(self.cursor[1])
				self.cursor[1]=self.cursor[1]-1
			end
			self.cooldown=true
			self.Alarm:Reset()
		elseif love.keyboard.isDown("backspace")==false then
			self.cooldown=false
		end
		if love.keyboard.isDown("left") and self.arrowkeys==false and self.Active then
			self.arrowkeys=true
			self.cursor[1]=self.cursor[1]-1
			if self.cursor[1]<0 then
				self.cursor[1]=0
			end
			self.ArrowAlarm:Reset()
		elseif love.keyboard.isDown("right") and self.arrowkeys==false and self.Active then
			self.arrowkeys=true
			self.cursor[1]=self.cursor[1]+1
			if self.cursor[1]>#self.text then
				self.cursor[1]=#self.text
			end
			self.ArrowAlarm:Reset()
		end
		if love.keyboard.isDown("delete") and self.Active then
			if #self.text>0 then
				self.text = ""
				self.ttext = ""
				self.cursor[1]=1
			end
		elseif (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and love.keyboard.isDown("return") and self.cooldown2==false then
			self.text=self.text.."\n"
			self.ttext=self.ttext.."\n"
			self.cooldown2=true
			c.Alarm2:Reset()
		elseif (love.keyboard.isDown("return") or love.keyboard.isDown("enter") or love.keyboard.isDown("kpenter")) and self.Active and self.Enter and not(love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
			if self.LoseFocusOnEnter then
				self.Active=false
			else
				self.Active=true
			end
			for cc=1,#self.funcE do
				self.funcE[cc](self,self.ttext)
			end
		end
	end)
	table.insert(gui.TB,c)
    return c
end
--TEXT BOX HELPER FUNCTION
function love.textinput(t)
	for tb=1,#gui.TB do
		if gui.TB[tb]~=nil then
			if gui.TB[tb].Active then
				if gui.TB[tb].hidden then
					--gui.TB[tb].text=gui.TB[tb].text.."*"
					gui.TB[tb].text=gui.TB[tb].text:insert(gui.TB[tb].cursor[1],"*")
				else
					--gui.TB[tb].text=gui.TB[tb].text..t
					gui.TB[tb].text=gui.TB[tb].text:insert(gui.TB[tb].cursor[1],t)
				end
				gui.TB[tb].ttext=gui.TB[tb].ttext:insert(gui.TB[tb].cursor[1],t)
				gui.TB[tb].cursor[1]=gui.TB[tb].cursor[1]+1
			end
		end
	end
end
function gui:newTextButton(t,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("TextButton",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.Tween=0
	c.XTween=0
	c.FontHeight=_defaultfont:getHeight()
	c.Font=_defaultfont
	c.FontSize=15
	c.TextFormat="center"
	c.text = t
	c.AutoScaleText=false
	c.TextVisibility=1 -- 0=invisible,1=solid (self.TextVisibility*254+1)
    c.Color = {220, 220, 220}
    c.TextColor = {0, 0, 0}
	c:OnEnter(function()
		--love.mouse.setCursor(_GuiPro.CursorH)
	end)
	c:OnExit(function()
		--love.mouse.setCursor(_GuiPro.CursorN)
	end)
    return c
end
function gui:newTextLabel(t,name, x, y, w, h, sx ,sy ,sw ,sh)
	x,y,w,h,sx,sy,sw,sh=filter(name, x, y, w, h, sx ,sy ,sw ,sh)
	local c=self:newBase("TextLabel",name, x, y, w, h, sx ,sy ,sw ,sh)
	c.Tween=0
	c.XTween=0
	c.FontHeight=_defaultfont:getHeight()
	c.Font=_defaultfont
	c.FontSize=15
	c.TextFormat="center"
    c.text = t
	c.AutoScaleText=false
	c.TextVisibility=1 -- 0=invisible,1=solid (self.TextVisibility*254+1)
    c.Color = {220, 220, 220}
    c.TextColor = {0, 0, 0}
    return c
end
function gui:AddDrawRuleB(rule)
	if not(self.DrawRulesB) then self.DrawRulesB={} end
	table.insert(self.DrawRulesB,rule)
end
function gui:AddDrawRuleE(rule)
	if not(self.DrawRulesE) then self.DrawRulesE={} end
	table.insert(self.DrawRulesE,rule)
end
function gui:draw()
	if _GuiPro.rotate~=0 then
		love.graphics.rotate(math.rad(_GuiPro.rotate))
	end
	if self.FormFactor:lower()=="rectangle" then
		self:drawR()
	elseif self.FormFactor:lower()=="circle" then
		self:drawC()
	else
		error("Unsupported FormFactor: "..self.FormFactor.."!")
	end
end
function gui:drawC()
	if love.mouse.isDown("l")==false and love.mouse.isDown("m")==false and love.mouse.isDown("r")==false then
		_GuiPro.DragItem={}
		_GuiPro.hasDrag=false
	end
	if self.Visible==true and self.VIS==true then
		local b=true
		for i,v in pairs(_GuiPro.Clips) do
			if self:isDescendant(v)==true then
				b=false
			end
		end
		if b then
			love.graphics.setStencilTest( )
			_GuiPro.HasStencel=false
			_GuiPro.StencelHolder=nil
		end
		local x,y,r,s=(self.offset.pos.x or 0)+self.Parent.x,(self.offset.pos.y or 0)+self.Parent.y,self.offset.size.x or 0,self.offset.size.y or 360
		if self.CC then
			x,y=x+r,y+r
		end
		self.x,self.y=x,y
		_GuiPro.circleStencilFunction = function()
			love.graphics.circle("fill",x,y,r,s)
		end
		if math.sqrt((love.mouse.getX()-x)^2+(love.mouse.getY()-y)^2)<=r and self:eventable() and self:Clickable() and self.Active==true then
			self.hovering=true
			if love.mouse.isDown("l") and _GuiPro.hasDrag==false then
				if string.find(self.Type, "Button") then
					love.graphics.setColor(self.Color[1]-10, self.Color[2]-10, self.Color[3]-10,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.lclicked=true
			elseif love.mouse.isDown("r") and _GuiPro.hasDrag==false then
				if string.find(self.Type, "Button") then
					love.graphics.setColor(self.Color[1]-10, self.Color[2]-10, self.Color[3]-10,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.rclicked=true
			elseif love.mouse.isDown("m") and _GuiPro.hasDrag==false then
				if string.find(self.Type, "Button") then
					love.graphics.setColor(self.Color[1]-10, self.Color[2]-10, self.Color[3]-10,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.mclicked=true
			else
				if string.find(self.Type, "Button") and _GuiPro.hasDrag==false then
					love.graphics.setColor(self.Color[1]-5, self.Color[2]-5, self.Color[3]-5,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.rclicked=false
				self.lclicked=false
				self.mclicked=false
			end
		else
			love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
			self.hovering=false
			self.rclicked=false
			self.lclicked=false
			self.mclicked=false
		end
		if self.ClipDescendants==true then
			_GuiPro.Clips[tostring(self)]=self
			_GuiPro.HasStencel=true
			_GuiPro.StencelHolder=self
			love.graphics.stencil(_GuiPro.circleStencilFunction)
			love.graphics.setStencilTest("notequal",0)
		end
		love.graphics.circle("fill",x,y,r,s)
		love.graphics.setColor(self.BorderColor[1], self.BorderColor[2], self.BorderColor[3],self.Visibility*254)
		for b=0,self.BorderSize-1 do
			love.graphics.circle("line",x,y,r+b,s)
		end
		if string.find(self.Type, "Text") then
			if self.text~=nil then
				if self.AutoScaleText then
					self.FontSize=math.floor(self.height/1.45833)
				end
				love.graphics.setColor(self.TextColor[1],self.TextColor[2],self.TextColor[3],self.TextVisibility*254)
				love.graphics.setFont(self.Font)
				love.graphics.printf(self.text, x-(r/2)+(self.XTween), y-(r/2)+self.Tween, r, self.TextFormat)
			end
		end
	end
end
function gui:drawR()
	if love.mouse.isDown("l")==false and love.mouse.isDown("m")==false and love.mouse.isDown("r")==false then
		_GuiPro.DragItem={}
		_GuiPro.hasDrag=false
	end
	if self.Visible==true and self.VIS==true then
		local b=true
		for i,v in pairs(_GuiPro.Clips) do
			if self:isDescendant(v)==true then
				b=false
			end
		end
		if b==true then
			love.graphics.setStencilTest()
			love.graphics.setScissor()
		end
		self.x=(self.Parent.width*self.scale.pos.x)+self.offset.pos.x+self.Parent.x
		self.y=(self.Parent.height*self.scale.pos.y)+self.offset.pos.y+self.Parent.y
		self.width=(self.Parent.width*self.scale.size.x)+self.offset.size.x
		self.height=(self.Parent.height*self.scale.size.y)+self.offset.size.y
		if self.DrawRulesB then
			for dr=1,#self.DrawRulesB do
				self.DrawRulesB[dr](self)
			end
		end
		if (love.mouse.getX() > self.x and love.mouse.getX() < self.x+self.width and love.mouse.getY() > self.y and love.mouse.getY() < self.y+self.height and self:Clickable() and self:eventable()) or self:touchable("r") and self.Active==true then
			self.hovering=true
			if love.mouse.isDown("l") or self:touchable("r") and _GuiPro.hasDrag==false then
				if string.find(self.Type, "Button") then
					love.graphics.setColor(self.Color[1]-10, self.Color[2]-10, self.Color[3]-10,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.lclicked=true
			elseif love.mouse.isDown("r") or self:touchable("r") and _GuiPro.hasDrag==false then
				if string.find(self.Type, "Button") then
					love.graphics.setColor(self.Color[1]-10, self.Color[2]-10, self.Color[3]-10,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.rclicked=true
			elseif love.mouse.isDown("m") or self:touchable("r") and _GuiPro.hasDrag==false then
				if string.find(self.Type, "Button") then
					love.graphics.setColor(self.Color[1]-10, self.Color[2]-10, self.Color[3]-10,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.mclicked=true
			else
				if string.find(self.Type, "Button") or self:touchable("r") and _GuiPro.hasDrag==false then
					love.graphics.setColor(self.Color[1]-5, self.Color[2]-5, self.Color[3]-5,self.Visibility*254)
				else
					love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
				end
				self.rclicked=false
				self.lclicked=false
				self.mclicked=false
			end
		else
			love.graphics.setColor(self.Color[1],self.Color[2],self.Color[3],self.Visibility*254)
			self.hovering=false
			self.rclicked=false
			self.lclicked=false
			self.mclicked=false
		end
		if self.ClipDescendants==true then
			_GuiPro.Clips[tostring(self)]=self
			love.graphics.setScissor(self.x, self.y, self.width, self.height)
		end
    if self:hasRoundness() then
      love.graphics.stencil(self.stfunc, "replace", 1)
      love.graphics.setStencilTest("greater", 0)
    end
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height,(self.rx or 1)*self.DPI,(self.ry or 1)*self.DPI,(self.segments or 1)*self.DPI)
		if string.find(self.Type, "Image") then
			self:ImageRule()
		end
		if self.Type=="Video" then
			self:VideoRule()
		end
    if self:hasRoundness() then
      love.graphics.setStencilTest()
    end
		love.graphics.setColor(self.BorderColor[1], self.BorderColor[2], self.BorderColor[3],self.Visibility*254)
		for b=0,self.BorderSize-1 do
			love.graphics.rectangle("line", self.x-(b/2), self.y-(b/2), self.width+b, self.height+b,(self.rx or 1)*self.DPI,(self.ry or 1)*self.DPI,(self.segments or 1)*self.DPI)
		end
		if string.find(self.Type, "Text") then
			if self.text~=nil then
				if self.AutoScaleText then
					self.FontSize=math.floor(self.height/1.45833)
				end
				love.graphics.setColor(self.TextColor[1],self.TextColor[2],self.TextColor[3],self.TextVisibility*254)
				if self.Font==_defaultfont then
					love.graphics.setFont(self.Font)
					love.graphics.printf(self.text, self.x+2+(self.XTween*self.DPI)+((self.marginL or 0)*self.DPI or self.XTween*self.DPI), self.y+(self.FontHeight/2)+self.Tween*self.DPI, self.width+(0 or (self.marginR or 0)*self.DPI), self.TextFormat)
				else
					if type(self.Font)=="string" then
						self.Font=love.graphics.newFont(self.Font,self.FontSize)
						self.FontHeight=self.Font:getHeight()
					else
						love.graphics.setFont(self.Font)
					end
					if type(self.FontSize)=="string" then
						self.FontSize=tonumber(self.FontSize)
						love.graphics.setNewFont(self.FontSize)
					end
					love.graphics.printf(self.text, self.x+2+((self.marginL or 0)*self.DPI or self.XTween*self.DPI), self.y+math.floor((self.FontHeight-self.FontSize)/2)+self.Tween*self.DPI, self.width+(0 or (self.marginR or 0)*self.DPI), self.TextFormat)
				end
			end
		end
		if self.DrawRulesE then
			for dr=1,#self.DrawRulesE do
				self.DrawRulesE[dr](self)
			end
		end
	end
end

gui:respectHierarchy()
_GuiPro.width,_GuiPro.height=love.graphics.getDimensions()
multi:newLoop():OnLoop(function() _GuiPro.width,_GuiPro.height=love.graphics.getDimensions() _GuiPro:update() end)
multi:onDraw(function() _GuiPro:draw() end)
gui.ff=gui:newFrame("",0,0,0,0,0,0,1,1)
gui.ff.Color={255,255,255}
gui.ff:OnUpdate(function(self)
	self:BottomStack()
end)

