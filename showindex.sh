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

printm_WIDTH=30
. $installpath/strings.func

echo
printl
echo "Shows $1 files Updating..."
printl

while read showname
do
	./findshow.sh "$showname" > "$indexfiles/$showname.cfg"
	./lastepisode.sh "$showname" >> "$indexfiles/$showname.cfg"
	printm "$showname" "$showname.cfg"
done < $1

stat -f "%Sm" TVShows.cfg > TVshows_file.ini
