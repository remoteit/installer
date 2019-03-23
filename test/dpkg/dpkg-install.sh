#!/bin/sh
# dpkg-install.sh
# connectd package Debian installation test for Continuous Integration
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=0.96
MODIFIED="March 10, 2019"
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
echo "$0"
checkForRoot

version=$(grep -i version "$controlFile" | awk '{ print $2 }' | xargs)

dpkg -i "$BUILD_DIR"/connectd_"$version"_amd64.deb
result=$?
echo "dpkg -i test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

# Status: install ok installed
status=$(dpkg -s connectd | grep ^Status | awk -F":" '{print $2 }' | xargs)
if [ "$status" != "install ok installed" ]; then
    echo "$0 Status error: $status"
    exit 1
else
    echo "Status: $status"
fi

# Version check
dpkg_version=$(dpkg -s connectd | grep ^Version | awk -F":" '{print $2 }' | xargs)
if [ "$dpkg_version" != "$version" ]; then
    echo "$0 Version error: $version $dpkg_version"
    exit 1
else
    echo "Version: $version"
fi


echo "$0 passed."
exit 0

