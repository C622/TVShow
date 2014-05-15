#!/bin/bash

. ./TVShow.cfg

TEMPFILE=$(mktemp -t allshows)

while read pathname
do
	ls -1 $pathname >> $TEMPFILE
done < $installpath/$showpaths

cat $TEMPFILE
rm $TEMPFILE
