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
zip=0
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS]

OPTIONS:

  -h, --help         show this help
  -z, --zip          create zip package
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

Builds ICU for Windows
EOF
            exit
            ;;
        (-d|--download) download=1;;
        (-v|--version) shift; version="$1";;
        (-z|--zip) zip=1;;
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
    if test -z "$version"; then
        json=$(wget -qO- https://api.github.com/repos/unicode-org/icu/releases/latest)
        tag=$(sed -n 's,.*"tag_name": *"\(.*\)".*,\1,p' <<<"$json")
        version=${tag#release-}
    else
        if [[ "$version" =~ ^[0-9.]+$ ]]; then
            tag="release-${version}"
        else
            tag="$version"
            version=${version##*[a-z]-}
            if ! [[ "$version" =~ ^[0-9.]+$ ]]; then
                version=$(date +'%Y-%m-%d')
            fi
        fi
    fi
    source=https://github.com/unicode-org/icu/archive/${tag}.tar.gz
    wget -qO- $source | tar xz
    cd icu-${tag}
elif test -n "${version}" -a -d icu-${version}; then
    cd icu-${version}
elif test -n "${version}" -a -d icu-release-${version}; then
    cd icu-release-${version}
elif test -z "${version}" -a -d icu-*; then
    version=$(ls -d icu-* | sed 's,icu-,,')
    cd icu-${version}
else
    version=${version:-$(date +'%Y-%m-%d')}
fi
version=${version//-/.}
path=icu-${version}
[[ "$version" =~ ^[0-9.]+$ ]]

echo "Version: $version"
echo "Package: $path"

test -d build-lin || mkdir build-lin
test -d build-win || mkdir build-win
cd build-lin
../icu4c/source/configure
make
cd ../build-win
../icu4c/source/configure \
    --host=${MINGW} \
    --with-cross-build=$(pwd)/../build-lin \
    --prefix="${TARGET}/${PREFIX}" \
    --bindir="${TARGET}/$BINDIR" \
    --sbindir="${TARGET}/$BINDIR" \
    --libdir="${TARGET}/$LIBDIR" \
    --libexecdir="${TARGET}/$LIBDIR"
make
make install
chmod -R u+rw "${TARGET}"

if test $zip -eq 1; then
    cd "${TARGET}"
    zip -r "${path}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
fi
