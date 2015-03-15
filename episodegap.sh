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
downloadfrompb_flag=$6
show_quality=$7
num_season_paths=$8
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
	list=($(ls "$dirpath" | grep -E '([sS][0-9][0-9][eE][0-9][0-9]|[0-9]x[0-9][0-9]|[0-9][0-9]x[0-9][0-9])' | grep -iE '(.mkv$|.avi$|.mpg$|.mpeg$|.wmv$|.mov$|.m4v$|.mp4$|.3gp$)' | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*[eE]\([0-9][0-9]\).*/\1#\2/' | tr '#' '\n' | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*/\1/' | sed 's/^.*[0-9][0-9]x\([0-9][0-9]\).*$/\1/' | sed 's/^.*[0-9]x\([0-9][0-9]\).*$/\1/' | sort | bc))

	size=${#list[@]}
	
	if [[ $size == 0 ]]; then
		printf "\033[0;31m[ Error: No episodes found in folder ]\033[00m\n"
		nl
		printn "   Path" "$dirpath"
		# if ! (( $high_season <= $season )); then
		# 	nl
		# fi
		
		size=1
		list[0]=0
		match=1
#		high_season=$season
	fi

	first=${list[0]}

#	if [ -z "$first" ]; then
#		first=1
#	fi

	last=$(./episodenames.sh $showname $season | tail -n2 | head -n1 | sed -E 's/Episode ([0-9]{1,2}).*$/\1/' | bc)		
	
	if [ -z "$last" ]; then
		last=${list[$size-1]}
	fi

	if [[ $season == $high_season ]]; then
		if (( "$last" > "$high_episode" )); then
			last=$high_episode
		fi
	fi
	
	if ! [ ${list[0]} == 0 ]; then
		for i in $(seq 1 $first); do
			found=0
			for j in $(seq 0 $[size-1]); do
				if [ ${list[$j]} == $i ]; then
					found=1
				fi
			done
			if [ $found == 0 ]; then
				if [ $match == 0 ]; then
					printf "\033[0;31m[ Missing ]\033[00m\n"
					nl
					printn "   Path" "$dirpath"
				fi
				printn "   * Missing Episode" "Season $season Episode $i"
				if $downloadfrompb_flag; then
					findstring="$showname S"
					if (( season <= 9 )); then findstring+="0$season"; else findstring+="$season"; fi
					if (( i <= 9 )); then findstring+="E0$i"; else findstring+="E$i"; fi
					if [ $show_quality == 'SD' ]; then
						./findtorrent.sh -t "$findstring" -c 205 -n 1 -d
					fi
					if [ $show_quality == 'HD' ]; then
						./findtorrent.sh -t "$findstring" -c 208 -n 1 -d
					fi
				fi
				match=1
			fi
		done
	fi

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
					printf "\033[0;31m[ Missing ]\033[00m\n"
					nl
					printn "   Path" "$dirpath"
				fi
				printn "   * Missing Episode" "Season $season Episode $i"
				if $downloadfrompb_flag; then
					findstring="$showname S"
					if (( season <= 9 )); then findstring+="0$season"; else findstring+="$season"; fi
					if (( i <= 9 )); then findstring+="E0$i"; else findstring+="E$i"; fi
					if [ $show_quality == 'SD' ]; then
						./findtorrent.sh -t "$findstring" -c 205 -n 1 -d
					fi
					if [ $show_quality == 'HD' ]; then
						./findtorrent.sh -t "$findstring" -c 208 -n 1 -d
					fi
				fi
				match=1
				#if [ $i == $last ] && ! (( $high_season <= $season )); then
				if [ $i == $last ] && (( $num_season_paths > $season )); then
					nl
				fi
				
			fi
		done
	fi
	
	if ! [ $size == 0 ] && [ $match == 0 ]; then
		printf "\033[1;32m[ OK ]\033[00m\n"
	fi
}

find_gap
