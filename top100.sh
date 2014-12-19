#!/bin/sh
re='^[0-9]{3}$'
hits=$2
type=$3
curlString=

#if [ -f /tmp/tmp_top.txt ]; then rm /tmp/tmp_top.txt; fi
#if [ -f /tmp/tmp_top2.txt ]; then rm /tmp/tmp_top2.txt; fi

## Check for 3 digiet number in Argument for category
if ! [[ $1 =~ $re ]]
then 
	echo "First Argument needs to be a 3 digit number!"
	exit 1
fi

## Check if -2 prameter is set for "added in the last 48h view"
if [[ $4 == "-2" ]]
	then
	curlString="http://thepiratebay.org/top/48h$1"
else
	curlString="http://thepiratebay.org/top/$1"
fi

## If no amount of hits are requisted, set it to 100	
if [ -z $hits ]
then
	hits=100
fi

## Use curl command to get the requiest query, and store the wanted information in a temporary text file
curl -L --compressed -s $curlString | \
grep -E '("detName|Magnet link|Uploaded|td align)' | \
sed -e 's/&nbsp;/ /g' \
    -e 's/^.*Uploaded \(.*\), Size \(.*\), ULed.*/uploaded = "\1"#size = "\2"/' \
    -e 's/^.*detName.*\">\(.*\)<\/a>/titel = "\1"/' \
    -e 's/^.*"\(magnet\:.*\)" title="Download this torrent using magnet.*/\1/' \
    -e 's/^.*td align=.right..\(.*\)..td.*/\1/' | \
tr '#' '\n' | \
head -n $(expr 6 \* $hits) > /tmp/tmp_top.txt

## Check $type is -s or -d. If non of them are requested, the temporary file will be showed "as is"
case "$type" in
	-s)
		## Short list view
		cat /tmp/tmp_top.txt | grep -E "^titel" | sed -e 's/titel = "//' -e 's/"//' | nl
		;;
	-t)
		## Short list view test
		
		line_number=0

		printf "    #   UPLOADED      TITEL\n" >> /tmp/tmp_top2.txt

		while read line_titel
		do
			read line_link
			read line_uploaded
			read line_size
			read line_leeds
			read line_seeds
			
			line_number=$[$line_number+1]

			line_titel=$(sed 's/titel = "\(.*\)"/\1/' <<< $line_titel)
			line_uploaded=$(sed 's/uploaded = "\(.*\)"/\1/' <<< $line_uploaded)
			
			printf "%5s" "$line_number" >> /tmp/tmp_top2.txt
			printf "%-17s" "   $line_uploaded" >> /tmp/tmp_top2.txt
			printf "$line_titel\n" >> /tmp/tmp_top2.txt
			
			
		done < /tmp/tmp_top.txt
		cat /tmp/tmp_top2.txt		
		;;
	-d)
		## Download the given number
		btc add -u "$(cat /tmp/tmp_top.txt | grep "^magnet" | tail -n 1)"
		;;
	*)
		cat /tmp/tmp_top.txt
		;;
esac

## Remove the temporary text file
if [ -f /tmp/tmp_top.txt ]; then rm /tmp/tmp_top.txt; fi
if [ -f /tmp/tmp_top2.txt ]; then rm /tmp/tmp_top2.txt; fi
