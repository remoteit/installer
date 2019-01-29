#!/bin/sh
#set BINPATH to put executables somewhere other than /usr/bin.
# e.g. for Mac OS/X, set BINPATH=/usr/local/bin
BINPATH=

ar x $1
rm control.tar.gz
tar xf data.tar.xz
rm data.tar.xz
if [ "$BINPATH" != "" ]; then
    mv usr/bin/* ./"$BINPATH"
fi

# this overwrites the builddate.txt file created and included in Deb pkg
# however it also appends the file list which can be used by a "delete" script
FILELOG=etc/connectd/builddate.txt
echo "Build date: $(date)" > "$FILELOG"
ls -lR usr >> "$FILELOG"
ls -lR etc >> "$FILELOG"
tar cf $1.tar usr etc
rm -r usr
rm -r etc

