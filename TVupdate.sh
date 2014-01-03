#!/bin/bash

callpath=$(dirname $0)
currentpath=$(pwd)
cd $callpath

. ./TVshow.cfg

TVlog="$logpath/$logfile"
div=$(cat ./devider.txt)

./rotatelog.sh > "$logpath/rotatelog.log"

echo "" >> $TVlog
echo $div >> $TVlog
echo "$(date)" >> $TVlog
echo $div >> $TVlog

VarMod=$(stat -f "%Sm" $showlist)
VarLast=$(cat TVshows_file.ini)

if [[ $VarMod == $VarLast ]]
then
  echo "TVShows.cfg has not changed... No updating." >> $TVlog
else
  echo "TVShows.cfg has been changed... Running update:" >> $TVlog
  ./showupdate.sh >> $TVlog
  ./showindex.sh >> $TVlog
fi

./2up.sh 208 showlistHD.cfg >> $TVlog
./2up.sh 205 showlistSD.cfg >> $TVlog

### Removing Torrent that are done downloading ###
/usr/local/bin/btc list | /usr/local/bin/btc filter --key progress --numeric-equals 100.0 | /usr/local/bin/btc remove

### Calling another bash script that will delete empty folders ###
~/Documents/Scripts/MoveShow/delEmpty.sh ~/Documents/TorrentDownload > "$logpath/TorrentDownload.log"

### Copy some key log-files to my Dropbox ###
cp "$logpath/TV.log" ~/Dropbox/logs/TV.log
cp "$logpath/TVadded.log" ~/Dropbox/logs/TVadded.log
cp "$logpath/TorrentDownload.log" ~/Dropbox/logs/TorrentDownload.log

cd $currentpath
