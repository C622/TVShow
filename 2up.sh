#!/bin/sh

TEMPFILE=$(mktemp -t 2up)

./top100.sh -c $1 > $TEMPFILE
div=$(cat ./devider.txt)

echo $div
date
echo "2up.sh $1 $2 output..."
echo $div

re1='^.*S[0-9]{2}E[0-9]{2}.*$'
re2='^.*[0-9]{1,2}x[0-9]{2}.*$'

while read -r VarTitel; do
  read -r VarMagLink
  read -r VarUpDateTime
  read -r VarSize
  read -r VarSeeders
  read -r VarLeechers

  VarTitelStr=$(sed -E 's/^titel = "(.*)"/\1/' <<< $VarTitel) 
  printf "** $VarTitelStr\n"
  
  ## If VarTitel has the right format (*S##E##*), start comparing to list of shownames from file ($2) 
  if [[ $VarTitel =~ $re1 ]]
  then
	VarSeason=$(sed -E 's/^.*S([0-9]{2})E[0-9]{2}.*/\1/' <<< $VarTitel)
	VarEpisode=$(sed -E 's/^.*S[0-9]{2}E([0-9]{2}).*/\1/' <<< $VarTitel)
	VarShow=$(sed -E 's/^titel = "(.*).S[0-9]{2}E[0-9]{2}.*/\1/' <<< $VarTitel | tr '.' ' ')

	printf " - Format is valid : S##E##\n"
	validstr=0
  else
	if [[ $VarTitel =~ $re2 ]]
	then
		VarSeason=$(echo $VarTitel | egrep -oh '[0-9]{1,2}x[0-9]{2}' | sed 's/\(.*\)x.*/\1/')
		VarEpisode=$(echo $VarTitel | egrep -oh '[0-9]{1,2}x[0-9]{2}' | sed 's/.*x\(.*\)/\1/')
		VarShow=$(sed -e 's/.[0-9]\{1,2\}x[0-9]\{2\}.*//' -e 's/titel = "//' -e 's/[\._]/ /' <<< $VarTitel)
	
		printf " - Format is valid : ##x##\n"
		validstr=0
	else
	  	printf " - Format is NOT valid!\n"
	  	validstr=1
	fi
  fi
  ## Remove end of line space ... if any?!
  VarShow=$(echo $VarShow | sed 's/ *$//')

  if [ $validstr == 0 ]
  then
    ## Remove 0 if Season and/or Episode strats with 0
    VarSeason=$(bc <<< $VarSeason)
    VarEpisode=$(bc <<< $VarEpisode)

    matchval=1
    while read line; do
      showname=$line
      if [[ $VarShow == $line ]]
      then
        while read -r VarPath; do
            read -r VarShowSeason
            read -r VarShowEpisode
            if ([[ $VarSeason == $VarShowSeason ]] || [[ $VarSeason == $((VarShowSeason + 1)) ]])
            then
		matchval=0
		echo "-----> Match!"
		echo "Show            : $VarShow"
		echo "Compare Season  : $VarShowSeason to $VarSeason"
		echo "Compare Episode : $VarShowEpisode to $VarEpisode"

              if ([[ $VarEpisode == $((VarShowEpisode + 1 )) ]] || [[ $VarSeason == $((VarShowSeason + 1)) && $VarEpisode == 1 ]])
              then
                echo "Episode is next episode! ... Adding!!! <-----"

                /usr/local/bin/btc add -u "$VarMagLink"

                echo "$VarPath" > "./ShowIndex/$showname.cfg"
                echo "$VarSeason" >> "./ShowIndex/$showname.cfg"
                echo "$VarEpisode" >> "./ShowIndex/$showname.cfg"

                echo "$(date)" >> "./log/TVadded.log"
                echo "Show    : $VarShow" >> "./log/TVadded.log"
                echo "Season  : $VarSeason" >> "./log/TVadded.log"
                echo "Episode : $VarEpisode" >> "./log/TVadded.log"
                echo "" >> "./log/TVadded.log"
              else
                echo "Episode is NOT next episode! <-----"
              fi
	      echo
      fi
    done < ./ShowIndex/$showname.cfg
  fi
  done < ./ShowIndex/$2
  if ! [ $matchval == 0 ]
  then
	printf " - NOT wanted show in this quality\n"
  fi
 fi
done < $TEMPFILE
rm $TEMPFILE
