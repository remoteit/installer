#!/bin/sh
# this script needs to execute as root in order to run 
# chown root:root

# check for su user at this point
if ! [ "$(id -u)" = 0 ]; then
    echo "Running this program requires root access." 1>&2
    echo "Please run sudo $0 instead of $0." 1>&2
    exit 1
fi

#set BINPATH to put executables somewhere other than /usr/bin.
# e.g. for Mac OS/X, set BINPATH=/usr/local/bin
BINPATH=

ar x $1
rm control.tar.xz
tar xf data.tar.xz
rm data.tar.xz
if [ "$BINPATH" != "" ]; then
    mv usr/bin/* ./"$BINPATH"
fi

# this overwrites the builddate.txt file created and included in Deb pkg
# however it also appends the file list which can be used by a "delete" script
FILELOG=etc/connectd/builddate.txt
echo "Build date: $(date)" > "$FILELOG"
# make sure that all files in tar are owned by root:root
chown -R root:root usr 
chown -R root:root etc 
chown -R root:root lib 
# list file contents to builddate.txt
ls -lR usr >> "$FILELOG"
ls -lR lib >> "$FILELOG"
ls -lR etc >> "$FILELOG"
# make sure that $FILELOG is also owned by root:root
chown -R root:root etc 
# create tar file
tar cf $1.tar usr etc lib
# make sure that tar file is owned by root:root
chown root:root $1.tar 
# clean up folders with temporary files
rm -r usr
rm -r lib
rm -r etc

