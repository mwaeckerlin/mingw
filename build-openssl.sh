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

#sed -i '/#define HEADER_X509V3_H/a \\n#ifdef X509_NAME\n#undef X509_NAME\n#endif'${WORKSPACE}/usr/include/openssl/x509v3.h

cd ${WORKSPACE}
zip -r ${path}~windows.${BUILD_NUMBER}_${ARCH}.zip usr
