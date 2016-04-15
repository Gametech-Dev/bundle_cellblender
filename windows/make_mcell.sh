#!/bin/bash

cd /cygdrive/c/Users/vagrant/bundle_cellblender/windows

mcell_dir_name="mcell-master"
mcell_zip_name="master.zip"
#wget https://github.com/mcellteam/mcell/archive/v3.3.zip
wget https://github.com/mcellteam/mcell/archive/$mcell_zip_name
unzip $mcell_zip_name
cd $mcell_dir_name/src
./bootstrap
cd ..
mkdir build
cd build
../src/configure "CFLAGS=-O3 -static"
make
