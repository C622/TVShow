#!/bin/bash

btc list | \
grep -E '"name"|"progress"|"state"|"size"|"order"' | \
sed -e 's/^.*"name": "\(.*\)".*$/Name      : \1/' | \
sed -e 's/^.*"progress": \(.*.[0-9]\).*$/Progress  : \1 %/' | \
sed -e 's/^.*"size": \([0-9]*\).*$/Size      : \1/' | \
sed -e 's/^.*"state": "\(.*\)".*$/State     : \1#/' | \
sed -e 's/^.*"order": \([0-9]*\).*$/Order     : \1/' | \
tr '#' '\n'
