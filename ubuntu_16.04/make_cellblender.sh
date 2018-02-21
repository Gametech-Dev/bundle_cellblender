#!/bin/bash

# This was designed to be used with Ubuntu 16.04. It probably needs to be
# tweaked to work with other distros.

# Echo every command
set -o verbose 
# Quit if there's an error
set -e

version="2.79"
minor=""
glibc="219"
project_dir=$(pwd)
blender_dir="blender-$version$minor-linux-glibc$glibc-x86_64"
python_ver="3.5.2"
blender_dir_full="$project_dir/blender-$version$minor-linux-glibc$glibc-x86_64"
addon_dir_full="$blender_dir_full/$version/scripts/addons/"
cellblender_dir_full="$addon_dir_full/cellblender"
blender_tar="$blender_dir.tar"
blender_bz2="$blender_tar.bz2"
mirror1="http://ftp.halifax.rwth-aachen.de/blender/release/Blender$version/$blender_bz2";
mirror2="http://ftp.nluug.nl/pub/graphics/blender/release/Blender$version/$blender_bz2";
mirror3="http://download.blender.org/release/Blender$version/$blender_bz2";
mirror4="http://www.mcell.org/download/files/$blender_bz2";
mirrors=($mirror1 $mirror2 $mirror3);
random=$(shuf -i 0-3 -n 1);

rm -fr $blender_dir_full

# Grab Blender and extract it
#selected_mirror=${mirrors[$random]}
selected_mirror=${mirrors[0]}
if [ ! -f $blender_tar ]
then
	wget $selected_mirror
	bunzip2 $blender_bz2
fi
tar xf $blender_tar

python_tarball="Python-$python_ver.tar.xz"
python_src_dir="$project_dir/Python-$python_ver"
python_build_dir="$project_dir/python_build_$python_ver"
cd $project_dir
if [ ! -f $python_tarball ]
then
  wget https://www.python.org/ftp/python/$python_ver/$python_tarball
fi

if [ ! -d $python_src_dir ]
then
  tar xf $python_tarball
fi

mkdir -p $python_build_dir
cd $python_src_dir
./configure --prefix=$python_build_dir
make
make install

cd $python_build_dir/bin
./pip3 install --ignore-installed numpy scipy matplotlib lxml python-libsbml

# remove existing python, add our new custom version
cd $blender_dir_full/$version
rm -fr python
mkdir -p python
cp -fr $python_build_dir/* $blender_dir_full/$version/python

# Set up GAMer
cd $blender_dir_full/$version
git clone https://github.com/jczech/gamer
cd gamer
make
make install
cd ..
rm -fr gamer

# Adding userpref.blend so that CB is enabled by default and startup.blend to
# give user a better default layout.
cd $project_dir
cp -fr ../config $blender_dir_full/$version

# Set up CellBlender
if [ ! -d cellblender ]
then
  git clone https://github.com/mcellteam/cellblender
fi
cd cellblender
git checkout development
git pull
# These changes seem to be needed for the versions of python and gcc that come
# with ubuntu.
sed -i 's/python3\.4/python3/' io_mesh_mcell_mdl/makefile
make

# Clean up CellBlender
cd $project_dir
cp -fr cellblender $addon_dir_full
cd $cellblender_dir_full
rm cellblender.zip
rm cellblender
#rm .gitignore
#rm -fr .git

# Build mcell
cd $project_dir
mcell_dir_name="mcell"
if [ ! -d mcell ]
then
  git clone https://github.com/mcellteam/mcell
fi
cd $mcell_dir_name
git checkout nfsim_dynamic_meshes_pymcell
git pull
export CC=/usr/bin/clang
sed -i 's:-O2:-O3:g' CMakeLists.txt
mkdir -p build
cd build
git submodule init
git submodule update
cmake ..
make
cp -fr mcell *.py lib bng2 $cellblender_dir_full/extensions

cd $project_dir
blender_dir_new=Blender-$version-CellBlender
mv $blender_dir $blender_dir_new
tar -cjf $blender_dir_new.Linux.bz2 $blender_dir_new
