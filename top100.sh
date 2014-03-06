#!/bin/sh
re='^[0-9]{3}$'
hits=$2
type=$3

if ! [[ $1 =~ $re ]]
then 
	echo "First Argument needs to be a 3 digit number!"
	exit 1
fi

if [ -z $hits ]
then
	hits=100
fi

curl -L -s http://thepiratebay.org/top/$1 | \
grep -E '("detName|Magnet link|Uploaded|td align)' | \
sed -e 's/&nbsp;/ /g' \
    -e 's/^.*Uploaded \(.*\), Size \(.*\), ULed.*/uploaded = "\1"#size = "\2"/' \
    -e 's/^.*detName.*\">\(.*\)<\/a>/titel = "\1"/' \
    -e 's/^.*"\(magnet\:.*\)" title="Download this torrent using magnet.*/\1/' \
    -e 's/^.*td align=.right..\(.*\)..td.*/\1/' | \
tr '#' '\n' | \
head -n $(expr 6 \* $hits) > /tmp/tmp_top.txt


case "$type" in
	-s)
		## Short list view
		cat /tmp/tmp_top.txt | grep "^titel" | sed -e 's/titel = "//' -e 's/"//' | nl
		;;
	-d)
		## Download the given number
		btc add -u "$(cat /tmp/tmp_top.txt | grep "^magnet" | tail -n 1)"
		;;
	*)
		cat /tmp/tmp_top.txt
		;;
esac

rm /tmp/tmp_top.txt
