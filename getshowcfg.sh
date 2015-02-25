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

## Function 'usage', displays usage information
function usage
{
cat << EOF
usage: $script_path/$script_file options

This script is used to find and index TV show information. An example could be to search for, $script_file -s "CSI" - This search will use the default option for output, and give you information from the Configuration file, information about last episode in store, and information on where it is stored. Equivalent of using option –c –e -f.

OPTIONS:
   -a    # List information for all shows
   -c    * Show "Configuration" information only 
   -e    * Show "last Episode" information only
   -f    * Show "Store path" information only
   -h      Show this message
   -i    # Update "Index" files (old style)
   -l    # Update "show quality index List" files
   -s      Provide "Search" string - Options marked with *, are depended on this option
   -u    # Update index files with all information (new style)
   
Options marked with # can only be called alone.

EOF
}

## Function 'search', main function for search
function search
{
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
		echo "No match!"
		exit 1
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
}

function show_search
{
	if [ -f $TEMPFILE ]; then
		cat $TEMPFILE
	fi
}

function combi
{
	if $show_search_func; then
		show_search
	fi

	if $store_show_func; then
		store_show
	fi
	
	if $store_lastepisode_func; then
		store_lastepisode
	fi
}

function getall_file 
{
	echo "*** $1 ***"
	nl
	while read line; do
		search "$line"
		combi
		echo
		((total++))
	done < $indexfiles/$1
}

function updateall_file 
{
	printl
	echo "Shows in $indexfiles/$1 Updating..."
	printl
	while read line; do
		if [ -f $TEMPFILE_INFO ]; then
			rm $TEMPFILE_INFO
		fi
		
		search "$line"
		printm "$show_name" "$show_name.cfg" 30
		combi > $TEMPFILE_INFO
		cp $TEMPFILE_INFO $indexfiles/"$show_name.cfg"
		((total++))
	done < $indexfiles/$1
	nl
}

function getall
{
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

function updateall
{
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
	
	printm "SD shows" "$totalSD" 30
	printm "HD shows" "$totalHD" 30
	printm "NO shows" "$totalNO" 30	
	printm "Total" "$total" 30
}

function gen_index
{
	showindex $indexfiles/showlistSD.cfg
	showindex $indexfiles/showlistHD.cfg
	showindex $indexfiles/showlistNO.cfg
}

function showindex
{
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

function gen_show_list
{
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

function store_show
{
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
}

function store_lastepisode
{
	if [ -f "$installpath/$indexfiles/$show_name.cfg" ]; then
		. $installpath/$indexfiles/"$show_name".cfg
	else
		echo "CFG File not here!"
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

function call_function
{
	## ==================
	##  VALIDATE SEGMENT
	## ==================

	comp_func=false
	alone_func=0
	full_alone_func=0
	
	## list of combi options/functions ... If one or more are used $comp_func is set to true
	if $store_show_func || $store_lastepisode_func || $show_search_func; then
		comp_func=true
	fi
	
	## list of alone options/functions
	for i in $getall_func $need_search ; do
		if $i; then
			alone_func=$((alone_func + 1))
		fi
	done

	## list of full-alone options/functions
	for j in $gen_show_list_func $gen_index_func $updateall_func; do
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
	elif (( $full_alone_func == 1 )) && ( $comp_func || (( $alone_func > 0 )) ); then
		echo "Error 12: Alone option called with other option!"
		usage
		exit 12

	## If a combi options/functions called without the search option, error
	elif $comp_func && ! ( $need_search || $getall_func ); then
		echo "Error 13: Option depended on s option, called without s option!"
		usage
		exit 13
	fi
	

	## ========================
	##  CALL FUNCTIONS SEGMENT
	## ========================

	## Now that the options are validated, we can call the functions

	## If no combi option, default is to show all combi options
	if ! $comp_func; then
		show_search_func=true
		store_show_func=true
		store_lastepisode_func=true
	fi

	if $updateall_func; then
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
		combi
	fi	
}

need_search=false
store_show_func=false
store_lastepisode_func=false
show_search_func=false
getall_func=false
gen_show_list_func=false
gen_index_func=false
updateall_func=false

while getopts “hailefcus:” opt_val
do
	case $opt_val in
		h) usage; exit 0;;
		s) SEARCH=$OPTARG; need_search=true; search $SEARCH;;
		i) gen_index_func=true;;
		l) gen_show_list_func=true;;
		f) store_show_func=true;;
		e) store_lastepisode_func=true;;
		c) show_search_func=true;;
		a) getall_func=true;;
		u) updateall_func=true;;
		*) usage; exit 2;;
	esac
done

call_function

## Clean-up
if [ -f $TEMPFILE ]; then
	rm $TEMPFILE
fi

if [ -f $TEMPFILE_INFO ]; then
	rm $TEMPFILE_INFO
fi

if [[ -z $1 ]]; then
	usage
	exit 1
fi
