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
tmpfile=$(mktemp -t showinfo_tmp)
TEMPFILE_SEARCH=$(mktemp -t showinfo_search)
re='^[0-9]+$'
update_time_of_day='03:00.00'
update_older_than=$(( 2*3600 ))

## Time diffrence between local time zone, and LA/USA 
time_diff_LA=$(( $(date '+%H' | bc) - $(TZ=America/Los_Angeles date '+%H' | bc) ))
if (( time_diff_LA < 0 )); then
	time_diff_LA=$(( time_diff_LA + 24 ))
fi
time_diff_LA=$(( time_diff_LA * 3600 ))

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

function cleanup_files
{
	if [ -f $TEMPFILE_SEARCH ]; then
		rm $TEMPFILE_SEARCH
	fi
	if [ -f $tmpfile ]; then
		rm $tmpfile
	fi

	## UnHide cursor
	if ! $auto_run; then
		tput cnorm
	fi
}
trap cleanup_files EXIT

## Function 'serach', main function for serach
function serach
{
	./getshowcfg.sh -n -s "$SERACH" > $TEMPFILE_SEARCH

	if (( $? == 51 )); then
	 	echo "No match!"
	 	exit 1
	fi

	zero_out_vals

	. $TEMPFILE_SEARCH
		
	showget_name=$show_name
	showget_url=$show_url
	
	. "$script_path/$indexfiles/$show_name.cfg"
	date_split
	
	if [ -z $update_date ]; then
		update_date=0
	fi	

	time_diff=$(( $now_date-$update_date ))
	next_diff=$(( $now_date-$next_date ))
	
	## If time diffrence is more than 2 hours (2 x 3600 sec), get new info from TV.com and write index file
	if ( (( $time_diff >= $update_older_than )) && (( $now_date >= $next_date )) ) || ( (( $time_diff >= $update_older_than )) && [[ $last =~ ^Tonight.*$ ]] ) || (( $update_date == 0 )); then
		$installpath/showgetinfo.pl $showget_url > $tmpfile
		. $tmpfile

		write_index_file
	fi
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
#	showcfg=$(find $installpath/$indexfiles/* -name "$showcfg.cfg")
	showcfg="$script_path/$indexfiles/$showcfg.cfg"
}

function disp_new {
	if [[ $state =~ ^Ended.*$ ]]; then
		## mobile_url=$(echo "$showget_url" | sed 's/\.com/\.com\/m/')
		## mobile_url+="episodes/"
		## curl -s $mobile_url | grep "section_header" | sed 's/.*Season \(.*\) <.*count\">(\(.*\)).*/Season \1#Episode \2/' | head -n 1 | tr '#' '\n'
		curl -s $showget_url | grep -A6 'class="nums"' | sed 's/.*S \(.*\)&nbsp\;\:.*$/Season \1/' | sed 's/^.*episodeNumber">\(.*\)<.*$/Episode \1/' | grep -E '(Season|Episode)' | head -n 2
	else
		if [ -z $last_season ]; then
			echo "Season 1"
		else
			echo "Season $last_season"
		fi
		if [ -z $last_episode ]; then
			echo "Episode 1"
		else
			echo "Episode $last_episode"
		fi
	fi
}

function disp_serach {
	echo "Looking For : $SERACH"
	echo "URL : $showget_url"
	printl

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
		if ! [ -z "$next" ] && ! [ -z "$next_titel" ] && ! [ -z "$next_season" ] && ! [ -z "$next_episode" ]; then
			nl
			printm "Next Episode Will Air" "$next"
			printm "Titel of Next Episode" "$next_titel"
			printm "Seaon of Next Episode" "$next_season"
			printm "Next Episode" "$next_episode"
		fi
	fi
	printl

	printm "Show Stored" "$store_path"
	printm "Season of Last Episode in Store" "$store_season"
	printm "Last Episode in Store" "$store_episode"

	printl
	
	if ! [ -z $update_date ]; then
		print_update=$(date -jr $update_date "+%-d/%-m %Y %H:%M:%S")
	else
		print_update=
	fi
	printm "Data Updated" "$print_update"
}

