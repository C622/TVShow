#!/bin/sh

re='^[0-9]{2}$'

log='TV'

CurrentDir=$(pwd)
cd /Users/chris/Documents/Scripts/TVShow/log

for i in {98..1}
do
  val=$i
  valnew=$[$val + 1]
  if ! [[ $val =~ $re ]]; then val="0$val"; fi
  if ! [[ $valnew =~ $re ]]; then valnew="0$valnew"; fi
  logadd=$log
  logadd+=_
  echo "$logadd$val.log -> $logadd$valnew.log"
  mv "$logadd$val.log" "$logadd$valnew.log"
done

logadd+='01'

echo "And the last one: $log.log -> $logadd.log"
mv "$log.log" "$logadd.log"

cd $CurrentDir
