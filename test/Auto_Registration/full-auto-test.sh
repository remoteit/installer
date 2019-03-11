#!/bin/sh
# there are some manual steps here which should get replaced by API calls
# when possible.

. /usr/bin/connectd_library

countServices()
{
    echo
    connectd_control status all
    nrunning=$(connectd_control status all | grep -c "and running")
    echo "$nrunning are running"
    nstopped=$(connectd_control status all | grep -c stopped)
    echo "$nstopped are stopped"
    nenabled=$(connectd_control status all | grep -c enabled)
    echo "$nenabled are enabled"
    ndisabled=$(connectd_control status all | grep -c disabled)
    echo "$ndisabled are disabled"
    echo
}

checkForRoot

echo "About to start initial auto-registration"
echo "Make sure the bulk id code is for an auto registration with at least service."
echo "Press Enter when ready."
read anykey
sed -i -e 's/36AC4A2A-AC89-E374-13CE-75E4231FE164/DA664353-2479-C05A-3BA2-B89B795F00E5/' ./auto-reg-test.sh
./auto-reg-test.sh
connectd_control start all
echo
echo "You should now have some services running."
echo "Check the counts below."
countServices

echo "Now add a new Service and enable it."
echo "Press Enter when ready."
read anykey

connectd_control -v dprovision
connectd_control -v bprovision all

echo
echo "You should now have 1 more service running."
countServices

echo
echo "Now disable a Service."
echo "Press Enter when ready."
read anykey

connectd_control -v dprovision
connectd_control -v bprovision all

echo
echo "You should now have 1 fewer services running."
countServices

echo
echo "Now re-enable the Service."
echo "Press Enter when ready."
read anykey

connectd_control -v dprovision
connectd_control -v bprovision all

echo
echo "You should now have 1 more service running."
countServices
