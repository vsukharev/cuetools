#!/bin/bash
# Usage: sp FLAC CUE <DATE=19??>
# splits FLAC, according to CUE to lots of flacs, and writes tags from CUE and rest of commandline
if [ ${#} -lt 2 ]
then
  echo "Usage: sp FLAC CUE <DATE=19??>"
  exit 0
fi
if [ ${#} -gt 3 ]
then
  echo "Usage: sp FLAC CUE <DATE=19??>"
  exit 0
fi

echo splitting $1 with $2, plus $3
echo ignoring $3 $4 $5 $6 $7 etc
cuebreakpoints "$2" | shnsplit -o flac -f "$2" -t "%n-%t" "$1"
rm -f 00-pregap.flac
#echo /home/kevin/cuetools/src/tools/cuetag.sh "$2" ??-*.flac "$3" ARTIST PERFORMER DATE YEAR ALBUM GENRE TRACKTOTAL TRACKNUMBER TITLE
/home/kevin/cuetools/src/tools/cuetag.sh "$2" ??-*.flac "$3" ARTIST PERFORMER DATE YEAR ALBUM GENRE TRACKTOTAL TRACKNUMBER TITLE

#echo /home/kevin/cuetools/src/tools/cuetag.sh "$2" "$1" "$3" ARTIST PERFORMER DATE YEAR ALBUM GENRE TRACKTOTAL
/home/kevin/cuetools/src/tools/cuetag.sh "$2" "$1" "$3" ARTIST PERFORMER DATE YEAR ALBUM GENRE TRACKTOTAL

#echo grep DATE "$2"
grep DATE "$2"
