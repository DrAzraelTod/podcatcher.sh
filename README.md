podcatcher.sh
=============

a podcast-aggregator and access to that data (currently mostly html5/m3u)

## RSS/Atom-Parsing

... is currently done by [podget](http://podget.sourceforge.net/) (GPL Podcast Downloader, shell script)
sadly the output of m3u-files didn't work ootb, so i included my own script for that and delete those of podget with every run.
In the future i will hopefully adapt the original script to do some more things (like additional output-formats)

## Playback

Currently 2 m3u-files are beeing generated, that should work for _some_ mediaplayers to play those files via http or similar network-transfer.
Since that isn't working everywhere (i'm looking at you android!), i built some HTML5/JS-Interface that should parse the m3u and play the files.

## Does it work?

Well.. some of it does. Testpage is aviable at [g33ky.de/static/podcasts](http://g33ky.de/static/podcasts/).

## TODO

at podget:
* add a flag to only mark everything downloaded without downloading (last time i removed 2 lines temporarily to do that)
* create additional output formats (rss/atom? json? ...)

at client:
* somehow remember what has been listened
* better support different formats
* sequential download/play of one file after another ([x] done)

other:
* do something python/golang
* mayhaps create android-client
