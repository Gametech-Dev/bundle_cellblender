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
miniconda_bins="$project_dir/miniconda3/bin"
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

# get miniconda
miniconda_script="Miniconda3-latest-Linux-x86_64.sh"
if [ ! -f $miniconda_script ]
then
	wget https://repo.continuum.io/miniconda/$miniconda_script
fi

if [ ! -d ./miniconda3 ]
then
	bash $miniconda_script -b -p ./miniconda3
fi
cd $miniconda_bins
PATH=$PATH:$miniconda_bins
if [ ! -d ../envs/cb ]
then
  ./conda create -n cb python=3.5.2 numpy scipy matplotlib
fi
source ./activate cb
./conda install -y -c SBMLTeam python-libsbml
./conda install lxml
./conda clean -y --all

# remove existing python, add our new custom version
cd $blender_dir_full/$version
rm -fr python
mkdir -p python/bin
cp ../../miniconda3/envs/cb/bin/python3.5m python/bin
cp -fr ../../miniconda3/envs/cb/lib python
find . -type f -name "*.pyc" -delete
find . -type d -name "__pycache__" -delete

# cleanup miniconda stuff
#rm -fr ../../miniconda3
#rm ../../Miniconda3-latest-Linux-x86_64.sh

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
rm .gitignore
rm -fr .git

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
zip -r cellblender1.2_bundle_linux.zip $blender_dir
