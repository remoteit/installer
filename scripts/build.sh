#!/bin/bash
# build.sh
# script to build Debian package for remote.it connectd Installer
# sorts out Lintian errors/warnings into individual
# text files
pkg=connectd
ver=2.1.5
MODIFIED="February 12, 2019"
pkgFolder="$pkg"
# set architecture
controlFilePath="$pkgFolder"/DEBIAN
controlFile="$controlFilePath"/control
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

    for i in $(find "$pkgFolder"/usr/bin/ -type f -name "connectd.*")
    do
        rm "$i"
    done

    for i in $(find "$pkgFolder"/usr/bin/ -type f -name "connectd_schannel.*")
    do
        rm "$i"
    done

    sudo cp ./assets/connectd."$2" "$pkgFolder"/usr/bin
    if [ $? -eq 1 ]; then
        echo "Error, missing file: connectd.$2"
        exit 1
    fi
    sudo chmod +x "$pkgFolder"/usr/bin/connectd."$2"
    sudo cp ./assets/schannel."$2" "$pkgFolder"/usr/bin/connectd_schannel."$2"
    if [ $? -eq 1 ]; then
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
    ret=0
    sudo chown -R root:root "$1"
    if [ "$buildDeb" -eq 1 ]; then
        dpkg-deb --build "$1"
        # only run lintian if we are really making a Debian package
        ret=$(runLintian "$1".deb)
    else
        dpkg-deb --build "$1"
        ret=$?
    fi
    return $ret
}

#-------------------------------------------------
runLintian()
{
    ret_val=0
    # scan debian file for errors and warnings
    lintian -vi --show-overrides "$1"  > lintian-result.txt
    grep E: lintian-result.txt > lintian-E.txt
    grep W: lintian-result.txt > lintian-W.txt
    grep I: lintian-result.txt > lintian-I.txt
    grep X: lintian-result.txt > lintian-X.txt
    if [ -s lintian-E.txt ]; then
	ret_val=1
    fi
    return $ret_val
}

gzip -9 "$pkgFolder"/usr/share/doc/$pkg/*.man

# change owner of all files to current user for manipulations
# later, will change owner of all files to root:root
# prior to executing dpkg-deb
sudo chown -R "$user":"$user" "$pkgFolder"

# save current folder to write output file to
cwd="$(pwd)/build"
mkdir -p $cwd

# build() takes 4 parameters: PLATFORM, arch, buildDeb, and tag (optional)
# PLATFORM indicates the remote.it daemon architecture, e.g. arm-linaro-pi
# buildDeb=0 means make a tar file.  buildDeb=1 means make a Debian file
# arch is the Debian architecture, e.g. armhf or amd64
# not required to pass in "arch" if buildDeb=0
# tag is an optional string to put in the file name to distinguish Debian packages
# which have the same "arch" but different "PLATFORM"

build() {
    echo
    echo "========================================"

    echo
    PLATFORM=$1
    buildDeb=$2
    if [ $buildDeb -eq 1 ]; then
        arch=$3
    else
# give it a default arch, it doesn't matter as we are just building a deb from which to extract the tar file
        arch="amd64"
    fi
    if [ "$4" != "" ]; then
        tag="$4"
    fi
    setEnvironment "$arch" "$PLATFORM"
    # put build date into connected_options
    setOption options "BUILDDATE" "\"$(date)\""

    # clean up and recreate md5sums file
    cd "$pkgFolder"
    sudo chmod 777 DEBIAN
    sudo find -type f ! -regex '.*?DEBIAN.*' -exec md5sum "{}" + | grep -v md5sums > md5sums
    sudo chmod 775 DEBIAN
    sudo mv md5sums DEBIAN
    sudo chmod 644 DEBIAN/md5sums
    cd ..

    if [ "$buildDeb" -eq 1 ]; then

        echo "Building Debian package for architecture: $arch"
        echo "PLATFORM=$PLATFORM"
        # tag variable was added to allow building different Debian packages with the same architecture
        # e.g. for Vyos I had to make a package using an older daemon architecture but it's still considered
        # amd64 or i386 architecture from the dpkg program's point of view
        if [ "$tag" != "" ]; then
            echo "tag = $tag"
        fi

        #--------------------------------------------------------
        # for Deb pkg build, remove builddate.txt file
        # builddate.txt is used by generic tar.gz installers
        file="$pkgFolder"/etc/connectd/builddate.txt

        if [ -e "$file" ]; then
            rm "$pkgFolder"/etc/connectd/builddate.txt
        fi
        #--------------------------------------------------------
        buildDebianFile "$pkgFolder"

        if [ $? -eq 1 ];then
            echo "Errors encountered during build."
            cat lintian-E.txt
        fi

        version=$(grep -i version "$controlFile" | awk '{ print $2 }')
        filename="${pkg}_${version}_$arch$tag".deb
        mv "$pkgFolder".deb "$cwd/$filename"
    else
        echo "Building tar package for PLATFORM: $PLATFORM"
        # we are making a tar file, but first  we make a Debian file
        # then extract the /usr, /etc and /lib folders.
        buildDebianFile "$pkgFolder"

        if [ $? == 1 ];then
            echo "Errors encountered during build."
        fi

        version=$(grep -i version "$controlFile" | awk '{ print $2 }')
        echo "Extracting contents to tar file"
        ./scripts/extract-scripts.sh "$pkgFolder".deb
        filename="${pkg}_${version}_$PLATFORM$tag".tar
        mv "$pkgFolder".deb.tar "$cwd/$filename"

    fi
    ls -l "$cwd/$filename"

}

# now define and create each build 1 by 1

# aarch64 package - tar package with static linking
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
setOption options "PSFLAGS" "ax"
build aarm64-ubuntu16.04_static 0

# aarch64 package - tar package with dynamic linking
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
setOption options "PSFLAGS" "ax"
build aarm64-ubuntu16.04 0

# arm64 package - Debian package with dynamic linking
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
setOption options "PSFLAGS" "ax"
build aarm64-ubuntu16.04 1 arm64

setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "PSFLAGS" "ax"
build arm-android 0

setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "PSFLAGS" "ax"
build arm-android_static 0

setOption options "PSFLAGS" "ax"
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
build arm-linaro-pi 1 armhf

setOption options "PSFLAGS" "ax"
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
build arm-linaro-pi 1 armel

setOption options "PSFLAGS" "ax"
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
build x86-etch 0

setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
setOption options "PSFLAGS" "ax"
build x86_64-ubuntu16.04 1 amd64

setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "PSFLAGS" "ax"
build arm-linaro-pi 0

setOption options "PSFLAGS" "w"
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
build arm-gnueabi 0

setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
setOption options "PSFLAGS" "ax"
build x86_64-etch 0

# here we are using the tag "-etch" to create an amd64 Debian architecture package for the older
# Debian "Etch" architecture that needs to be distinct from the one for Ubuntu 16.04
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
setOption options "PSFLAGS" "ax"
build x86_64-etch 1 amd64 -etch

# here we are using the tag "-etch" to create an i386 Debian architecture package for the older
# Debian "Etch" architecture that needs to be distinct from the one for Ubuntu 16.04
setOption options "mac" '$'"(ip addr | grep ether | tail -n 1 | awk" "'{ print" '$2' "}')"
setOption options "BASEDIR" ""
setOption options "PSFLAGS" "ax"
build x86-etch 1 i386 -etch

echo "======   build.sh $ver completed   =============="
