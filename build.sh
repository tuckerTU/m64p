#!/usr/bin/env bash

set -e

UNAME=$(uname -s)
gui_dir_suffix=""
if [[ $UNAME == *"MINGW"* ]]; then
  suffix=".dll"
  if [[ $UNAME == *"MINGW64"* ]]; then
    mingw_prefix="mingw64"
  else
    mingw_prefix="mingw32"
  fi
elif [[ $UNAME == *"Darwin"* ]]; then
  suffix=".dylib"
  gui_dir_suffix=".app/Contents/MacOs/mupen64plus-gui"
  export CXXFLAGS='-stdlib=libc++'
  export LDFLAGS='-mmacosx-version-min=10.7'
else
  suffix=".so"
fi

install_dir=$PWD/mupen64plus
mkdir -p $install_dir
base_dir=$PWD

cd $base_dir/mupen64plus-core/projects/unix
make NETPLAY=1 OSD=0 NO_ASM=1 -j4 all
cp -P $base_dir/mupen64plus-core/projects/unix/*$suffix* $install_dir
cp $base_dir/mupen64plus-core/data/* $install_dir

cd $base_dir/mupen64plus-rsp-hle/projects/unix
make -j4 all
cp $base_dir/mupen64plus-rsp-hle/projects/unix/*$suffix $install_dir

cd $base_dir/mupen64plus-input-raphnetraw/projects/unix
make -j4 all
cp $base_dir/mupen64plus-input-raphnetraw/projects/unix/*$suffix $install_dir

mkdir -p $base_dir/mupen64plus-input-qt/build
cd $base_dir/mupen64plus-input-qt/build
qmake ../mupen64plus-input-qt.pro
make -j4
if [[ $UNAME == *"MINGW"* ]]; then
  cp $base_dir/mupen64plus-input-qt/build/release/mupen64plus-input-qt.dll $install_dir
else
  cp $base_dir/mupen64plus-input-qt/build/libmupen64plus-input-qt$suffix $install_dir/mupen64plus-input-qt$suffix
fi

cd $base_dir/mupen64plus-audio-sdl2/projects/unix
make -j4 all
cp $base_dir/mupen64plus-audio-sdl2/projects/unix/*$suffix $install_dir

cd $base_dir
GUI_DIRECTORY=$base_dir/mupen64plus-gui
rev=\"`git rev-parse HEAD`\"
lastrev=$(head -n 1 $GUI_DIRECTORY/version.h | awk -F'GUI_VERSION ' {'print $2'})

echo current revision $rev
echo last build revision $lastrev

if [ "$lastrev" != "$rev" ]
then
   echo "#define GUI_VERSION $rev" > $GUI_DIRECTORY/version.h
fi

mkdir -p $base_dir/mupen64plus-gui/build
cd $base_dir/mupen64plus-gui/build
qmake ../mupen64plus-gui.pro
make -j4
if [[ $UNAME == *"MINGW"* ]]; then
  cp $base_dir/mupen64plus-gui/build/release/mupen64plus-gui.exe $install_dir
else
  cp $base_dir/mupen64plus-gui/build/mupen64plus-gui$gui_dir_suffix $install_dir
fi

cd $base_dir/GLideN64/src
./getRevision.sh

cd $base_dir/GLideN64/projects/cmake
if [[ $UNAME == *"MINGW"* ]]; then
  cmake -G "MSYS Makefiles" -DMUPENPLUSAPI_GLIDENUI=On -DNOHQ=On -DVEC4_OPT=On -DCRC_OPT=On -DMUPENPLUSAPI=On ../../src/
else
  cmake -DMUPENPLUSAPI_GLIDENUI=On -DNOHQ=On -DVEC4_OPT=On -DCRC_OPT=On -DMUPENPLUSAPI=On ../../src/
fi
make -j4

if [[ $UNAME == *"MINGW"* ]]; then
  cp mupen64plus-video-GLideN64$suffix $install_dir
else
  cp plugin/Release/mupen64plus-video-GLideN64$suffix $install_dir
fi
cp $base_dir/GLideN64/ini/GLideN64.custom.ini $install_dir

if [[ $UNAME == *"MINGW"* ]]; then
  cd $install_dir
  windeployqt.exe mupen64plus-gui.exe

  if [[ $UNAME == *"MINGW64"* ]]; then
    my_os=win64
    cp /$mingw_prefix/bin/libgcc_s_seh-1.dll $install_dir
  else
    my_os=win32
    cp /$mingw_prefix/bin/libgcc_s_dw2-1.dll $install_dir
  fi
  cp /$mingw_prefix/bin/libwinpthread-1.dll $install_dir
  cp /$mingw_prefix/bin/SDL2.dll $install_dir
  cp /$mingw_prefix/bin/SDL2_net.dll $install_dir
  cp /$mingw_prefix/bin/libpng16-16.dll $install_dir
  cp /$mingw_prefix/bin/libglib-2.0-0.dll $install_dir
  cp /$mingw_prefix/bin/libstdc++-6.dll $install_dir
  cp /$mingw_prefix/bin/zlib1.dll $install_dir
  cp /$mingw_prefix/bin/libintl-8.dll $install_dir
  cp /$mingw_prefix/bin/libpcre-1.dll $install_dir
  cp /$mingw_prefix/bin/libiconv-2.dll $install_dir
  cp /$mingw_prefix/bin/libharfbuzz-0.dll $install_dir
  cp /$mingw_prefix/bin/libgraphite2.dll $install_dir
  cp /$mingw_prefix/bin/libfreetype-6.dll $install_dir
  cp /$mingw_prefix/bin/libbz2-1.dll $install_dir
  cp /$mingw_prefix/bin/libminizip-1.dll $install_dir
  cp /$mingw_prefix/bin/libsamplerate-0.dll $install_dir
  cp /$mingw_prefix/bin/libjasper-4.dll $install_dir
  cp /$mingw_prefix/bin/libjpeg-8.dll $install_dir
  cp /$mingw_prefix/bin/libpcre2-16-0.dll $install_dir
  cp /$mingw_prefix/bin/libdouble-conversion.dll $install_dir
  cp /$mingw_prefix/bin/libicuin67.dll $install_dir
  cp /$mingw_prefix/bin/libicuuc67.dll $install_dir
  cp /$mingw_prefix/bin/libicudt67.dll $install_dir
  cp /$mingw_prefix/bin/libzstd.dll $install_dir
  cp /$mingw_prefix/bin/libhidapi-0.dll $install_dir
  cp /$mingw_prefix/bin/libbrotlidec.dll $install_dir
  cp /$mingw_prefix/bin/libbrotlicommon.dll $install_dir
  cp /$mingw_prefix/bin/libssl-1_1-x64.dll $install_dir
  cp /$mingw_prefix/bin/libcrypto-1_1-x64.dll $install_dir
  cp $base_dir/7za.exe $install_dir
else
  if [[ $HOST_CPU == "i686" ]]; then
    my_os=linux32
  else
    my_os=linux64
  fi
fi

if [[ $UNAME != *"Darwin"* ]]; then
  cd $base_dir
  rm -f $base_dir/*.zip
  HASH=$(git rev-parse --short HEAD)
  zip -r m64p-$my_os-$HASH.zip mupen64plus
fi
