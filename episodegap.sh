#!/bin/bash

IFS=$'\r\n' list=($(ls "$1" | sed 's/^.*[sS][0-9][0-9][eE]\([0-9][0-9]\).*/\1/' | sort | bc))

size=${#list[@]}
first=${list[0]}
last=${list[$size-1]}

#echo "Number of episodes : $size"
#echo "First episode      : $first"
#echo "Last episde        : $last"
#echo
#echo "Missing episodes :"


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
