#!/bin/bash

btc list | grep -E '"name"|"progress"|"state"' | sed -e 's/^.*"name": "\(.*\)".*$/Name      : \1/' -e 's/^.*"progress": \(.*.[0-9]\).*$/Progress  : \1 %/' -e 's/^.*"state": "\(.*\)".*$/State     : \1#/' | tr '#' '\n'
