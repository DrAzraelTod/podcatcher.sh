#!/bin/bash
podget --verbosity 1 >&1;
f=`dirname "$0"`;
$f/update_playlists.sh >/dev/null;
