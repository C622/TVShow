#!/bin/bash

callpath=$(dirname $0)
currentpath=$(pwd)
cd $callpath

. ./TVShow.cfg


function gap_one {
	showname=$(grep -i "$SERACH" $installpath/$showlist | sed -n -e 's/name = "\(.*\)"/\1/p' | head -n1)
	showpath=$(head -n1 "$indexfiles/$showname.cfg")

	IFS_store=$IFS
	IFS=$'\r\n'
	season_paths=$(ls -1 $showpath | grep "Season ")

	while read -r line; do
		line_num=$(sed 's/^Season //' <<< $line)
		./episodegap.sh "$showpath/$line" $line_num $showname
	done <<< "$season_paths"
	
	IFS=$IFS_store
}

function gap_all {
	while read line_titel
	do
		SERACH=$line_titel
		gap_one
	done < $indexfiles/showlist.cfg
}

while getopts “has:” opt_val
do
        case $opt_val in
                h) usage; exit 0;;
                a) gap_all; exit 0;;
                s) SERACH=$OPTARG; gap_one; exit 0;;
                *) usage; exit 1;;
        esac
done
