#!/usr/bin/env bash
# small transfer script by Shaque 2012-11-22
mvd="$1"
game="$2"

_file="$game/demos/$mvd"

if [ -f "$_file" ]; then
	scp "$_file"  your_domain@here.com:/home/user/public_html/q2demos/   &
else
	echo "$0 Error: '$_file' not found. Not transferring anything. :("
fi
