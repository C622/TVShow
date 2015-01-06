#!/bin/bash

callpath=$(dirname $0)
currentpath=$(pwd)
cd $callpath

. ./TVShow.cfg

## Fuction 'usage', displays usage information
function usage {
cat << EOF
usage: $0 options

This script has the following options.

OPTIONS:
   -a   Check gap for all TV shows.
   -s   Check gap for a single show.
		
EOF
}

function gap_one {
	showname=$(grep -i "$SERACH" $installpath/$showlist | sed -n -e 's/name = "\(.*\)"/\1/p' | head -n1)
	showpath=$(head -n1 "$indexfiles/$showname.cfg")

	IFS_store=$IFS
	IFS=$'\r\n'
	season_paths=$(ls -1 $showpath | grep "Season ")

	echo "Checking... $showname"

	## High mark
	high_mark=$(showinfo -n -s "$showname")
	high_season=$(echo "$high_mark" | grep "Season " | sed "s/Season //" | bc)
	high_episode=$(echo "$high_mark" | grep "Episode " | sed "s/Episode //" | bc)

	while read -r line; do
		line_num=$(sed 's/^Season //' <<< $line)
		echo " --> $line"
		./episodegap.sh "$showpath/$line" $line_num $showname $high_season $high_episode
	done <<< "$season_paths"
	
	IFS=$IFS_store
}

function gap_all {
	while read line_titel; do
		SERACH=$line_titel
		gap_one
	done < $indexfiles/showlist.cfg
}

while getopts “has:” opt_val; do
        case $opt_val in
                h) usage; exit 0;;
                a) gap_all; exit 0;;
                s) SERACH=$OPTARG; gap_one; exit 0;;
                *) usage; exit 1;;
        esac
done

usage
