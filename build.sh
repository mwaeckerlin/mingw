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
WININC=${WININC:-${WINREQ}/include}
WINLIB=${WINLIB:-${WINREQ}/exe}

name=
svn=
git=
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS] [CONFIGURE-ARGUMENTS]

OPTIONS:

  -h, --help         show this help
  -s, --svn [src]    specify subversion source
  -g, --git [src]    specify git source
  -n, --name [name]  project name

Specify either --svn or --git, otherwise sources must be in $(pwd)

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
  WININC             path to required windows include files (default: $WININC)
  WINLIB             path to required windows libraries (default: $WINLIB)

Builds Standard Autoconf Projects for Windows
EOF
            exit
            ;;
        (-s|--svn) shift; svn="$1";;
        (-g|--git) shift; git="$1";;
        (-n|--name) shift; name="$1";;
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
if test -n "$git"; then
    git clone $git "${name:-.}"
fi
if test -n "$svn"; then
    svn co "$svn" "${name:-.}"
fi
if test -n "$name"; then
    cd "$name"
fi

./bootstrap.sh -c \
    --host=${MINGW} \
    --prefix="${TARGET}/${PREFIX}" \
    --bindir="${TARGET}/$BINDIR" \
    --sbindir="${TARGET}/$BINDIR" \
    --libdir="${TARGET}/$LIBDIR" \
    --libexecdir="${TARGET}/$LIBDIR" \
    CPPFLAGS="-I${WININC}" \
    LDFLAGS="-L${WINLIB}" \
    PKG_CONFIG_PATH="${WINLIB}/pkgconfig" \
    $*

if test -z "$name" -o "$name" = "."; then
    name=$(sed -n 's,PACKAGE_NAME = ,,p' makefile)
fi
version=$(sed -n 's,PACKAGE_VERSION = ,,p' makefile)
set +x
echo "======================================================"
echo "Version: $version"
echo "Package: $name"
echo "======================================================"
set -x
[ -n "$name" ] && [[ "$version" =~ ^[0-9.]+$ ]]
make
make install

cd "${WORKSPACE}"
zip -r "${name}-${version}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
