#!/bin/bash

# This was designed to be used with Ubuntu 14.04. It probably needs to be
# tweaked to work with other distros.

# Echo every command
set -o verbose 
# Quit if there's an error
set -e

version="2.77"
minor="a"
project_dir=$(pwd)
blender_dir="blender-$version$minor-linux-glibc211-x86_64"
blender_dir_full="$project_dir/blender-$version$minor-linux-glibc211-x86_64"
blender_tar="$blender_dir.tar"
blender_bz2="$blender_tar.bz2"
mirror1="http://ftp.halifax.rwth-aachen.de/blender/release/Blender$version/$blender_bz2";
mirror2="http://ftp.nluug.nl/pub/graphics/blender/release/Blender$version/$blender_bz2";
mirror3="http://download.blender.org/release/Blender$version/$blender_bz2";
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

# Set up GAMer
cd $blender_dir_full/$version
#git clone https://github.com/mcellteam/gamer
cd gamer
sed -i 's/^INSTALL_DIR.*/INSTALL_DIR = ../' makefile 
make
make install
cd ..
rm -fr gamer

# Set up CellBlender
# Need to add userpref.blend, so that CB is enabled by default. Maybe add
# startup.blend too.
#cp -fr config $blender_dir/$version
cd $blender_dir_full/$version/scripts/addons
git clone https://github.com/mcellteam/cellblender
cd cellblender
git checkout development
git submodule init
git submodule update
# These changes seem to be needed for the versions of python and gcc that come
# with ubuntu.
sed -i 's/python3\.3/python3/' io_mesh_mcell_mdl/makefile
sed -i 's/gcc \(-lGL -lglut -lGLU\) \(-o SimControl SimControl.o\)/gcc \2 \1/' makefile
make
rm cellblender.zip
rm cellblender
rm .gitignore
rm -fr .git

mcell_dir_name="mcell-master"
mcell_zip_name="master.zip"
# Get and build MCell
#wget https://github.com/mcellteam/mcell/archive/v3.3.zip
wget https://github.com/mcellteam/mcell/archive/$mcell_zip_name
unzip $mcell_zip_name
cd $mcell_dir_name
mkdir build
cd build
cmake ..
make
mv mcell ../..
cd ../..
rm -fr $mcell_dir_name $mcell_zip_name
mkdir bin
mv mcell bin

# Build sbml2json for bng importer
cd bng
mkdir bin
make
make install
make clean

cd $project_dir
zip -r cellblender1.1_bundle_linux.zip $blender_dir_full
