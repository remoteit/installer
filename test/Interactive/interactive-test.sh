#!/bin/sh
# interactive.sh - 
# front end for running the /usr/bin/connectd_installer script in a repeatable way
# while capture debug output to the "debug.txt" file.
# Author - Gary Worsham gary@remote.it
. /usr/bin/connectd_library

checkForRoot

#-----------------------------------------------------------------------

# If run with no following parameter, just run the script interactively
# while capturing the debug output (e.g. for manual testing).
if [ "$1" = "" ]; then
#    sudo sh -x /usr/bin/connectd_installer 2> debug.txt | tee console.txt
    sudo sh -x /usr/bin/connectd_installer 2> /tmp/debug.txt | tee /tmp/console.txt
else
# If run with one following parameter, use that parameter as the name of a keystroke file
# such as configure-01.key, configure-02.key, remove-all.key
#    sudo sh -x /usr/bin/connectd_installer < "$1" 2> debug.txt | tee console.txt
    sudo sh -x /usr/bin/connectd_installer < "$1" 2> /tmp/debug.txt | tee /tmp/console.txt
fi

