#!/bin/bash

# This was designed to be used with Ubuntu 14.04. It probably needs to be
# tweaked to work with other distros.

# Echo every command
set -o verbose 
set -e

blender_dir="blender-2.76b-linux-glibc211-x86_64"
blender_tar="$blender_dir.tar"
blender_bz2="$blender_tar.bz2"
mirror1="http://ftp.halifax.rwth-aachen.de/blender/release/Blender2.76/$blender_bz2";
mirror2="http://ftp.nluug.nl/pub/graphics/blender/release/Blender2.76/$blender_bz2";
mirror3="http://download.blender.org/release/Blender2.76/$blender_bz2";
mirrors=($mirror1 $mirror2 $mirror3);
random=$(shuf -i 0-2 -n 1);

# Grab Blender and extract it
#selected_mirror=${mirrors[$random]}
selected_mirror=${mirrors[$1]}
echo $selected_mirror
wget $selected_mirror
bunzip2 $blender_bz2
tar xf $blender_tar
rm -fr $blender_tar

# Set up CellBlender
# Need to add userpref.blend, so that CB is enabled by default. Maybe add
# startup.blend too.
#cp -fr config $blender_dir/2.76
cd $blender_dir/2.76/scripts/addons
#git clone https://github.com/mcellteam/cellblender
wget https://github.com/mcellteam/cellblender/archive/development.zip
unzip development.zip
rm development.zip
mv cellblender-development cellblender
cd cellblender
# These changes seem to be needed for the versions of python and gcc that come
# with ubuntu.
sed -i 's/python3\.3/python3/' io_mesh_mcell_mdl/makefile
sed -i 's/gcc \(-lGL -lglut -lGLU\) \(-o SimControl SimControl.o\)/gcc \2 \1/' makefile
make

# Install MCell
wget https://github.com/mcellteam/mcell/archive/v3.3.zip
unzip v3.3.zip
cd mcell-3.3/src
./bootstrap
cd ..
mkdir build
cd build
../src/configure "CFLAGS=-O3 -static"
make
mv mcell ../..
cd ../..
rm -fr mcell-3.3 v3.3.zip
mkdir bin
mv mcell bin
