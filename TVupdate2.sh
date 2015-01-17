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

### Use rotatelog script to make default log spot avalibel ###
./rotatelog.sh > "$logpath/rotatelog.log" 2>&1

{
	printl
	printm "Standard Definition" "$(date)"
	printl
	./showinfo.sh -l "$indexfiles/showlistSD.cfg" -d SD
	nl
	printl
	printm "High Definition" "$(date)"
	printl
	./showinfo.sh -l "$indexfiles/showlistHD.cfg" -d HD
	nl
	printl

	### Calling another bash script that will delete empty folders ###
	printm "Delete empty folders" "$(date)"
	printl
	~/Documents/Scripts/MoveShow/delEmpty.sh ~/Documents/TorrentDownload

	### Copy some key log-files to my Dropbox ###
	cp "$logpath/TV.log" ~/Dropbox/logs/TV.log
	cp "$logpath/TorrentDownload.log" ~/Dropbox/logs/TorrentDownload.log
} 2>&1 | tee $logpath/$logfile
