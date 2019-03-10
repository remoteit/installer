#!/bin/sh
# auto-reg-test.sh
# connectd package auto-registration test for Continuous Integration
# pre-requisiste: the connectd package must be installed
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=0.96
MODIFIED="March 10, 2019"
#---------------------------------------------
# Set the predefined Bulk ID code used in an Auto Registration.
# This one is from the faultline1989 account.
# If you change the Bulk ID code you will need to regenerate the reference files used
# below in the diff statements.
# - dprov_result.txt
# - bprov_result.txt
# - status_result.txt
# - stop_result.txt

#---------------------------------------------
BULKIDCODE="36AC4A2A-AC89-E374-13CE-75E4231FE164"

# include the package library to access some utility functions

. /usr/bin/connectd_library

#---------------------------------------------
# script execution starts here

#---------------------------------------------
# make sure user is running with root access (sudo is OK)

checkForRoot

# generate a new Hardware ID

uuid > /etc/connectd/hardware_id.txt

# generate a new Registration Key

uuid > /etc/connectd/registration_key.txt

echo "$BULKIDCODE" > /etc/connectd/bulk_identification_code.txt

# display bulk registration configuration

connectd_control show

# make sure any previously configured services are stopped (there shouldn't be any, but...)
# and then factory reset (clears all provisioning files)

connectd_control -v stop all
connectd_control reset

# run the provisioning step, capture both stdio and stderr outputs

sh -x /usr/bin/connectd_control -v dprovision > /tmp/dprov.txt 2> debug.txt

# compare stdio output to the reference

diff /tmp/dprov.txt dprov_result.txt
result=$?
echo "dprov test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

# run the registration (bprovision) step, capture both stdio and stderr outputs
# RETRY can occur with registration queued or registration throttled
# these are not predictable so we filter them out

sh -x /usr/bin/connectd_control bprovision all 2>> debug.txt | grep -v "RETRY" > /tmp/bprov.txt

# compare stdio output to the reference
# some variation in request throttling is expected so we filter those out

diff /tmp/bprov.txt bprov_result.txt
result=$?
echo "bprov test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

# get status of all services

connectd_control -v status all > /tmp/status.txt

# compare stdio output to the reference

diff /tmp/status.txt status_result.txt
result=$?
echo "status test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

# get status of all services

connectd_control -v stop all > /tmp/stop.txt

# compare stdio output to the reference
# it is possible that the script will report "still running" prior to shutdown of the daemon
diff /tmp/stop.txt stop_result.txt | grep -v "still running"
result=$?
echo "stop test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

exit 0

