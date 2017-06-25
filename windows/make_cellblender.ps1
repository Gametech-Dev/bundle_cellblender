# Change the project dir as needed
$bl_version = "2.78"
$bl_minor = "c"
#$project_dir = "$home\bundle_cellblender\windows"
#$config_dir = "$home\bundle_cellblender\config"
$project_dir = "$home\Documents\GitHub\bundle_cellblender\windows"
$config_dir = "$home\Documents\GitHub\bundle_cellblender\config"
$blender_download_url = "http://ftp.halifax.rwth-aachen.de/blender/release/Blender$bl_version/blender-$bl_version$bl_minor-windows64.zip"
#$blender_download_url = "http://mcell.org/download/files/blender-$bl_version$bl_minor-windows64.zip"
$blender_zip = "$project_dir\blender.zip"
$anaconda_dir = "$home\Anaconda3\envs\cb"
$anaconda_scripts = "$anaconda_dir\Scripts"
$mcell_version = "master"
$blender_dir = "$project_dir\blender-$bl_version$bl_minor-windows64"
$python_dir = "$blender_dir\$bl_version\python"
$addon_dir = "$blender_dir\$bl_version\scripts\addons"
$cellblender_dir = "$addon_dir\cellblender"

cd $project_dir

# Ugh. We have to build MCell with cygwin first to create files for the Windows build
& "$home\.babun\cygwin\bin\dos2unix.exe" $project_dir\make_mcell.sh
& "$home\.babun\cygwin\bin\bash.exe" -login $project_dir\make_mcell.sh

# Get Blender
$strFileName="c:\filename.txt"
If (Test-Path $blender_zip){
  # blender zip exists, do nothing
}Else{
  # blender zip does not exist, grab it
  Invoke-WebRequest $blender_download_url -OutFile $blender_zip
}
#Extract Blender
& 'C:\Program Files\7-Zip\7z.exe' x $blender_zip -o"$project_dir"

cd $addon_dir

# Get CellBlender
$cellblender_download_url = "https://github.com/mcellteam/cellblender/archive/development.zip"
$cellblender_url = "https://github.com/mcellteam/cellblender"
git clone -q $cellblender_url
cd cellblender
git checkout development

cd $cellblender_dir

# Get and build MCell (for Windows this time... using MingW)
#$mcell_download_url = "https://github.com/mcellteam/mcell/archive/v$mcell_version.zip"
$mcell_download_url = "https://github.com/mcellteam/mcell/archive/master.zip"
$mcell_zip = "$cellblender_dir\mcell.zip"
Invoke-WebRequest $mcell_download_url -OutFile $mcell_zip
& 'C:\Program Files\7-Zip\7z.exe' x $mcell_zip -o"$cellblender_dir"
$mcell_build_dir =  "$cellblender_dir\mcell-$mcell_version\src"
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
rm -Recurse -Force $mcell_build_dir
rm $mcell_zip


# Replace Blender's Python with Anaconda version
# Assume Miniconda was already installed, because chocolatey version isn't working for me
cd $anaconda_scripts
.\conda create --name cb python=3.5.2 matplotlib numpy scipy
cd $project_dir
& .\make_conda_env.bat
rm -Force -Recurse "$python_dir\bin"
rm -Force -Recurse "$python_dir\lib"
mkdir $python_dir\bin
cp -Force -Recurse $anaconda_dir\*.exe $python_dir\bin
cp -Force -Recurse $anaconda_dir\*.dll $python_dir\bin
cp -Force -Recurse $anaconda_dir\qt.conf $python_dir\bin
cp -Force -Recurse $anaconda_dir\Lib $python_dir
cp -Force -Recurse $anaconda_dir\DLLs $python_dir
cp -Force -Recurse $anaconda_dir\Library $python_dir
cp -Force -Recurse $anaconda_dir\tcl\tcl8.6 $python_dir\Lib
cp -Force -Recurse $anaconda_dir\tcl\tk8.6 $python_dir\Lib

cd $python_dir
Get-ChildItem -Filter '*.pyc' -Force -Recurse | Remove-Item -Force
Get-ChildItem -Filter '__pycache__' -Force -Recurse | Remove-Item -Force

cp -Force -Recurse $config_dir $blender_dir\$bl_version

# Some cleanup
rm -Force -Recurse "$cellblender_dir\mcell-$mcell_version"
rm -Force -Recurse "$project_dir\mcell-$mcell_version"
rm -Force "$project_dir\v$mcell_version.zip"
rm -Force -Recurse "$cellblender_dir\.git"
rm -Force "$cellblender_dir\.gitignore"
rm -Force "$cellblender_dir\.gitmodules"
rm -Force -Recurse "$cellblender_dir\test_suite"

# Zip up modified blender directory
$final_zip = "$project_dir\cellblender1.1_bundle_windows.zip"
& 'C:\Program Files\7-Zip\7z.exe' a -mx=9 $final_zip $blender_dir

cd $project_dir