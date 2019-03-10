#!/bin/sh
# auto-reg-add.sh
# connectd package auto-registration test for Continuous Integration
#
# Pre-requisites: 
# 1) Run this script on Ubuntu 16.04 or later 
# 2) the connectd package must be installed; use the amd64 Debian package.
# 3) run after auto-reg-test.sh to confirm that adding a new service and rebooting works.

VERSION=0.95
MODIFIED="March 09, 2019"

# include the package library to access some utility functions

. /usr/bin/connectd_library

# make sure user is running with root access (sudo is OK)

checkForRoot

# display bulk registration configuration

connectd_control show

# make sure any previously configured services are stopped 
# at the end of this script they should be running again

connectd_control -v stop all

# run the provisioning step, capture both stdio and stderr outputs

sh -x /usr/bin/connectd_control -v dprovision > /tmp/dprov.txt 2> debug.txt

# compare stdio output to the reference

diff /tmp/dprov.txt dprov_add_result.txt
result=$?
echo "dprov test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

# run the registration step, capture both stdio and stderr outputs

sh -x /usr/bin/connectd_control bprovision all > /tmp/bprov.txt 2>> debug.txt

# compare stdio output to the reference
# some variation in request throttling is expected so we filter those out

diff /tmp/bprov.txt bprov_add_result.txt | grep -v "auto registration requests being throttled"
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

diff /tmp/stop.txt stop_result.txt
result=$?
echo "stop test result: $result"
if [ $result -eq 1 ]; then
    exit 1
fi

exit 0

