#!/bin/bash

set -e

MINGW=${MINGW:-x86_64-w64-mingw32}
WORKSPACE=${WORKSPACE:-$(pwd)}
BUILD_NUMBER=${BUILD_NUMBER:-0}
ARCH=${ARCH:-${MINGW%%-*}}

version=
download=0
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS]

OPTIONS:

  -h, --help      show this help
  -v, --version   specify version string
  -d, --download  download sources
                  otherwise sources must be in $(pwd)

VARIABLES:

  MINGW           mingw parameter (default: $MINGW)
  WORKSPACE       workspace path (default: $WORKSPACE)
  BUILD_NUMBER    build number (default: $BUILD_NUMBER)
  ARCH            architecture (default: $ARCH)

Builds OpenSSL for Windows
EOF
            exit
            ;;
        (-d|--download) download=1;;
        (-v|--version) shift; version="$1";;
        (*) echo "ERROR: unknown option: $1" 1>&2; exit 1;;
    esac
    if ! test $# -gt 0; then
        echo "ERROR: missing parameter" 1>&2
        exit 1
    fi
    shift
done

set -x

cd ${WORKSPACE}
if test $download -eq 1; then
    git clone https://code.qt.io/qt/qt5.git qt5
    cd qt5
    if test -z "$version"; then
        version=$(git branch -r | sed -n 's,^ *origin/\([0-9.]\+\)$,\1,p' | tail -1)
    fi
    git checkout "$version"
    perl init-repository
fi
if test -z "$version"; then
    version=$(git branch | sed -n 's,^\* *,,p')
fi
path=qt-${version}
[[ "$version" =~ ^[0-9.]+$ ]]

echo "Version: $version"
echo "Package: $path"

git submodule foreach --recursive "git clean -dfx"

# bugfixes:
#   MinGW has no uiviewsettingsinterop.h
sed -i '/^ *# *define *HAS_UI_VIEW_SETTINGS_INTEROP *$/d' qtbase/src/plugins/platforms/windows/qwin10helpers.cpp
#   https://bugreports.qt.io/browse/QTBUG-38223
sed -i '/option(host_build)/d' qtactiveqt/src/tools/idc/idc.pro

# /workdir/qtwinextras/src/winextras
# qwinjumplist.cpp:404:106: error: ‘SHCreateItemFromParsingName’ was not declared in this scope
sed -i '/# *if *defined *( *_WIN32_IE *) *&& *_WIN32_IE *<< *0x0700/{s,<<,<,}' qtwinextras/src/winextras/qwinjumplist.cpp

# /workdir/qtlocation/src/location
# ./.obj/release/qgeotiledmapscene.o:qgeotiledmapscene.cpp:(.text+0x3f53): undefined reference to `__imp__ZN19QSGDefaultImageNode18setAnisotropyLevelEN10QSGTexture15AnisotropyLevelE
# → requires OpenGL

# in qtexttospeech_sapi.cpp file sphelper.h is missing → "-skip qtspeech"
./configure -v -recheck-all -opensource -confirm-license \
    -xplatform win32-g++ -device-option CROSS_COMPILE=${MINGW}- \
    -no-compile-examples \
    -I${WORKSPACE}/usr/include \
    -L${WORKSPACE}/usr/lib \
    -prefix ${WORKSPACE}/usr \
    -system-proxies \
    -opengl desktop \
    -openssl-runtime \
    -skip qtspeech \
    -shared \
    -release

make
make install

cd ${WORKSPACE}
zip -r ${path}~windows.${BUILD_NUMBER}_${ARCH}.zip usr
