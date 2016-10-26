#!/bin/bash

# This was designed to be used with Ubuntu 14.04. It probably needs to be
# tweaked to work with other distros.

# Echo every command
set -o verbose 
# Quit if there's an error
set -e

version="2.78"
minor=""
project_dir=$(pwd)
blender_dir="blender-$version$minor-linux-glibc211-x86_64"
miniconda_bins="$project_dir/miniconda3/bin"
blender_dir_full="$project_dir/blender-$version$minor-linux-glibc211-x86_64"
blender_tar="$blender_dir.tar"
blender_bz2="$blender_tar.bz2"
mirror1="http://ftp.halifax.rwth-aachen.de/blender/release/Blender$version/$blender_bz2";
mirror2="http://ftp.nluug.nl/pub/graphics/blender/release/Blender$version/$blender_bz2";
mirror3="http://download.blender.org/release/Blender$version/$blender_bz2";
mirror4="http://www.mcell.org/download/files/$blender_bz2";
mirrors=($mirror1 $mirror2 $mirror3 $mirror4);
random=$(shuf -i 0-3 -n 1);

# Grab Blender and extract it
#selected_mirror=${mirrors[$random]}
selected_mirror=${mirrors[3]}
if [ ! -f $blender_tar ]
then
	wget $selected_mirror
	bunzip2 $blender_bz2
fi
tar xf $blender_tar

# get matplotlib recipe that doesn't use qt
if [ ! -d ./matplotlib-feedstock ]
then
	git clone https://github.com/jczech/matplotlib-feedstock
	# not sure why the latest commit isn't working
	cd matplotlib-feedstock
	git checkout 1e58ca8
	cd ..
fi

# get miniconda, add custom matplotlib with custom recipe
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
./conda install -y conda-build
./conda install -y -c SBMLTeam python-libsbml
./conda install -y nomkl
./conda build $project_dir/matplotlib-feedstock/recipe --numpy 1.11
./conda install --use-local -y matplotlib
./conda clean -y --all

# remove existing python, add our new custom version
cd $blender_dir_full/$version
rm -fr python
mkdir -p python/bin
cp ../../miniconda3/bin/python3.5m python/bin
cp -fr ../../miniconda3/lib python
find . -type f -name "*.pyc" -delete
find . -type d -name "__pycache__" -delete

# Set up GAMer. XXX: This is not working right now. :(
cd $blender_dir_full/$version
git clone https://github.com/jczech/gamer
cd gamer
sed -i 's:3.5:3.4:g' makefile
make
make install
cd ..
rm -fr gamer

# Set up CellBlender
# Adding userpref.blend so that CB is enabled by default and startup.blend to
# give user a better default layout.
cd $project_dir
cp -fr ../config $blender_dir/$version
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

#mcell_dir_name="mcell-master"
#mcell_zip_name="master.zip"
mcell_dir_name="mcell-3.4"
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

cd $project_dir
zip -r cellblender1.1_bundle_linux.zip $blender_dir
