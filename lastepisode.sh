#!/bin/bash
show="$1"

if [ -f "./ShowIndex/$show.cfg" ]; then

  read -r showpath < ./ShowIndex/"$show".cfg

else

  echo "CFG File not here!"
  exit 1

fi

if [ -d "$showpath" ]; then

  seasonpath=$(ls -t1 "$showpath" | head -n 1)
  seasonnum=$(echo "$seasonpath" | sed -E 's/^Season (.*)/\1/')
  printf "$seasonnum\n"

else

  echo "Show path not there!"
  exit 2

fi

if [ -d "$showpath"/"$seasonpath" ]; then
  ls -1 "$showpath"/"$seasonpath" | \
  sed -e 's/^.*S[0-9][0-9].*E\([0-9][0-9]\).*/\1/' \
      -e 's/^.*s[0-9][0-9].*e\([0-9][0-9]\).*/\1/' | \
  sort -r | \
  sed -e 's/^0\([0-9]\)/\1/' | \
  head -n 1
else
  echo "Episode path not there?!"
  exit 3
fi
