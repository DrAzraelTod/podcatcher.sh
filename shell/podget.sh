#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------------------
# Filename:      podget.sh                                                                                                       {{{
# Maintainer:    Dave Vehrs <davev(at)users.sourceforge.net>
# Created:       05 Mar 2005 09:35:44 PM
# Last Modified: 06 Jan 2007 08:01:34 PM by Dave V
# Copyright:     © 2005, 2006 Dave Vehrs
#
#                This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
#                License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any
#                later version.
#
#                This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
#                warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#                details.
#
#                You should have received a copy of the GNU General Public License along with this program; if not, write to the
#                Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA _OR_ download at copy at
#                http://www.gnu.org/licenses/licenses.html#TOCGPL
#
# Description:   Podget is a simple bash script to automate the downloading and
#                organizing of podcast content.
# Dependencies:  bash, coreutils, grep, libc6 (for iconv), sed, tofrodos (unix2dos for ASX Playlists) and wget.
# Installation:  cp podget.sh /usr/local/bin
#                chmod 755 /usr/local/bin/podget.sh                                                                              }}}
#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Exit Codes                                                                                                                     {{{

# "Reserved" Exit codes
# 1     General Error
# 2     Misuse of shell built-ins
# 126   Command invoked cannot execute
# 127   Command not found
# 128   Invalid argument to exit
# 130   Script terminated by Control-C
err_libnotdef=50
err_libc6notinstalled=51

# ----------------------------------------------------------------------------------------------------------------------------------
# Help text and default file formats                                                                                             {{{

: << HELP_STEXT
    -c --config <FILE>           Name of configuration file.
    -C --cleanup                 Skip downloading and only run cleanup loop.
    --cleanup_simulate           Skip downloading and simulate running cleanup loop.
                                 Display files to be deleted.
    --cleanup_days               Number of days to retain files.  Anything older will
                                 be removed.
    -d --dir_config <DIRECTORY>  Directory that configuration files are stored in.
    -f --force                   Force download of items from each feed even if 
                                 they've already been downloaded.
    --import_opml <FILE or URL>  Import servers from OPML file or HTTP/FTP URL.
    --import_pcast <FILE or URL> Import servers from iTunes PCAST file or HTTP/FTP URL.
    -l --library <DIRECTORY>     Directory to store downloaded files in.
    -p --playlist-asx            In addition to the default M3U playlist, create
                                 an ASX Playlist.
    -r --recent <count>          Download only the <count> newest items from 
                                 each feed.
    --serverlist <list>          Serverlist to use.
    -s --silent                  Run silently (for cron jobs).
    -v                           Set verbosity to level 1.
    --verbosity <LEVEL>          Set verbosity level (0-4).
    -h --help                    Display help.
