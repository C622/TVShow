#!/bin/bash

dirpath=$1

if [ -z $dirpath ]
then
	dirpath=$(pwd)
	#echo "No path given -----> Current path will be used"
fi

IFS=$'\r\n' list=($(ls "$dirpath" | grep -E '([sS][0-9][0-9][eE][0-9][0-9]|[0-9][0-9]x[0-9][0-9])' | grep -E '(.mkv$|.avi$|.mpg$|.mpeg$|.wmv$|.mov$|.m4v$|.mp4$|.3gp$)' | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*/\1/' | sed 's/^.*[0-9][0-9]x\([0-9][0-9]\).*$/\1/' | sort | bc))

size=${#list[@]}

if [[ $size == 0 ]]
then
	echo "No episodes found in folder --> Exit!"
	exit 1
fi


first=${list[0]}
last=${list[$size-1]}

echo "Number of episodes : $size"
echo "First episode      : $first"
echo "Last episode       : $last"
echo
echo "Missing episodes :"

for i in $(seq 1 $first)
do
	#echo "> Episode $i"
	found=0
	for j in $(seq 0 $[size-1])
	do
		#echo $j
	
		if [ ${list[$j]} == $i ]
		then
			#echo "Yes!"
			found=1
		fi
	done
	if [ $found == 0 ]
	then
		echo "$i"
	fi
done

for i in $(seq $[first+1] $last)
do
	#echo "< Episode $i"
	found=0
	for j in $(seq 0 $[size-1])
	do
		#echo $j
	
		if [ ${list[$j]} == $i ]
		then
			#echo "Yes!"
			found=1
		fi
	done
	if [ $found == 0 ]
	then
		echo "$i"
	fi
done

#while read line
#do
#    	pathname=$line
#	find $pathname -name "$2" -print -quit
#done < $1
