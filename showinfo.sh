#!/bin/bash

## Script start...
## Change working directory to path of the called scripted
## This needs to be done regradless if the scripted is called direct or using a link

if [ -L $0 ]; then
	script_name=`readlink $0`
	script_path=`dirname $script_name`
	script_file=`basename $script_name`
else
	script_path=`dirname $0`					# relative
	script_path=`( cd $script_path && pwd )`	# absolutized and normalized
	script_file=`basename $0`
fi

if [ -z "$script_path" ] ; then
  exit 1
fi

current_path=`pwd`
cd $script_path

## Working directory is now set to the path of the called script
## Tree values are set: 
## script_path	: Path of the called script
## script_file	: Name of the called script
## current_path	: Path where is script was called from (Current path at that time)

. ./TVShow.cfg

logfile="$installpath/$logpath/showinfo.log"
tmpfile="/tmp/showgetinfo2showinfo.tmp"
re='^[0-9]+$'

printm_WIDTH=34
. $installpath/strings.func

## Function 'usage', displays usage information
function usage
{
cat << EOF
usage: $0 options

This script list infomation about a given show.

OPTIONS:
   -h      Show this message
   -s      Serach string
   -l      Use list from file
   -d      Download latest episode, if missing ... in SD or HD quality. Any other will give any quality
   -n      Just show newest Season and Episode

EOF
}


## Function 'serach', main function for serach
function serach
{
#showget=$(grep -iA 1 "$SERACH" $installpath/$showlist | sed -n -e 's/url = "\(.*\)"/\1/p' | head -n1)

## Try and match the serach, at the start of of the show names
showget=$(grep -iA 1 "^name = \"$SERACH" $installpath/$showlist)

## If there is no match at the start, try and find one somewhere in the show names
if (( $? )); then
	showget=$(grep -iA 1 "^name = .*$SERACH" $installpath/$showlist | head -n2)
else
	showget=$(head -n2 <<< "$showget")
fi

## If there is no match found, exit!
if [[ $showget == "" ]]
then
	echo "No match!"
	exit 1
fi

## Split the result in to URL and NAME values
showget_url=$(echo "$showget" | sed -n -e 's/url = "\(.*\)"/\1/p')
showget_name=$(echo "$showget" | sed -n -e 's/name = "\(.*\)"/\1/p')


$installpath/showgetinfo.pl $showget_url > $tmpfile

. $tmpfile
rm $tmpfile

}

