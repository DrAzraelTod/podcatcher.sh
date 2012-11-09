#!/bin/bash
pushd .;
cd /home/dat/AeroFS/public/podcasts;
rm ./*.m3u
#mv Comedy/Neues\ vom\ K\&#xE4nguru/ Comedy/Neues\ vom\ Kaenguru;
#mv Comedy/NDR\ 2\ -\ Fr\&#xFChst\&#xFCck\ bei\ Stefanie Comedy/Fruehstueck\ bei\ Stefanie
#mv ÖR/Klassiker\ von\ \&quotFragen\ an\ den\ Autor\&quot ÖR/Klassiker\ von\ Fragen\ an\ den\ Autor;
#mv sonst/ZEIT\ Wissen\ \&#x2013\ Der\ Podcast/ sonst/ZEIT\ Wissen
#mv musik/AVICII\ -\ LEVELS\ PODCAST/ musik/AVICII
#mv ÖR/IQ\ -\ Wissenschaft\ und\ Forschung\ -\ Bayern\ 2 ÖR/IQ\ -\ Wissenschaft\ und\ Forschung
m3u.sh . relative;
sed -e "s/.\//http:\/\/g33ky.de\/static\/podcasts\//" relative.m3u > absolute.m3u;
cat absolute.m3u;
echo  -n 'Gefundene feeds:';
grep -c '\n' absolute.m3u;
popd;
