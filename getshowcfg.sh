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

printm_WIDTH=30
. $installpath/strings.func

TEMPFILE=$(mktemp -t getshowcfg)
TEMPFILE_INFO=$(mktemp -t getshowinf)
TEMPFILE_episode=$(mktemp -t getshowepisode)

## Function 'usage', displays usage information
function usage {
cat << EOF
usage: $script_path/$script_file options

This script is used to find and index TV show information. An example could be to search for, $script_file -s "CSI" - This search will use the default option for output, and give you information from the Configuration file, information about last episode in store, and information on where it is stored. Equivalent of using option –c –e -f.

OPTIONS:
   -a      Auto option - Used for running script with no color print output etc. 
   -c    * Show "Configuration" information only 
   -e    * Show "last Episode" information only
   -f    * Show "Store path" information only
   -h      Show this message
   -i    # Update "Index" files (old style)
   -l    # Update "show quality index List" files
   -r    # Run list of information for all shows
   -s      Provide "Search" string - Options marked with *, are depended on this option
   -t    * Get Show information from TV.com
   -n      No update - Will get cached information
   -u    # Update index files with all information (new style)
   
Options marked with # can only be called alone.

EOF
}

function cleanup_files {
	if [ -f $TEMPFILE ]; then
		rm $TEMPFILE
	fi

	if [ -f $TEMPFILE_INFO ]; then
		rm $TEMPFILE_INFO
	fi

	if [ -f $TEMPFILE_episode ]; then
		rm $TEMPFILE_episode
	fi
}
trap cleanup_files EXIT

## Function 'search', main function for search
function search {
	SEARCH=$1
	
	if [ -f $TEMPFILE ]; then
		rm $TEMPFILE
	fi
	
	## Try and match the search, at the start of of the show names
	## Size of the info-block for one show is the number after -iA, Global variable $SHOWINFO_BLOCKSIZE is used for this
	showget=$(grep -iA $SHOWINFO_BLOCKSIZE "^name = \"$SEARCH" $installpath/$showlist)

	## If there is no match at the start, try and find one somewhere in the show names
	if (( $? )); then
		showget=$(grep -iA $SHOWINFO_BLOCKSIZE "^name = .*$SEARCH" $installpath/$showlist | head -n $SHOWINFO_BLOCKSIZE)
	else
		showget=$(head -n $SHOWINFO_BLOCKSIZE <<< "$showget")
	fi

	## If there is no match found, exit!
	if [[ $showget == "" ]]
	then
		echo "Error 51: No match!"
		exit 51
	fi

	## Line by line ...

	IFS_SAVE=$IFS
	IFS=$'\n'

	for line in $showget; do
		line_name=$(sed -e 's/^\(.*\) = ".*"/\1/' <<< $line)
		line_val=$(sed -e 's/^.* = "\(.*\)"/\1/' <<< $line)
		echo "show_$line_name='$line_val'" >> $TEMPFILE
	done

	IFS=$IFS_SAVE

	. $TEMPFILE
	
	if ! [ -f $indexfiles/"$show_name.cfg" ]; then
		silent_update
	fi
}

function show_search {
	if [ -f $TEMPFILE ]; then
		cat $TEMPFILE
	fi
}

function combi {
	## We need to write the file when not excisting!!!
	if $no_update_func && [ -f $indexfiles/"$show_name.cfg" ]; then
		cat $indexfiles/"$show_name.cfg"
	else
		if $show_search_func; then
			show_search
		fi

		if $store_show_func; then
			store_show
		fi
	
		if $store_lastepisode_func; then
			store_lastepisode
		fi
		
		if $getTVcom_func; then
			if (( $comp_func > 1 )); then
				nl
				echo "## TV.COM information ##"
			fi
			
			getTVcom
			
			if (( $comp_func == 1000 )); then
				update_date=`/bin/date "+%s"`
			
				nl
				echo "## Update Stamp ##"
				echo "update_date='$update_date'"
				echo "next_update='$next_update'"
			fi
		fi
	fi
}

function getall_file {
	printl
	echo "Shows in $indexfiles/$1 Listing..."
	printl
	while read line; do
		search "$line"
		combi
		nl
		((total++))
	done < $indexfiles/$1
}

