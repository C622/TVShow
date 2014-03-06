#!/bin/sh
re='^[0-9]{3}$'
hits=$2
short=$3

if ! [[ $1 =~ $re ]]
then 
	echo "Argument needs to be a 3 digit number!"
	exit 1
fi

if [ -z $hits ]
then
	hits=100
fi

if [[ $short == 's' ]]
then
	short=0
else
	short=1
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

if [[ $short == 0 ]]
then
	cat /tmp/tmp_top.txt | grep "^titel" | sed -e 's/titel = "//' -e 's/"//' | nl
else
	cat /tmp/tmp_top.txt
fi

rm /tmp/tmp_top.txt
