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

curlString="http://thepiratebay.org/top/"
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
   -2      Last 48 hours

EOF
}

function go
{
	## Check for 3 digiet number in Argument for category
	if ! [[ $type =~ $re ]]
	then 
		echo "Category Argument needs to be a set - 3 digit number!"
		exit 1
	fi

	## Check if -2 prameter is set for "added in the last 48h view"
	if $last_48_func; then
		curlString+="48h$type"
	else
		curlString+="$type"
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

function short_list {
	## Short list view
	cat $TEMPFILE | grep -E "^titel" | sed -e 's/titel = "//' -e 's/"//' | /usr/bin/nl
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

function download {
	btc add -u "$(cat $TEMPFILE | grep "^magnet" | tail -n 1)"
}

function default {
	cat $TEMPFILE
}

default_func=true
download_func=false
short_list_func=false
top_list_func=false
last_48_func=false
hits=0

while getopts “c:dhn:st2” opt_val
do
	case $opt_val in
		c) type=$OPTARG;;
		d) default_func=false; download_func=true;;
		h) usage; exit 0;;
		n) hits=$OPTARG;;
		s) default_func=false; top_list_func=true;;
		2) last_48_func=true;;
		*) usage; exit 0;;
	esac
done

if $default_func; then
	if (( $hits == 0 )); then
		hits=100
	fi
	go
	default
fi

if $top_list_func; then
	if (( $hits == 0 )); then
		hits=25
	fi
	go
	top_list
fi

if $short_list_func; then
	if (( $hits == 0 )); then
		hits=25
	fi
	go
	short_list
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
