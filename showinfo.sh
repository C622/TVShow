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
usage: $script_path/$script_file options

This script list infomation about a given show.

OPTIONS:
   -h      Show this message

   -s      Serach string

   -l      Use list from file

   -d      Download latest episode, if missing ... in SD or HD quality. Any other will give any quality

   -n      Just shows newest Season and Episode.
   
   -u      List upcoming Episodes, Yesterday, Tonight and Tomrrow. Information is cached, 
           and will be valied until 6:55 the following day. 
		   
   -f	   Will force update of cashed information in upcoming Episodes list.
   
EOF
}


## Function 'serach', main function for serach
function serach
{
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

	. "$showcfg"

	printm "Show Stored" "$store_path"
	printm "Season of Last Episode in Store" "$store_season"
	printm "Last Episode in Store" "$store_episode"
}

function runfile
{
	file_next_new_enough=false

	if $upcomming_flag; then
		date_tomorrow=`/bin/date -j -v+1d "+%d/%-m %Y"`
		date_yesterday=`/bin/date -j -v-1d "+%d/%-m %Y"`
		date_today=`/bin/date -j "+%d/%-m %Y"`
		file_tomorrow="$installpath/$indexfiles/tomorrow.ini"
		file_yesterday="$installpath/$indexfiles/yesterday.ini"
		file_tonight="$installpath/$indexfiles/tonight.ini"
		file_next="$installpath/$indexfiles/TVnext.ini"
		
		if ! $force_update; then
			if [[ -f $file_next ]]; then
				if test `date +"%k"` -lt 7; then
					if test `find $file_next -newermt "Yesterday 06:55"`; then
						file_next_new_enough=true
					fi
				else
					if test `find $file_next -newermt "Today 06:55"`; then
						file_next_new_enough=true
					fi
				fi
			fi
		fi
		
		if ! $file_next_new_enough; then
			echo "Updating TVnext.ini..."
			if [[ -f $file_tomorrow ]]; then
				rm $file_tomorrow
			fi
			if [[ -f $file_yesterday ]]; then
				rm $file_yesterday
			fi
			if [[ -f $file_tonight ]]; then
				rm $file_tonight
			fi
			if [[ -f $file_next ]]; then
				rm $file_next
			fi			
		fi
	fi
	
	if ! $file_next_new_enough; then
		while read SERACH; do
			store_season=
			store_episode=
			last_season=
			last_episode=
		
			serach
				
			if $upcomming_flag; then
				
				if [[ $next =~ ^Tonight.*$ ]]; then
					printf "%-30.30s %-37.37s S%02d / E%02d\n" "$showget_name" "$next_titel" "$next_season" "$next_episode" >> $file_tonight
				elif [[ $next =~ $date_tomorrow ]]; then
					printf "%-30.30s %-37.37s S%02s / E%02d\n" "$showget_name" "$next_titel" "$next_season" "$next_episode" >> $file_tomorrow
				fi
		
				if [[ $last =~ $date_yesterday ]]; then
					showcfg=$(find $installpath/$indexfiles/* -name "$showget_name.cfg")
					. "$showcfg"
					printf "%-30.30s %-37.37s S%02d / E%02d" "$showget_name" "$last_titel" "$last_season" "$last_episode" >> $file_yesterday
					if (("$store_season" == "$last_season")) && (("$store_episode" == "$last_episode")); then
						printf " *" >> $file_yesterday
					fi
					printf "\n" >> $file_yesterday
				fi
			elif (( $download_flag == 0 )); then
				disp_serach
				printl
				nl
			else
				rundownload
			fi
		done < $FILENAME

		if $upcomming_flag; then
			{
				if [[ -f $file_yesterday ]]; then
					printc "YESTERDAY - $date_yesterday"
					printl
					cat $file_yesterday | sort
					printl
					nl
				fi
				if [[ -f $file_tonight ]]; then
					printc "TONIGHT - $date_today"
					printl
					cat $file_tonight | sort
					printl
					nl
				fi
				if [[ -f $file_tomorrow ]]; then
					printc "TOMORROW - $date_tomorrow"
					printl
					cat $file_tomorrow | sort
					printl
				fi
				echo "Updated: `/bin/date`  * Downloaded and in Store"
			} 2>&1 | tee $file_next
			
			### Copy new version to Dropbox ###
			cp $file_next ~/Dropbox/logs/
		fi
	fi
	
	if $file_next_new_enough; then
		cat $file_next
	fi
	
}

function rundownload
{
	clean_string

	. "$showcfg"

	echo ""
	printm "Show Name" "$show"

	if ! [[ $last_season =~ $re ]] ; then
	   echo "error: last_season Not a number"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $store_season =~ $re ]] ; then
	   echo "error: store_season Not a number : $store_season"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $last_episode =~ $re ]] ; then
	   echo "error: last_episode Not a number"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $store_episode =~ $re ]] ; then
		store_episode="0"
#	   echo "error: store_episode Not a number"
#	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if (( "$last_season" == "$store_season" )); then
		printm "Season of Last Aired Episode" "$last_season = Store ($store_season)"
		if (( "$last_episode" == "$store_episode" )); then
			printm "Last Aired Episode" "$last_episode = Store ($store_episode)"
		else
			if (( "$last_episode" > "$store_episode" )); then
				printm "Last Aired Episode" "$last_episode > Store ($store_episode)"
				echo "Newer Than Last Episode in Store, Download..."
				
				for (( download_episode = $store_episode+1; download_episode <= $last_episode; download_episode++ )); do
					case $download_flag in
						1)
						nl
						./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d
						nl
						;;
						2)
						nl
						./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r SD
						nl
						;;
						3)
						nl
						./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r HD
						nl
						;;
					esac
				done
			else
				printm "Last Aired Episode" "$last_episode < Store ($store_episode)"
				echo "error: Lower Than Episode in Store"
			fi
		fi
	fi

	if (( "$last_season" > "$store_season" )); then
		printm "Season of Last Aired Episode" "$last_season > Store ($store_season)"
		printm "Last Aired Episode" "$last_episode <> Store ($store_episode)" 
		echo "Newer Than Last Season in Store, Download..."

		for (( download_episode = 1; download_episode <= $last_episode; download_episode++ )); do
			case $download_flag in
				1)
				nl
				./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d
				nl
				;;
				2)
				nl
				./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r SD
				nl
				;;
				3)
				nl
				./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r HD
				nl
				;;
			esac
		done
	fi
	
	if (( "$last_season" < "$store_season" )); then
		printm "Season of Last Aired Episode" "$last_season < Store ($store_season)"
		echo "error: Lower Than Season in Store"
	fi
}

download_quality=
download_flag=0
new_flag=false
upcomming_flag=false
force_update=false
SERACH=
FILENAME=

while getopts “hfnud:s:l:” opt_val
do
	case $opt_val in
		h) usage; exit 2;;
		d) download_quality=$OPTARG; download_flag=1;;
		s) SERACH=$OPTARG;;
		l) FILENAME=$OPTARG;;
		n) new_flag=true;;
		u) upcomming_flag=true;;
		f) force_update=true;;
		\?) usage; exit 3;;
		*) usage; exit 3;;
	esac
done

if (( $download_flag == 1)); then
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
	if $new_flag; then
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

if $upcomming_flag && [ -z $FILENAME ]; then
	FILENAME="$installpath/$indexfiles/showlist.cfg"
fi

if ! [ -z $FILENAME ]; then
	runfile
	exit 0
fi

usage
