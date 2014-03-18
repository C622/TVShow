#!/bin/bash
while read line
do
	pathname=$line
	find $pathname -name "$2" -print -quit
done < $1
