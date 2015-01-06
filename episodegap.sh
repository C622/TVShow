#!/bin/bash

dirpath=$1
season=$2
showname=$3
high_season=$4
high_episode=$5
match=0

## If no path given -----> Current path will be used
if [ -z "$dirpath" ]; then
	dirpath=$(pwd)
fi

function find_gap ()
{
	IFS=$'\r\n'
	list=($(ls "$dirpath" | grep -E '([sS][0-9][0-9][eE][0-9][0-9]|[0-9]x[0-9][0-9]|[0-9][0-9]x[0-9][0-9])' | grep -E '(.mkv$|.avi$|.mpg$|.mpeg$|.wmv$|.mov$|.m4v$|.mp4$|.3gp$)' | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*[eE]\([0-9][0-9]\).*/\1#\2/' | tr '#' '\n' | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*/\1/' | sed 's/^.*[0-9][0-9]x\([0-9][0-9]\).*$/\1/' | sed 's/^.*[0-9]x\([0-9][0-9]\).*$/\1/' | sort | bc))

	size=${#list[@]}

	if [[ $size == 0 ]]; then
		echo "$dirpath"
		echo "No episodes found in folder"
		echo 
		exit 1
	fi

	first=${list[0]}
#	last=${list[$size-1]}
    last=$(./episodenames.sh $showname $season | tail -n2 | head -n1 | sed -E 's/Episode ([0-9]{1,2}).*$/\1/' | bc)


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
				echo "$dirpath"
			fi
			echo "$showname S$season E$i"
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
					echo "$dirpath"
				fi
				echo "$showname S$season E$i"
				match=1
			fi
		done
	fi
	
	# if [ $match == 1 ]; then
	# 	echo
	# fi
}

find_gap
