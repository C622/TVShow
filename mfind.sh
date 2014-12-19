#!/bin/bash

callpath=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && callpath=$callpath/$(basename -- "$0")
currentpath=$(pwd)
SYM=$(readlink $callpath)
DIR=$(dirname -- "$SYM")

cd $DIR

. ./TVShow.cfg

## Fuction 'usage', displays usage information
usage()
{
cat << EOF
usage: $0

This script needs be called with one option. This would be the string to serach for, i.e. "Smurfs*".
Wildcard can be used: * and ?

EOF
}

if [[ -z $1 ]]
	then
	usage
	exit 1
fi

while read pathname
do
	find "$pathname" -maxdepth 1 -iname "$1" -exec du -hd 0 {} \;
done < $installpath/$moviepaths

cd $currentpath