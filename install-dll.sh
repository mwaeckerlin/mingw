#!/bin/bash

set -e

MINGW=${MINGW:-x86_64-w64-mingw32}
PREFIX=${PREFIX:-usr}
WORKSPACE=${WORKSPACE:-$(pwd)}
TARGET=${TARGET:-${WORKSPACE}}
WINLIBS=${WINLIBS:-${TARGET}/${PREFIX}}
BUILD_NUMBER=${BUILD_NUMBER:-0}
ARCH=${ARCH:-${MINGW%%-*}}

while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS]

OPTIONS:

  -h, --help         show this help

VARIABLES:

  MINGW              mingw parameter (default: $MINGW)
  PREFIX             relative installation prefix (default: $PREFIX)
  WORKSPACE          workspace path (default: $WORKSPACE)
  WINLIBS            path to windows libraries (default: $WINLIBS)
  TARGET             installation target (default: $TARGET)
  BUILD_NUMBER       build number (default: $BUILD_NUMBER)
  ARCH               architecture (default: $ARCH)

Copies required DLLs to ${WINLIBS}/lib
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

test -d ${WINLIBS}/lib || mkdir -p ${WINLIBS}/lib
cp $(dpkg -S *.dll | sed -n 's,.*-'"${ARCH//_/-}"'.*: ,,p')  ${WINLIBS}/lib/

cd "${WORKSPACE}"
zip -r "${name}-${version}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
