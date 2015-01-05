#!/bin/bash

## Fuction 'usage', displays usage information
usage()
{
cat << EOF
usage: $0 options

This script has the following options.

OPTIONS:
   -h   Show this message
   -n   Called with a numeric value. Will remove that torrent with the order number.

   Default for the script with no options will clear torrents that are finished downloading.

EOF
}

while getopts “hn:” OPTION
do
	case $OPTION in
			h)
			usage
			exit
			;;
			n)
			order_val=$OPTARG
			/usr/local/bin/btc list | /usr/local/bin/btc filter --key order --numeric-equals $order_val | /usr/local/bin/btc remove
			exit
			;;
			*)
			usage
			exit 1
			;;
	esac
done

/usr/local/bin/btc list | /usr/local/bin/btc filter --key progress --numeric-equals 100.0 | /usr/local/bin/btc remove
