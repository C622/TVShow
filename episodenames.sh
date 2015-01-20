#!/bin/bash

callpath=$(dirname $0)
currentpath=$(pwd)
cd $callpath

. ./TVShow.cfg

## Eks.: ./episodenames.sh "Under" 2
## Will give you the names from Season 2 of the TV show "Under the Dome"

## ./episodenames.sh big 6 | tail -n2 | head -n1 | sed 's/Episode //'

SERACH=$1

## Try and match the serach, at the start of of the show names
showname=$(grep -iA 1 "^name = \"$SERACH" $installpath/$showlist)

## If there is no match at the start, try and find one somewhere in the show names
if (( $? )); then
	showname=$(grep -iA 1 "^name = .*$SERACH" $installpath/$showlist | head -n2)
else
	showname=$(head -n2 <<< "$showname")
fi

## If there is no match found, exit!
if [[ $showname == "" ]]
then
	echo "No match!"
	exit 1
fi

showname=$(echo "$showname" | sed -n -e 's/url = "\(.*\)"/\1/p')

curl -s "$showname"season-$2/ | tr -d '\t' | grep -B 4 "^Episode" | egrep "title|Episode [1-9]" | sed -e 's/^.*>\(.*\)<.*/\1/' | sed -n '1!G;h;$p'
