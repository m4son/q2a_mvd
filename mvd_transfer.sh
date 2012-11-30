!/usr/bin/env bash
# small transfer script by Shaque 2012-11-22
mvd="$1"
game="$2"

_file="$game/demos/$mvd"

if [ -f "$_file" ]; then
  # sleep a little, so q2proded has time to finalize the demo file
  ( sleep 2 ) && ( echo "put $_file" | sftp -q -p someuser@aq2world.com:/demos ) &
else
  echo "$0 Error: '$_file' not found. Not transferring anything. :("
fi


# vim: expandtab tabstop=2 autoindent:
# kate: space-indent on; indent-width 2; mixedindent off;