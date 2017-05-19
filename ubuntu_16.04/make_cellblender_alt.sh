#!/bin/bash

# This was designed to be used with Ubuntu 16.04. It probably needs to be
# tweaked to work with other distros.

# Echo every command
set -o verbose 
# Quit if there's an error
set -e

version="2.78"
minor=""
project_dir=$(pwd)
blender_dir="blender-$version$minor-linux-glibc211-x86_64"
#blender_dir_full="$project_dir/blender-$version$minor-linux-glibc211-x86_64"
blender_dir_full="$project_dir/blender-git/build_linux/bin/"

#rm -fr $blender_dir_full

mkdir -p $project_dir/blender-git
cd $project_dir/blender-git
if [ ! -d blender ]
then
  git clone https://git.blender.org/blender.git
fi
cd blender
git submodule update --init --recursive
git submodule foreach git checkout master
git submodule foreach git pull --rebase origin master

cd $project_dir/blender-git
./blender/build_files/build_environment/install_deps.sh

cd $project_dir/blender-git/blender
sed -i '/tkinter/d' ./source/creator/CMakeLists.txt
make
#make install

cd $project_dir/blender-git/build_linux/bin/2.78/python/bin
cp $project_dir/get-pip.py .
./python3.5m get-pip.py

#sudo apt-get install libxml2 libxml2-dev
#sudo apt-get install zlib1g zlib1g-dev
#sudo apt-get install bzip2 libbz2-dev

cd $project_dir/blender-git/build_linux/bin/2.78/python/local/bin
./pip install python-libsbml
./pip install matplotlib

# Set up GAMer
cd $blender_dir_full/$version
git clone https://github.com/jczech/gamer
cd gamer
make
make install
cd ..
rm -fr gamer

# Set up CellBlender
# Adding userpref.blend so that CB is enabled by default and startup.blend to
# give user a better default layout.
cd $project_dir/
cp -fr ../config $project_dir/blender-git/build_linux/bin/$version
cd $project_dir/blender-git/build_linux/bin/$version/scripts/addons
if [ -d cellblender ]
then
  rm -fr cellblender 
fi
git clone https://github.com/mcellteam/cellblender
cd cellblender
git checkout development
git submodule init
git submodule update
# These changes seem to be needed for the versions of python and gcc that come
# with ubuntu.
sed -i 's/python3\.4/python3/' io_mesh_mcell_mdl/makefile
#sed -i 's/gcc \(-lGL -lglut -lGLU\) \(-o SimControl SimControl.o\)/gcc \2 \1/' makefile
make
rm cellblender.zip
rm cellblender
rm .gitignore
rm -fr .git

mcell_dir_name="mcell-3.4"
#mcell_zip_name="master.zip"
mcell_zip_name="v3.4.zip"
# Get and build MCell
wget https://github.com/mcellteam/mcell/archive/$mcell_zip_name
unzip $mcell_zip_name
cd $mcell_dir_name
export CC=/usr/bin/clang
sed -i 's:-O2:-O3:g' CMakeLists.txt
mkdir build
cd build
cmake ..
make
mv mcell ../..
cd ../..
rm -fr $mcell_dir_name $mcell_zip_name
mkdir bin
mv mcell bin

#cd $project_dir
#zip -r cellblender1.1_bundle_linux.zip $blender_dir
