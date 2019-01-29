#!/bin/bash
# lintpkg.sh
# script to build Debian package for remote.it connectd Installer
# sorts out Lintian errors/warnings into individual
# text files
pkg=connectd
ver=2.1.1
pkgFolder="$pkg"
# set architecture
controlFilePath="$pkgFolder"/DEBIAN
controlFile="$controlFilePath"/control
RELEASE="_RTM"
# current user account
user=$(whoami)

#-------------------------------------------------
# setOption() is used to change settings in the connectd_$1 file

setOption()
{
    sedFilename="$pkgFolder"/usr/bin/connectd_$1
    sed -i '/'"^$2"'/c\'"$2=$3 $4 $5 $6 $7"'' "$sedFilename"
}

#-------------------------------------------------
setEnvironment()
{
    sed -i "/Architecture:/c\Architecture: $1" "$controlFile"

    setOption "options" "Architecture" "$1"
    if [ -e "$pkgFolder"/usr/bin/connectd.* ]; then
        rm "$pkgFolder"/usr/bin/connectd.*
    fi
    if [ -e "$pkgFolder"/usr/bin/connectd_schannel.* ]; then
        rm "$pkgFolder"/usr/bin/connectd_schannel.*
    fi
    sudo cp ./assets/connectd."$2" "$pkgFolder"/usr/bin
    if [ $? = 1 ]; then
        echo "Error, missing file: connectd.$2"
        exit 1
    fi
    sudo chmod +x "$pkgFolder"/usr/bin/connectd."$2"
    sudo cp ~/Github/Server-Channel/pre-built/schannel."$2" "$pkgFolder"/usr/bin/connectd_schannel."$2"
    if [ $? = 1 ]; then
        echo "Error, missing file: schannel.$2"
        exit 1
    fi
    sudo chmod +x "$pkgFolder"/usr/bin/connectd_schannel."$2"

    setOption options "PLATFORM" "$2"
    setOption control "PLATFORM" "$2"
}

# buildDebianFile takes 1 parameter, the package name/folder
# then runs lintian file checker
# and creates connectd.deb in the current folder.

buildDebianFile()
{
    # build reference DEB file
    sudo chown -R root:root "$1"
    dpkg-deb --build "$1"
    ret=$(runLintian "$1".deb)
    return $ret
}

#-------------------------------------------------
runLintian()
{
    ret_val=0
    # scan debian file for errors and warnings
    lintian -EviIL +pedantic "$1"  > lintian-result.txt
    grep E: lintian-result.txt > lintian-E.txt
    grep W: lintian-result.txt > lintian-W.txt
    grep I: lintian-result.txt > lintian-I.txt
    grep X: lintian-result.txt > lintian-X.txt
    rm lintian-result.txt
    if [ -s lintian-E.txt ]; then
	ret_val=1
    fi
    return $ret_val
}

