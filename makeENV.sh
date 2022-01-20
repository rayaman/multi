#!/bin/bash
mkdir luajit
hererocks -j 2.1.0-beta3 -r latest --compat all ./luajit
. luajit/bin/activate
echo | lua -v
luarocks install multi
deactivate-lua
mkdir lua5.1
hererocks -l 5.1 -r latest --patch --compat all ./lua5.1
. lua5.1/bin/activate
echo | lua -v
luarocks install multi
deactivate-lua
mkdir lua5.2
hererocks -l 5.2 -r latest --patch --compat all ./lua5.2
. lua5.2/bin/activate
echo | lua -v
luarocks install multi
deactivate-lua
mkdir lua5.3
hererocks -l 5.3 -r latest --patch --compat all ./lua5.3
. lua5.3/bin/activate
echo | lua -v
luarocks install multi
deactivate-lua
mkdir lua5.4
hererocks -l 5.4 -r latest --patch --compat all ./lua5.4
. lua5.4/bin/activate
echo | lua -v
luarocks install multi
deactivate-lua