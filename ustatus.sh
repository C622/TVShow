#!/bin/bash

TEMPFILE1=$(mktemp -t ustat1)
TEMPFILE2=$(mktemp -t ustat2)
TEMPFILE3=$(mktemp -t ustat3)

# You may want to do this if your code is in a script.
unhide_cursor() {
    printf '\e[?25h'
	if [ -f $TEMPFILE1 ]
	then
		rm $TEMPFILE1
	fi	
	if [ -f $TEMPFILE2 ]
	then
		rm $TEMPFILE2
	fi	
	if [ -f $TEMPFILE3 ]
	then
		rm $TEMPFILE3
	fi
	clear
}
trap unhide_cursor EXIT

getlist()
{
btc list | \
grep -E '"name"|"progress"|"state"|"size"|"order"|"upload_rate"|"download_rate"' | \
sed -e 's/^.*"name": "\(.*\)".*$/name="\1"/' | \
sed -e 's/^.*"progress": \(.*.[0-9]\).*$/progress="\1"/' | \
sed -e 's/^.*"size": \([0-9]*\).*$/size="\1"/' | \
sed -e 's/^.*"state": "\(.*\)".*$/state="\1"/' | \
sed -e 's/^.*"order": \([0-9]*\).*$/order="\1"/' | \
sed -e 's/^.*"upload_rate": \([0-9]*\).*$/upload_rate="\1"/' | \
sed -e 's/^.*"download_rate": \([0-9]*\).*$/download_rate="\1"/' > $TEMPFILE1

while read -r Line1; do
	read -r Line2
	read -r Line3
	read -r Line4
	read -r Line5
	read -r Line6
	read -r Line7
	echo $Line1 > $TEMPFILE2
	echo $Line2 >> $TEMPFILE2
	echo $Line3 >> $TEMPFILE2
	echo $Line4 >> $TEMPFILE2
	echo $Line5 >> $TEMPFILE2
	echo $Line6 >> $TEMPFILE2
	echo $Line7 >> $TEMPFILE2
	
	. $TEMPFILE2
	
	if [ $state == "ERROR" ]; then
		uclear
	fi
	if [ $progress == "100.0" ]; then
		uclear
	fi
	
	printf "Name : $name \033[K \n" >> $TEMPFILE3
	printf "#$order  //  State : $state  //  Progress : $progress %%  //  Size : $(($size >> 20)) MB  //  Up : $(($upload_rate >> 10)) KBit/s  //  Down : $(($download_rate >> 10)) KBit/s\033[K \n \033[K \n" >> $TEMPFILE3
done < $TEMPFILE1

if [ -f $TEMPFILE3 ]
then
	cat $TEMPFILE3
	rm $TEMPFILE3
fi	

}

# Hide the cursor (there is probably a much better way to do this)
printf '\e[?25l'
clear

while true; do
	# Move the cursor to the top of the screen but don't clear the screen
    printf '\033[;H'
	
	getlist
	
	## Clear to the end of screen
	printf '\x1b[J'
	
    sleep 1
done
