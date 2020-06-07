#!/bin/sh
# auto-reg-test.sh
# connectd package auto-registration test for Continuous Integration
# pre-requisiste: the connectd package must be installed
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=1.1.0
MODIFIED="June 07, 2020"
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
result=0

#---------------------------------------------
# Set the predefined Bulk ID code used in an Auto Registration.
# This one is from the faultline1989 account.

#---------------------------------------------
# this should be set by a Circle CI environment variable
# but for now it's hardwired to a specific account
BULKIDCODE="434ABC4D-BEAC-B77C-C58A-C91127CAB4E3"

# include the package library to access some utility functions

. /usr/bin/connectd_library

/usr/bin/connectd_mp_configure -n | tee mp_configure.txt

#---------------------------------------------
# script execution starts here
echo "Test $0 starting..."
echo

# the next lines can be used as needed to override a specific API version
# comment these lines out to return to default API
# echo "API:"
# sed -i -e 's/\/api/\/apv\/xxxx/' /usr/bin/connectd_options
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

# display bulk registration configuration
echo
echo "connectd_control show"
connectd_control show

# make sure any previously configured services are stopped 
# (there shouldn't be any when running CI, but just to be sure.)
# and then factory reset (clears all provisioning files)

echo
echo "connectd_control -v stop all"
connectd_control -v stop all
echo
echo "connectd_control reset"
connectd_control reset < "$SCRIPT_DIR"/reset.key

# run the provisioning step, capture both stdio and stderr outputs
echo
echo "connectd_control -v dprovision"
sh -x /usr/bin/connectd_control -v dprovision 2> /tmp/dprov.txt

# run the registration (bprovision) step, capture both stdio and stderr outputs
echo
echo "connectd_control bprovision all"
sh -x /usr/bin/connectd_control bprovision all 2> /tmp/bprov.txt

# get status of all services
echo
echo "connectd_control status all"
connectd_control -v status all | tee  /tmp/status.txt

# get status of all services
echo
echo "connectd_control stop all"
connectd_control -v stop all | tee /tmp/stop.txt

# get status of all services
echo
echo "connectd_control status all"
connectd_control -v status all | tee -a /tmp/status.txt

# factory reset
echo
echo "connectd_control reset"
connectd_control -v reset < "$SCRIPT_DIR"/reset.key | tee  /tmp/reset.txt


echo
echo "Basic Auto Registration test $0 passed."
exit 0

