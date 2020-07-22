#!/bin/sh
#
# This tests a set of remote.it binaries in the directory containing this script.
#
#       This will now download matching daemons from Github to a test folder.
#       Then it will try executing them and tell you which one is compatible.
#       GSW.

VERSION=2.5.37
BUILDPATH=https://github.com/remoteit/installer/releases/download/v$VERSION
LOGFILE=remote.itBinaryTestLog.txt

# to install curl tool
installCurl() {
    printf "\nInstalling curl..........\n"
    apt-get install -y curl
    if [ "$?" -ne 0 ]; then
        apt-get update && apt-get install -y curl
    fi
}

# check whether curl tool is installed, if not then install it
checkCurl() {
    curlSupported=$(curl --version)
    if [ "$curlSupported" = "" ]; then
        installCurl
        curlSupported=$(curl --version)
        if [ "$curlSupported" = "" ]; then
            printf 'error : install curl'
            exit 1
        else
            return 1
        fi
    else
        printf "\n curl found \n"
        return 1
    fi
}

downloadAndTestDaemon()
{
    local testArch=$1
    local testDaemon=connectd."$testArch"
    local retval=1

    printf "\n"
    printf "%s\n" "Downloading and testing $testDaemon..." | tee -a $LOGFILE
    if [ ! -e "$testDaemon" ]; then
        curl -sLkO "https://github.com/remoteit/connectd/releases/latest/download/${testDaemon}" > /dev/null
        if [ "$?" != "0" ]; then
            printf "%s\n" "$testDaemon download failed!" | tee -a $LOGFILE
            exit 1
        fi
    else
        printf "%s\n" "$testDaemon already in current directory, testing now..." | tee -a $LOGFILE   
    fi
    sleep 2
    chmod +x "$testDaemon"
    ./"$testDaemon" -n > /dev/null 2>&1
    if [ "$?" = "0" ]; then
        printf "%s\n" "$testDaemon is compatible!" | tee -a $LOGFILE
        retval=0
    else
        echo "."
        # printf "%s\n" "$testDaemon is not compatible!" | tee -a $LOGFILE       
        rm "$testDaemon"
        retval=1
    fi
    return $retval
}

downloadSchannel()
{
    local testArch=$1
    local testDaemon=schannel."$testArch"
    local retval=0

    printf "\n"
    printf "%s\n" "Downloading and testing $testDaemon..." | tee -a $LOGFILE   
    if [ ! -e "$testDaemon" ]; then
        curl -sLkO "https://github.com/remoteit/multiport/releases/latest/download/${testDaemon}" > /dev/null
        if [ "$?" != "0" ]; then
            printf "%s\n" "$testDaemon download failed!" | tee -a $LOGFILE           
	    exit 1
        fi
    fi
    sleep 2
    chmod +x "$testDaemon"
    mv $testDaemon /usr/bin/connectd_"$testDaemon"
    ln -s /usr/bin/connectd_"$testDaemon" "/usr/bin/connectd_schannel"
    echo $retval
}



downMultiport()
{
    local testArch=$1
    local muxer="muxer"
    local demuxer="demuxer"
    local muxerDaemon="${muxer}.${testArch}"
    local demuxerDaemon="${demuxer}.${testArch}"
    local retval=0

    printf "\n"
    printf "%s\n" "Downloading and testing $muxerDaemon..." | tee -a $LOGFILE
    if [ ! -e "$muxerDaemon" ]; then
        curl -sLkO "https://github.com/remoteit/multiport/releases/latest/download/${muxerDaemon}" >> $LOGFILE
        if [ "$?" != "0" ]; then
            printf "%s\n" "$muxerDaemon download failed!" | tee -a $LOGFILE
            exit 1
        fi
    fi
    #
    # link it and chmod it
    chmod +x "$muxerDaemon"
    mv $muxerDaemon "/usr/bin/connectd_${muxerDaemon}"
    ln -s "/usr/bin/connectd_${muxerDaemon}" "/usr/bin/connectd_${muxer}"

    printf "\n"
    printf "%s\n" "Downloading and testing $demuxerDaemon..." | tee -a $LOGFILE
    if [ ! -e "$demuxerDaemon" ]; then
        curl -sLkO "https://github.com/remoteit/multiport/releases/latest/download/${demuxerDaemon}" >> $LOGFILE
        if [ "$?" != "0" ]; then
            printf "%s\n" "$demuxerDaemon download failed!" | tee -a $LOGFILE
            exit 1
        fi
    fi    
    sleep 2
    chmod +x "$demuxerDaemon"
    mv $demuxerDaemon /usr/bin/connectd_"$demuxerDaemon"
    ln -s "/usr/bin/connectd_${demuxerDaemon}" "/usr/bin/connectd_${demuxer}"
    echo $retval
}


# when using Debian package we have to check for compatibility with older versions
# and use the older daemon if the newer one doesn't work.  If the older daemon gets used,
# we add "-etch" to the Debian package name.
#
# Note this function might set daemon=
#
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
        printf "%s\n" "Couldn't find a compatible daemon for $arch!" | tee -a $LOGFILE       
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
# clear log file each time
if [ -e $LOGFILE ]; then
    rm $LOGFILE
