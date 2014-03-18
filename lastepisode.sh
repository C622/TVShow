#!/bin/bash
show="$1"

if [ -f "/Users/chris/Documents/Scripts/TVShow/ShowIndex/$show.cfg" ]; then
	read -r showpath < ~/Documents/Scripts/TVShow/ShowIndex/"$show".cfg
else
	echo "CFG File not here!"
	exit 1
fi

if [ -d "$showpath" ]; then
	seasonpath=$(echo "Season $(ls -t1 "$showpath" | grep '^Season' | sed -E 's/^Season ([0-9]*).*$/\1/' | sort -n -r | head -n 1)")
	seasonnum=$(sed -E 's/^Season (.*)/\1/' <<< $seasonpath)
	printf "$seasonnum\n"
else
	echo "Show path not there!"
	exit 2
fi

if [ -d "$showpath"/"$seasonpath" ]; then
	ls -1 "$showpath"/"$seasonpath" | \
	sed -E 's/^.*[Ss][0-9][0-9].*[Ee]([0-9][0-9]).*/\1/' | \
	sed -E 's/^.*[0-9][0-9]x([0-9][0-9]).*/\1/' | \
	sort -r | \
	sed 's/^0//' | \
	head -n 1
else
	echo "Episode path not there?!"
	exit 3
fi
