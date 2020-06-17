#!/bin/sh
# interactive.sh - 
# front end for running the /usr/bin/connectd_installer script in a repeatable way
# while capture debug output to the "debug.txt" file.
# Author - Gary Worsham gary@remote.it
. /usr/bin/connectd_library

checkForRoot

#-----------------------------------------------------------------------

# it is necessasry to remove the bulk_identification_code.txt file for the following tests to work
# bulk_identification_code.txt is only used by bulk and auto registration
if [ -e /etc/connectd/bulk_identification_code.txt ]; then
    echo "Deleting /etc/connectd/bulk_identification_code.txt"
    sudo rm /etc/connectd/bulk_identification_code.txt
fi

# If run with no following parameter, just run the script interactively
# while capturing the debug output (e.g. for manual testing).
if [ "$1" = "" ]; then
    sudo sh -x /usr/bin/connectd_installer 2> /tmp/debug.txt | tee /tmp/console.txt
else
# If run with one following parameter, use that parameter as the name of a keystroke file
# such as configure-01.key, configure-02.key, remove-all.key
    sudo sh -x /usr/bin/connectd_installer < "$1" 2> /tmp/debug.txt | tee /tmp/console.txt
fi

