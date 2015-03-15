#!/bin/bash

callpath=$(dirname $0)
currentpath=$(pwd)
cd $callpath

. ./TVShow.cfg

TVlog="$logpath/$logfile"
div=$(cat ./$devider)

## Use rotatelog script to make default log spot avalibel
./rotatelog.sh > "$logpath/rotatelog.log"

## Send Date and Time to log file - With headers
echo "" >> $TVlog
echo $div >> $TVlog
echo "$(date)" >> $TVlog
echo $div >> $TVlog

## Get Modyfid date and time stamp for $showlist, and value stored in TVshows_file.ini
VarMod=$(stat -f "%Sm" $showlist)
VarLast=$(cat TVshows_file.ini)

## If $showlist has changed run showupdate and showindex scripts
if [[ $VarMod == $VarLast ]]
then
  echo "TVShows.cfg has not changed... No updating." >> $TVlog
else
  echo "TVShows.cfg has been changed... Running update:" >> $TVlog
  ./getshowcfg.sh -l >> $TVlog
  ./getshowcfg.sh -u >> $TVlog
fi

## Run 2up script with paremeters for HD (208 on TPB) and SD (205 on TPB)
./2up.sh 208 showlistHD.cfg >> $TVlog
./2up.sh 205 showlistSD.cfg >> $TVlog

### Removing Torrent that are done downloading ###
./uclear.sh

### Calling another bash script that will delete empty folders ###
~/Documents/Scripts/MoveShow/delEmpty.sh ~/Documents/TorrentDownload > "$logpath/TorrentDownload.log"

### Copy some key log-files to my Dropbox ###
cp "$logpath/TV.log" ~/Dropbox/logs/TV.log
cp "$logpath/TVadded.log" ~/Dropbox/logs/TVadded.log
cp "$logpath/TorrentDownload.log" ~/Dropbox/logs/TorrentDownload.log

cd $currentpath
