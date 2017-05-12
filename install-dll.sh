#!/bin/bash

set -e

MINGW=${MINGW:-${ARCH:-x86_64}-w64-mingw32}
PREFIX=${PREFIX:-usr}
WORKSPACE=${WORKSPACE:-$(pwd)}
TARGET=${TARGET:-${WORKSPACE}}
WINREQ=${WINREQ:-${TARGET}/${PREFIX}}
BUILD_NUMBER=${BUILD_NUMBER:-0}
ARCH=${ARCH:-${MINGW%%-*}}
WINLIB=${WINLIB:-${WINREQ}/exe}

zip=0
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS]

OPTIONS:

  -h, --help         show this help
  -z, --zip          create zip package

VARIABLES:

  MINGW              mingw parameter (default: $MINGW)
  PREFIX             relative installation prefix (default: $PREFIX)
  WORKSPACE          workspace path (default: $WORKSPACE)
  WINREQ             path to windows libraries (default: $WINREQ)
  TARGET             installation target (default: $TARGET)
  BUILD_NUMBER       build number (default: $BUILD_NUMBER)
  ARCH               architecture (default: $ARCH)
  WINLIB             path to required windows libraries (default: $WINLIB)

Copies required DLLs to ${WINLIB}
EOF
            exit
            ;;
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

test -d ${WINLIB} || mkdir -p ${WINLIB}
cp $(dpkg -S *.dll | sed -n '/-posix\//d;s,.*-'"${ARCH//_/-}"'.*: ,,p')  ${WINLIB}/

if test $zip -eq 1; then
    cd "${TARGET}"
    zip -r "${name}-${version}~windows.${BUILD_NUMBER}_${ARCH}.zip" "${PREFIX}"
fi
