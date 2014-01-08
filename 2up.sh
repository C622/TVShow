#!/bin/sh

./top100.sh $1 > 2up.tmp
div=$(cat ./devider.txt)

echo $div
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
  printf "\n$VarTitelStr "
  
  ## If VarTitel has the right format (*S##E##*), start comparing to list of shownames from file ($2) 
  if [[ $VarTitel =~ $re1 ]]
  then
	VarSeason=$(sed -E 's/^.*S([0-9]{2})E[0-9]{2}.*/\1/' <<< $VarTitel)
	VarEpisode=$(sed -E 's/^.*S[0-9]{2}E([0-9]{2}).*/\1/' <<< $VarTitel)
	VarShow=$(sed -E 's/^titel = "(.*).S[0-9]{2}E[0-9]{2}.*/\1/' <<< $VarTitel | tr '.' ' ')

	## Remove 0 if Season and/or Episode strats with 0

	VarSeason=$(sed -E 's/^0([0-9])/\1/' <<< $VarSeason)
	VarEpisode=$(sed -E 's/^0([0-9])/\1/' <<< $VarEpisode)

	printf "... Valid : S##E##"
	validstr=0
  else
	if [[ $VarTitel =~ $re2 ]]
	then
		VarSeason=$(sed -E 's/^.*([0-9]{1,2})x[0-9]{2}.*/\1/' <<< $VarTitel)
		VarEpisode=$(sed -E 's/^.*[0-9]{1,2}x([0-9]{2}).*/\1/' <<< $VarTitel)
		VarShow=$(sed -E 's/^titel = "(.*).[0-9]{1,2}x[0-9]{2}.*/\1/' <<< $VarTitel | tr '.' ' ')
	
		printf "... Valid : ##x##"
		validstr=0
	else
	  	printf "... NOT valid!"
	  	validstr=1
	fi
  fi

  if [ $validstr == 0 ]
  then
    matchval=1
    while read line; do
      showname=$line
      if [[ $VarShow == $line ]]
      then
	printf "\n"
        while read -r VarPath; do
            read -r VarShowSeason
            read -r VarShowEpisode
            if ([[ $VarSeason == $VarShowSeason ]] || [[ $VarSeason == $((VarShowSeason + 1)) ]])
            then
		matchval=0
		echo
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
      fi
    done < ./ShowIndex/$showname.cfg
  fi
  done < ./ShowIndex/$2
  if ! [ $matchval == 0 ]
  then
	printf " ... Skip!"
  fi
 fi
done < 2up.tmp
printf "\n"
rm 2up.tmp
