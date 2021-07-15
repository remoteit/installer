#!/bin/sh
# login.sh
# gets a login token so that Auto-Registration can check ownership of the created services
# As the assumption is that this test script is running on an Ubuntu VM,
# use the amd64 Debian package.

VERSION=1.0.0
MODIFIED="July 15, 2021"

#---------------------------------------------
USERNAME=$TESTUSERNAME
PASSWORD=$TESTPASSWORD
AUTHHASH="REPLACE_AUTHHASH"

# include the package library to access some utility functions

. /usr/bin/connectd_library

userLogin
echo "token = $token"
# iterate through files in /etc/connectd/available (after auto or bulk registration)
# and try to change their names using the REST API.
setNameURL="${apiMethod}${apiServer}${apiVersion}"/device/name
for file in $(ls /etc/connectd/available); 
do 
    echo Processing $file ; 
    uid=$(grep UID /etc/connectd/available/$file | awk '{ print $2 }')
    echo $uid
    result=$(curl ${CURL_OPTS} 'POST' $setNameURL -d "{\"deviceaddress\":\"$uid\", \"devicealias\":\"$file\" }" -H "Content-Type:application/json" -H "apikey:$apikey" -H "token:$token")
    status=$(jsonval "$result" "status")
    if [ "$status" = "false" ]; then
        echo $result
	echo "Error!  ($USERNAME with UID $uid)"
        exit 1
    else
	echo "Changed name of $uid, confirmed ownership..."
    fi
done;
exit 0
