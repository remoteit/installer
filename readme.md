# remote.it Installer

> System tools for setting up remote.it on your internet connected devices.

## Install

### Debian Install

#### Install using apt

The easiest way to install remote.it on a Debian system is to run the following on the command line:

```
sudo apt-get update
sudo apt-get install connectd
```

Now you should have the `connectd` tools installed on your system. To run the installer, type:

```
sudo connectd_installer
```

And follow the interactive prompts to setup your device.

#### Manual install

To manually install remote.it connectd services to your Debian system:

1. Determine your _Debian_ system architecture:

```shell
sudo dpkg --print-architecture
```

Then type your system password and you should see something like:

```
amd64
```

2. Copy the deb file whose file name includes the architecture of your system.
3. Run `sudo dpkg -i <debfilename>`
4. Now run `sudo connectd_installer` to install services interactively.

### Notes for developers

1. The connectd folder contains the source files for the Debian package creation process.
2. lintpkg.sh is a script you can run on your Debian/Ubuntu system to build a Debian package.

It will also let you build an archive "tar" file which can be exrtacted on a target system by placing the file into the root folder `/` and running: `sudo tar xvf <tarfilename>`.

3. `sgwi.sh` is handy during development when repeatedly editing the installer scripts since it deletes the backup file and runs as su, so you don't have to change permissions on the file itself (which messes things up during package
   creation).
4. `sgwd.sh` is handy during development when repeatedly editing the Debian package control files and maintainer scripts since it deletes the backup file and runs as su, so you don't have to change permissions on the files themselves.

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

```shell
npm run build
```