function runfile {
	file_next_new_enough=false

	if $upcomming_flag; then
		date_tomorrow=`/bin/date -j -v+1d "+%-d/%-m %Y"`
		date_yesterday=`/bin/date -j -v-1d "+%-d/%-m %Y"`
		date_today=`/bin/date -j "+%-d/%-m %Y"`
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
		## Hide cursor
		if ! $auto_run; then
			tput civis
		fi
		
		count_shows_in_file=$( cat "$FILENAME" | wc -l | bc )
		count_in_file=1
		
		while read SERACH; do

			serach
			
			if $upcomming_flag; then
				## Delete before courser and return to start of line - Used to delete next from next line
				printf "\033[1K\r"
				printf "Updating TVnext.ini [ $(( (count_in_file*100)/count_shows_in_file ))%% ] : $showget_name"
				(( count_in_file++ ))

				if [[ $next =~ ^Tonight.*$ ]]; then
					printf "%-30.30s %-37.37s S%02d / E%02d\n" "$showget_name" "$next_titel" "$next_season" "$next_episode" >> $file_tonight
				elif [[ $next =~ $date_tomorrow ]]; then
					printf "%-30.30s %-37.37s S%02s / E%02d\n" "$showget_name" "$next_titel" "$next_season" "$next_episode" >> $file_tomorrow
				fi
		
				if [[ $last =~ $date_yesterday ]] || [[ $last =~ ^Tonight.*$ ]]; then
					. "$installpath/$indexfiles/$showget_name.cfg"
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
			## Delete before courser and return to start of line, final delete show titel
			printf "\033[1K\r"
			## UnHide cursor
			if ! $auto_run; then
				tput cnorm
			fi
			
			{
				if [[ -f $file_yesterday ]]; then
					printc "YESTERDAY - $date_yesterday"
					printl
					cat $file_yesterday | sort
					printl
					nl
				fi
				if [[ -f $file_tonight ]]; then
					printc "TODAY - $date_today"
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

function rundownload {
	clean_string

	. "$showcfg"

	nl
	printm "Show Name" "$show"
	
	if ! [[ $last_season =~ $re ]] ; then
	   echo "error: last_season Not a number"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $store_season =~ $re ]] ; then
	   echo "error: store_season Not a number -> $store_season"
	   store_season=$last_season
#	   if ! [ -z $FILENAME ]; then continue; else exit; fi
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
						1) nl; ./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d; nl;;
						2) nl; ./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r SD; nl;;
						3) nl; ./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r HD; nl;;
					esac
				done
			else
				printm "Last Aired Episode" "$last_episode < Store ($store_episode)"
				echo "error: Lower Than Episode in Store - 1 (last)"
			fi
		fi
	fi

	if (( "$last_season" > "$store_season" )); then
		printm "Season of Last Aired Episode" "$last_season > Store ($store_season)"
		printm "Last Aired Episode" "$last_episode <> Store ($store_episode)" 
		echo "Newer Than Last Season in Store, Download..."

		for (( download_episode = 1; download_episode <= $last_episode; download_episode++ )); do
			case $download_flag in
				1) nl; ./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d; nl;;
				2) nl; ./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r SD; nl;;
				3) nl; ./kafind.sh -t "$my_clean_string" -s $last_season -e $download_episode -h -d -r HD; nl;;
			esac
		done
	fi
	
	if (( "$last_season" < "$store_season" )); then
		printm "Season of Last Aired Episode" "$last_season < Store ($store_season)"
		echo "error: Lower Than Season in Store - 2 (last)"
	fi
	
	if ! [[ $next_season =~ $re ]] ; then
	   # echo "error: next_season Not a number"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi
	if ! [[ $next_episode =~ $re ]] ; then
	   # echo "error: next_episode Not a number"
	   if ! [ -z $FILENAME ]; then continue; else exit; fi
	fi

	if (( $next_diff > 0 )) && ! (( $next_date == 0 )); then
		if (( "$next_season" == "$store_season" )); then
			printm "Season of Next Episode to Air" "$next_season = Store ($store_season)"
			if (( "$next_episode" == "$store_episode" )); then
				printm "Next Episode to Air" "$next_episode = Store ($store_episode)"
			else
				if (( "$next_episode" > "$store_episode" )); then
					printm "Next Episode to Air" "$next_episode > Store ($store_episode)"
					echo "Newer Than Last Episode in Store, Download... AND should be out now!?"
				
					for (( download_episode = $store_episode+1; download_episode <= $next_episode; download_episode++ )); do
						case $download_flag in
							1) nl; ./kafind.sh -t "$my_clean_string" -s $next_season -e $download_episode -h -d; nl;;
							2) nl; ./kafind.sh -t "$my_clean_string" -s $next_season -e $download_episode -h -d -r SD; nl;;
							3) nl; ./kafind.sh -t "$my_clean_string" -s $next_season -e $download_episode -h -d -r HD; nl;;
						esac
					done
				else
					printm "Next Episode to Air" "$next_episode < Store ($store_episode)"
					echo "error: Lower Than Episode in Store - 3 (next)"
				fi
			fi
		fi
	fi
	
	
}

