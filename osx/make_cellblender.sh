#!/bin/bash

# Note: this is mostly functional, although the GAMer build is currently
# failing.

# Echo every command
set -o verbose 
# Quit if there's an error
set -e

version="2.78"
minor=""
# I can't get anything newer thatn 2.76b to work in vbox
#version="2.76"
#minor="b"
project_dir=$(pwd)
blender_dir="blender-$version$minor-OSX_10.6-x86_64"
miniconda_dir="$project_dir/miniconda3/"
blender_dir_full="$project_dir/blender-$version$minor-OSX_10.6-x86_64"
blender_zip="$blender_dir.zip"
mirror1="http://ftp.halifax.rwth-aachen.de/blender/release/Blender$version/$blender_zip";
mirror2="http://ftp.nluug.nl/pub/graphics/blender/release/Blender$version/$blender_zip";
mirror3="http://download.blender.org/release/Blender$version/$blender_zip";
mirror4="http://www.mcell.org/download/files/$blender_zip";
mirrors=($mirror1 $mirror2 $mirror3);
#random=$(shuf -i 0-3 -n 1);

# Grab Blender and extract it
#selected_mirror=${mirrors[$random]}
selected_mirror=${mirrors[1]}
if [ ! -f $blender_zip ]
then
	wget $selected_mirror
fi
rm -fr $project_dir/__MACOSX
rm -fr $blender_dir_full
unzip $blender_zip -d $blender_dir_full
#unzip $blender_zip -d .

# get matplotlib recipe that doesn't use qt
matplotlib_dir="matplotlib-feedstock"
if [ ! -d $matplotlib_dir ]
then
	git clone https://github.com/jczech/$matplotlib_dir
fi

# get miniconda, add custom matplotlib with custom recipe
miniconda_script="Miniconda3-latest-MacOSX-x86_64.sh"
if [ ! -f $miniconda_script ]
then
	wget --no-check-certificate https://repo.continuum.io/miniconda/$miniconda_script
fi

if [ ! -d $miniconda_dir ]
then
	bash $miniconda_script -b -p ./miniconda3
fi

cd $miniconda_dir/bin
PATH=$PATH:$miniconda_dir/bin
#./conda install -y python=3.4
./conda install -y conda-build
./conda install -y -c SBMLTeam python-libsbml
#./pip install python-libsbml
./conda install -y nomkl
./conda build ../../$matplotlib_dir/recipe --numpy 1.11
./conda install --use-local -y matplotlib
./conda clean -y --all
cd ..
# Remove pyc file and __pycache__ directories to keep build size down
find . \( -name \*.pyc -o -name \*.pyo -o -name __pycache__ \) -prune -exec rm -rf {} +

# remove existing python, add our new custom version
cd $blender_dir_full/blender.app/Contents/Resources/$version/
cp -fr $miniconda_dir/ python/

# cleanup miniconda stuff
#rm -fr $miniconda_dir
#rm -fr $project_dir/$matplotlib_dir

# Set up GAMer
cd $blender_dir_full/blender.app/Contents/Resources/$version
git clone https://github.com/jczech/gamer
cd gamer
make
make install
cd ..
rm -fr gamer

# Set up CellBlender
# Adding userpref.blend so that CB is enabled by default and startup.blend to
# give user a better default layout.
cd $project_dir
cp -fr $project_dir/../config $blender_dir_full/blender.app/Contents/Resources/$version/config
cd $blender_dir_full/blender.app/Contents/Resources/$version/scripts/addons
git clone https://github.com/mcellteam/cellblender
cd cellblender
git checkout development
git submodule init
git submodule update
sed -i '' 's/python3\.4/python3/' io_mesh_mcell_mdl/makefile
#sed -i '' 's/gcc \(-lGL -lglut -lGLU\) \(-o SimControl SimControl.o\)/gcc \2 \1/' makefile
#make
#rm cellblender.zip
#rm cellblender
cd io_mesh_mcell_mdl
make
cd ..
rm .gitignore
rm -fr .git

mcell_dir_name="mcell-3.4"
#mcell_zip_name="master.zip"
mcell_zip_name="v3.4.zip"
# Get and build MCell
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

cd $project_dir
zip -r cellblender1.1_bundle_osx.zip $blender_dir
