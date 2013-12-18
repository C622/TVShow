#!/bin/bash

div=$(cat ./devider.txt)

echo
echo $div
echo "Shows .cfg files Updating..."
echo $div

while read showname
do
	echo $showname
	sh findshow.sh ShowPaths.cfg "$showname" > "./ShowIndex/$showname.cfg"
	sh lastepisode.sh "$showname" >> "./ShowIndex/$showname.cfg"
done < ./ShowIndex/showlist.cfg

stat -f "%Sm" TVShows.cfg > TVshows_file.ini
