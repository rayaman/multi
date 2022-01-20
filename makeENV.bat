mkdir lua5.1
mkdir lua5.2
mkdir lua5.3
mkdir lua5.4
mkdir luajit
python -m hererocks -j 2.1.0-beta3 -r latest --compat all ./luajit
python -m hererocks -l 5.1 -r latest --compat all ./lua5.1
python -m hererocks -l 5.2 -r latest --compat all ./lua5.2
python -m hererocks -l 5.3 -r latest --compat all ./lua5.3
python -m hererocks -l 5.4 -r latest --compat all ./lua5.4