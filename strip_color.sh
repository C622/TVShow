#!/bin/bash

VALUE=$(cat $1 | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g')

echo "$VALUE" > $1
cat $1
