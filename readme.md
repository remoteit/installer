# remote.it Installer

## Please note, the connectd package is deprecated and not recommended for new installs.

Please find the new instructions for single-device installation at: https://link.remote.it/support/rpi-linux-quick-install

[![CircleCI](https://circleci.com/gh/remoteit/installer.svg?style=svg&circle-token=51d69d01d1536ee58ad7ddf3ae927811416fee63)](https://circleci.com/gh/remoteit/installer)

> System tools for setting up remote.it on your internet connected devices.

## Install

### All types of Linux

The easiest way to install remote.it on a Linux system is to run the following on the command line:

```
curl -LkO https://raw.githubusercontent.com/remoteit/installer/master/scripts/auto-install.sh
chmod +x ./auto-install.sh
sudo ./auto-install.sh
```
This script tests all available daemon architectures, then downloads a compatible package.  If your system is Debian based, a deb package file will be downloaded and installed.  Otherwise a tar file is downloaded and installed.

Now you should have the `connectd` tools installed on your system. To run the installer, type:

```
sudo connectd_installer
```

And follow the interactive prompts to setup your device.


### Notes for developers

1. The connectd folder contains the source files for the Debian and tar package creation process.
2. scripts/build.sh is the script which handles building all packages.

### Available Characters

remote.it is able to handle only ASCII characters. Japanese, including Kanji, is not available.

For example, the name of the install folder, hardware ID, registration key, information used for bulk registration in web portal can use only ASCII.

## Development

### Get latest connectd and schannel daemon

Make sure you have node installed and then run:

```shell
npm run download-assets
```

This will download the latest connectd and Server Channel release assets from Github and place them in `./assets`.

### Make a build

To generate a build, you must first be on a Linux system, then run the following:

```shell
npm run build-one
```
