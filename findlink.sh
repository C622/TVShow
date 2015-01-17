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
. $installpath/strings.func


## Function 'usage', displays usage information
function usage
{
cat << EOF
usage: $0 options

This script will find the url for a show on TV.com.

OPTIONS:
   -h      Show this message
   -t      Titel to search for
   -a      Add to config file

EOF
}

function find_show
{
	showname=$search_string
	echo "Search : $showname"
	search_string=$( sed 's/ /+/g' <<< $search_string )
	echo "Using  : $search_string"

	subpath=$(curl -s http://www.tv.com/search?q=$search_string | grep "<h4>" | head -n1 | sed -n -e 's/^.*"\(.*\)".*$/\1/p')
	showlink="http://www.tv.com$subpath"

	printl
	echo "name = \"$showname\""
	echo "url = \"$showlink\""
	echo "quality = \"NO\""
		
	if [[ $add_to_config == 1 ]]; then
		echo ""  >> TVShows.cfg
		echo "name = \"$showname\"" >> TVShows.cfg
		echo "url = \"$showlink\"" >> TVShows.cfg
		echo "quality = \"NO\"" >> TVShows.cfg
	fi

}

add_to_config=0

while getopts “ht:a” opt_val
do
	case $opt_val in
		h) usage; exit 1;;
		t) search_string=$OPTARG;;
		a) add_to_config=1;;
		\?) usage; exit 2;;
		*) usage; exit 2;;
	esac
done

if ! [ -z "$search_string" ]; then
	find_show
	exit 0
fi

usage
