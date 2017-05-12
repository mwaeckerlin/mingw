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
        version=$(wget -qO- http://source.icu-project.org/repos/icu/icu/tags | sed -n 's,.*href="release-\([0-9]\+-[0-9]\+\)/".*,\1,p' | tail -1)
        # bugfix: 58-1 does not compile
        if test "$version" = "58-1"; then
            version="57-1"
        fi
        tag="release-${version}"
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
    source=http://source.icu-project.org/repos/icu/icu/tags/release-${version}
    svn co $source icu-${version}
    cd icu-${version}
elif test -n "${version}" -a -d icu-${version}; then
    cd icu-${version}
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
../source/configure
make
cd ../build-win
../source/configure \
    --host=${MINGW} \
    --with-cross-build=$(pwd)/../build-lin \
    --prefix="${TARGET}/${PREFIX}" \
    --bindir="${TARGET}/$BINDIR" \
    --sbindir="${TARGET}/$BINDIR" \
    --libdir="${TARGET}/$LIBDIR" \
    --libexecdir="${TARGET}/$LIBDIR"
make
make install

if test $zip -eq 1; then
    cd "${TARGET}"
    zip -r "${path}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
fi
