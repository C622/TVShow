#!/bin/sh

./top100.sh $1 > 2up.tmp
div=$(cat ./devider.txt)

echo $div
echo "2up.sh $1 $2 output..."
echo $div

re='^.*S[0-9]{2}E[0-9]{2}.*$'

while read -r VarTitel; do
  read -r VarMagLink
  read -r VarUpDateTime
  read -r VarSize
  read -r VarSeeders
  read -r VarLeechers

  echo "$VarTitel"

  VarSeason=$(sed -E 's/^.*S([0-9]{2})E[0-9]{2}.*/\1/' <<< $VarTitel)
  VarEpisode=$(sed -E 's/^.*S[0-9]{2}E([0-9]{2}).*/\1/' <<< $VarTitel)
  VarShow=$(sed -E 's/^titel = "(.*).S[0-9]{2}E[0-9]{2}.*/\1/' <<< $VarTitel | tr '.' ' ')

  ## Remove 0 if Season and/or Episode strats with 0

  VarSeason=$(sed -E 's/^0([0-9])/\1/' <<< $VarSeason)
  VarEpisode=$(sed -E 's/^0([0-9])/\1/' <<< $VarEpisode)

  ## If VarTitel has the right format (*S##E##*), start comparing to list of shownames from file ($2) 

  if [[ $VarTitel =~ $re ]]
  then

    while read line; do
      showname=$line
      if [[ $VarShow == $line ]]
      then
        while read -r VarPath; do
            read -r VarShowSeason
            read -r VarShowEpisode
            if ([[ $VarSeason == $VarShowSeason ]] || [[ $VarSeason == $((VarShowSeason + 1)) ]])
            then
              echo "-----> Match!"
              echo "Show    : $VarShow"
              echo "Season  : $VarShowSeason"
              echo "Episode : $VarShowEpisode"

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

              echo ""
            fi
        done < ./ShowIndex/$showname.cfg
      fi
    done < ./ShowIndex/$2

  fi
done < 2up.tmp

rm 2up.tmp
