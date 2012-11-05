#!/bin/bash
pushd .;
cd /home/dat/AeroFS/public/podcasts;
rm ./*.m3u
m3u.sh . relative;
sed -e "s/.\//http:\/\/g33ky.de\/static\/podcasts\//" relative.m3u > absolute.m3u;
cat absolute.m3u;
echo  -n 'Gefundene feeds:';
grep -c '\n' absolute.m3u;
popd;
