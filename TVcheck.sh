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
## script_path  : Path of the called script
## script_file  : Name of the called script
## current_path : Path where is script was called from (Current path at that time)

. ./TVShow.cfg

printm_WIDTH=34
. $installpath/strings.func

large_update=0
silent_index=0

## Fuction 'usage', displays usage information
function usage {
cat << EOF
usage: $script_path/$script_file options

This script has the following options.

OPTIONS:
   -s   Silent - No output
   -i   "indexing..." line displayed will script is running - No other output
		
EOF
}

while getopts “hsi” opt_val; do
        case $opt_val in
                h) usage; exit 0;;
                s) exec 1>/dev/null 2>&1;;
				i) silent_index=1;;
                *) usage; exit 1;;
        esac
done


if (( $silent_index )) ; then
	exec 6>&1
	exec 7>&2
	exec 1>/dev/null 2>&1
fi

## Get Modyfid date and time stamp for $showlist, and value stored in TVshows_file.ini
VarMod=$(stat -f "%Sm" $showlist)
VarLast=$(cat TVshows_file.ini)

## If $showlist has changed run showupdate and showindex scripts
if [[ $VarMod == $VarLast ]]; then
	printm "TVShows.cfg" "No change"
else
	if (( $silent_index )) ; then
		exec 1>&6 6>&-
		exec 2>&7 7>&-
		printf "indexing..."
		exec 6>&1
		exec 7>&2
		exec 1>/dev/null 2>&1	
	fi
	printm "TVShows.cfg" "Changed"
	./showupdate.sh
	./showindex.sh $indexfiles/showlistSD.cfg
	./showindex.sh $indexfiles/showlistHD.cfg
	./showindex.sh $indexfiles/showlistNO.cfg
	large_update=1
fi

if [ -f "TVcheck.ini" ] && [ "$large_update" == 0 ]; then
	if (( $silent_index )) ; then
		exec 1>&6 6>&-
		exec 2>&7 7>&-
		printf "indexing..."
		exec 6>&1
		exec 7>&2
		exec 1>/dev/null 2>&1	
	fi
	printm "TVcheck.ini" "Pressent"
	printl
	
	IFS_SAVE=$IFS
	IFS=$'\n'
	update_list=(`cat TVcheck.ini | sort --uniq`)
	IFS=$IFS_SAVE

	for item in "${update_list[@]}"; do
		name_in_conf=`grep "$item" TVShows.cfg | sed -E 's/^name.*"(.*)"/\1/'`
		if [[ "$item" == "$name_in_conf" ]]; then
			printm "$item" "$item.cfg"
			./findshow.sh "$item" > "$indexfiles/$item.cfg"
			./lastepisode.sh "$item" >> "$indexfiles/$item.cfg"
		else
			printm "$item" "*** No Match ***"
		fi	
	done
	printl
	
	## Remove the TVcheck.ini file, after listed items has been updated.
	printm "Remove" "TVcheck.ini"
	rm $installpath/TVcheck.ini
else
	if [ "$large_update" == 0 ]; then
		printm "TVcheck.ini" "Not Pressent"
	fi
fi

if (( $silent_index )) ; then
	exec 1>&6 6>&-
	exec 2>&7 7>&-
	## Delete before courser and return to start of line
	printf "\033[1K\r"
fi
