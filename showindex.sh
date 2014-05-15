#!/bin/bash

. ./TVShow.cfg

div=$(cat ./$devider)

echo
echo $div
echo "Shows .cfg files Updating..."
echo $div

while read showname
do
	echo $showname
	./findshow.sh "$showname" > "$indexfiles/$showname.cfg"
	./lastepisode.sh "$showname" >> "$indexfiles/$showname.cfg"
done < $1

stat -f "%Sm" TVShows.cfg > TVshows_file.ini
