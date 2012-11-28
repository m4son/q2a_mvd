#!/usr/bin/env bash
# small transfer script by Shaque 2012-11-22
mvd="$1"
game="$2"

_file="$game/demos/$mvd"

if [ -f "$_file" ]; then
	echo "put $_file" | sftp -q -p someuser@aq2world.com &
else
	echo "$0 Error: '$_file' not found. Not transferring anything. :("
fi
