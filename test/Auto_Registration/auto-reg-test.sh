#!/bin/sh
# auto-reg-test.sh
# connectd package auto-registration test for Continuous Integration
# pre-requisiste: the connectd package must be installed
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=1.1.2
MODIFIED="June 18, 2020"
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
result=0

#---------------------------------------------

# include the package library to access some utility functions

. /usr/bin/connectd_library

#---------------------------------------------
# script execution starts here
echo "Test $0 starting..."
echo

checkForRoot
# the next lines can be used as needed to override a specific API version
# comment these lines out to return to default API
# echo "API:"
# sed -i -e 's/\/api/\/apv\/xxxx/' /usr/bin/connectd_options
# grep ^api /usr/bin/connectd_options
# echo

#---------------------------------------------

# generate a new Hardware ID
uuid > /etc/connectd/hardware_id.txt

# generate a new Registration Key

uuid > /etc/connectd/registration_key.txt

# Set the predefined Bulk ID code used in an Auto Registration.
if [ "$CI_AUTO_REG_ID_CODE" != "" ]; then
    echo "$CI_AUTO_REG_ID_CODE" > /etc/connectd/bulk_identification_code.txt
else
    echo "Bulk Identification Code is missing!"
    exit 1
fi

# display bulk registration configuration
/usr/bin/connectd_mp_configure -n | tee mp_configure.txt
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

# the next section should trigger clone detection as we are using the same hardware ID
# run the provisioning step, capture both stdio and stderr outputs
echo
echo "Clone check: connectd_control -v dprovision"
sh -x /usr/bin/connectd_control -v dprovision 2> /tmp/dprov-clone.txt

# run the registration (bprovision) step, capture both stdio and stderr outputs
echo
echo "Clone check: connectd_control bprovision all"
sh -x /usr/bin/connectd_control bprovision all 2> /tmp/bprov-clone.txt

# stop all daemons so that subsequent tests don't get confused
echo
echo "connectd_control -v stop all"
connectd_control -v stop all
echo
echo "connectd_control reset"
connectd_control reset < "$SCRIPT_DIR"/reset.key

echo
echo "Basic Auto Registration test $0 passed."
exit 0

