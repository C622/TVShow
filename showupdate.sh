#!/bin/bash

callpath=$(dirname $0)
currentpath=$(pwd)
cd $callpath

. ./TVShow.cfg

div=$(cat $devider)

echo
echo $div
echo "showlist.cfg Updating..."
echo $div

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
    echo "$VarPrint >>> SD!"
  fi

  if [[ $VarQuality == 'quality = "HD"' ]]
  then
	echo "$VarPrint" >> $indexfiles/showlist.cfg
    echo "$VarPrint" >> $indexfiles/showlistHD.cfg
    echo "$VarPrint >>> HD!"
  fi

  if [[ $VarQuality == 'quality = "NO"' ]]
  then
    echo "$VarPrint" >> $indexfiles/showlistNO.cfg
    echo "$VarPrint >>> NO!"
  fi
 
done < $showlist