#!/bin/sh
# full-interactive.sh - 
# runs the interactive insatller (connectd_installer) through 3 scenarios
# a) First rime, add device name and a few services
# b) second time, add a few more services
# c) remove all services
# Author - Gary Worsham gary@remote.it
# set -e
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
. /usr/bin/connectd_library
user=$(whoami)

#-----------------------------------------------------------------------
count_services()
{
    ps ax | grep "connectd\." | grep -v grep > ~/nservices
    services="$(wc -l ~/nservices  | awk '{ print $1 }')"
    return $services
}

#-----------------------------------------------------------------------
count_schannel()
{
    ps ax | grep "connectd_schannel" | grep -v grep > ~/nschannel
    schannel="$(wc -l ~/nschannel  | awk '{ print $1 }')"
    return $schannel
}

#-----------------------------------------------------------------------
# pass this the # of expected connectd daemons, 0 or 1 for schannel, and
# the name of the keystroke file

check_service_counts()
{
echo "Starting interactive install test with keystroke file $3..."
sudo "$SCRIPT_DIR"/interactive-test.sh "$SCRIPT_DIR"/"$3"
sleep 1

count_services
nservices=$?
if [ $nservices -ne $1 ]; then
   echo "$3 test failed with services: $nservices"
   exit 1
fi
count_schannel
nschannel=$?
if [ $nschannel -ne $2 ]; then
   echo "$3 test failed with schannel: $nschannel"
   exit 1
fi
echo "Interactive installer $3 test passed."
}

# main program starts here
echo "------------------------------------------------"
echo "Interactive installer test suite - begin"
echo "user=$user"
# checkForRoot
#-------------------------------------------------------------------
# show test account credentials from environment variables
echo "USERNAME from environment variable"
grep USERNAME /usr/bin/connectd_installer
echo

#-------------------------------------------------------------------
# create random string to serve as part of device/service names
# this allows overlapping CI tests to run
TESTNAME=$(cat /dev/urandom | tr -cd '0-9' | dd bs=10 count=1 2>/dev/null)
sed "s/SERVICENAME/$TESTNAME/g" "$SCRIPT_DIR"/configure-01.key > "$SCRIPT_DIR"/configure-01-test.key
sed "s/SERVICENAME/$TESTNAME/g" "$SCRIPT_DIR"/configure-02.key > "$SCRIPT_DIR"/configure-02-test.key

#-------------------------------------------------------------------
# run installer for first time, add device name and 3 services
# expected result is that 4 connectd services and 1 schannel service will be running
check_service_counts 4 1 configure-01-test.key

#-------------------------------------------------------------------
# run installer for second time, add 6 more services
# expected result is that 9 connectd services and 1 schannel service will be running
check_service_counts 10 1 configure-02-test.key

#-------------------------------------------------------------------
# run installer for third time, remove all services
# expected result is that 0 connectd services and 0 schannel service will be running
check_service_counts 0 0 remove-all.key

echo "Interactive installer test suite - all passed"
echo "------------------------------------------------"

exit 0