function updateall_file  {
	printl
	echo "Shows in $indexfiles/$1 Updating..."
	printl
	while read line; do
		if [ -f $TEMPFILE_INFO ]; then
			rm $TEMPFILE_INFO
		fi
		
		search "$line"

		if ! $no_update_func; then
			printm "$show_name" "$show_name.cfg"
			{
				combi
			} > $TEMPFILE_INFO
			cp $TEMPFILE_INFO $indexfiles/"$show_name.cfg"
		else
			NEED_UPDATE=false
			printf '%-.38s' "$show_name.cfg ......................................"
			if [ -f $indexfiles/"$show_name.cfg" ]; then
				. $indexfiles/"$show_name.cfg"
				if ! [[ "$show_quality" == "NO" ]]; then
					if [[ "$store_path" == "error" ]]; then
						NEED_UPDATE=true
						if ! $auto_run; then printf "\033[0;31m"; fi
						printf " [ error : Path ]"
						if ! $auto_run; then printf "\033[00m"; fi
						printf "\n"
#						store_show
					elif  [[ "$store_season" == "S-NON" ]]; then
						NEED_UPDATE=true
						if ! $auto_run; then printf "\033[0;31m"; fi
						printf " [ error : Season ]"
						if ! $auto_run; then printf "\033[00m"; fi
						printf "\n"
#						store_lastepisode
					elif  [[ "$store_episode" == "E-NON" ]]; then
						NEED_UPDATE=true
						if ! $auto_run; then printf "\033[0;31m"; fi
						printf " [ error : Episode ]"
						if ! $auto_run; then printf "\033[00m"; fi
						printf "\n"
#						store_lastepisode
					else
						if ! $auto_run; then printf "\033[1;32m"; fi
						printf " [ OK ]"
						if ! $auto_run; then printf "\033[00m"; fi
						printf "\n"
					fi
				else
					if ! $auto_run; then printf "\033[1;34m"; fi
					printf " [ Skip ]"
					if ! $auto_run; then printf "\033[00m"; fi
					printf "\n"
				fi
			else
				NEED_UPDATE=true
				if ! $auto_run; then printf "\033[0;31m"; fi
				printf " [ Missing ]"
				if ! $auto_run; then printf "\033[00m"; fi
				printf "\n"
			fi
			if $NEED_UPDATE; then
				no_update_func=false
				{
					combi
				} > $TEMPFILE_INFO
				cp $TEMPFILE_INFO $indexfiles/"$show_name.cfg"
				no_update_func=true
			fi
		fi
		((total++))
	done < $indexfiles/$1
	nl
}

function getall {
	totalSD=0
	totalHD=0
	totalNO=0
	total=0
	
	getall_file showlistSD.cfg
	((totalSD=total))
	getall_file showlistHD.cfg
	((totalHD=total-totalSD))
	getall_file showlistNO.cfg
	((totalNO=total-totalSD-totalHD))
	
	printm "SD shows" "$totalSD" 12
	printm "HD shows" "$totalHD" 12
	printm "NO shows" "$totalNO" 12	
	printm "Total" "$total" 12
}

function updateall {
	totalSD=0
	totalHD=0
	totalNO=0
	total=0
	
	updateall_file showlistSD.cfg
	((totalSD=total))
	updateall_file showlistHD.cfg
	((totalHD=total-totalSD))
	updateall_file showlistNO.cfg
	((totalNO=total-totalSD-totalHD))
	
	printm "SD shows" "$totalSD" 12
	printm "HD shows" "$totalHD" 12
	printm "NO shows" "$totalNO" 12
	printm "Total" "$total" 12
	
	stat -f "%Sm" $installpath/$showlist > TVshows_file.ini
}

function silent_update {
	update_date=`/bin/date "+%s"`
	silent_update_func=true
	{
		show_search
		store_show
		store_lastepisode
		nl
		echo "## TV.COM information ##"
		getTVcom
		nl
		echo "## Update Stamp ##"
		echo "update_date='$update_date'"
		echo "next_update='$next_update'"
	} > $TEMPFILE_INFO
	
	cp $TEMPFILE_INFO $indexfiles/"$show_name.cfg"
	update_date=
}

function update_single {
	if [ -f $TEMPFILE_INFO ]; then
		rm $TEMPFILE_INFO
	fi

	search "$SEARCH"
	printm "Updating" "$show_name.cfg"

	{
		combi
	} > $TEMPFILE_INFO
	cp $TEMPFILE_INFO $indexfiles/"$show_name.cfg"
}

