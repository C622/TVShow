#!/bin/bash

## list generated with: curl -L -s http://thepiratebay.com | grep 'application/rss+xml' | sed -e 's/^.*rss.thepiratebay.se.//' -e 's/" title="/ /' -e 's/">//' | grep '^[0-9]'

cat /users/chris/Documents/Scripts/TVShow/categories.txt
