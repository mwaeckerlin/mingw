#!/bin/bash

set -e

MINGW=${MINGW:-${ARCH:-x86_64}-w64-mingw32}
PREFIX=${PREFIX:-usr}
WORKSPACE=${WORKSPACE:-$(pwd)}
TARGET=${TARGET:-${WORKSPACE}}
WINREQ=${WINREQ:-${TARGET}/${PREFIX}}
BUILD_NUMBER=${BUILD_NUMBER:-0}
ARCH=${ARCH:-${MINGW%%-*}}
BINDIR=${BINDIR:-${PREFIX}/exe}
LIBDIR=${LIBDIR:-${PREFIX}/exe}
PLUGINDIR=${PLUGINDIR:-${PREFIX}/exe}
WININC=${WININC:-${WINREQ}/include}
WINLIB=${WINLIB:-${WINREQ}/exe}

version=
download=0
zip=0
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS] [CONFIGURE-ARGUMENTS]

OPTIONS:

  -h, --help         show this help
  -z, --zip          create zip package
  -v, --version      specify version string
  -d, --download     download sources
                     otherwise sources must be in $(pwd)

CONFIGURE-ARGUMENTS:

Arguments that are passed to configure.  

VARIABLES:

  MINGW              mingw parameter (default: $MINGW)
  PREFIX             relative installation prefix (default: $PREFIX)
  WORKSPACE          workspace path (default: $WORKSPACE)
  WINREQ             path to required windows libraries (default: $WINREQ)
  TARGET             installation target (default: $TARGET)
  BUILD_NUMBER       build number (default: $BUILD_NUMBER)
  ARCH               architecture (default: $ARCH)
  BINDIR             install dir for exe files (default: $BINDIR)
  LIBDIR             install dir for dll files (default: $LIBDIR)
  PLUGINDIR          install dir for qt plugins (default: $PLUGINDIR)
  WININC             path to required windows include files (default: $WININC)
  WINLIB             path to required windows libraries (default: $WINLIB)

DEPENDENCIES:

  openssl        /build-openssl.sh
  icu            /build-icu.sh

Builds QT for Windows
EOF
            exit
            ;;
        (-d|--download) download=1;;
        (-v|--version) shift; version="$1";;
        (-z|--zip) zip=1;;
        (*) break;;
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
    perl init-repository --module-subset=default,-qtwebkit,-qtwebkit-examples,-qtwebengine
elif test -d qt5; then
    cd qt5
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
    -I"${WININC}" \
    -L"${WINLIB}" \
    -prefix "${TARGET}/${PREFIX}" \
    -bindir "${TARGET}/$BINDIR" \
    -libdir "${TARGET}/$LIBDIR" \
    -plugindir "${TARGET}/$PLUGINDIR" \
    -libexecdir "${TARGET}/$LIBDIR" \
    -system-proxies \
    -opengl desktop \
    -openssl-runtime \
    -skip qtspeech \
    -skip qtlocation \
    -shared \
    -release \
    $*

make
make install
chmod -R u+rw "${TARGET}"

# bugfixes:
#  Qt pkg-config files link to debug version in release build
#  https://bugreports.qt.io/browse/QTBUG-60028
for f in "${TARGET}/${LIBDIR}"/pkgconfig/*.pc; do
    sed -i 's,\(-lQt5[-_a-zA-Z0-9]*\)d,\1,g' "$f"
done

if test $zip -eq 1; then
    cd "${TARGET}"
    zip -r "${path}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
fi
