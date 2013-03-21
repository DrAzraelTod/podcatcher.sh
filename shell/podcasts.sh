#!/bin/bash
podget >&1;
f=`dirname "$0"`;
$f/update_playlists.sh >&1;
