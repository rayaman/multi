function alphanumsort(o)
	local function padnum(d) local dec, n = string.match(d, "(%.?)0*(.+)")
		return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n)
	end
	table.sort(o, function(a,b) return tostring(a):gsub("%.?%d+",padnum)..("%3d"):format(#b)< tostring(b):gsub("%.?%d+",padnum)..("%3d"):format(#a) end)
	return o
end