function gen_index {
	showindex $indexfiles/showlistSD.cfg
	showindex $indexfiles/showlistHD.cfg
	showindex $indexfiles/showlistNO.cfg
}

## showindex.sh
function showindex {
	nl
	printl
	echo "Shows $1 files Updating..."
	printl

	while read show_name
	do
		printm "$show_name" "$show_name.cfg"
		store_show > "$indexfiles/$show_name.cfg"
		store_lastepisode >> "$indexfiles/$show_name.cfg"
	done < $1

	stat -f "%Sm" $installpath/$showlist > TVshows_file.ini
}

## showupdate.sh
function gen_show_list {
	nl
	printl
	echo "showlist config-files Updating..."
	printl

	if [ -f $indexfiles/showlist.cfg ]; then
		rm $indexfiles/showlist.cfg
	fi
	if [ -f $indexfiles/showlistSD.cfg ]; then
		rm $indexfiles/showlistSD.cfg
	fi
	if [ -f $indexfiles/showlistHD.cfg ]; then
		rm $indexfiles/showlistHD.cfg
	fi
	if [ -f $indexfiles/showlistNO.cfg ]; then
		rm $indexfiles/showlistNO.cfg
	fi

	while read -r VarShow
	do
	  read -r VarTVURL
	  read -r VarEZTV
	  read -r VarQuality
	  read -r VarDrop
 
	  VarPrint=$(echo "$VarShow" | sed -E 's/^name.*"(.*)"/\1/')
 
	  if [[ $VarQuality == 'quality = "SD"' ]]
	  then
		echo "$VarPrint" >> $indexfiles/showlist.cfg
	    echo "$VarPrint" >> $indexfiles/showlistSD.cfg
	    printm "$VarPrint" "showlistSD.cfg"
	  fi

	  if [[ $VarQuality == 'quality = "HD"' ]]
	  then
		echo "$VarPrint" >> $indexfiles/showlist.cfg
	    echo "$VarPrint" >> $indexfiles/showlistHD.cfg
	    printm "$VarPrint" "showlistHD.cfg"
	  fi

	  if [[ $VarQuality == 'quality = "NO"' ]]
	  then
	    echo "$VarPrint" >> $indexfiles/showlistNO.cfg
	    printm "$VarPrint" "showlistNO.cfg"
	  fi
 
	done < $showlist
}

## findshow.sh
function store_show {
	show_path_tmp=
	show_path=
	
	while read pathname
	do
		show_path_tmp=`find $pathname -name "$show_name" -print -quit`
		if ! [[ $show_path_tmp == '' ]]; then
			show_path=$show_path_tmp
		fi
	done < $installpath/$showpaths

	if [[ $show_path == '' ]]; then
		echo "store_path='error'"
	else
		echo "store_path='$show_path'"
	fi
	
	if ( $updateall_func && ! [ -f $indexfiles/"$show_name.cfg" ] ) || $silent_update_func; then
		cp $TEMPFILE_INFO $indexfiles/"$show_name.cfg"
	fi
}

## lastepisode.sh
function store_lastepisode {
	seasonnum=
	seasonpath=
	episodenum=
	
	if [ -f "$installpath/$indexfiles/$show_name.cfg" ]; then
		cat $installpath/$indexfiles/"$show_name".cfg | head -n 5 > $TEMPFILE_episode
		. $TEMPFILE_episode
		if [ -f $TEMPFILE_episode ]; then
			rm $TEMPFILE_episode
		fi
	else
#		echo "CFG File not here!"
		return 1
	fi

	if [ -d "$store_path" ]; then
		seasonnum=$(ls -t1 "$store_path" | grep '^Season' | sed -E 's/^Season ([0-9]*).*$/\1/' | sort -n -r | head -n 1)
		seasonpath=$(echo "Season $seasonnum")
	else
		echo "store_season='S-NON'"
		echo "store_episode='E-NON'"
		return 2
	fi

	if [ -d "$store_path"/"$seasonpath" ]; then
		episodenum=$(ls -1 "$store_path"/"$seasonpath" | \
		sed -E 's/^.*[Ss][0-9][0-9].*[Ee]([0-9][0-9]).*/\1/' | \
		sed -E 's/^.*[0-9]{1,2}x([0-9][0-9]).*/\1/' | \
		sort -r | \
		sed 's/^0//' | \
		grep "^[0-9]" | \
		head -n 1)
	fi

	if ! [ -z "$seasonnum" ]; then 
		echo "store_season='$seasonnum'"
	else
		echo "store_season='S-NON'"
	fi

	if ! [ -z "$episodenum" ]; then
		echo "store_episode='$episodenum'"
	else
		echo "store_episode='E-NON'"
	fi
}

