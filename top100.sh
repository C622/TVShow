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

printm_WIDTH=30
. $installpath/strings.func

re='^[0-9]{3}$'

TEMPFILE=$(mktemp -t top100)
TEMPFILE_INFO=$(mktemp -t top100_info)

## Function 'usage', displays usage information
function usage
{
cat << EOF
usage: $script_path/$script_file options

This script is used to list top 1-100 list of a category on The Piratebay.

OPTIONS:
   -c      Category, a 3 digiet number
   -h      Help ... This text
   -n      Amound of hits ie. 1-100
   -s      Top list
   -t      Serach string - Title
   -2      Last 48 hours

EOF
}

function go {
	curlString="http://thepiratebay.org/top/"

	## Check if -2 prameter is set for "added in the last 48h view"
	if $last_48_func; then
		curlString+="48h$category"
	else
		curlString+="$category"
	fi
	
	## Use curl command to get the requiest query, and store the wanted information in a temporary text file
	curl -L --compressed -s $curlString | \
	grep -E '("detName|Magnet link|Uploaded|td align)' | \
	sed -e 's/&nbsp;/ /g' \
	    -e 's/^.*Uploaded \(.*\), Size \(.*\), ULed.*/uploaded = "\1"#size = "\2"/' \
	    -e 's/^.*detName.*\">\(.*\)<\/a>/titel = "\1"/' \
	    -e 's/^.*"\(magnet\:.*\)" title="Download this torrent using magnet.*/\1/' \
	    -e 's/^.*td align=.right..\(.*\)..td.*/\1/' | \
	tr '#' '\n' | \
	head -n $(expr 6 \* $hits) > $TEMPFILE
}

function go_find {
	curlString="http://thepiratebay.org/search/"

	line=$(echo $SEARCH_string | sed -e 's/ /%20/g')

	curl -L --compressed -s $curlString$line/0/7/$category | \
	grep -E '("detLink"|Magnet link|Uploaded |td align)' | \
	sed -e 's/&nbsp;/ /g' \
	    -e 's/^.*Uploaded \(.*\), Size \(.*\), ULed.*/uploaded = "\1"#size = "\2"/' \
	    -e 's/^.*detName.*\">\(.*\)<\/a>/titel = "\1"/' \
	    -e 's/^.*"\(magnet\:.*\)" title="Download this torrent using magnet.*/\1/' \
	    -e 's/^.*td align=.right..\(.*\)..td.*/\1/' | \
	tr '#' '\n' | \
	head -n $(expr 6 \* $hits) > $TEMPFILE
}

function top_list {
	## Short list view
	line_number=0

	{
		color_lwhite
		printf "   #   TITEL\n"
		color_reset
	} >> $TEMPFILE_INFO

	while read line_titel
	do
		read line_link
		read line_uploaded
		read line_size
		read line_leeds
		read line_seeds
		
		line_number=$[$line_number+1]

		line_titel=$(sed 's/titel = "\(.*\)"/\1/' <<< $line_titel)
		line_uploaded=$(sed 's/uploaded = "\(.*\)"/\1/' <<< $line_uploaded)
		line_print_size=$(sed 's/size = "\(.*\)"/\1/' <<< $line_size)
		
		{
			color_lblue
			printf "%4s" "$line_number"
			color_reset

			printf "%-3s" ""

			color_lgreen
			printf "$line_titel\n"
			color_reset

			color_white
			printf "%6s Uploaded: " " "
			color_white
			printf "$line_uploaded"
			color_reset

			printf " // "
			
			color_white
			printf "Leeds: "
			color_white
			printf "$line_leeds"
			color_reset

			printf " // "
			
			color_white
			printf "Seeds: " 
			color_white
			printf "$line_seeds"
			color_reset

			printf " // "

			color_white
			printf "Size: "
			color_white
			printf "$line_print_size"
			color_reset

			printf "\n"
		} >> $TEMPFILE_INFO
		
	done < $TEMPFILE
	cat $TEMPFILE_INFO		
}

function download {
	btc add -u "$(cat $TEMPFILE | grep "^magnet" | tail -n 1)"
}

function default {
	cat $TEMPFILE
}

function color_black {
	printf "\033[0;30m"
}
function color_lblack {
	printf "\033[1;30m"
}
function color_red {
	printf "\033[0;31m"
}
function color_lred {
	printf "\033[1;31m"
}
function color_green {
	printf "\033[0;32m"
}
function color_lgreen {
	printf "\033[1;32m"
}
function color_yellow {
	printf "\033[0;33m"
}
function color_lyellow {
	printf "\033[1;33m"
}
function color_blue {
	printf "\033[0;34m"
}
function color_lblue {
	printf "\033[1;34m"
}
function color_magenta {
	printf "\033[0;35m"
}
function color_lmagenta {
	printf "\033[1;35m"
}
function color_cyan {
	printf "\033[0;36m"
}
function color_lcyan {
	printf "\033[1;36m"
}
function color_white {
	printf "\033[0;37m"
}
function color_lwhite {
	printf "\033[1;37m"
}
function color_reset {
	printf "\033[00m"
}

search_func=false
default_func=true
download_func=false
top_list_func=false
last_48_func=false
hits=0

while getopts “c:dhn:st:2” opt_val
do
	case $opt_val in
		c) category=$OPTARG;;
		d) default_func=false; download_func=true;;
		h) usage; exit 0;;
		n) hits=$OPTARG;;
		s) default_func=false; top_list_func=true;;
		t) SEARCH_string=$OPTARG; search_func=true;;
		2) last_48_func=true;;
		*) usage; exit 51;;
	esac
done

if ! [[ $category =~ $re ]];then
	usage
	echo "Error 2: Category argument needs to set as a 3 digit number!"; exit 2
fi

if $default_func; then
	if $search_func; then
		if (( $hits == 0 )); then
			hits=1
		fi
		go_find
	else
		if (( $hits == 0 )); then
			hits=100
		fi
		go
	fi
	default
fi

if $top_list_func; then
	if (( $hits == 0 )); then
		hits=25
	fi

	if $search_func; then
		go_find
	else
		go
	fi
	top_list
fi

if $download_func; then
	if (( $hits == 0 )); then
		hits=1
	fi
	
	if ! $top_list_func; then
		if $search_func; then
			go_find
		else
			go
		fi
	fi
	download
fi

## Remove the temporary text file
if [ -f $TEMPFILE ]; then rm $TEMPFILE; fi
if [ -f $TEMPFILE_INFO ]; then rm $TEMPFILE_INFO; fi
