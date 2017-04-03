#!/bin/bash

set -e

MINGW=${MINGW:-x86_64-w64-mingw32}
WORKSPACE=${WORKSPACE:-$(pwd)}
BUILD_NUMBER=${BUILD_NUMBER:-0}
ARCH=${ARCH:-${MINGW%%-*}}

download=0
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS]

OPTIONS:

  -h, --help      show this help
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
        (*) echo "unknown option: $1" 1>&2; exit 1;;
    esac
    shift
done

set -x

cd ${WORKSPACE}
if test $download -eq 1; then
    source=https://www.openssl.org/source
    file=$(wget -qO- $source | sed -n 's,.*<a *href="\(openssl-[0-9][^"]*\.tar\.gz\)".*,\1,p'  | head -1)
    path=${file%.tar.gz}
    wget -qO$file $source/$file
    tar xf $file
    cd $path
else
    path=$(pwd | sed 's,.*/,,')
fi
version=${path#openssl-}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+[a-z]$ ]] && [ "$path" = "openssl-${version}" ]

echo "Version: $version"
echo "Package: $path"

case ${MINGW} in
    (*i?86*)
        TARGET=mingw
        ;;
    (*x86_64*)
        TARGET=mingw64
        ;;
    (*) false;;
esac

./Configure ${TARGET} shared --cross-compile-prefix=${MINGW}- --prefix=${WORKSPACE}/usr

make
make install
cp *.dll ${WORKSPACE}/usr/lib/

cd ${WORKSPACE}
zip -r ${path}~windows.${BUILD_NUMBER}_${ARCH}.zip usr
