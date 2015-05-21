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

TEMPFILE_SEARCH=$(mktemp -t missing_search)

./TVcheck.sh -i

## Fuction 'usage', displays usage information
function usage {
cat << EOF
usage: $script_path/$script_file options

This script has the following options.

OPTIONS:
   -a   Check gap for all TV shows.
   -s   Check gap for a single show.
   -d   Download missing episodes from PB.
		
EOF
}

function gap_one {
	./getshowcfg.sh -n -s "$SERACH" > $TEMPFILE_SEARCH

	## If there is no match found, exit!
	if (( $? == 51 )); then
	 	echo "No match!"
	 	exit 1
	fi
	
	. $TEMPFILE_SEARCH

	if [ -f $TEMPFILE_SEARCH ]; then
		rm $TEMPFILE_SEARCH
	fi

	showname=$show_name
	showpath=$store_path

	echo "Show Name: $showname"

	if [[ $showpath == "Show path not there!" ]]; then
		echo "Error: Nothing in Store for That Show!"
		exit 1
	fi

	IFS_store=$IFS
	IFS=$'\r\n'
	season_paths=$(ls -1 $showpath | grep "Season " | sed 's/Season //' | sort -n | sed 's/^/Season /')
	
	## Count how many Season folders
	num_season_paths=$(echo "$season_paths" | wc -l | bc)

	## High mark
	high_mark=$(showinfo -n -s "$showname")
	high_season=$(echo "$high_mark" | head -n 1 | sed 's/Season //' | tr -d $'\r' | bc )
	high_episode=$(echo "$high_mark" | tail -n 1 | sed 's/Episode //' | tr -d $'\r' | bc )

	printn "   High Mark" "Season $high_season Episode $high_episode"

	while read -r line; do
		line_num=$(sed 's/^Season //' <<< $line)
		printf "   Checking Folder       : $line "
		## If season number is one digit, print an extra space
		if (( $line_num <= 9 )); then
			printf " "
		fi
		./episodegap.sh "$showpath/$line" $line_num $showname $high_season $high_episode $downloadfrompb_flag $show_quality $num_season_paths
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
		## Only print newline between shows, not after last
		if (( $file_lines > $count_line )); then
			nl
			(( count_line++ ))
		fi
	done
}

downloadfrompb_flag="false"

while getopts “adhs:” opt_val; do
        case $opt_val in
                a) gap_all; exit 0;;
				d) downloadfrompb_flag="true";;
                h) usage; exit 0;;
                s) SERACH=$OPTARG; gap_one; exit 0;;
                *) usage; exit 1;;
        esac
done

usage
