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
	find $pathname -name "$1" -print -quit
done < $installpath/$showpaths