HELP_STEXT

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Defaults                                                                                                                       {{{

     #########################################################################################################################
     ## Do not configure here.  Run podget once to install default user configuration files ($HOME/.podget) and edit those. ##
     #########################################################################################################################

# Set dir_cache, dir_install, dir_log, dir_temp in config file.
dir_config="$HOME/.podget"
config_core="podgetrc"
config_serverlist="serverlist"

# Default Verbosity
#  0 == silent
#  1 == Warning messages only.
#  2 == Progress and Warning messages.
#  3 == Debug, Progress and Warning messages.
#  4 == All messages and wget set to maximum verbosity.
verbosity=2

# Silent mode (for calling from cron jobs)
# 0 == normal
# 1 == suppress all messages
silent=0

# Auto-Cleanup. 
# 0 == disabled
# 1 == delete any old content
cleanup=0

# Skip downloading and just run cleanup
# 0 == disable
cleanup_only=0

# Simulate cleanup
cleanup_simulate=0

# Number of days to keep files.   Cleanup will remove anything 
# older than this.
cleanup_days=7

# Most Recent
# 0  == download all new items.
# 1+ == download only the <count> most recent
most_recent=0

# Force
# 0 == Only download new material.
# 1 == Force download all items even those you've downloaded before. 
force=0

# Install session.  This gets called when script is first installed.
install_session=0

# Fix filenames for FAT32 compatibility
modify_filename=0

# Fix downloaded file names of format filename.mp3?1232456 to filename123456.mp3
filename_formatfix=1

# Stop downloads if available space drops below
min_space=10000

# ASX Playlists for Windows Media Player
# 0 == do not create
# 1 == create
asx_playlist=0

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Text for default configuration files:                                                                                          {{{

: << TEXT_DEFAULT_CONFIG
# Name of Server List configuration file
config_serverlist=serverlist

# Directory where to store downloaded files
dir_library=@HOME@/POD

# Directory to store logs in
# dir_log=@HOME@/POD/LOG

# Set logging files
log_fail=errors
log_comp=done

# Build playlists (comment out or set to null value to disable)
playlist_namebase=New-

# Date format for new playlist names
date_format=+%m-%d-%Y

# Wget base options
# Commonly used options:
#   -c            Continued interupted downloads
#   -nH           No host directories (overrides .wgetrc defaults if necessary)
#   --proxy=off   To disable proxy set by environmental variable http_proxy/
#wget_baseopts=-c --proxy=off
wget_baseopts=-c -nH

# Most Recent
# 0  == download all new items.
# 1+ == download only the <count> most recent
most_recent=0

# Force
# 0 == Only download new material.
# 1 == Force download all items even those you've downloaded before. 
force=0

# Autocleanup. 
# 0 == disabled
# 1 == delete any old content
cleanup=0

# Number of days to keep files.   Cleanup will remove anything 
# older than this.
cleanup_days=7

# Filename Cleanup: For FAT32 filename compatability (Feature Request #1378956)
# Tested with the following characters: !@#$%^&*()_-+=||{[}]:;"'<,>.?/
# filename_badchars=!#$^&=+{}[]:;"'<>?|\

# Filename Replace Character: Character to use to replace any/all 
# bad characters found.
filename_replacechar=_

# Filename Cleanup 2:  Some RSS Feeds (like the BBC World News Bulletin) download files with names like filename.mp3?1234567.
# Enable this mode to fix the format to filename1234567.mp3.
# 0 == disabled
# 1 == enabled (default)
filename_formatfix=1

# Stop downloading if available space on the partition drops below value (in KB)
# default:  614400 (600MB)
min_space=614400

# ASX Playlists for Windows Media Player
# 0 == do not create
# 1 == create
asx_playlist=0
TEXT_DEFAULT_CONFIG

: << TEXT_DEFAULT_SERVERLIST
# Default Server List for podget
# FORMAT:    <url> <category> <name>
# NOTES: 
#    1. The Category must be one word without spaces.  You may use underscores.
#    2. Any spaces in the urls needs to be converted to %20 
#    3. Disable the downloading of any feed by commenting it out with a #.
#    4. If you are creating ASX playlists, make sure the feed name does not
#       have any spaces in it.
# Find more servers at: http://www.ipodder.org/directory/4/podcasts
http://thelinuxlink.net/tllts/tllts.rss LINUX The Linux Link
http://www.lugradio.org/episodes.rss Linux LUG Radio
http://www.aarontitus.net/privacy/podcast.php Privacy Privacy Podcast
TEXT_DEFAULT_SERVERLIST

: << TEXT_ASX_BEGINNING
<ASX version = "3.0">
        <PARAM NAME = "Encoding" VALUE = "UTF-8" />
        <PARAM NAME = "Custom Playlist Version" VALUE = "V1.0 WMP8 for CE" />
TEXT_ASX_BEGINNING

: << TEXT_ASX_END
</ASX>
TEXT_ASX_END



#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Functions                                                                                                                      {{{

function display_shelp {  
	echo; echo "Usage $0 [options]"
	sed --silent -e '/HELP_STEXT$/,/^HELP_STEXT/p' "$0" | sed -e '/HELP_STEXT/d'
} 

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Parse command line                                                                                                             {{{

unset cmdl_library

while [ $# -ge 1 ] ; do
	case $1 in 
        -c | --config       ) config_core=$2             ; shift ; shift ;;
        -C | --cleanup      ) cleanup_only=1 ; cleanup=1 ; shift         ;;
        --cleanup_days      ) cleanup_days_cmdl=$2       ; shift ; shift ;;
        --cleanup_simulate  ) cleanup_sim_cmdl=1 ; cleanup_only=1 ; cleanup=1 ; shift ; shift ;;
        -d | --dir_config   ) dir_config=$2              ; shift ; shift ;;
        -f | --force        ) force=1                    ; shift         ;;
             --import_opml  ) import_opml=$2             ; shift ; shift ;;
             --import_pcast ) import_pcast=$2            ; shift ; shift ;;
        -l | --library      ) cmdl_library=$2            ; shift ; shift ;;
        -p | --playlist-asx ) cmdl_asx=1                 ; shift ;       ;;
        -r | --recent       ) most_recent=$2             ; shift ; shift ;;
             --serverlist   ) cmdl_serverlist=$2         ; shift ; shift ;;
        -s | --silent       ) silent=1                   ; shift         ;;
		-v                  ) verbosity=1                ; shift         ;;
             --verbosity    ) verbosity=$2               ; shift ; shift ;;
		*                   ) display_shelp              ; exit 1        ;; 
	esac
