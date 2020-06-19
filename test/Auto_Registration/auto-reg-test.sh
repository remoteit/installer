#!/bin/sh
# auto-reg-test.sh
# connectd package auto-registration test for Continuous Integration
# pre-requisiste: the connectd package must be installed
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=1.1.3
MODIFIED="June 19, 2020"
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
# SERVICECOUNT is the expected number of active services, depends on the product definition
# and per-serrvice "enabled" state.
SERVICECOUNT=2
result=0

#---------------------------------------------

# include the package library to access some utility functions

. /usr/bin/connectd_library

count_services()
{
    ps ax | grep "connectd\." | grep -v grep > ~/nservices
    cat ~/nservices
    services="$(wc -l ~/nservices  | awk '{ print $1 }')"
    return $services
}

#-----------------------------------------------------------------------
# pass this the # of expected connectd daemons, and
# a string to indicate the test step

check_service_counts()
{

count_services
nservices=$?
if [ $nservices -ne $1 ]; then
   echo "Auto-registration $2 test failed with services: $nservices.  Expected $1."
   exit 1
fi
echo "Auto-registration service test $2 $1 passed."
}

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

# Set the predefined Bulk ID code used in an Auto Registration.
if [ "$CI_AUTO_REG_ID_CODE" != "" ]; then
    echo "$CI_AUTO_REG_ID_CODE" > /etc/connectd/bulk_identification_code.txt
else
    echo "Bulk Identification Code is missing!"
    exit 1
fi

# auto_reg_test() takes 4 parameters
# $1 is whether to factory reset prior to running the test
# $2 is whether or not a clone is expected at this step
# $3 is a label for this test run
# $4 is the number of services expected to be running at the end of the cycle

auto_reg_test()
{
echo "#=================================================================================="
echo "Test step: $3"

# make sure any previously configured services are stopped 
# (there shouldn't be any when running CI, but just to be sure.)
# and then factory reset (clears all provisioning files)

echo
echo "connectd_control -v stop all"
connectd_control -v stop all
echo

if [ $1 -eq 1 ]; then
    echo "connectd_control reset"
    connectd_control reset < "$SCRIPT_DIR"/reset.key
else
    echo "No factory reset"
fi

# display bulk registration configuration
/usr/bin/connectd_mp_configure -n | tee mp_configure$3.txt
echo

check_service_counts 0 "Check $3: stop all services"

#================================================================
# first time device detection
# run the provisioning step, capture both stdio and stderr outputs
echo
echo "dprovision $3"
sh -x /usr/bin/connectd_control -v dprovision 2> /tmp/dprov$3.txt
grep "Clone detected" /tmp/dprov$3.txt
if [ $? -eq 0 ]; then
    if [ $2 -eq 1 ]; then
        echo "Clone detected, OK."
    else
        echo "Clone detected, error."
        exit 1
    fi
else
    if [ $2 -eq 1 ]; then
        echo "Clone not detected, error."
        exit 1
    else
        echo "Clone not detected, OK."
    fi
fi

# run the registration (bprovision) step, capture both stdio and stderr outputs
echo
echo "bprovision $3"
sh -x /usr/bin/connectd_control bprovision all 2> /tmp/bprov$3.txt

# get status of all services
echo
echo "connectd_control status all"
connectd_control -v status all | tee  /tmp/status$3.txt

check_service_counts $4 "Provisioned $4 services $3"

# get stop all services
echo
echo "connectd_control stop all"
connectd_control -v stop all | tee /tmp/stop$3.txt

# get status of all services
echo
echo "connectd_control status all"
connectd_control -v status all | tee -a /tmp/status$3.txt

check_service_counts 0 "Stopped 2 services $3"
echo "#=================================================================================="
echo
}

# generate a new Hardware ID
# uuid > /etc/connectd/hardware_id.txt
# removing the hardware_id.txt file forces use of the MAC for the hardware ID
rm /etc/connectd/hardware_id.txt

# generate a new Registration Key
uuid > /etc/connectd/registration_key.txt

# generate a new  CPUID
uuid > /etc/connectd/cpuid.txt

# run first test - factory reset, no clone, fresh
auto_reg_test 1 0 "fresh" $SERVICECOUNT

#==================================================================================
# the next section should not trigger clone detection as we are using the same hardware ID
# and CPUID
# and have not deleted the provisioning files
auto_reg_test 0 0 "restart" 0

#==================================================================================
# the next section should trigger clone detection as we are using the same hardware ID
# and CPUID
# we deleted the provisioning files
auto_reg_test 1 1 "clone-a" $SERVICECOUNT

# generate a new CPUID
uuid > /etc/connectd/cpuid.txt

#==================================================================================
# the next section should trigger clone detection as we are using the same hardware ID
# we changed the CPUID
# we did not delete the provisioning files

auto_reg_test 1 1 "clone-new-cpuid" $SERVICECOUNT

connectd_control stop all

check_service_counts 0 "Final stop all"
# have to clear provisioning files to prevent interactive test from restarting
# any services which were auto-registered

connectd_control reset < "$SCRIPT_DIR"/reset.key

echo
echo "Auto Registration test $0 passed."
exit 0

