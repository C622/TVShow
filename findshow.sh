#!/bin/bash

. ./TVShow.cfg

## Fuction 'usage', displays usage information
usage()
{
cat << EOF
usage: $0

This script needs be called with one option. This would be the string to serach for, i.e. "CSI"

EOF
}

if [[ -z $1 ]]
	then
	usage
	exit 1
fi

while read pathname
do
	show_path_tmp=`find $pathname -name "$1" -print -quit`
	if ! [[ $show_path_tmp == '' ]]; then
		show_path=$show_path_tmp
	fi
done < $installpath/$showpaths

if [[ $show_path == '' ]]; then
	echo "store_path='error'"
else
	echo "store_path='$show_path'"
fi
