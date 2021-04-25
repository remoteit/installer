#!/bin/sh
# full-interactive.sh - 
# runs the interactive insatller (connectd_installer) through 3 scenarios
# a) First time, add device name and a few services
# b) second time, add a few more services
# c) remove all services
# Author - Gary Worsham gary@remote.it
# set -e

SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
. /usr/bin/connectd_library
user=$(whoami)

# set -x
#-----------------------------------------------------------------------
count_services()
{
    ps ax | grep "connectd\." | grep -v grep > /tmp/nservices
    cat /tmp/nservices
    services="$(wc -l /tmp/nservices  | awk '{ print $1 }')"
    return $services
}

#-----------------------------------------------------------------------
count_schannel()
{
    ps ax | grep "connectd_schannel\." | grep -v grep > /tmp/nschannel
    cat /tmp/nschannel
    schannel="$(wc -l /tmp/nschannel  | awk '{ print $1 }')"
    return $schannel
}

#-----------------------------------------------------------------------
# pass this the # of expected connectd daemons, 0 or 1 for schannel, and
# the name of the keystroke file (without the .key extension)

check_service_counts()
{
sed "s/SERVICENAME/$4/g" "$SCRIPT_DIR"/$3.key > "$SCRIPT_DIR"/$3-test.key
if [ "$3" != "" ]; then
    echo "Starting interactive install test with keystroke file $3..."
    sudo "$SCRIPT_DIR"/interactive-test.sh "$SCRIPT_DIR"/"$3"-test.key
    # not entirely sure if sleep is needed here
    sleep 1
fi

count_services
nservices=$?
if [ $nservices -ne $1 ]; then
   echo "$3 test failed with services: $nservices (expected $1)"
   exit 1
fi
count_schannel
nschannel=$?
if [ $nschannel -ne $2 ]; then
   echo "$3 test failed with schannel: $nschannel"
   exit 1
fi
echo "Interactive installer service test $3 $1 $2 test passed."
}


# main program starts here
echo "------------------------------------------------"
echo "Interactive installer test suite - begin"
echo "user=$user"
#---------------------------------------------------------------------------------
# add_creds takes the environment variables and puts them into the file
# for use by the intereactive installer tests
add_creds()
{
# get account login credentials from environment variables (set in Circle CI)
if [ "${TESTUSERNAME}" = "" ]; then
    echo "TESTUSERNAME environment variable not set! ${TESTUSERNAME}"
    exit 1
elif [ "${TESTPASSWORD}" = "" ]; then
    echo "TESTPASSWORD environment variable not set! ${TESTPASSWORD}"
    exit 1
# get account access key/secret from environment variables (set in Circle CI)
elif [ "${TESTACCESSKEY}" = "" ]; then
    echo "TESTACCESSKEY environment variable not set! ${TESTACCESSKEY}"
    exit 1
elif [ "${TESTKEYSECRET}" = "" ]; then
    echo "TESTKEYSECRET environment variable not set! ${TESTKEYSECRET}"
    exit 1
fi

testusername=${TESTUSERNAME}
testpassword=${TESTPASSWORD}
testaccesskey=${TESTACCESSKEY}
testkeysecret=${TESTKEYSECRET}

file1=/usr/bin/connectd_installer
sudo sed -i "/USERNAME/c\USERNAME=$testusername" "$file1"
sudo sed -i "/PASSWORD/c\PASSWORD=$testpassword" "$file1"
sudo sed -i "/ACCESSKEY/c\ACCESSKEY=$testaccesskey" "$file1"
sudo sed -i "/KEYSECRET/c\KEYSECRET=$testkeysecret" "$file1"
grep USERNAME "$file1"
}

add_creds

#-------------------------------------------------------------------
# show test account credentials from environment variables
# Generally speaking, Circle CI will obscure these with *****
echo "USERNAME from environment variable"
grep USERNAME /usr/bin/connectd_installer
echo
echo "ACCESSKEY from environment variable"
grep ACCESSKEY /usr/bin/connectd_installer
echo

#-------------------------------------------------------------------
# create random string to serve as part of device/service names
# this allows overlapping CI tests to run
sudo -H sh -c "cat /dev/urandom | tr -cd '0-9' | dd bs=10 count=1 >/tmp/testname.txt 2>/dev/null"
TESTNAME=$(cat /tmp/testname.txt)

#-------------------------------------------------------------------
# run installer for first time, add device name and 1 service
# first pass uses username and password
# expected result is that 2 connectd services and 1 schannel service will be running
check_service_counts 2 1 configure-01 $TESTNAME

#-------------------------------------------------------------------
# run installer for second time, add 6 more services
# expected result is that 9 connectd services and 1 schannel service will be running
if [ "${CI_FULL_INTERACTIVE_TEST}" = "1" ]; then
    COUNT=10
    check_service_counts $COUNT 1 configure-02 $TESTNAME
else
    COUNT=2
fi

#-------------------------------------------------------------------
# run installer for third time, remove all services
# expected result is that 0 connectd services and 0 schannel service will be running
check_service_counts 0 0 remove-all

#-------------------------------------------------------------------
# run installer for first time, add device name and 1 service
# first pass uses username and password
# expected result is that 2 connectd services and 1 schannel service will be running
check_service_counts 2 1 configure-01-ak $TESTNAME

#-------------------------------------------------------------------
# run installer for second time, add 6 more services
# expected result is that 9 connectd services and 1 schannel service will be running
if [ "${CI_FULL_INTERACTIVE_TEST}" = "1" ]; then
    COUNT=3
    check_service_counts $COUNT 1 configure-02-ak $TESTNAME
else
    COUNT=2
fi

# Now use systemd to turn off and then on the connectd and connectd_schannel
# daemons and confirm operation.

sudo systemctl stop connectd
sleep 10
check_service_counts 0 1
sudo systemctl stop connectd_schannel
sleep 5
check_service_counts 0 0

sudo systemctl start connectd
sleep 10
check_service_counts $COUNT 0
sudo systemctl start connectd_schannel
sleep 5
check_service_counts $COUNT 1

#-------------------------------------------------------------------
# run installer for third time, remove all services
# expected result is that 0 connectd services and 0 schannel service will be running
check_service_counts 0 0 remove-all
echo "Interactive installer test suite - all passed"
echo "------------------------------------------------"

exit 0
