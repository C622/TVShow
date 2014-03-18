#!/bin/bash

div=$(cat ./devider.txt)

echo
echo $div
echo "showlist.cfg Updating..."
echo $div

rm ./ShowIndex/showlist.cfg
rm ./ShowIndex/showlistSD.cfg
rm ./ShowIndex/showlistHD.cfg

while read -r VarShow
do
  read -r VarTVURL
  read -r VarQuality
  read -r VarDrop
 
  VarPrint=$(echo "$VarShow" | sed -E 's/^name.*"(.*)"/\1/')
 
  if [[ $VarQuality == 'quality = "SD"' ]]
  then
	echo "$VarPrint" >> ./ShowIndex/showlist.cfg
    echo "$VarPrint" >> ./ShowIndex/showlistSD.cfg
    echo "$VarPrint >>> SD!"
  fi

  if [[ $VarQuality == 'quality = "HD"' ]]
  then
	echo "$VarPrint" >> ./ShowIndex/showlist.cfg
    echo "$VarPrint" >> ./ShowIndex/showlistHD.cfg
    echo "$VarPrint >>> HD!"
  fi
 
done < ./TVshows.cfg