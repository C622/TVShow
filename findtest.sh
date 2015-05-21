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

printm_WIDTH=38
. $installpath/strings.func

TEMPFILE_SEARCH=$(mktemp -t showtest_filelist)
TEMPFILE_INFO=$(mktemp -t showtest_info)


function findbest {
	LINE_TEXT=()
	LINE_CFG=()
	LINE_LONG=()
	LINE_MATCH=()
	shopt -s nocasematch
	
	MATRIX_SIZE=0
	
	while read CFG; do
		read LONG;
		LINE_CFG[$MATRIX_SIZE]="$CFG"
		LINE_TEXT[$MATRIX_SIZE]=$(sed s/.cfg$// <<< $CFG)
		LINE_LONG[$MATRIX_SIZE]="$LONG"
		(( MATRIX_SIZE++ ))
	done < "$installpath/$indexfiles/titles.ini"
	
	SERACH_NR=0
	
	for WORD in $SERACH; do
		if $DEBUG; then echo "*** $WORD ***"; fi
		for ((i = 0; i < ${#LINE_TEXT[@]}; i++)); do
			if [[ "${LINE_TEXT[$i]}" =~ ^$WORD$ ]] || [[ "${LINE_LONG[$i]}" =~ ^$WORD$ ]] ; then
				(( LINE_MATCH[$i] = LINE_MATCH[$i] + 6 ))
				if $DEBUG; then echo "Match1 +6:${LINE_MATCH[$i]} ${BASH_REMATCH[0]} (${LINE_TEXT[$i]})"; fi
			elif [[ "${LINE_TEXT[$i]}" =~ ^$WORD ]] || [[ "${LINE_LONG[$i]}" =~ ^$WORD ]] ; then
				save_val="${BASH_REMATCH[0]}"
				if [[ $WORD =~ ^the$ ]] && (( SERACH_NR == 0 )); then
				 	(( LINE_MATCH[$i] = LINE_MATCH[$i] + 2 ))
					if $DEBUG; then echo "Match2 +2:${LINE_MATCH[$i]} ${BASH_REMATCH[0]} (${LINE_TEXT[$i]})"; fi
				else
				 	(( LINE_MATCH[$i] = LINE_MATCH[$i] + 5 ))
					if $DEBUG; then echo "Match3 +5:${LINE_MATCH[$i]} $save_val (${LINE_TEXT[$i]})"; fi
				fi
			fi
			
			if [[ "${LINE_TEXT[$i]}" =~ ^.*\ $WORD ]] || [[ "${LINE_LONG[$i]}" =~ ^.*\ $WORD ]] ; then
				(( LINE_MATCH[$i] = LINE_MATCH[$i] + 3 ))
				if $DEBUG; then echo "Match4 +3:${LINE_MATCH[$i]} ${BASH_REMATCH[0]} (${LINE_TEXT[$i]})"; fi
				if [[ "${LINE_TEXT[$i]}" =~ ^the\ $WORD.*$ ]]; then
					(( LINE_MATCH[$i]++ ))
					if $DEBUG; then echo "Match5 +1:${LINE_MATCH[$i]} ${BASH_REMATCH[0]} (${LINE_TEXT[$i]})"; fi
				fi
			elif [[ "${LINE_TEXT[$i]}" =~ ^..*$WORD ]] || [[ "${LINE_LONG[$i]}" =~ ^..*$WORD ]] ; then
				(( LINE_MATCH[$i]++ ))
				if $DEBUG; then echo "Match6 +1:${LINE_MATCH[$i]} ${BASH_REMATCH[0]} (${LINE_TEXT[$i]})"; fi
			fi
		done
		if $DEBUG; then echo; fi
		(( SERACH_NR++ ))
	done

	val=
	
	if $TEXT_OUT; then 
		for ((k = 0; k < ${#LINE_TEXT[@]}; k++)); do
			if ! [ -z ${LINE_MATCH[$k]} ]; then
				printf "${LINE_MATCH[$k]}\t#$k\tTitel: ${LINE_TEXT[$k]}\n"
			fi
		done | sort -n -r -k 1n | tail -r -n 10
	else
		result_val=$(for ((k = 0; k < ${#LINE_TEXT[@]}; k++)); do
			if ! [ -z ${LINE_MATCH[$k]} ]; then
				printf "${LINE_MATCH[$k]}\t$k\n"
			fi
		done | sort -r -n -k 1n | tail -n 1 | cut -f2)
		#echo "$installpath/$indexfiles/${LINE_CFG[$result_val]}"
		cat "$installpath/$indexfiles/${LINE_CFG[$result_val]}"
	fi

}

function update_list {
	LINE_TEXT=()
	LINE_LONG=()
	LINE_MATCH=()
	ls -1 $installpath/$indexfiles | grep ".cfg" | grep -v "^showlist" > $TEMPFILE_SEARCH
	
	if [ -f "$installpath/$indexfiles/titles.ini" ]; then
		rm "$installpath/$indexfiles/titles.ini"
	fi
	
	shopt -s nocasematch
	
	MATRIX_SIZE=0
	
	while read line; do
		line2=$(sed -e 's/.cfg//' <<< "$line")
		./getshowcfg.sh -t -n -s "$line2" > $TEMPFILE_INFO
		. $TEMPFILE_INFO
		printm "$line" "$show"
		LINE_TEXT[$MATRIX_SIZE]="$line"
		LINE_LONG[$MATRIX_SIZE]="$show"
		(( MATRIX_SIZE++ ))
	done < $TEMPFILE_SEARCH

	for ((k = 0; k < ${#LINE_TEXT[@]}; k++)); do
		echo "${LINE_TEXT[$k]}" >> "$installpath/$indexfiles/titles.ini"
		echo "${LINE_LONG[$k]}" >> "$installpath/$indexfiles/titles.ini"
	done
}

DEBUG=false
SERACH_flag=false
TEXT_OUT=false
update_flag=false

while getopts “ds:tu” opt_val
do
	case $opt_val in
		d) DEBUG=true; TEXT_OUT=true;;
		s) SERACH=$OPTARG; SERACH_flag=true;;
		t) TEXT_OUT=true;;
		u) update_flag=true;;
	esac
done

if $SERACH_flag; then
	findbest
elif $update_flag; then
	update_list
fi

if [ -f $TEMPFILE_SEARCH ]; then
	rm $TEMPFILE_SEARCH
fi
if [ -f $TEMPFILE_INFO ]; then
	rm $TEMPFILE_INFO
fi
