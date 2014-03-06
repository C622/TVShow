#!/bin/bash

/usr/local/bin/btc list | /usr/local/bin/btc filter --key progress --numeric-equals 100.0 | /usr/local/bin/btc remove
