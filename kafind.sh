#!/bin/sh

re='^[0-9]{2}$'
re2='^[0-9]{1,2}$'

function finish {
	if [ -f /tmp/katmp_find.txt ]; then
		rm /tmp/katmp_find.txt
	fi
}
trap finish EXIT

## Fuction 'usage', displays usage information
usage()
{
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
   -r   Resolution, HD or SD.
   -d   Automatic start download of the highest hit, using BTC.
   
   Default with no option -h, -p or -d. Will give you a list of hits, only showing title.
		
EOF
}

getlist()
{
	curl -L --compressed -s http://kickass.so/usearch/$search_string/?rss=1 | grep -E "<title>|<torrent:magnetURI>|<torrent:seeds>|<torrent:peers>|<pubDate>|<torrent:contentLength>" | grep -v "Torrents by keyword" | sed -e 's/<!\[CDATA\[//' -e 's/\]\]>//' -e 's/<[^>]*>//g' -e 's/^ *//' > /tmp/katmp_find.txt
}

ifhigher()
{
	if (( $line_leeds > $line_leeds_high )); then
		line_size_high=$line_size
		line_titel_high=$line_titel
		line_uploaded_high=$line_uploaded
		line_link_high=$line_link
		line_leeds_high=$line_leeds
		line_seeds_high=$line_seeds
	fi
}

gethigh()
{
	getlist
	
	line_leeds=0
	line_seeds=
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
		
	done < /tmp/katmp_find.txt

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

printlist ()
{
	getlist

	while read line_titel
	do
		read line_uploaded
		read line_size
		read line_link
		read line_leeds
		read line_seeds
		printf "$line_titel\n"
		printf "     leeds:$line_leeds // seeds:$line_seeds // size:$(($line_size >> 20)) MB\n\n"
		
	done < /tmp/katmp_find.txt
	
}

btc_download ()
{
	btc add -u "$line_link_high"
}

default_opt ()
{
	getlist
	cat /tmp/katmp_find.txt
}

movie_title=
search_title=
search_season=
search_episode=
select_option=1
resolution="NOT"

while getopts “m:dphs:e:t:r:” OPTION
do
	case $OPTION in
		m)
			## Get Title for Movie serach
			movie_title=$OPTARG
			;;
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
			## Download HIGHEST HIT
			select_option=3
			;;
		h)
			## Show HIGHEST HIT
			select_option=4
			;;
		r)
			## Resolution
			resolution=$OPTARG
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


## Check for resolution

resolution=$(echo "$resolution" | tr "[:lower:]" "[:upper:]")

if [ $resolution == "HD" ]; then
	resolution=2
else
	if [ $resolution == "SD" ]; then
		resolution=1
	fi
fi

search_string=$(echo "$search_title $search_season$search_episode" | sed 's/ /\%20/g')

case $select_option in
	1)
	printlist
	;;
	2)
	default_opt
	;;
	3)
	gethigh
	btc_download
	;;
	4)
	gethigh
	;;
esac

exit 0