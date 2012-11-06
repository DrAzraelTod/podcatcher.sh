#!/bin/bash
dir="$1"
#echo "Create playlist for $1 ..."
if [[ $2 ]]; then list="$2"; else list="$1"; fi
 
pushd "$dir" 2>&1 >/dev/null
#find . -type f -name "*.mp3" -or -name "*.ogg" -or -name "*.m4a" -or -name "*.opus" -or -name "*.avi" > "$list.m3u"
find . -type f \
	-not -name "*.m3u" \
	-and -not -name "*.asx" \
	-and -not -name "done" \
	-and -not -name "errors" \
	-and -not -name "*.html" \
	-and -not -name "*.js" \
	-and -not -name "*.swp" \
        -and -not -path "*/.git/*" \
	-and -not -name "*.sh" \
	-and -not -name "*.md" \
	> "$list.m3u"
wc -l "$list.m3u"
popd 2>&1 >/dev/null
