#!/bin/bash
F="$1"
T="$2"
grep -qr "T" . || (echo "$T: name exists";exit 1) || exit 1
[ -n "$F" -a -n "$T" ] && replace "$F" "$T" -- $(find . -maxdepth 1 -type f)
echo "note[$F->$T]: Rename dir,files. Update plug.php,info.sh ..." 1>&2
