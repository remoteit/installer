#!/bin/sh
# dpkg-purge.sh
# connectd package Debian purge test for Continuous Integration
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=0.96
MODIFIED="March 16, 2019"
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
BUILD_DIR="$SCRIPT_DIR/../../build"
pkgFolder="$SCRIPT_DIR/../../connectd"
controlFilePath="$pkgFolder"/DEBIAN
controlFile="$controlFilePath"/control

#---------------------------------------------
# make sure user is running with root access (sudo is OK)
##### checkForRoot #####
checkForRoot()
{
    # check for su user at this point
    if ! [ "$(id -u)" = 0 ]; then
        echo "Running this program requires root access." 1>&2
        echo "Please run sudo $0 instead of $0." 1>&2
	exit 1
    fi
}

#---------------------------------------------
# Main program starts here
# display script name
echo "$(basename $0)"
checkForRoot

dpkg --purge connectd
result=$?
echo "dpkg --purge test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

# after the purge, we do a status.  It should return 1 as the package
# is expected to no longer be installed
dpkg -s connectd
result=$?
if [ $result -eq 0 ]; then
    # Status: install ok installed
    status=$(dpkg -s connectd | grep ^Status | awk -F":" '{print $2 }' | xargs)
    echo "$(basename $0) dpkg Status error: $status"
    exit 1
fi

echo "$0 passed."
exit 0

