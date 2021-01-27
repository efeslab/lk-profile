#!/bin/bash

cd mysql-5.1.73

./configure \
'--prefix=/usr' \
'--exec-prefix=/usr' \
'--libexecdir=/usr/sbin' \
'--datadir=/usr/share' \
'--localstatedir=/var/lib/mysql' \
'--includedir=/usr/include' \
'--infodir=/usr/share/info' \
'--mandir=/usr/share/man' \
'--with-system-type=debian-linux-gnu' \
'--enable-shared' \
'--enable-static' \
'--enable-thread-safe-client' \
'--enable-assembler' \
'--enable-local-infile' \
'--with-fast-mutexes' \
'--with-big-tables' \
'--with-unix-socket-path=/var/run/mysqld/mysqld.sock' \
'--with-mysqld-user=mysql' \
'--with-libwrap' \
'--with-readline' \
'--with-ssl' \
'--without-docs' \
'--with-extra-charsets=all' \
'--with-plugins=max' \
'--with-embedded-server' \
'--with-embedded-privilege-control' \

CXXFLAGS="-Wno-narrowing -fpermissive"

make