function date_split {
	now_date=`/bin/date "+%s"`

	if [[ $last =~ ^Tonight.*$ ]]; then
		last_date=$now_date
	elif ! [ -z "$last" ]; then
		last_date=$(date -j -f "%d/%m %Y %H:%M.%S" "$last $update_time_of_day" "+%s")
	else
		last_date=0
	fi

	if [[ $next =~ ^Tonight.*$ ]]; then
		next_date=$now_date
	elif ! [ -z "$next" ]; then
		next_date=$(date -j -f "%d/%m %Y %H:%M.%S" "$next $update_time_of_day" "+%s")
	else
		next_date=0
	fi
	
	## If show has status "ended", then set the time stamp for next_date and next_update to 95617591200 (1 Jan. 5000)
	if [[ $state =~ ^Ended.*$ ]]; then
		next_date=95617591200
		next_update=95617591200
	fi
}

function write_index_file {
	update_date=`/bin/date "+%s"`
	{
		echo "show_name='$show_name'"
		echo "show_url='$show_url'"
		echo "show_eztv='$show_eztv'"
		echo "show_quality='$show_quality'"
		echo "store_path='$store_path'"
		echo "store_season='$store_season'"
		echo "store_episode='$store_episode'"
		echo

		echo "## TV.COM information ##"
		echo "show=\"$show\""
		echo "state=\"$state\""
		echo "last=\"$last\""
		echo "last_titel=\"$last_titel\""
		echo "last_season=\"$last_season\""
		echo "last_episode=\"$last_episode\""
		echo "next=\"$next\""
		echo "next_titel=\"$next_titel\""
		echo "next_season=\"$next_season\""
		echo "next_episode=\"$next_episode\""
		echo

		echo "## Update Stamp ##"
		echo "update_date='$update_date'"
		echo "next_update='$next_update'"
	} > "$script_path/$indexfiles/$show_name.cfg"
}

function zero_out_vals {
	zero_cfg_vals
	zero_cfg_vals
	
	update_date=
	last_date=
	next_date=
	now_date=
}

function zero_cfg_vals {
	show_name=
	show_url=
	show_eztv=
	show_quality=
	store_path=
	store_season=
	store_episode=
}

function zero_tv_vals {
	tv_info=
	show=
	state=
	last=
	last_titel=
	last_season=
	last_episode=
	next=
	next_titel=
	next_season=
	next_episode=
}

download_quality=
download_flag=0
new_flag=false
upcomming_flag=false
force_update=false
auto_run=false
SERACH=
FILENAME=

while getopts “hfnud:s:l:” opt_val
do
	case $opt_val in
		h) usage; exit 2;;
		d) download_quality=$OPTARG; download_flag=1;;
		s) SERACH=$OPTARG;;
		l) FILENAME=$OPTARG; auto_run=true;;
		n) new_flag=true; auto_run=true;;
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
