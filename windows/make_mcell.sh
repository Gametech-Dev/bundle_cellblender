#!/bin/bash

cd /cygdrive/c/Users/vagrant/bundle_cellblender/windows

wget https://github.com/mcellteam/mcell/archive/v3.3.zip
unzip v3.3.zip
cd mcell-3.3/src
./bootstrap
cd ..
mkdir build
cd build
../src/configure "CFLAGS=-O3 -static"
make
