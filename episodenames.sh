#!/bin/bash

showget=$(grep -iA 1 "$1" ~/Documents/Scripts/TVShow/TVShows.cfg | sed -n -e 's/url = "\(.*\)"/\1/p' | head -n1)

curl -s "$showget"season-$2/ | tr -d '\t' | grep -B 4 "^Episode" | egrep "title|Episode [1-9]" | sed -e 's/^.*>\(.*\)<.*/\1/' | sed -n '1!G;h;$p'

