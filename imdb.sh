#!/bin/bash

## IMDB.com serach

## curl -s 'http://www.omdbapi.com/?i=tt2317225&plot=full' | jq -M '.' | sed 's/\\\"/\"/g'
## curl -s 'http://www.omdbapi.com/?s=the+machine&y=2013' | jq -M '.Search[] | select(.Type == "movie")'

## Fuction 'usage', displays usage information
usage()
{
cat << EOF
usage: $0 options

This script uses www.omdbapi.com, an api for IMDB.com.

OPTIONS:
   -h      Show this message
   -i      IMDB id             (Syntax: i.e. tt2317225)
   -s      Serach string
   -t      Type                (Syntax: movie, episode, series, game or any - default is movie)
   -y      Year                (Syntax: Four digit number - 0000 to 9999)

   Option -i or -s has to be set, if both are set, the -i option is used and other options are ignored.

EOF
}

## Zero out values
imdbID=
SERACH=
TYPE=
YEAR=

## Get options set - If a non valied options is set, fuction 'usage' is called
while getopts “hi:s:t:y:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 0
             ;;
         i)
             imdbID=$OPTARG
             ;;
         s)
             SERACH=$OPTARG
             ;;
         t)
             TYPE=$OPTARG
             ;;
         y)
             YEAR=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

## If $TYPE is empty, a default value of 'movie' is set
if [[ -z $TYPE ]]
then
	TYPE=movie
fi


## Replace space with + in serach string
if [[ ! -z $SERACH ]]
then
	SERACH=$(sed 's/ /+/g' <<< $SERACH)
fi

# echo "imdbID   : $imdbID"
# echo "SERACH   : $SERACH"
# echo "TYPE     : $TYPE"
# echo "YEAR     : $YEAR"

## Check if both $SERACH and $imdbID are empty
if [[ -z $SERACH ]] && [[ -z $imdbID ]]
then
	echo "Both SERACH and imdbID are empty!!"
	usage
	exit 1
fi

## If $imdbID is set, query www.omdbapi.com with given IMDB ID
if [[ ! -z $imdbID ]]
then
	urlstring="http://www.omdbapi.com/?i=$imdbID&plot=full"
	curl -s $urlstring | jq -M '.' | sed 's/\\\"/\"/g'
	exit
fi

## If $YEAR is set, add '&y=' to the front of the variable - Used for the final url
if [[ ! -z $YEAR ]]
then
	YEAR="&y=$YEAR"
fi

## If $SERACH is set, prepare final url. Case statement used to select $TYPE
if [[ ! -z $SERACH ]]
then
	urlstring="http://www.omdbapi.com/?s=$SERACH$YEAR"
#	echo "urlstring : $urlstring"
	
	case "$TYPE" in
		movie)
			curl -s $urlstring | jq -M '.Search[] | select(.Type == "movie")'
			;;
		episode)
			curl -s $urlstring | jq -M '.Search[] | select(.Type == "episode")'
			;;
		series)
			curl -s $urlstring | jq -M '.Search[] | select(.Type == "series")'
			;;
		game)
			curl -s $urlstring | jq -M '.Search[] | select(.Type == "game")'
			;;
		any)
			curl -s $urlstring | jq -M '.Search[]'
			;;
		*)
		echo "No valid TYPE requested"
			;;
	esac

	exit
fi