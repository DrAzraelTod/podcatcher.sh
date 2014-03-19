#!/bin/bash
podget --verbosity 1 >&1;
f=`dirname "$0"`;
update_playlists.sh >/dev/null;
