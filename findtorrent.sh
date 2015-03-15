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

curlString="http://thepiratebay.org/search/"
re='^[0-9]{3}$'

TEMPFILE=$(mktemp -t torrentfind)
TEMPFILE_INFO=$(mktemp -t torrentfind_info)

## Function 'usage', displays usage information
function usage
{
cat << EOF
usage: $script_path/$script_file options

This script is used to find torrents on The Piratebay.

OPTIONS:
   -c      Category, a 3 digiet number
   -h      Help ... This text
   -n      Amound of hits ie. 1-100
   -s      Short list view
   -t      Serach string - Title
   -2      Last 48 hours

EOF
}

function go {
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
	## Short list view test
	line_number=0

	printf "    #   UPLOADED      TITEL\n" >> $TEMPFILE_INFO

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
		
		printf "%5s" "$line_number" >> $TEMPFILE_INFO
		printf "%-17s" "   $line_uploaded" >> $TEMPFILE_INFO
		printf "$line_titel\n" >> $TEMPFILE_INFO
		
		
	done < $TEMPFILE
	cat $TEMPFILE_INFO		
}

function short_list {
	## Short list view
	cat $TEMPFILE | grep "^titel" | sed -e 's/titel = "//' -e 's/"//' | cat -b
}

function download {
	## Download the given number
	btc add -u "$(cat $TEMPFILE | grep "^magnet" | tail -n 1)"
}

function default {
	## Default
	cat $TEMPFILE
}

search_needed=true
default_func=true
download_func=false
short_list_func=false
last_48_func=false
hits=0

while getopts “c:dhn:st:2” opt_val
do
	case $opt_val in
		c) category=$OPTARG;;
		d) default_func=false; download_func=true;;
		h) usage; exit 0;;
		n) hits=$OPTARG;;
		s) default_func=false; short_list_func=true;;
		t) SEARCH_string=$OPTARG; search_needed=false;;
		2) last_48_func=true;;
		*) usage; exit 51;;
	esac
done

if $search_needed; then
	usage
	echo "Error 1: You need to have a search"; exit 1
fi

if ! [[ $category =~ $re ]];then
	usage
	echo "Error 2: Category argument needs to set as a 3 digit number!"; exit 2
fi

if $default_func; then
	if (( $hits == 0 )); then
		hits=1
	fi
	go
	default
fi

if $short_list_func; then
	if (( $hits == 0 )); then
		hits=25
	fi
	go
	top_list
fi

if $download_func; then
	if (( $hits == 0 )); then
		hits=1
	fi
	go
	download
fi

## Remove the temporary text file
if [ -f $TEMPFILE ]; then rm $TEMPFILE; fi
if [ -f $TEMPFILE_INFO ]; then rm $TEMPFILE_INFO; fi
