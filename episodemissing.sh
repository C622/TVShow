#!/bin/bash

## Script start...
## Change working directory to path of the called scripted
## This needs to be done regradless if the scripted is called direct or using a link

if [ -L $0 ]; then
	script_name=`readlink $0`
	script_path=`dirname $script_name`
	script_file=`basename $script_name`
else
	script_path=`dirname $0`					# relative
	script_path=`( cd $script_path && pwd )`	# absolutized and normalized
	script_file=`basename $0`
fi

if [ -z "$script_path" ] ; then
  exit 1
fi

current_path=`pwd`
cd $script_path

## Working directory is now set to the path of the called script
## Tree values are set: 
## script_path	: Path of the called script
## script_file	: Name of the called script
## current_path	: Path where is script was called from (Current path at that time)

. ./TVShow.cfg

printm_WIDTH=25
. $installpath/strings.func

./TVcheck.sh -i

## Fuction 'usage', displays usage information
function usage {
cat << EOF
usage: $script_path/$script_file options

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

	printm "Show name" "$showname"

	## High mark
	high_mark=$(showinfo -n -s "$showname")
	high_season=$(echo "$high_mark" | grep "Season " | sed "s/Season //" | bc)
	high_episode=$(echo "$high_mark" | grep "Episode " | sed "s/Episode //" | bc)

	while read -r line; do
		line_num=$(sed 's/^Season //' <<< $line)
		printm " - Checking folder" "$line"
		./episodegap.sh "$showpath/$line" $line_num $showname $high_season $high_episode
	done <<< "$season_paths"
	
	IFS=$IFS_store
}

function gap_all {
	IFS=$'\r\n'
	FILE=(`cat $indexfiles/showlist.cfg`)
	count_line=1
	file_lines=${#FILE[@]}
	for line_titel in "${FILE[@]}"; do
		SERACH=$line_titel
		gap_one
		if (( $file_lines > $count_line )); then
			nl
			(( count_line++ ))
		fi
	done
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
