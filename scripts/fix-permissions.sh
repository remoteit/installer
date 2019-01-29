#!/bin/bash
# script to fix permissions after checking out of Github
DIR=connectd
chmod 644 $DIR/DEBIAN/control
chown root:root $DIR/DEBIAN/control
chown root:root $DIR/DEBIAN/conffiles
chmod 755 $DIR/DEBIAN/prerm
chown root:root $DIR/DEBIAN/prerm
chmod 755 $DIR/DEBIAN/postinst
chown root:root $DIR/DEBIAN/postinst
chmod 755 $DIR/DEBIAN/postrm
chown root:root $DIR/DEBIAN/postrm

chown root:root $DIR/etc
chown root:root $DIR/etc/connectd
chown root:root $DIR/etc/connectd/schannel.conf
chown root:root $DIR/etc/connectd/bulk_identification_code.txt
chown -R root:root $DIR/etc/init.d
chown root:root $DIR/usr
chown root:root $DIR/usr/bin
chown root:root $DIR/usr/bin/*
chown root:root $DIR/usr/share
chown root:root $DIR/usr/share/connectd
chown root:root $DIR/usr/share/connectd/cron
chown root:root $DIR/usr/share/connectd/cron/*.*
chown root:root $DIR/usr/share/connectd/scripts
chown root:root $DIR/usr/share/connectd/scripts/*
chown root:root $DIR/usr/share/connectd/scripts/*.*
chown root:root $DIR/usr/share/doc
chown root:root $DIR/usr/share/doc/connectd
chown root:root $DIR/usr/share/doc/connectd/*
chown root:root $DIR/usr/share/doc/connectd/*.*
chmod +x $DIR/usr/bin/*
