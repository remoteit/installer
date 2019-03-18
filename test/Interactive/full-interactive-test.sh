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


add_creds()
{
# get account login credentials from environment variables (set in Circle CI)
if [ "${TESTUSERNAME}" = "" ]; then
    echo "TESTUSERNAME environment variable not set! ${TESTUSERNAME}"
    exit 1
elif [ "${TESTPASSWORD}" = "" ]; then
    echo "TESTPASSWORD environment variable not set! ${TESTPASSWORD}"
    exit 1
fi

testusername=${TESTUSERNAME}
testpassword=${TESTPASSWORD}

file1=/usr/bin/connectd_installer
sudo sed -i "/USERNAME/c\USERNAME=$testusername" "$file1"
sudo sed -i "/PASSWORD/c\PASSWORD=$testpassword" "$file1"
}

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
sudo "$SCRIPT_DIR"/interactive-test.sh "$SCRIPT_DIR"/"$3" > console.txt
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
# checkForRoot
#-------------------------------------------------------------------
# get test account credentials from environment variables
add_creds

#-------------------------------------------------------------------
# run installer for first time, add device name and 3 services
# expected result is that 4 connectd services and 1 schannel service will be running
check_service_counts 4 1 configure-01.key

#-------------------------------------------------------------------
# run installer for second time, add 3 more services
# expected result is that 6 connectd services and 1 schannel service will be running
check_service_counts 7 1 configure-02.key

#-------------------------------------------------------------------
# run installer for third time, remove all services
# expected result is that 0 connectd services and 0 schannel service will be running
check_service_counts 0 0 remove-all.key

echo "Interactive installer test suite - all passed"
echo "------------------------------------------------"

exit 0
