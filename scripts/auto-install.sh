#!/bin/sh
#
# This tests a set of remote.it binaries in the directory containing this script.
#
#       This will now download matching daemons from Github to a test folder.
#       Then it will try executing them and tell you which one is compatible.
#       GSW.

FOLDER=2.1
VERSION=2.2.5
BUILDPATH=https://github.com/remoteit/installer/releases/download/v$VERSION

downloadAndTestDaemon()
{
    testArch=$1
    testDaemon=connectd."$testArch"
    printf "\n"
    printf "%s\n" "Downloading and testing $testDaemon..." | tee -a remote.itBinaryTestLog.txt
    if [ ! -e "$testDaemon" ]; then
        curl -sLkO https://github.com/remoteit/misc_bins_and_scripts/raw/master/connectd/"$testDaemon" > /dev/null
        if [ "$?" != "0" ]; then
            printf "%s\n" "$testDaemon download failed!" | tee -a remote.itBinaryTestLog.txt
            exit 1
        fi
    else
        printf "%s\n" "$testDaemon already in current directory, testing now..." | tee -a remote.itBinaryTestLog.txt
    fi
    sleep 2
    chmod +x "$testDaemon"
    ./"$testDaemon" -n > /dev/null
    if [ "$?" = "0" ]; then
        printf "%s\n" "$testDaemon is compatible!" | tee -a remote.itBinaryTestLog.txt
        mv $testDaemon /usr/bin/"$testDaemon"
	retval=0
    else
        printf "%s\n" "$testDaemon is not compatible!" | tee -a remote.itBinaryTestLog.txt
        rm "$testDaemon"
        retval=1
    fi
    return $retval
}

downloadSchannel()
{
    testArch=$1
    testDaemon=schannel."$testArch"
    printf "\n"
    printf "%s\n" "Downloading and testing $testDaemon..." | tee -a remote.itBinaryTestLog.txt
    if [ ! -e "$testDaemon" ]; then
        curl -sLkO https://github.com/remoteit/Server-Channel/raw/master/pre-built/"$testDaemon" > /dev/null
        if [ "$?" != "0" ]; then
            printf "%s\n" "$testDaemon download failed!" | tee -a remote.itBinaryTestLog.txt
            exit 1
        fi
    fi
    sleep 2
    chmod +x "$testDaemon"
    mv $testDaemon /usr/bin/connectd_"$testDaemon"
    echo $retval
}

# when using Debian package we have to check for compatibility with older versions
# and use the older daemon if the newer one doesn't work.  If the older daemon gets used,
# we add "-etch" to the Debian package name.

check_x86_64()
{
    daemon=x86_64-ubuntu16.04
    downloadAndTestDaemon $daemon
    if [ "$?" != 0 ]; then
        daemon=x86_64-etch
        downloadAndTestDaemon $daemon
    else
        return 0
    fi
    if [ "$?" != 0 ]; then
        daemon=x86_64-ubuntu16.04_static
        downloadAndTestDaemon $daemon
    else
    # etch daemon passed test, so set return value 2
        return 2
    fi
    if [ "$?" != 0 ]; then
        printf "%s\n" "Couldn't find a compatible daemon for $arch!" | tee -a remote.itBinaryTestLog.txt
        exit 1
    fi
}


#==========================================
# checkForUtilities confirms the presence of all utilities needed to run the provisioning
# and interactive installation scripts

checkForUtilities()
{
    ls > /dev/null
}


# main program starts here
#
# Add a timestamp and divider line as headers to the log file and console
#
PWD=$(pwd)
echo "********************************************************"  | tee -a remote.itBinaryTestLog.txt
echo "remote.it platform and binary tester for current directory $PWD" | tee -a remote.itBinaryTestLog.txt
date  | tee -a remote.itBinaryTestLog.txt
echo "********************************************************" | tee -a remote.itBinaryTestLog.txt
#
signature=$(uname -a)
if [ $? = 127 ]; then
    echo "uname command not supported, cannot determine architecture."
    echo "Please contact support@remote.it."
    exit
fi
echo "$signature" | tee -a remote.itBinaryTestLog.txt

# check for architecture
if [ "$(echo "$signature" | grep -i mips)" != "" ]; then
    BASEPLATFORM="mips"
elif [ "$(echo "$signature" | grep -i arm)" != "" ]; then
    BASEPLATFORM="arm"
elif [ "$(echo "$signature" | grep -i x86_64)" != "" ]; then
    BASEPLATFORM="x86_64"
elif [ "$(echo "$signature" | grep -i i686)" != "" ]; then
    BASEPLATFORM="i686"
else
   echo "Cannot determine platform CPU architecture."
   echo "$(uname -a)"
   echo "Please contact support@remote.it."
   exit 1
fi

echo "Detected architecture is $BASEPLATFORM"

dpkg --help > /dev/null
if [ $? = 127 ]; then
    echo "using tar file installer..."
    if [ "$BASEPLATFORM" = "mips" ]; then
        daemon=mips-24kec
        downloadAndTestDaemon $daemon
        if [ "$?" != 0 ]; then
            daemon=mips-34kc
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mips-gcc-4.7.3
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mipsel-bcm5354
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mipsel-gcc342
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mips-24kec_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mips-34kc_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mips-gcc-4.7.3_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mipsel-bcm5354-static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mipsel-gcc342-static
            downloadAndTestDaemon $daemon
        fi
    elif [ "$BASEPLATFORM" = "arm" ]; then
        daemon=arm-android
        downloadAndTestDaemon $daemon
        if [ "$?" != 0 ]; then
            daemon=arm-android_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=arm-gnueabi
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
        daemon=arm-gnueabi_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
        daemon=arm-linaro-pi
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
        daemon=arm-linaro-pi_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
        daemon=arm-v5tle
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
        daemon=arm-v5tle_static
            downloadAndTestDaemon $daemon
        fi
    elif [ "$BASEPLATFORM" = "x86_64" ]; then
        check_x86_64
    elif [ "$BASEPLATFORM" = "i686" ]; then
        daemon=x86-ubuntu16.04
        downloadAndTestDaemon $daemon
        if [ "$?" != 0 ]; then
            daemon=x86-ubuntu16.04_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=x86-linaro_uClibc
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=x86-linaro_uClibc_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=x86-etch
            downloadAndTestDaemon $daemon
        fi
    fi

    echo "daemon $daemon"
    downloadSchannel "$daemon"
    currentFolder=$(pwd)
    filename=connectd_"$VERSION"_"$daemon"".tar"
    echo "filename $filename"
    filepath="$BUILDPATH"/"$filename"
    echo "filepath $filepath"
    curl -sLkO "$filepath" > /dev/null
    ls -l "$filename"
    mv "$filename" /
    cd /
    tar xvf "$filename"  > "$currentFolder"/connectd_"$VERSION"_files.txt
else
    echo "Debian OS detected."
    arch=$(dpkg --print-architecture)
    echo "$arch architecture detected."
    if [ "$arch" = "amd64" ]; then
        check_x86_64
        if [ $? = 2 ]; then
            tag="-etch"
        fi
    fi
    filename=connectd_"$VERSION""_""$arch""$tag"".deb"
    echo "filename $filename"
    filepath="$BUILDPATH"/"$filename"
    echo "filepath $filepath"
    curl -sLkO "$filepath" > /dev/null
    sudo dpkg -i "$filename"
fi
exit 0