function getTVcom {
	$installpath/showgetinfo.pl $show_url
}

function call_function {
	## ==================
	##  VALIDATE SEGMENT
	## ==================

	comp_func=0
	alone_func=0
	full_alone_func=0
	
	## list of combi options/functions ... If one or more are used $comp_func is incremented
	for h in $store_show_func $store_lastepisode_func $show_search_func $getTVcom_func; do
		if $h; then
			comp_func=$(($comp_func + 1))
		fi
	done
	
	## list of alone options/functions ... If one or more are used $alone_func is incremented
	for i in $getall_func $need_search; do
		if $i; then
			alone_func=$((alone_func + 1))
		fi
	done

	## list of full-alone options/functions ... If one or more are used $full_alone_func is incremented
	for j in $gen_show_list_func $gen_index_func; do
		if $j; then
			full_alone_func=$((full_alone_func + 1))
		fi
	done

	## If more that one "alone" options/functions are used, error
	if (( $alone_func > 1 )); then
		echo "Error 10: More than one alone option called!"
		usage
		exit 10
	fi
	
	## If more that one "full-alone" options/functions are used, error
	if (( $full_alone_func > 1 )); then
		echo "Error 11: More than one alone option called!"
		usage
		exit 11

	## If a "full-alone" options/functions are used together with any other option, error
	elif (( $full_alone_func == 1 )) && ( (( $comp_func > 0 )) || (( $alone_func > 0 )) ); then
		echo "Error 12: Alone option called with other option!"
		usage
		exit 12

	## If a combi options/functions called without the search option, error
	elif (( $comp_func > 0 )) && ! ( $need_search || $getall_func ); then
		echo "Error 13: Option depended on s option, called without s option!"
		usage
		exit 13
	fi
	
	if (( $full_alone_func == 0 )) && (( $alone_func == 0 )) && ! $updateall_func; then
		echo "Error 14: No option selected that will give output!"
		usage
		exit 14
	fi
	
	## ========================
	##  CALL FUNCTIONS SEGMENT
	## ========================

	## Now that the options are validated, we can call the functions

	## If no combi option, default is to show all combi options
	
	if $need_search; then
		search "$SEARCH"
	fi

	if (( $comp_func == 0 )); then
		show_search_func=true
		store_show_func=true
		store_lastepisode_func=true
		getTVcom_func=true
		## To indicate that $comp_func was '0', and show_search_func, store_show_func, store_lastepisode_func and getTVcom_func
		## has been changed to 'true'. $comp_func is set to 1000. 
		comp_func=1000
	fi

	if $updateall_func && ! $need_search; then
		updateall
	fi

	if $gen_index_func; then
		gen_index
	fi
		
	if $gen_show_list_func; then
		gen_show_list
	fi

	if $getall_func; then
		getall
	fi

	if $need_search; then
		if $updateall_func; then
			update_single
		else
			combi
		fi
	fi
}

## Default values for flags
need_search=false
store_show_func=false
store_lastepisode_func=false
show_search_func=false
getall_func=false
gen_show_list_func=false
gen_index_func=false
updateall_func=false
no_update_func=false
getTVcom_func=false
auto_run=false
silent_update_func=false

while getopts “acefhilnrs:tux” opt_val
do
	case $opt_val in
		a) auto_run=true;;
		h) usage; exit 0;;
		s) SEARCH=$OPTARG; need_search=true;;
		i) gen_index_func=true;;
		l) gen_show_list_func=true;;
		f) store_show_func=true;;
		e) store_lastepisode_func=true;;
		c) show_search_func=true;;
		r) getall_func=true;;
		u) updateall_func=true;;
		n) no_update_func=true;;
		t) getTVcom_func=true;;
		x) silent_update_func=true;;
		*) usage; exit 2;;
	esac
done

call_function

## Clean-up
cleanup_files
