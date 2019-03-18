#!/bin/sh
# auto-reg-test.sh
# connectd package auto-registration test for Continuous Integration
# pre-requisiste: the connectd package must be installed
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=0.99
MODIFIED="March 16, 2019"
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
result=0

#---------------------------------------------
# Set the predefined Bulk ID code used in an Auto Registration.
# This one is from the faultline1989 account.

#---------------------------------------------
BULKIDCODE="1233F068-A3F9-9C3F-006F-FBFA9D018813"

# include the package library to access some utility functions

. /usr/bin/connectd_library

#---------------------------------------------
# script execution starts here
echo "Test $0 starting..."
echo
echo "API:"
# the next line can be used as needed to override a specific API version
# comment this line out to return to default API
sed -i -e 's/\/api/\/apv\/v27.5/' /usr/bin/connectd_options
grep ^api /usr/bin/connectd_options
echo

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

# make sure any previously configured services are stopped 
# (there shouldn't be any when running CI, but just to be sure.)
# and then factory reset (clears all provisioning files)

connectd_control -v stop all
connectd_control reset

# run the provisioning step, capture both stdio and stderr outputs

sh -x /usr/bin/connectd_control -v dprovision > /tmp/dprov.txt 2> debug.txt

result=$?
if [ $result -eq 1 ]; then
    cat /tmp/dprov.txt
    exit 1
fi

# run the registration (bprovision) step, capture both stdio and stderr outputs

sh -x /usr/bin/connectd_control bprovision all 2>> debug.txt | grep -v "RETRY" > /tmp/bprov.txt

result=$?
if [ $result -eq 1 ]; then
    cat /tmp/bprov.txt
    exit 1
fi

# get status of all services

connectd_control -v status all > /tmp/status.txt

result=$?
if [ $result -eq 1 ]; then
    cat /tmp/status.txt
    exit 1
fi

# get status of all services

connectd_control -v stop all > /tmp/stop.txt

result=$?
if [ $result -eq 1 ]; then
    cat /tmp/stop.txt
    exit 1
fi

echo "Basic Auto Registration test $0 passed."
exit 0

