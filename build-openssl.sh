#!/bin/bash

set -e

MINGW=${MINGW:-${ARCH:-x86_64}-w64-mingw32}
PREFIX=${PREFIX:-usr}
WORKSPACE=${WORKSPACE:-$(pwd)}
TARGET=${TARGET:-${WORKSPACE}}
BUILD_NUMBER=${BUILD_NUMBER:-0}
ARCH=${ARCH:-${MINGW%%-*}}
BINDIR=${BINDIR:-${PREFIX}/exe}
LIBDIR=${LIBDIR:-${PREFIX}/exe}

version=
download=0
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS]

OPTIONS:

  -h, --help         show this help
  -v, --version      specify version string
  -d, --download     download sources
                     otherwise sources must be in $(pwd)

VARIABLES:

  MINGW              mingw parameter (default: $MINGW)
  PREFIX             relative installation prefix (default: $PREFIX)
  WORKSPACE          workspace path (default: $WORKSPACE)
  TARGET             installation target (default: $TARGET)
  BUILD_NUMBER       build number (default: $BUILD_NUMBER)
  ARCH               architecture (default: $ARCH)
  BINDIR             install dir for exe files (default: $BINDIR)
  LIBDIR             install dir for dll files (default: $LIBDIR)

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
    source=https://www.openssl.org/source
    if test -n "$version"; then
        file=openssl-${version}.tar.gz
    else
        #file=$(wget -qO- $source | sed -n 's,.*<a *href="\(openssl-[0-9][^"]*\.tar\.gz\)".*,\1,p'  | head -1)
        # use old version 1.0.x, because Qt < 5.10 cannot handle 1.1.x
        file=$(wget -qO- $source | sed -n 's,.*<a *href="\(openssl-1.0.[0-9][^"]*\.tar\.gz\)".*,\1,p'  | head -1)
    fi
    path=${file%.tar.gz}
    wget -qO$file $source/$file
    tar xf $file
    cd $path
else
    if test -n "$version"; then
        path=openssl-${version}
    else
        path=$(pwd | sed 's,.*/,,')
    fi
fi
version=${version:-${path#openssl-}}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+[a-z]$ ]] && [ "$path" = "openssl-${version}" ]

echo "Version: $version"
echo "Package: $path"

case ${MINGW} in
    (*i?86*)
        TYPE=mingw
        ;;
    (*x86_64*)
        TYPE=mingw64
        ;;
    (*) false;;
esac

./Configure ${TYPE} shared \
    --cross-compile-prefix=${MINGW}- \
    --prefix="${TARGET}/${PREFIX}" \
    --openssldir="${TARGET}/$BINDIR" \
    --libdir="${TARGET}/$LIBDIR"

make
make install
test -d "$LIBDIR" || mkdir -p "$LIBDIR"
cp *.dll "$LIBDIR/"

cd "${TARGET}"
zip -r "${path}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
