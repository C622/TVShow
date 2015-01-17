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

dirpath=$1
season=$2
showname=$3
high_season=$4
high_episode=$5
match=0

## If no path given -----> Current path will be used
if [ -z "$dirpath" ]; then
	dirpath=$current_path
fi

## If no high_season given -----> Set to 99
if [ -z "$high_season" ]; then
	high_season=99
fi

## If no high_episode given -----> Set to 99
if [ -z "$high_episode" ]; then
	high_episode=99
fi

## If no season given -----> Set to number on folder
if [ -z "$season" ]; then
	season=`sed 's/^.*Season //' <<< $dirpath`
fi

## If no showname given -----> Set to last in list
if [ -z "$showname" ]; then
#	last=${list[$size-1]}
	showname=`sed 's/^.*\/\(.*\)\/Season .*$/\1/' <<< $dirpath`
fi


function find_gap ()
{
	IFS=$'\r\n'
	list=($(ls "$dirpath" | grep -E '([sS][0-9][0-9][eE][0-9][0-9]|[0-9]x[0-9][0-9]|[0-9][0-9]x[0-9][0-9])' | grep -E '(.mkv$|.avi$|.mpg$|.mpeg$|.wmv$|.mov$|.m4v$|.mp4$|.3gp$)' | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*[eE]\([0-9][0-9]\).*/\1#\2/' | tr '#' '\n' | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*/\1/' | sed 's/^.*[0-9][0-9]x\([0-9][0-9]\).*$/\1/' | sed 's/^.*[0-9]x\([0-9][0-9]\).*$/\1/' | sort | bc))

	size=${#list[@]}

	if [[ $size == 0 ]]; then
		printm "Path" "$dirpath"
		printm "Error" "No episodes found in folder"
		exit 1
	fi

	first=${list[0]}

	last=$(./episodenames.sh $showname $season | tail -n2 | head -n1 | sed -E 's/Episode ([0-9]{1,2}).*$/\1/' | bc)		
	
	if [ -z "$last" ]; then
		last=${list[$size-1]}
	fi

	# printm "showname" "$showname"
	# printm "season" "$season"
	# printm "last" "$last"

	if [[ $season == $high_season ]]; then
		if (( "$last" > "$high_episode" )); then
			last=$high_episode
		fi
	fi
		
	for i in $(seq 1 $first); do
		found=0
		for j in $(seq 0 $[size-1]); do
			if [ ${list[$j]} == $i ]; then
				found=1
			fi
		done
		if [ $found == 0 ]; then
			if [ $match == 0 ]; then
				printm "Path" "$dirpath"
			fi
			printm "* Missing Episode" "$showname S$season E$i"
			match=1
		fi
	done

	if ! [[ "$first" == "$last" ]]; then
		for i in $(seq $[first+1] $last); do
			found=0
			for j in $(seq 0 $[size-1]); do
				if [ ${list[$j]} == $i ]; then
					found=1
				fi
			done
			if [ $found == 0 ]; then
				if [ $match == 0 ]; then
					printm "Path" "$dirpath"
				fi
				printm "* Missing Episode" "$showname S$season E$i"
				match=1
			fi
		done
	fi
	
	# if [ $match == 1 ]; then
	# 	echo
	# fi
}

find_gap
