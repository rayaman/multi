function difference(a, b)
    local ai = {}
    local r = {}
	local rr = {}
    for k,v in pairs(a) do r[k] = v; ai[v]=true end
    for k,v in pairs(b) do 
        if ai[v]==nil then table.insert(rr,r[k]) end
    end
    return rr
end
function remove(a, b)
    local ai = {}
	local r = {}
    for k,v in pairs(a) do ai[v]=true end
    for k,v in pairs(b) do 
        if ai[v]==nil then table.insert(r,a[k]) end
	end
    return r
end

function printtab(tab,msg)
	print(msg or "TABLE")
	for i,v in pairs(tab) do
		print(i, v)
	end
	print("")
end

local tab1 = {1,2,3,4,5}
local tab2 = {3,4,5,6,7}
tab1 = remove(tab1,tab2)
printtab(tab1, "Table 1")
printtab(tab2, "Table 2")
