#!/bin/bash
show="$1"

. ./TVShow.cfg

## Fuction 'usage', displays usage information
usage()
{
cat << EOF
usage: $0

This script needs be called with one option. This would be the string to serach for, i.e. "CSI"

EOF
}

if [[ -z $1 ]]
	then
	usage
	exit 1
fi


if [ -f "$installpath/$indexfiles/$show.cfg" ]; then
	#read -r showpath < $installpath/$indexfiles/"$show".cfg
	. $installpath/$indexfiles/"$show".cfg
else
	echo "CFG File not here!"
	exit 1
fi

if [ -d "$store_path" ]; then
	seasonnum=$(ls -t1 "$store_path" | grep '^Season' | sed -E 's/^Season ([0-9]*).*$/\1/' | sort -n -r | head -n 1)
	seasonpath=$(echo "Season $seasonnum")
else
	echo "store_season='S-NON'"
	echo "store_episode='E-NON'"
	exit 2
fi

if [ -d "$store_path"/"$seasonpath" ]; then
	episodenum=$(ls -1 "$store_path"/"$seasonpath" | \
	sed -E 's/^.*[Ss][0-9][0-9].*[Ee]([0-9][0-9]).*/\1/' | \
	sed -E 's/^.*[0-9]{1,2}x([0-9][0-9]).*/\1/' | \
	sort -r | \
	sed 's/^0//' | \
	grep "^[0-9]" | \
	head -n 1)
fi

if ! [ -z "$seasonnum" ]; then 
	echo "store_season='$seasonnum'"
else
	echo "store_season='S-NON'"
fi

if ! [ -z "$episodenum" ]; then
	echo "store_episode='$episodenum'"
else
	echo "store_episode='E-NON'"
fi
