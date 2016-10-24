﻿# Change the project dir as needed
$bl_version = "2.78"
$bl_minor = ""
$project_dir = "$home\bundle_cellblender\windows"
$config_dir = "$home\bundle_cellblender\config"
#$blender_download_url = "http://ftp.halifax.rwth-aachen.de/blender/release/Blender$bl_version/blender-$bl_version$bl_minor-windows64.zip"
$blender_download_url = "http://mcell.org/download/files/blender-$bl_version$bl_minor-windows64.zip"
$blender_zip = "$projectdir\blender.zip"
$miniconda_dir = "$home\Miniconda3"
$miniconda_scripts = "$miniconda_dir\Scripts"
$mcell_version = "3.4"
$blender_dir = "$project_dir\blender-$bl_version$bl_minor-windows64"
$python_dir = "$blender_dir\$bl_version$bl_minor\python"
$addon_dir = "$blender_dir\$bl_version\scripts\addons"
$cellblender_dir = "$addon_dir\cellblender"
$matplotlib_dir = "$project_dir\matplotlib-feedstock"

cd $project_dir

# Ugh. We have to build MCell with cygwin first to create files for the Windows build
C:\Users\vagrant\.babun\cygwin\bin\dos2unix.exe $project_dir\make_mcell.sh
C:\Users\vagrant\.babun\cygwin\bin\bash.exe -login $project_dir\make_mcell.sh

# Get Blender
Invoke-WebRequest $blender_download_url -OutFile $blender_zip
& 'C:\Program Files\7-Zip\7z.exe' x $blender_zip -o"$project_dir"

cd $addon_dir

# Get CellBlender
#$cellblender_download_url = "https://github.com/mcellteam/cellblender/archive/development.zip"
$cellblender_url = "https://github.com/mcellteam/cellblender"
#$cellblender_zip = "$addon_dir\cellblender.zip"
#Invoke-WebRequest $cellblender_download_url -Outfile $cellblender_zip
#& 'C:\Program Files\7-Zip\7z.exe' x $cellblender_zip -o"$addon_dir"
#mv cellblender-development cellblender
git clone -q $cellblender_url
cd cellblender
git checkout development
git submodule init
git submodule update

cd $cellblender_dir

# Get and build MCell (for Windows this time... using MingW)
$mcell_download_url = "https://github.com/mcellteam/mcell/archive/v$mcell_version.zip"
$mcell_zip = "$cellblender_dir\mcell.zip"
Invoke-WebRequest $mcell_download_url -OutFile $mcell_zip
& 'C:\Program Files\7-Zip\7z.exe' x $mcell_zip -o"$cellblender_dir"
mv mcell-$mcell_version mcell
$mcell_build_dir =  "$cellblender_dir\mcell\src"
$cygwin_build_dir = "$project_dir\mcell-$mcell_version\build"

cp $cygwin_build_dir\config.h $mcell_build_dir
cp $cygwin_build_dir\version.h $mcell_build_dir
cp $cygwin_build_dir\mdllex.c $mcell_build_dir
cp $cygwin_build_dir\mdlparse.h $mcell_build_dir
cp $cygwin_build_dir\mdlparse.c $mcell_build_dir

cd $mcell_build_dir
gcc -mconsole -std=c99 -O3 -fno-schedule-insns2 -Wall -Wshadow -o mcell.exe *.c 
mkdir "$cellblender_dir\bin"
cp "$mcell_build_dir\mcell.exe" "$cellblender_dir\bin"

# Replace Blender's Python with Miniconda version and custom matplotlib (w/o Qt)
# Assume Miniconda was already installed, because chocolatey version isn't working for me
cd $project_dir
git clone https://github.com/jczech/matplotlib-feedstock
cd $miniconda_scripts
.\conda.exe install -y conda-build
.\conda.exe install -c SBMLTeam -y python-libsbml
.\conda.exe install -y m2-patch
.\conda.exe build $matplotlib_dir\recipe --numpy 1.11
.\conda.exe install --use-local -y matplotlib
.\conda.exe build purge
.\conda.exe clean -y --all
rm -Force -Recurse "$python_dir\bin"
rm -Force -Recurse "$python_dir\lib"
mkdir $python_dir\bin
cp -Force -Recurse $miniconda_dir\*.exe $python_dir\bin
cp -Force -Recurse $miniconda_dir\*.dll $python_dir\bin
cp -Force -Recurse $miniconda_dir\Lib $python_dir
cp -Force -Recurse $miniconda_dir\DLLs $python_dir
cp -Force -Recurse $miniconda_dir\tcl\tcl8.6 $python_dir\Lib
cp -Force -Recurse $miniconda_dir\tcl\tk8.6 $python_dir\Lib
cd $python_dir
Get-ChildItem -Filter '*.pyc' -Force -Recurse | Remove-Item -Force
Get-ChildItem -Filter '__pycache__' -Force -Recurse | Remove-Item -Force

cp -Force -Recurse $config_dir $blender_dir\$bl_version

# Some cleanup
rm -Force -Recurse "$cellblender_dir\mcell"
rm -Force -Recurse "$project_dir\mcell-$mcell_version"
rm -Force "$project_dir\v$mcell_version.zip"
#rm -Force "$project_dir\blender.zip"
rm -Force "$cellblender_dir\mcell.zip"
rm -Force -Recurse "$cellblender_dir\.git"
rm -Force "$cellblender_dir\.gitignore"
rm -Force "$cellblender_dir\.gitmodules"
rm -Force -Recurse "$project_dir\test_suite"
rm -Force -Recurse "$cellblender_dir\bng\dist"
rm -Force -Recurse "$cellblender_dir\bng\build"
rm -Force -Recurse "$cellblender_dir\pyinstaller2"
rm -Force -Recurse $matplotlib_dir

# Zip up modified blender directory
$final_zip = "$project_dir\cellblender1.1_bundle_windows.zip"
& 'C:\Program Files\7-Zip\7z.exe' a -mx=9 $final_zip $blender_dir

cd $project_dir