done

if [ -n "$cmdl_serverlist" ] ; then
    config_serverlist=$cmdl_serverlist
fi

if [ $silent -eq 1 ] ; then
    verbosity=0   
fi

if [ $verbosity -ge 2 ] ; then
    echo "podget"
fi

if [ $verbosity -ge 3 ] ; then
    echo "Parsing Config file."
    echo -e "Config directory:\t\t$dir_config" 
    echo -e "Config file:\t\t$config_core" 
fi

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Test for another session.                                                                                                      {{{

for file in $(ls -1 ${dir_config}/session.[0-9]* 2>/dev/null) ; do 
    if [ $verbosity -ge 2 ] ; then
        echo "Session file found, testing: ${file}"
    fi
    while read line ; do
        testindex=$(expr "$line" : "\sfile:")
        if [ "A${testindex}" != "A" ]; then
            test_file=$(echo $line | sed -n -e 's/^[^:]\+:\s\(.*\)$/\1/p')
            if [ "$test_file" == "$config_core" ] ; then
                session_pid=$(echo ${file} | sed -n -e 's/^.\+\.\([0-9]*\)$/\1/p')
                if [ $verbosity -ge 2 ] ; then
                    echo "  Testing PID ${session_pid} to determine if its still running."
                fi
                if kill -0 ${session_pid} 2&> /dev/null ; then 
                    echo "Another session with config file ${config_core} found running.  Killing session."
                    exit 1
                else
                    if [ $verbosity -ge 2 ] ; then
                        echo "  Session PID ${session_pid} is not running, removing lock file"
                    fi
                    rm -f ${file}
                fi
            fi 
        fi
    done < $file
done
if [ $verbosity -ge 2 ] ; then
    echo -e "\nSession file not found.  Creating."
fi
echo -e "Config file: $config_core" > ${dir_config}/session.$$ 

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Configuration                                                                                                                  {{{

# Test for config dir.   If missing install it.
if [ ! -d $dir_config ] ; then
    echo "  First Run.  Installing user configuration files."
    echo "  Configuration directory not found.  Creating ${dir_config}"
    mkdir $dir_config
    sed --silent -e '/TEXT_DEFAULT_CONFIG$/,/^TEXT_DEFAULT_CONFIG/p' "$0" | 
        sed -e '/TEXT_DEFAULT_CONFIG/d' | 
        sed -e "s|@HOME@|${HOME}|" > $dir_config/$config_core
    
    sed --silent -e '/TEXT_DEFAULT_SERVERLIST$/,/^TEXT_DEFAULT_SERVERLIST/p' "$0" | 
        sed -e '/TEXT_DEFAULT_SERVERLIST/d' > $dir_config/$config_serverlist
    install_session=1    
fi

# Parse config file
while read line ; do
    if [ $verbosity -ge 3 ] ; then
        echo -e "\nConfig line --> $line"
    fi
    testindex=$(expr "$line" : "\(^[ ]*#\)")
    if [ "A${testindex}" != "A" ]; then
        if [ $verbosity -ge 4 ] ; then
            echo "Discarding comment."
        fi
        continue
    fi
    if [[ $(expr "$line" : ".*=") > 0 ]]; then
        if [ $verbosity -ge 3 ] ; then
            echo " Found config line."
        fi
        var2set=$(echo $line | sed -n -e 's/^\([^=]\+\)=.*$/\1/p')
        set2var=$(echo $line | sed -n -e 's/^[^=]\+=\(.*\)$/\1/p')
        eval export $var2set='$set2var'
    fi
done < $dir_config/$config_core

if [ $install_session -gt 0 ] ; then
    echo "  Downloading a single item from each default server to test configuration."
    echo 
    most_recent=1
    verbosity=3
fi

if [ $verbosity -ge 3 ] ; then
    echo "LIBRARY DIR:  $dir_library" 
fi

if [ -n "$cmdl_library" ] ; then
    dir_library=$cmdl_library
fi

if [ -z $dir_library ] ; then
    echo "ERROR - Library directory not defined."
    exit $err_libnotdef
fi

if [ ! -z $cleanup_days_cmdl ] ; then
    cleanup_days=$cleanup_days_cmdl
fi

if [ ! -z $cleanup_sim_cmdl ] ; then
    cleanup_simulate=$cleanup_sim_cmdl
fi

if [ -z $dir_log ] ; then
    dir_log=$dir_library/.LOG
fi

if [ -n "$cmdl_serverlist" ] ; then
    config_serverlist=$cmdl_serverlist
fi

if [ -n "$cmdl_asx" ] ; then
    asx_playlist=$cmdl_asx
fi

if [ $verbosity -le 1 ] ; then
    wget_options="-q $wget_baseopts" 
elif [ $verbosity -eq 2 ] ; then
    wget_options="-nv $wget_baseopts" 
elif [ $verbosity -eq 3 ] ; then
    wget_options="$wget_baseopts --progress=dot:mega" 
else
    wget_options="$wget_baseopts --progress=bar" 
fi

if [ ! -z $filename_badchars ] ; then
    # insert a space between all characters.
    filename_badchars=$(echo ${filename_badchars} | sed -e 's/\([^ ]\)/\1 /g' -e 's/[*]/\\*/g')
    
    if [ $verbosity -eq 3 ] ; then
        echo -e "\nFilename Bad Characters: ${filename_badchars}"
        echo "Filename Replace Character: ${filename_replacechar}"
    fi

    modify_filename=1
fi

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Loop over servers on list                                                                                                      {{{

if [ $cleanup_only -eq 0 ] && [ -z $import_opml ] && [ -z $import_pcast ] ; then
    if [ $verbosity -ge 3 ] ; then
        echo -e "\nMain loop."
        echo "SERVER LIST FILE: $config_serverlist" 
        echo "WGET OPTIONS: $wget_options" 
    fi

    mkdir -p $dir_log
    touch $dir_log/$log_fail $dir_log/$log_comp

    if [ -n "$playlist_namebase" ] ; then
        playlist_name=$playlist_namebase$(date $date_format).m3u
    else
        playlist_name="New-$(date $date_format).m3u"
    fi
    
    counter=2
    while [ -e $dir_library/$playlist_name ]
    do
        playlist_name=$playlist_namebase$(date $date_format).r$counter.m3u
        counter=$((counter+1))
    done

    # UTF-8/16 handling
    for filetype in utf8 utf16 ; do 
        if [ $verbosity -ge 3 ] ; then
            echo
            case $filetype in
                'utf8')  
                    echo "UTF-8 Loop running." ;;
                'utf16') 
                    echo "UTF-16 Loop running." ;;
            esac
        fi
        case $filetype in
            'utf8')  
                current_serverlist="${dir_config}/${config_serverlist}" ;;
            'utf16')
                iconv_binary=$(which iconv)
                if [ -z $iconv_binary ] ; then
                    echo "Can't find iconv binary, is libc6 installed?"
                    echo "Exiting UTF16 loop, unable to convert file to UTF8"
                    exit $err_libc6notinstalled
                fi
                current_serverlist="${dir_config}/${config_serverlist}.utf16" ;;
            *) 
                echo "Unknown Filetype: $filetype"
        esac
        if [ ! -f $current_serverlist ] ; then
            if [ $verbosity -ge 3 ] ; then
                echo "No config file found, exiting loop."
            fi
            continue
        fi

        while read feed_url feed_category feed_name ; do
            if [ $verbosity -ge 3 ] ; then
                echo -e "\nServer/Feed URL --> $feed_url"
            fi

            if   [[ $(expr index "# " "$feed_url") > 0 ]] && [[ $(expr index "# " "$feed_url") < 2 ]] || [[ $feed_url == "" ]] ; then
                if [ $verbosity -ge 3 ] ; then
                    echo "  Discarding line (comment or blank line)."
                fi
                continue
            fi
            
            if [ $verbosity -ge 2 ] ; then
                echo -e "\n-------------------------------------------------"
                echo -e "Category: $feed_category\t\tName: $feed_name"
                echo "Downloading feed index from $feed_url" 
            fi
            
            case $filetype in
                'utf8')  
                    indexfile=$(wget $wget_options -O - $feed_url  | sed -e 's/\r/\n/g' -e "s/'/\"/g"  -e 's/<\([^/]\)/\n<\1/g' | \
                        sed -n -e :a -e 's/.*<enclosure.*url\s*=\s*"\([^"]\+\)".*/\1/Ip;/<enclosure\s\+/{N;s/ *\n/ /;ba;}') ;;
                'utf16') 
                    indexfile=$(wget $wget_options -O - $feed_url | iconv -f UTF-16 -t UTF-8  | \
                        sed -e 's/\r/\n/g' -e "s/'/\"/g"  -e 's/<\([^/]\)/\n<\1/g' | \
                        sed -n -e :a -e 's/.*<enclosure.*url\s*=\s*"\([^"]\+\)".*/\1/Ip;/<enclosure\s\+/{N;s/ *\n/ /;ba;}') ;;
            esac
            
            
            if [ -n "$indexfile" ] ; then
                if [ $most_recent -gt 0 ] ; then
                    fullindexfile=$indexfile
                    indexfile=$(echo ${indexfile} | cut -d \  -f -${most_recent})
                fi
                
                if [ $verbosity -ge 3 ] ; then 
                    if [ $most_recent -gt 0 ] ; then
                        echo -e "Modified Index List:\n${indexfile}"
                        echo -e "Full Index List:\n${fullindexfile}"
                    else
                        echo -e "Index List:\n${indexfile}"
                    fi
                fi
                
                for url in $indexfile
                do
                    url_filename=$(echo $url | sed -e 's/.*\/\([^\/]\+\)/\1/' -e 's/%20/ /g')
                    url_base=$(echo $url | sed -e 's/\(.*\/\)[^\/]\+/\1/')

                    # Test for available space on library partition
                    avail_space=$(df -kP ${dir_library} | tail -n 1 | awk '{print $4}')
                    if [ ${avail_space} -le ${min_space} ] ; then
                        echo -e "\nAvailable space on Library partition has dropped below allowed.\nStopping Session."
                        exit 1
                    fi

                    # Test for filename modifications.
                    if [ ${modify_filename} -gt 0 ] ; then
                        mod_filename=${url_filename}

                        for character in ${filename_badchars} ; do 
                            eval "mod_filename=$(echo $mod_filename | sed -e s/[\\${character}]/${filename_replacechar}/g)"
                        done
                        if [ $verbosity -ge 3 ] ; then 
                            echo "MODIFIED FILENAME: $mod_filename"
                        fi
                    fi
                    
                    # Fix improperly formated filenames (fixes filename.mp3?123456 to filename123456.mp3)
                    if [ ${filename_formatfix} -gt 0 ] ; then
                        if [ ${modify_filename} -eq 0 ] ; then
                            mod_filename=${url_filename}
                        fi
                        if [ $(expr "${mod_filename}" : ".*\.mp3\?[\\?][0-9]*\?[0-9]\$") -gt 0 ] ; then 
                            mod_filename=$(echo ${mod_filename} | sed 's/\(.*\)\.mp3.\([0-9]*\)/\1\2\.mp3/g')
                            if [ $verbosity -ge 3 ] ; then 
                                echo "FILENAME FORMAT FIXED: $mod_filename"
                            fi
                        fi
                    fi

                    mkdir -p "$dir_library/$feed_category/$feed_name"
                    dtest=$(fgrep $url $dir_log/$log_comp)
                    
                    if [ -z "${dtest}" ] || [ ${force} -ne 0 ] ; then
                        if [ ${verbosity} -ge 2 ] ; then
                            echo -e "\nDownloading $url_filename from $url_base"
                        fi
                        
                        if [ $modify_filename -gt 0 ] || [ $filename_formatfix -gt 0 ] ; then
                            wget $wget_options -O "$dir_library/$feed_category/$feed_name/$mod_filename" $url
                        else
                            wget $wget_options -P "$dir_library/$feed_category/$feed_name/" $url
                        fi
                        
                        if [ $? ] ; then
                            echo $url >> $dir_log/$log_comp
                            if [ -n "$playlist_name" ] ; then
                                if [ $modify_filename -gt 0 ] ; then
                                    echo "$feed_category/$feed_name/$mod_filename" >> $dir_library/$playlist_name
                                else
                                    echo "$feed_category/$feed_name/$url_filename" >> $dir_library/$playlist_name
                                fi
                            fi
                        else
                            echo $url >> $dir_log/$log_fail
                        fi
                    else
                        if [ $verbosity -ge 2 ] ; then
                            if [ $verbosity -ge 3 ] ; then echo ; fi
                            echo "Already downloaded $url_filename."
                        fi
                    fi
                done
                if [ $most_recent -ne 0 -a $install_session -eq 0 ] ; then
                    for url in $fullindexfile
                    do
                        dtest=$(fgrep $url $dir_log/$log_comp)
                        if [ -z "${dtest}" ] ; then
                            url_filename=$(echo $url | sed -e 's/.*\/\([^\/]\+\)/\1/' -e 's/%20/ /g')
                            if [ $verbosity -ge 2 ] ; then
                                echo "Marking as already dowloaded $url_filename."
                            fi
                            echo $url >> $dir_log/$log_comp
                        fi
                    done
                fi
            else
                if [ $verbosity -ge 1 ] ; then
                    echo "  No enclosures in feed: $feed_url"
                fi
                echo $feed_url >> $dir_log/$log_fail
            fi
        done < $current_serverlist
    done

    # Sort new playlist
    if [ -e "$dir_library/$playlist_name" ] ; then 
        cat "$dir_library/$playlist_name" | sort > "$dir_library/$playlist_name"
        
        # Create ASX Playlist
        if [ ${asx_playlist} -gt 0 ] ; then 
            asx_location="\\SD Card\\POD\\"
            asx_playlist_name=`basename ${dir_library}/${playlist_name} .m3u`.asx
            sed --silent -e '/TEXT_ASX_BEGINNING$/,/^TEXT_ASX_BEGINNING/p' "$0" |
              sed -e '/TEXT_ASX_BEGINNING/d' > ${dir_library}/${asx_playlist_name}

            while read line ; do
#            for entry in `cat "$dir_library/$playlist_name"`; do
              fixed_entry=$(echo ${line} | sed 's/\//\\/g')
              echo '    <ENTRY>' >> ${dir_library}/${asx_playlist_name}                                         
              echo "        <ref href = \"${asx_location}${fixed_entry}\" />" >> ${dir_library}/${asx_playlist_name}
              echo "        <ref href = \".\\${fixed_entry}\" />" >> ${dir_library}/${asx_playlist_name}
              echo '    </ENTRY>' >> ${dir_library}/${asx_playlist_name}
#            done >> $dir_library/$asx_playlist_name
            done < ${dir_library}/${playlist_name}

            sed --silent -e '/TEXT_ASX_END$/,/^TEXT_ASX_END/p' "$0" |
              sed -e '/TEXT_ASX_END/d' >> ${dir_library}/${asx_playlist_name}

            unix2dos -d ${dir_library}/${asx_playlist_name}
        fi
    fi
fi

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Cleanup loop                                                                                                                   {{{

if [ -z $import_opml ]  && [ -z $import_pcast ] ; then
    if [ $cleanup -ne 0 ] || [ $cleanup_only -ne 0 ] ; then
        if [ $verbosity -ge 2 ] ; then
            if [ $cleanup_simulate -gt 0 ] ; then
                echo "Simulating cleanup, the following files will be removed when you run cleanup."
            else
                echo -e "\n-------------------------------------------------\nCleanup old tracks."
            fi
        fi
        filelist=$(find $dir_library/ -maxdepth 1 -type f -name "*.m3u" -mtime +${cleanup_days})
        for file in $filelist ; do
            if [ $verbosity -ge 2 ] ; then
                echo "Deleting tracks from $file:"
            fi
            while read line ; do
                if [ $cleanup_simulate -gt 0 ] ; then
                    echo "File:  $dir_library/$line"
                else
                    if [ $verbosity -ge 2 ] ; then
                        rm -v "$dir_library/$line"
                    else
                        rm -f "$dir_library/$line" 
                    fi
                fi
            done < $file
            if [ $cleanup_simulate -gt 0 ] ; then
                echo "Removing playlist: $file"
            else
                if [ $verbosity -eq 0 ] ; then
                    rm -f "$file" 
                else
                    rm -fv "$file"
                fi
            fi
        done
    fi
fi

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# OPML import loop:                                                                                                              {{{

if [ ! -z $import_opml ] ; then
    if [ $verbosity -ge 2 ] ; then
        echo -e "\nImport servers from OPML file: $import_opml"
    fi
    
    new_category="OPML_Import_$(date ${date_format})"

    if [[ $import_opml == http:* ]] || [[ $import_opml == ftp:* ]] ; then
        if [ $verbosity -ge 2 ] ; then
            echo "Getting opml list."
        fi
        opml_list=$(wget ${wget_options} -O - ${import_opml})
    else
        opml_list=$(cat ${import_opml})
    fi
    
    new_list=$(echo ${opml_list} | sed -e 's/\(\/>\)/\1\n/g' | sed -e :a -n -e 's/<outline\([^>]\+\)\/>/\1/Ip;/<outline/{N;s/\n\s*/ /;ba;}')
    
    if [ -n "$new_list" ] ; then
        
        OLD_IFS=$IFS
        IFS=$'\n'
        
        for data in ${new_list} ; do
            if [ $verbosity -ge 1 ] ; then
                echo -e "\n---------------"
            fi

            new_label=$(echo $data | sed -n -e 's/.*text="\([^"]\+\)".*/\1/Ip' | sed -e 's/^\s*[0-9]\+\.\s\+//' -e "s/[:;'\".,!/?<>\\|]//g")
            new_url=$(echo $data | sed -n -e 's/.*[xml]*url="\([^"]\+\)".*/\1/Ip' | sed -e 's/ /%20/g')

            if [ $verbosity -ge 3 ] ; then
                echo "LABEL:  ${new_label}"
                echo "URL:    ${new_url}"
            fi

            test=$(grep ${new_url} ${dir_config}/${config_serverlist})
            if [ -z $test ] ; then
                echo "${new_url} ${new_category} ${new_label}" >> ${dir_config}/${config_serverlist}
            elif [ $verbosity -ge 2 ] ; then
                echo "Feed ${new_label} is already in the serverlist"
            fi
        done 
        
        IFS=$OLD_IFS
    else
        if [ $verbosity -ge 2 ] ; then
            echo "  OPML Import Error $import_opml"
        fi
        echo OPML Import Error: $import_opml >> $dir_log/$log_fail
        exit 1
    fi
fi

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# PCAST import:                                                                                                                  {{{

if [ ! -z $import_pcast ] ; then
    if [ $verbosity -ge 2 ] ; then
        echo -e "\nImport server from PCAST file: $import_pcast"
    fi

    if [[ $import_pcast == http:* ]] || [[ $import_pcast == ftp:* ]] ; then
        if [ $verbosity -ge 2 ] ; then
            echo "Getting pcast file."
        fi
        pcast_data=$(wget ${wget_options} -O - ${import_pcast})
    else
        pcast_data=$(cat ${import_pcast})
    fi

    new_link=$(echo ${pcast_data} | sed -n -e 's/.*\(href\|url\)="\([^"]\+\)".*/\2/Ip' | sed -e 's/ /%20/g')
    new_category=$(echo ${pcast_data} | sed -n -e 's/.*<category>\([^<]\+\)<.*/\1/Ip' | sed -e 's/ /_/g;s/\&quot;/\&/g;s/\&amp;/\&/g')
    new_title=$(echo ${pcast_data} | sed -n -e 's/.*<title>\([^<]\+\)<.*/\1/Ip')

    if [ $verbosity -ge 2 ] ; then
        echo "LINK: ${new_link}"
        echo "CATEGORY: ${new_category}"
        echo "TITLE: ${new_title}"
    fi

    test=$(grep ${new_link} ${dir_config}/${config_serverlist})
    if [ -z "$test" ] ; then
        echo "${new_link} ${new_category} ${new_title}" >> ${dir_config}/${config_serverlist}
    elif [ $verbosity -ge 2 ] ; then
        echo "Feed ${new_title} is already in the serverlist"
    fi
fi


#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Close session and clean up:                                                                                                    {{{

if [ $verbosity -ge 2 ] ; then
    echo -e "\nClosing session and removing lock file."
fi
rm -f ${dir_config}/session.$$

#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# Notes:                                                                                                                         {{{
# 1.  Best viewed in Vim (http://vim.sf.net) with the AutoFold plugin and the Relaxedgreen colorscheme (vimscripts #925 and #791).
# 2.  Known Bug:  If the same filename is downloaded for multiple items on a single feed, wgets continue fuction will cause them to
#     append or error.
#                                                                                                                                }}}
# ----------------------------------------------------------------------------------------------------------------------------------
# vim:tw=132:ts=4:sw=4
