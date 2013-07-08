#!/bin/bash
NAME=qproject-sample
[ ! -w "$1" ] && exit 1
#[ ! -w "$2" ] && exit 1
B=`printf "1.%(%Y%m%d)T" -1`
T=`printf "%(%Y-%m-%d %H:%M:%S)T" -1`
IFS=:
grep 'Plugin Name:' $1 -A 20 | while read a b
do
b=`expr substr "$b" 2 length "$b"`
case "$a" in
Plugin?Name) printf "'name' : '%s',\n" "$b";;
Plugin?Slug) printf "'slug' : '%s',\n" "$b";;
Plugin?URI) printf "'download_url' : '%s',\n" "$b";;
Version)
	echo "$0: Version $b => $B" 1>&2
	replace -s "Version: $b" "Version: $B" -- $1 
	printf "'version' : '%s',\n" "$B"
	;;
last_updated)
	replace -s "last_updated: $b" "last_updated: $T" -- $1
	printf "'last_updated' : '%s',\n" "$T"
	;;
\*\/) exit;;
*) printf "'%s' : '%s',\n" "$a" "$b";;
esac
done >$2
exit 0

