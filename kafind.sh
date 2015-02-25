#!/bin/sh

re='^[0-9]{2}$'
re2='^[0-9]{1,2}$'
log_add="/Users/chris/Documents/Scripts/TVShow/log/TVadded.log"
TEMPFILE=$(mktemp -t kafind)


function finish {
	if [ -f $TEMPFILE ]; then
		rm $TEMPFILE
	fi
}
trap finish EXIT

## Fuction 'usage', displays usage information
function usage {
cat << EOF
usage: $0 options

This script has the following options.

OPTIONS:
   -m   Movie search.

   -t   Title to search for.

   -s   Season number to search for.
   -e   Episode number to search for.

   -p   Will print a dump of all the information returned from your search.

   -h   Show information about the highest hit.
   -n   Select number from list.
   -r   Resolution, HD or SD.
   -d   Download your selecting highest hit or the selected number using BTC.
   
   Default with no option -h, -p or -d. Will give you a list of hits, only showing title.
		
EOF
}

function getlist {
	curl -L --compressed -s "http://kickass.to/usearch/$search_string/?rss=1&field=seeders&sorder=desc" | grep -E "<title>|<torrent:magnetURI>|<torrent:seeds>|<torrent:peers>|<pubDate>|<torrent:contentLength>" | grep -v "Torrents by keyword" | sed -e 's/<!\[CDATA\[//' -e 's/\]\]>//' -e 's/<[^>]*>//g' -e 's/^ *//' > $TEMPFILE
}

function ifhigher {
	if (( $line_leeds > $line_leeds_high )); then
		line_size_high=$line_size
		line_titel_high=$line_titel
		line_uploaded_high=$line_uploaded
		line_link_high=$line_link
		line_leeds_high=$line_leeds
		line_seeds_high=$line_seeds
	fi
}

function gethigh {
	getlist
	
	line_seeds=
	line_leeds=0
	line_leeds_high=0
	line_seeds_high=0
	
	while read line_titel
	do
		read line_uploaded
		read line_size
		read line_link
		read line_leeds
		read line_seeds
		
		if [[ $resolution == 2 ]]; then
			if (( $line_size > "850000000" )); then
				## This is high res.
				ifhigher
			fi
		else
			if [[ $resolution == 1 ]]; then
				if (( $line_size < "850000000" )); then
					## This is low res.
					ifhigher
				fi
			else
				## This is What-ever res.
				ifhigher
			fi
		fi
		
	done < $TEMPFILE

	if [ ! "$line_seeds_high" == 0 ]; then
		echo "Title       : $line_titel_high"
		echo "Upload Date : $line_uploaded_high"
		echo "Size        : $(($line_size_high >> 20)) MB"
		#echo "URL         : $line_link_high"
		echo "Leeds       : $line_leeds_high"
		echo "Seeds       : $line_seeds_high"
	else
		echo "No hit for : $search_string"
		exit 6
	fi
}

function getnumber {
	getlist
	
	line_seeds=
	line_leeds=
	item_no=0
	
	while read line_titel
	do
		item_no=$((item_no + 1))
		read line_uploaded
		read line_size
		read line_link
		read line_leeds
		read line_seeds
		if (($item_no == $select_number)); then
			break
		fi
	done < $TEMPFILE

	if [ ! "$item_no" == 0 ]; then
		echo "Title       : $line_titel"
		echo "Upload Date : $line_uploaded"
		echo "Size        : $(($line_size >> 20)) MB"
		#echo "URL         : $line_link"
		echo "Leeds       : $line_leeds"
		echo "Seeds       : $line_seeds"
		#echo "Item number : $item_no"		
	else
		echo "No hit for : $search_string"
		exit 7
	fi
	
	line_link_high=$line_link
	line_titel_high=$line_titel
}

function printlist {
	getlist
	item_no=1
	while read line_titel
	do
		read line_uploaded
		read line_size
		read line_link
		read line_leeds
		read line_seeds
		printf "%0.2d: %s\n" $item_no "$line_titel"
		printf "     leeds:$line_leeds // seeds:$line_seeds // size:$(($line_size >> 20)) MB\n"
		item_no=$((item_no + 1))
	done < $TEMPFILE
}

function btc_download {
	/usr/local/bin/btc add -u "$line_link_high"
	echo "$(date)" >> $log_add
	echo "$line_titel_high" >> $log_add
	echo  >> $log_add
}

function default_opt {
	getlist
	cat $TEMPFILE
}

search_movie=false
select_download=false
select_option=1
search_title=
search_season=
search_episode=
select_number=
resolution="NOT"

while getopts “mdphn:s:e:t:r:” OPTION
do
	case $OPTION in
		t)
			## Get Title to search for
			search_title=$OPTARG
			;;
		s)
			## Get Season
			search_season=$OPTARG
			if ! [[ $search_season =~ $re2 ]]
			then
			        echo "Season needs to be a 1 or 2 digit number! Your input was : $search_season"
			        exit 4
			fi

			if ! [[ $search_season =~ $re ]] ; then
				search_season=$(echo "s0$search_season")
			else
				search_season=$(echo "s$search_season")
			fi
			;;
		e)
			## Get Episode
			search_episode=$OPTARG
			if ! [[ $search_episode =~ $re2 ]]
			then
			        echo "Episode needs to be a 1 or 2 digit number! Your input was : $search_episode"
			        exit 5
			fi
			
			if ! [[ $search_episode =~ $re ]] ; then
				search_episode=$(echo "e0$search_episode")
			else
				search_episode=$(echo "e$search_episode")
			fi
			;;
		p)
			## Print list
			select_option=2
			;;
		d)
			## Download
			select_download=true
			;;
		h)
			## Show HIGHEST HIT
			select_option=4
			;;
		r)
			## Check for resolution
			resolution=$OPTARG
			resolution=$(echo "$resolution" | tr "[:lower:]" "[:upper:]")

			if [ $resolution == "HD" ]; then
				resolution=2
			else
				if [ $resolution == "SD" ]; then
					resolution=1
				fi
			fi
			;;
		m)
			## Get Title for Movie serach
			search_movie=true
			;;
		n)
			## Select number to download
			select_number=$OPTARG
			select_option=5			
			;;
 		?)
			## Default
			usage
			exit
			;;
	esac
done

if [ -z "$search_title" ]; then
	echo "No Title given!"
	usage
	exit 1
fi
if $search_movie; then
	search_string=$(echo "$search_title category%3Amovies" | sed 's/ /\%20/g')
else
	if [ -z $search_season ]; then
		echo "No Season given!"
		usage
		exit 2
	fi
	if [ -z $search_episode ]; then
		echo "No Episode given!"
		usage
		exit 3
	fi
	search_string=$(echo "$search_title $search_season$search_episode" | sed 's/ /\%20/g')
fi


if $select_download; then
	if [ $select_option != 4 ] && [ $select_option != 5 ]; then
		echo "Download selected without -n or -h option"
		exit 8
	fi
fi

case $select_option in
	1)
		printlist
		;;
	2)
		default_opt
		;;
	4)
		gethigh
		if $select_download; then
			btc_download
		fi
		;;
	5)
		getnumber
		if $select_download; then
			btc_download
		fi
		;;
esac

exit 0
