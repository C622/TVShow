#!/bin/bash

callpath=$(dirname $0)
currentpath=$(pwd)
cd $callpath

. ./TVShow.cfg

## Eks.: ./episodenames.sh "Under" 2
## Will give you the names from Season 2 of the TV show "Under the Dome"

## ./episodenames.sh big 6 | tail -n2 | head -n1 | sed 's/Episode //'

showget=$(grep -iA 1 "$1" $showlist | sed -n -e 's/url = "\(.*\)"/\1/p' | head -n1)

curl -s "$showget"season-$2/ | tr -d '\t' | grep -B 4 "^Episode" | egrep "title|Episode [1-9]" | sed -e 's/^.*>\(.*\)<.*/\1/' | sed -n '1!G;h;$p'
