#!/bin/sh
# auto-reg-test.sh
# connectd package auto-registration test for Continuous Integration
# pre-requisiste: the connectd package must be installed
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=1.0.0
MODIFIED="September 28, 2019"
TEST_DIR="$(cd $(dirname $0) && pwd)"
result=0

#---------------------------------------------
# Set the predefined Bulk ID code used in an Auto Registration.
# This one is from the faultline1989 account.

#---------------------------------------------
# BULKIDCODE should be set by a Circle CI environment variable

# include the package library to access some utility functions

. /usr/bin/connectd_library

#---------------------------------------------
# script execution starts here
echo "Test $0 starting..."
echo

# the next lines can be used as needed to override a specific API version
# comment these lines out to return to default API
# echo "API:"
# sed -i -e 's/\/api/\/apv\/v27.5/' /usr/bin/connectd_options
# grep ^api /usr/bin/connectd_options
# echo

#---------------------------------------------
# make sure user is running with root access (sudo is OK)

checkForRoot

# generate a new Hardware ID

uuid > /etc/connectd/hardware_id.txt

# generate a new Registration Key

uuid > /etc/connectd/registration_key.txt

echo "$BULKIDCODE" > /etc/connectd/bulk_identification_code.txt

# run connectd_check_production_ready
connectd_check_production_ready > production_ready.txt
if [ $? -ne 0 ]; then
    echo "Error in connectd_check_production_ready"
    cat production_ready.txt
    exit 1
fi

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

