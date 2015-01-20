#!/bin/bash
show="$1"

if [ -f "/Users/chris/Documents/Scripts/TVShow/ShowIndex/$show.cfg" ]; then
	read -r showpath < ~/Documents/Scripts/TVShow/ShowIndex/"$show".cfg
else
	echo "CFG File not here!"
	exit 1
fi

if [ -d "$showpath" ]; then
	seasonnum=$(ls -t1 "$showpath" | grep '^Season' | sed -E 's/^Season ([0-9]*).*$/\1/' | sort -n -r | head -n 1)
	seasonpath=$(echo "Season $seasonnum")
else
	echo "Show path not there!"
	exit 2
fi

if [ -d "$showpath"/"$seasonpath" ]; then
	episodenum=$(ls -1 "$showpath"/"$seasonpath" | \
	sed -E 's/^.*[Ss][0-9][0-9].*[Ee]([0-9][0-9]).*/\1/' | \
	sed -E 's/^.*[0-9]{1,2}x([0-9][0-9]).*/\1/' | \
	sort -r | \
	sed 's/^0//' | \
	grep "^[0-9]" | \
	head -n 1)
fi

if ! [ -z "$seasonnum" ]; then 
	printf "$seasonnum\n"
else
	printf "S-NON\n"
fi

if ! [ -z "$episodenum" ]; then
	printf "$episodenum\n"
else
	printf "E-NON\n"
fi
