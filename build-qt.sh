#!/bin/bash

set -e

MINGW=${MINGW:-x86_64-w64-mingw32}
PREFIX=${PREFIX:-usr}
WORKSPACE=${WORKSPACE:-$(pwd)}
TARGET=${TARGET:-${WORKSPACE}}
WINLIBS=${WINLIBS:-${TARGET}/${PREFIX}}
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
  PREFIX          relative installation prefix (default: $PREFIX)
  WORKSPACE       workspace path (default: $WORKSPACE)
  WINLIBS         path to windows libraries (default: $WINLIBS)
  TARGET          installation target (default: $TARGET)
  BUILD_NUMBER    build number (default: $BUILD_NUMBER)
  ARCH            architecture (default: $ARCH)

DEPENDENCIES:

  openssl        /build-openssl.sh
  icu            /build-icu.sh

Builds QT for Windows
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

# in qtexttospeech_sapi.cpp file sphelper.h is missing → "-skip qtspeech"
./configure -v -recheck-all -opensource -confirm-license \
    -xplatform win32-g++ -device-option CROSS_COMPILE=${MINGW}- \
    -no-compile-examples \
    -I"${WINLIBS}/include" \
    -L"${WINLIBS}/lib" \
    -prefix "${TARGET}/${PREFIX}" \
    -system-proxies \
    -opengl desktop \
    -openssl-runtime \
    -skip qtspeech \
    -shared \
    -release

make
make install

# bugfixes:
#  Qt pkg-config files link to debug version in release build
#  https://bugreports.qt.io/browse/QTBUG-60028
for f in "${TARGET}/${PREFIX}"/lib/pkgconfig/*.pc; do
    sed -i 's,\(-lQt5[-_a-zA-Z0-9]*\)d,\1,g' "$f"
done

cd "${TARGET}"
zip -r "${path}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
