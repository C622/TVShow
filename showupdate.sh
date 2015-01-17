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
## script_path  : Path of the called script
## script_file  : Name of the called script
## current_path : Path where is script was called from (Current path at that time)

. ./TVShow.cfg

printm_WIDTH=30
. $installpath/strings.func

echo
printl
echo "showlist config-files Updating..."
printl

rm $indexfiles/showlist.cfg
rm $indexfiles/showlistSD.cfg
rm $indexfiles/showlistHD.cfg
rm $indexfiles/showlistNO.cfg

while read -r VarShow
do
  read -r VarTVURL
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