# print out program banner
echo
echo "========================="
echo "connectd installer build script"
echo "========================="
echo
# copy build tree to /tmp to do actual build
# commented out, temporarily disabling this method
# cp -R "$pkg" "$pkgFolder"
gzip -9 "$pkgFolder"/usr/share/doc/$pkg/*.man

# change owner of all files to current user for manipulations
# later, will change owner of all files to root:root
# prior to executing dpkg-deb
sudo chown -R "$user":"$user" "$pkgFolder"

# save current folder to write output file to
cwd="$(pwd)"

echo "========================="
echo "Select target package and architecture below"
echo "========= ARM ==========="
echo "1) Debian, armhf, arm-linaro-pi (use for Pi)"
echo "2) Debian, armel, arm-linaro-pi"
echo "3) tar, arm-linaro-pi for Liverock modem"
echo "4) tar, ARM gnueabi "
echo "======= AMD/Intel ========="
echo "10) tar, x86 Etch (32 bit)"
echo "11) Debian, amd64, x86_64-ubuntu16.04 (64 bit) Ubuntu 16.04"
echo "12) tar, amd64 Etch (64 bit) Generic"
echo

read archMenu
echo

if [ "$archMenu" -eq 1 ]; then
    buildDeb=1
    setOption options "PSFLAGS" "ax"
    setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
    arch="armhf"
    PLATFORM=arm-linaro-pi
    setOption options "BASEDIR" ""
elif [ "$archMenu" -eq 2 ]; then
    buildDeb=1
    setOption options "PSFLAGS" "ax"
    setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
    arch="armel"
    PLATFORM=arm-linaro-pi
    setOption options "BASEDIR" ""
elif [ "$archMenu" -eq 10 ]; then
    buildDeb=0
    setOption options "PSFLAGS" "ax"
#    setOption "mac" '$(ip addr | grep ether | tail -n 1 | awk "{ print $2 }")'
    setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
    arch="i386"
    PLATFORM=x86-etch
    setOption options "BASEDIR" ""
elif [ "$archMenu" -eq 11 ]; then
    buildDeb=1
    arch="amd64"
    setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
    PLATFORM=x86_64-ubuntu16.04
    setOption options "BASEDIR" ""
    setOption options "PSFLAGS" "ax"
elif [ "$archMenu" -eq 3 ]; then
    buildDeb=0
    arch="armhf"
    PLATFORM=arm-linaro-pi
    setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
    setOption options "PSFLAGS" "ax"
elif [ "$archMenu" -eq 4 ]; then
    buildDeb=0
    arch="arm-gnueabi"
    PLATFORM=arm-gnueabi
    setOption options "PSFLAGS" "w"
    setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
elif [ "$archMenu" -eq 12 ]; then
    buildDeb=0
    arch="amd64"
    PLATFORM=x86_64-etch
    setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
    setOption options "BASEDIR" ""
    setOption options "PSFLAGS" "ax"
else
    echo "Menu setting $archMenu not defined!"
    exit 1
fi

if [ $buildDeb -eq 1 ]; then
    echo "Building Debian package..."
else
    echo "Building tar package..."
fi
echo "PLATFORM=$PLATFORM"
echo "arch=$arch"
echo

setEnvironment "$arch" "$PLATFORM"
# put build date into connected_options
setOption options "BUILDDATE" "\"$(date)\""

# clean up and recreate md5sums file
cd "$pkgFolder"
sudo chmod 777 DEBIAN
# ls -l
sudo find -type f ! -regex '.*?DEBIAN.*' -exec md5sum "{}" + | grep -v md5sums > md5sums
sudo chmod 775 DEBIAN
sudo mv md5sums DEBIAN
sudo chmod 644 DEBIAN/md5sums
# cd "$cwd"
cd ..

if [ "$buildDeb" = 1 ]; then

echo "Building Debian package for architecture: $arch"

#--------------------------------------------------------
# for Deb pkg build, remove builddate.txt file
# builddate.txt is used by generic tar.gz installers
file="$pkgFolder"/etc/connectd/builddate.txt

if [ -e "$file" ]; then
    rm "$pkgFolder"/etc/connectd/builddate.txt
fi
#--------------------------------------------------------
buildDebianFile "$pkgFolder"

if [ $? == 0 ];then
    version=$(grep -i version "$controlFile" | awk '{ print $2 }')
    filename="${pkg}_${version}_$arch$RELEASE".deb
    # for now, mark all releases as $RELEASE
    mv "$pkgFolder".deb "$filename"
else
    echo "Errors encountered during build."
    echo "Press Enter to review errors."
    read anykey
    less lintian-E.txt
fi

else
# we are making a tar file, but first  we make a Debian file
# use lintian to check for errors
# then extract the /usr, /etc and /lib folders.
buildDebianFile "$pkgFolder"

if [ $? == 0 ];then
    version=$(grep -i version "$controlFile" | awk '{ print $2 }')

    # for now, mark all releases per RELEASE variable
    echo "Extracting contents to tar file"
    ./extract-scripts.sh "$pkgFolder".deb
    filename="${pkg}_${version}_$PLATFORM$RELEASE"
    mv "$pkgFolder".deb.tar "$cwd/$filename".tar
else
    echo "Errors encountered during build."
    echo "Press Enter to review errors."
    read anykey
    less lintian-E.txt
fi

fi

ls -l "${pkg}"*.*
