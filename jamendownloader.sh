#!/bin/bash

# Download Jamendo album (single tracks not supported yet) in FLAC format (YA RLY!)

clientid="PUT_YOUR_CLIENT_ID_HERE"
#Get your client id from https://devportal.jamendo.com/

if [ -z "$1" ]; then echo "Usage : \"$0 url\" where url is the url of the album you want to download"; exit ;fi

inurl="$1"

albumid="`echo "$inurl" | sed -e 's/.*\/album\/\([0-9]\+\).*/\1/'`"

# get metadata

metadata="`wget -O - -q "https://api.jamendo.com/v3.0/albums/musicinfo?client_id=$clientid&format=jsonpretty&id=$albumid"`"

artist_name="`echo "$metadata"|grep artist_name|sed 's/\s*\"artist_name\":\"//'|sed 's/\",//'`"
album_name="`echo "$metadata"|grep '"name"'|sed 's/\s*\"name\":\"//'|sed 's/\",//'`"
album_art="`echo "$metadata"|grep '"image"'|sed 's/\s*\"image\":\"//'|sed 's/\",//'| tr -d '\\\'|sed 's/.\{3\}$//'| sed 's/$/600/'`"
date="`echo "$metadata"|grep '"releasedate"'|sed 's/\s*\"releasedate\":\"//'|sed 's/\",//'|sed 's/.\{6\}$//'`"

#DEBUG echo "albumid «$albumid»"
#DEBUG echo "artist_name «$artist_name» «$album_name»"

targetdir="./$artist_name/$album_name"
mkdir -p "$targetdir"

wget -c -O "$targetdir/cover.jpg" "$album_art"

tracksid=`wget -O - -q "https://api.jamendo.com/v3.0/tracks/?client_id=$clientid&format=jsonpretty&album_id=$albumid&audiodlformat=flac&limit=all" | grep '"id"' | sed 's/\s*\"id\":\"//'|sed 's/\",//' `

for track_id in  $tracksid; do 
    track_info=`wget -O - -q "https://api.jamendo.com/v3.0/tracks/?client_id=$clientid&format=jsonpretty&id=$track_id&audiodlformat=flac"`
    #DEBUG echo $track_info
    track_name="`echo "$track_info"|grep '"name"'|sed 's/\s*\"name\":\"//'|sed 's/\",//'`"
    track_url="`echo "$track_info"|grep '"audiodownload"'|sed 's/\s*\"audiodownload\":\"//'|sed 's/\",//'| tr -d '\\\'`"
    trackn="`echo "$track_info"|grep '"position"'|sed 's/\s*\"position\"://'|sed 's/,//'`"
    tracknp=$trackn
    if [ $trackn -lt 10 ]; then
        tracknp=0$trackn
    fi

    trackfile="$targetdir/${tracknp} - $track_name.flac"
    
    echo "$trackfile" "$track_url"
    
    wget -c -O "$trackfile" "$track_url"

    # set metadata

    metaflac --remove-all-tags-except=GENRE\
             --set-tag="TITLE=$track_name"\
             --set-tag="ARTIST=$artist_name"\
             --set-tag="ALBUMARTIST=$artist_name"\
             --set-tag="ALBUM=$album_name"\
             --set-tag="TRACKNUMBER=$trackn"\
             --set-tag="DATE=$date"\
             "$trackfile"

done
exit

