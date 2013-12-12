#!/bin/sh
re='^[0-9]{3}$'
hits=$3

if ! [[ $2 =~ $re ]]
then echo "2nd argument needs to be a 3 digit number!"; exit 1
fi

if [ -z "$hits" ]
then
  hits=1
fi

line=$(echo $1 | sed -e 's/ /%20/g')

curl -L -s http://thepiratebay.com/search/$line/0/7/$2 | \
grep -E '("detLink"|Magnet link|Uploaded |td align)' | \
sed -e 's/&nbsp;/ /g' \
    -e 's/^.*Uploaded \(.*\), Size \(.*\), ULed.*/uploaded = "\1"#size = "\2"/' \
    -e 's/^.*detName.*\">\(.*\)<\/a>/titel = "\1"/' \
    -e 's/^.*"\(magnet\:.*\)" title="Download this torrent using magnet.*/\1/' \
    -e 's/^.*td align=.right..\(.*\)..td.*/\1/' | \
tr '#' '\n' | \
head -n $(expr 6 \* $hits)