fi

# check whether is it Debian, if yes then check for curl is installed
dpkg --help > /dev/null
if [ $? = 0 ]; then
    checkCurl
fi

#
# Get command line if "f" then force non deb
#
forceTar=0;
if [ "$1" = "f" ]; then
    forceTar=1;
fi

# Add a timestamp and divider line as headers to the log file and console
#
PWD=$(pwd)
echo "********************************************************"  | tee -a $LOGFILE
echo "remote.it platform and binary tester version $VERSION " | tee -a $LOGFILE
echo "Current directory $PWD" | tee -a $LOGFILE
date  | tee -a $LOGFILE
echo "********************************************************" | tee -a $LOGFILE
#
signature=$(uname -a)
if [ $? = 127 ]; then
    echo "uname command not supported, cannot determine architecture."
    echo "Please contact support@remote.it."
    exit
fi
echo "$signature" | tee -a $LOGFILE
# check for architecture
if [ "$(echo "$signature" | grep -i mips)" != "" ]; then
    BASEPLATFORM="mips"
elif [ "$(echo "$signature" | grep -i aarch64)" != "" ]; then
    BASEPLATFORM="arm64"
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

# see if Debian "dpkg" utility is installed.
useTar=1

# check for dpkg only of forceTar is off
if [ $forceTar -eq 0 ]; then

    which dpkg

    if [ $? -eq 0 ]; then
        dpkg --help > /dev/null
        if [ $? = 0 ]; then
            useTar=0
        fi
    fi
fi

if [ $useTar -eq 1 ]; then
    echo "using tar file installer..."
    if [ "$BASEPLATFORM" = "mips" ]; then
        daemon=mips-24kec
        downloadAndTestDaemon $daemon
        if [ "$?" != 0 ]; then
            daemon=mips-24kec-musl
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mips-34kc
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mips-gcc-4.7.3
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mipsel-bmc5354
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
            daemon=mipsel-bmc5354-static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=mipsel-gcc342-static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            echo "Could not locate a compatible package."
            echo "Please contact support@remote.it."
            echo "Attach the file $LOGFILE which was created in this folder."
            echo "Press ENTER to display system information."
            echo "$(uname -a)"
            echo "$(cat /proc/cpuinfo)"
            exit 1
        fi
    elif [ "$BASEPLATFORM" = "arm64" ]; then
        daemon=aarm64-ubuntu16.04
        downloadAndTestDaemon $daemon
        if [ "$?" != 0 ]; then
            daemon=aarm64-ubuntu16.04_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            echo "Could not locate a compatible package."
            echo "Please contact support@remote.it."
            echo "Press ENTER to display system information."
            echo "$(uname -a)"
            echo "$(cat /proc/cpuinfo)"
            exit 1
        fi
    elif [ "$BASEPLATFORM" = "arm" ]; then
        daemon=arm-android
        downloadAndTestDaemon $daemon
        if [ "$?" != 0 ]; then
            daemon=arm-linaro-pi
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=arm-gnueabi
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=arm-v5tle
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=arm-android_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=arm-gnueabi_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=arm-linaro-pi_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=arm-v5tle_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            echo "Could not locate a compatible package."
            echo "Please contact support@remote.it."
            echo "Press ENTER to display system information."
            echo "$(uname -a)"
            echo "$(cat /proc/cpuinfo)"
            exit 1
        fi
    elif [ "$BASEPLATFORM" = "x86_64" ]; then
        # daemon= is set here
        check_x86_64
    elif [ "$BASEPLATFORM" = "i686" ]; then
        daemon=x86-ubuntu16.04
        downloadAndTestDaemon $daemon
        if [ "$?" != 0 ]; then
            daemon=x86-linaro_uClibc
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=x86-etch
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=x86-ubuntu16.04_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            daemon=x86-linaro_uClibc_static
            downloadAndTestDaemon $daemon
        fi
        if [ "$?" != 0 ]; then
            echo "Could not locate a compatible package."
            echo "Please contact support@remote.it."
            echo "Press ENTER to display system information."
            echo "$(uname -a)"
            echo "$(cat /proc/cpuinfo)"
            exit 1
        fi
    fi

    downMultiport "$daemon"
    
    currentFolder=$(pwd)
    filename=connectd_"$VERSION"_"$daemon"".tar"

    # echo "filename $filename"
    filepath="$BUILDPATH"/"$filename"
    # echo "filepath $filepath"
    curl -sLkO "$filepath" > /dev/null
    echo
    ls -l "$filename"
    echo
    echo "We downloaded the file $filename to the current folder."
    echo "As root, or using sudo, move this file to the / folder."
    echo "e.g."
    echo "mv $filename /"
    echo
    echo "Now switch folders to the / folder, e.g."
    echo "cd /"
    echo
    echo "Then extract the files to your system with the following command:"
    echo "tar xvhf $filename"
    echo
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
    if [ $? -ne 0 ]; then
        echo "dpkg error!"
        exit 1
    fi
fi
exit 0


