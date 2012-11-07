#!/bin/bash
pushd .;
cd /home/dat/AeroFS/public/podcasts;
rm ./*.m3u
mv Comedy/Neues\ vom\ K\&#xE4nguru/ Comedy/Neues\ vom\ Kaenguru;
mv ÖR/Klassiker\ von\ \&quotFragen\ an\ den\ Autor\&quot ÖR/Klassiker\ von\ Fragen\ an\ den\ Autor;
mv sonst/ZEIT\ Wissen\ \&#x2013\ Der\ Podcast/ sonst/ZEIT\ Wissen
mv musik/AVICII\ -\ LEVELS\ PODCAST/ musik/AVICII
m3u.sh . relative;
sed -e "s/.\//http:\/\/g33ky.de\/static\/podcasts\//" relative.m3u > absolute.m3u;
cat absolute.m3u;
echo  -n 'Gefundene feeds:';
grep -c '\n' absolute.m3u;
popd;