function clean_string
{
	showcfg="$showget_name"

	## Remove '
	showcfg=$(sed "s/\'//" <<< $showcfg)
	## Remove everything after :
	showcfg=$(sed "s/:.*//" <<< $showcfg)
	## Replace . with space
	showcfg=$(sed "s/\./ /g" <<< $showcfg)
	## Remove space at end of string
	showcfg=$(sed 's/ *$//' <<< $showcfg)

	my_clean_string=$showcfg
	showcfg=$(find $installpath/$indexfiles/* -name "$showcfg.cfg")
}

function disp_new
{
	echo "Season $last_season"
	echo "Episode $last_episode"
}

function disp_serach
{
	echo "Looking For : $SERACH"
	echo "URL : $showget_url"
	printdl

	clean_string
	
	printm "Show Name" "$show"
	printm "Clean // .cfg name" "$my_clean_string // $showget_name" 
	printm "Config File" "$showcfg"
	printm "Show State" "$state"
	if ! [[ $state =~ ^Ended.*$ ]]; then
		nl
		printm "Previous Episode Aried" "$last"
		printm "Titel of Previous Episode" "$last_titel"
		printm "Season of Previous Episode" "$last_season"
		printm "Previous Episode" "$last_episode"
		nl
		printm "Next Episode Will Air" "$next"
		printm "Titel of Next Episode" "$next_titel"
		printm "Seaon of Next Episode" "$next_season"
		printm "Next Episode" "$next_episode"
	fi
	nl

	while read FILE; do
		read -r StoreSeason
		read -r StoreEpisode
		printm "Show Stored" "$FILE"
		printm "Season of Last Episode in Store" "$StoreSeason"
		printm "Last Episode in Store" "$StoreEpisode"
	done < "$showcfg"
}

function runfile
{
	while read SERACH; do
		StoreSeason=
		StoreEpisode=
		last_season=
		last_episode=
		
		serach
		
		if (( $download_flag == 0 )); then
			disp_serach
			printl
			nl
		else
			rundownload
		fi
	done < $FILENAME
}

function rundownload
{
	clean_string

	while read FILE; do
		read -r StoreSeason
		read -r StoreEpisode
	done < "$showcfg"

	echo ""
	printm "Show Name" "$show"

	if ! [[ $last_season =~ $re ]] ; then
	   echo "error: last_season Not a number"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $StoreSeason =~ $re ]] ; then
	   echo "error: StoreSeason Not a number : $StoreSeason"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $last_episode =~ $re ]] ; then
	   echo "error: last_episode Not a number"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $StoreEpisode =~ $re ]] ; then
		StoreEpisode="0"
#	   echo "error: StoreEpisode Not a number"
#	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if (( "$last_season" == "$StoreSeason" )); then
		printm "Season of Last Aired Episode" "$last_season = Store ($StoreSeason)"
		if (( "$last_episode" == "$StoreEpisode" )); then
			printm "Last Aired Episode" "$last_episode = Store ($StoreEpisode)"
		else
			if (( "$last_episode" > "$StoreEpisode" )); then
				printm "   -> Last Aired Episode" "$last_episode > Store ($StoreEpisode) ===> Newer Than Last Episode in Store, Download..."
			
				case $download_flag in
					1)
					nl
					./kafind.sh -t "$my_clean_string" -s $last_season -e $last_episode -d
					nl
					;;
					2)
					nl
					./kafind.sh -t "$my_clean_string" -s $last_season -e $last_episode -d -r SD
					nl
					;;
					3)
					nl
					./kafind.sh -t "$my_clean_string" -s $last_season -e $last_episode -d -r HD
					nl
					;;
				esac
			else
				printm "Last Aired Episode" "$last_episode < Store ($StoreEpisode) ===> Lower Than Episode in Store"
			fi
		fi
	fi

	if (( "$last_season" > "$StoreSeason" )); then
		printm "   -> Season of Last Aired Episode" "$last_season > Store ($StoreSeason)"
		printm "   -> Last Aired Episode" "$last_episode <> Store ($StoreEpisode) ===> Newer Than Last Episode in Store, Download..."

		case $download_flag in
			1)
			nl
			./kafind.sh -t "$my_clean_string" -s $last_season -e $last_episode -d
			nl
			;;
			2)
			nl
			./kafind.sh -t "$my_clean_string" -s $last_season -e $last_episode -d -r SD
			nl
			;;
			3)
			nl
			./kafind.sh -t "$my_clean_string" -s $last_season -e $last_episode -d -r HD
			nl
			;;
		esac
	fi
	
	if (( "$last_season" < "$StoreSeason" )); then
		printm "Season of Last Aired Episode" "$last_season < Store ($StoreSeason) -> Lower Than Season in Store"
	fi
}

download_flag=0
download_quality=
new_flag=0
SERACH=
FILENAME=

while getopts “nd:hs:l:” opt_val
do
	case $opt_val in
		h) usage; exit 2;;
		d) download_quality=$OPTARG; download_flag=1;;
		s) SERACH=$OPTARG;;
		l) FILENAME=$OPTARG;;
		n) new_flag=1;;
		\?) usage; exit 3;;
		*) usage; exit 3;;
	esac
done

if [[ $download_flag == 1 ]]; then
	download_quality=$(echo "$download_quality" | tr "[:lower:]" "[:upper:]")
	if [ $download_quality == "SD" ]; then
		download_flag=2
	else
		if [ $download_quality == "HD" ]; then
			download_flag=3
		fi
	fi
fi

if ! [[ -z $SERACH ]]; then
	if [[ $new_flag == 1 ]]; then
		serach
		disp_new
	else
		./TVcheck.sh -i
		serach
		disp_serach
	fi
	if [[ $download_flag != 0 ]]; then
		rundownload
	fi
	exit 0
fi

if ! [ -z $FILENAME ]; then
	runfile
	exit 0
fi

usage
