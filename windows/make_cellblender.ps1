# Change the project dir as needed
$project_dir = "$home\bundle_cellblender\windows"
$blender_download = "http://ftp.halifax.rwth-aachen.de/blender/release/Blender2.76/blender-2.76b-windows64.zip"
$blender_destination = "$projectdir\blender.zip"

# TODO: Just use 7zip to unzip, since we already need it to zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

cd $project_dir

# Ugh. We have to build MCell with cygwin first to create files for the Windows buildd
C:\Users\vagrant\.babun\cygwin\bin\bash.exe -login $project_dir\make_mcell.sh

# Get Blender
Invoke-WebRequest $blender_download -OutFile $blender_destination
Unzip $blender_destination $project_dir
$blender_dir = "$project_dir\blender-2.76b-windows64"
$addon_dir = "$blender_dir\2.76\scripts\addons"
cd $addon_dir

# Get CellBlender
$cellblender_download = "https://github.com/mcellteam/cellblender/archive/development.zip"
$cellblender_destination = "$addon_dir\cellblender.zip"
Invoke-WebRequest $cellblender_download -Outfile $cellblender_destination
Unzip $cellblender_destination $addon_dir
mv cellblender-development cellblender
$cellblender_dir = "$addon_dir\cellblender"

cd "$cellblender_dir\bng"
& 'C:\Program Files\7-Zip\7z.exe' x pyinstaller2.zip
C:\tools\python2\python.exe .\pyinstaller2\pyinstaller.py sbml2json.spec
mkdir bin
cp dist\sbml2json bin\sbml2json.exe

cd $cellblender_dir

# Get and build MCell (for Windows this time... using MingW)
$mcell_source = "https://github.com/mcellteam/mcell/archive/v3.3.zip"
$mcell_destination = "$cellblender_dir\mcell.zip"
Invoke-WebRequest $mcell_source -OutFile $mcell_destination
Unzip $mcell_destination $cellblender_dir
mv mcell-3.3 mcell
$mcell_build_dir =  "$cellblender_dir\mcell\src"
$cygwin_build_dir = "$project_dir\mcell-3.3\build"

cp $cygwin_build_dir\config.h $mcell_build_dir
cp $cygwin_build_dir\version.h $mcell_build_dir
cp $cygwin_build_dir\mdllex.c $mcell_build_dir
cp $cygwin_build_dir\mdlparse.h $mcell_build_dir
cp $cygwin_build_dir\mdlparse.c $mcell_build_dir

cd $mcell_build_dir
gcc -mconsole -std=c99 -O3 -fno-schedule-insns2 -Wall -Wshadow -o mcell.exe *.c 

mkdir "$cellblender_dir\bin"
cp "$mcell_build_dir\mcell.exe" "$cellblender_dir\bin"

# Some cleanup
rm -Force -Recurse "$cellblender_dir\mcell"
rm -Force -Recurse "$project_dir\mcell-3.3"
rm -Force "$project_dir\v3.3.zip"
rm -Force "$project_dir\blender.zip"
rm -Force "$cellblender_dir\mcell.zip"
rm -Force "$cellblender_dir\.gitignore"
rm -Force -Recurse "$project_dir\test_suite"
rm -Force -Recurse "$cellblender_dir\bng\dist"
rm -Force -Recurse "$cellblender_dir\bng\build"
rm -Force -Recurse "$cellblender_dir\pyinstaller2"

# Zip up modified blender directory
$final_zip = "$project_dir\blender_final.zip"
& 'C:\Program Files\7-Zip\7z.exe' a -mx=9 $final_zip $blender_dir

cd $project_dir