commands = [[
mkdir luajit && python -m hererocks -j 2.1.0-beta3 -r latest --patch --compat all ./luajit && set "PATH=G:\VSCWorkspace\multi\luajit\bin;%PATH%" && lua -v && luarocks install multi
mkdir lua5.1 && python -m hererocks -l 5.1 -r latest --patch --compat all ./lua5.1 && set "PATH=G:\VSCWorkspace\multi\luajit\bin;%PATH%" && lua -v && luarocks install multi
mkdir lua5.2 && python -m hererocks -l 5.2 -r latest --patch --compat all ./lua5.2 && set "PATH=G:\VSCWorkspace\multi\luajit\bin;%PATH%" && lua -v && luarocks install multi
mkdir lua5.3 && python -m hererocks -l 5.3 -r latest --patch --compat all ./lua5.3 && set "PATH=G:\VSCWorkspace\multi\luajit\bin;%PATH%" && lua -v && luarocks install multi
mkdir lua5.4 && python -m hererocks -l 5.4 -r latest --patch --compat all ./lua5.4 && set "PATH=G:\VSCWorkspace\multi\luajit\bin;%PATH%" && lua -v && luarocks install multi
]]
function string.split (inputstr, sep)
	local sep = sep or "\n"
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end
local run = commands:split()
for i=1,#run do
	os.execute(run[i])
end