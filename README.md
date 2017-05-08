# MinGW Docker Build Image

Build Scripts for Cross Compiling Windows Targets in an Ubuntu Docker Container.

See also: [my blog](https://marc.wäckerlin.ch/computer/cross-compile-openssl-for-windows-on-linux)

## Build Scripts

List all available build scripts:

    docker run -it --rm mwaeckerlin/mingw -c ‘ls /build-*.sh’

Currently, there are:

- Build [OpenSSL](https://www.openssl.org/): /build-openssl.sh
- Build [ICU](http://site.icu-project.org/): /build-icu.sh
- Build [Qt5](https://www.qt.io/): /build-qt.sh
- Build [generic project](https://dev.marc.waeckerlin.org/redmine/projects): /build.sh

Show options e.g. for building OpenSSL:

    docker run -it --rm mwaeckerlin/mingw /build-openssl.sh -h

## Add Required DLLs

Some MinGW DLLs are required for running the builds on Windows. Install them into the installation directory using the script `install-dll.sh`:

    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /install-dll.sh

## Environment Variables

 - `MINGW`              mingw parameter (default: detect from `ARCH` or `x86_64-w64-mingw32`)
 - `PREFIX`             relative installation prefix (default: `usr`)
 - `WORKSPACE`          workspace path (default: `/workdir`)
 - `TARGET`             installation target (default: `WORKSPACE`)
 - `WINREQ`             path to required windows libraries (default: `TARGET/PREFIX`)
 - `BUILD_NUMBER`       build number (default: `0`)
 - `ARCH`               architecture (default: from `MINGW`, which defaults to `x86_64`)
 - `BINDIR`             install dir for exe files (default: `PREFIX/exe`)
 - `LIBDIR`             install dir for dll files (default: `PREFIX/exe`)
 - `WININC`             path to required windows include files (default: `WINREQ/include`)
 - `WINLIB`             path to required windows libraries (default: `WINREQ/exe`)

    
## Build Generic Projects

You can build any project, that is based on the [Bootstrap Build Environment](https://dev.marc.waeckerlin.org/redmine/projects/bootstrap-build-environment), i.e. my own projects:

    mkdir -p /tmp/build
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build.sh -s https://dev.marc.waeckerlin.org/svn/mrw-c++/trunk -n mrw-c++
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build.sh -s https://dev.marc.waeckerlin.org/svn/libxml-cxx/trunk -n libxml-cxx

Now you find a zip file per library, containing the installation that you find in subdir `/tmp/build/usr`. Subsequent builds also contain the depending libraries. If you don't want this behaviour, you can pass variables to docker build into different directories. For details, call e.g. `docker run [...] /build.sh --help`, then pass the variables for the build, e.g. specify a different target for the result, e.g. `docker run [...] -e PREFIX=otherdir mwaeckerlin/mingw /build.sh -s [...]`. Then you find the derieved objets in `otherdir`, and the zip file does not contain the depending libraries.

Qt requires OpenSSL and ICU:

    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-openssl.sh -d
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-icu.sh -d
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-qt.sh -d

The projects proxyface and libpcscxx require Qt, so build them after the lines above:

    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build.sh -s https://dev.marc.waeckerlin.org/svn/proxyface/trunk -n proxyface
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build.sh -s https://dev.marc.waeckerlin.org/svn/libpcscxx/trunk -n libpcscxx --enable-pkcs11-download

## Build OpenSSL

Compile latest OpenSSL in the current working directory:

    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-openssl.sh -d

## Build ICU

Build ICU version 57-1 in the current working directory:

    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-icu.sh -d -v 57-1

## Build Qt5

- Script: `/build-qt.sh -d`
- Requires: `/build-openssl.sh`, `build-icu.sh`

    mkdir -p /tmp/build/usr
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-openssl.sh -d
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-icu.sh -d
    docker run -it --rm -v /tmp/build:/workdir -u $(id -u) mwaeckerlin/mingw /build-qt.sh -d

Now in `/tmp/build` you find:
- `usr` with an installation of all the build targets
- `openssl-1.0.2k~windows.0_x86_64.zip` the OpenSSL library for windows (or another version number)
- `icu-57.1~windows.0_x86_64.zip` the ICU library for windows (or another version number)
- `...` the QT library for windows (or another version number)
- the sources and build files

### Qt Configuration:

```
Configure summary:

Building on: linux-g++ (x86_64, CPU features: mmx sse sse2)
Building for: win32-g++ (x86_64, CPU features: mmx sse sse2)
Configuration: cross_compile use_gold_linker sse2 sse3 ssse3 sse4_1 sse4_2 avx avx2 avx512f avx512bw avx512cd avx512dq avx512er avx512ifma avx512pf avx512vbmi avx512vl f16c largefile precompile_header shared release c++11 c++14 c++1z concurrent dbus no-pkg-config stl
Build options:
  Mode ................................... release
  Building shared libraries .............. yes
  Using C++ standard ..................... C++1z
  Using gold linker ...................... yes
  Using precompiled headers .............. yes
  Using LTCG ............................. no
  Target compiler supports:
    SSE .................................. SSE2 SSE3 SSSE3 SSE4.1 SSE4.2
    AVX .................................. AVX AVX2 F16C
    AVX512 ............................... F ER CD PF DQ BW VL IFMA VBMI
  Build parts ............................ libs examples
  App store compliance ................... no
Qt modules and options:
  Qt Concurrent .......................... yes
  Qt D-Bus ............................... yes
  Qt D-Bus directly linked to libdbus .... no
  Qt Gui ................................. yes
  Qt Network ............................. yes
  Qt Sql ................................. yes
  Qt Testlib ............................. yes
  Qt Widgets ............................. yes
  Qt Xml ................................. yes
Support enabled for:
  Using pkg-config ....................... no
  QML debugging .......................... yes
  udev ................................... no
  Using system zlib ...................... no
Qt Core:
  DoubleConversion ....................... yes
    Using system DoubleConversion ........ no
  GLib ................................... no
  iconv .................................. no
  ICU .................................... no
  Logging backends:
    journald ............................. no
    syslog ............................... no
    slog2 ................................ no
  Using system PCRE2 ..................... no
Qt Network:
  getaddrinfo() .......................... yes
  getifaddrs() ........................... no
  IPv6 ifname ............................ no
  libproxy ............................... no
  OpenSSL ................................ yes
    Qt directly linked to OpenSSL ........ no
  SCTP ................................... no
  Use system proxies ..................... yes
Qt Sql:
  DB2 (IBM) .............................. no
  InterBase .............................. no
  MySql .................................. no
  OCI (Oracle) ........................... no
  ODBC ................................... yes
  PostgreSQL ............................. no
  SQLite2 ................................ no
  SQLite ................................. yes
    Using system provided SQLite ......... no
  TDS (Sybase) ........................... no
Qt Gui:
  Accessibility .......................... yes
  FreeType ............................... yes
    Using system FreeType ................ no
  HarfBuzz ............................... yes
    Using system HarfBuzz ................ no
  Fontconfig ............................. no
  Image formats:
    GIF .................................. yes
    ICO .................................. yes
    JPEG ................................. yes
      Using system libjpeg ............... no
    PNG .................................. yes
      Using system libpng ................ no
  EGL .................................... no
  OpenVG ................................. no
  OpenGL:
    ANGLE ................................ no
    Desktop OpenGL ....................... yes
    Dynamic OpenGL ....................... no
    OpenGL ES 2.0 ........................ no
    OpenGL ES 3.0 ........................ no
    OpenGL ES 3.1 ........................ no
  Session Management ..................... yes
Features used by QPA backends:
  evdev .................................. no
  libinput ............................... no
  mtdev .................................. no
  tslib .................................. no
  xkbcommon-evdev ........................ no
QPA backends:
  DirectFB ............................... no
  EGLFS .................................. no
  LinuxFB ................................ no
  VNC .................................... no
  Mir client ............................. no
  Windows:
    Direct 2D ............................ no
    DirectWrite .......................... yes
    DirectWrite 2 ........................ no
Qt Widgets:
  GTK+ ................................... no
  Styles ................................. Fusion Windows WindowsXP WindowsVista
Qt PrintSupport:
  CUPS ................................... no
Qt SerialBus:
  Socket CAN ............................. no
  Socket CAN FD .......................... no
QtXmlPatterns:
  XML schema support ..................... yes
Qt QML:
  QML interpreter ........................ yes
  QML network support .................... yes
Qt Quick:
  Direct3D 12 ............................ no
  AnimatedImage item ..................... yes
  Canvas item ............................ yes
  Support for Quick Designer ............. yes
  Flipable item .......................... yes
  GridView item .......................... yes
  ListView item .......................... yes
  Path support ........................... yes
  PathView item .......................... yes
  Positioner items ....................... yes
  ShaderEffect item ...................... yes
  Sprite item ............................ yes
Qt Gamepad:
  SDL2 ................................... no
Qt 3D:
  Assimp ................................. yes
  System Assimp .......................... no
Qt 3D GeometryLoaders:
  Autodesk FBX ........................... no
Qt Wayland Client ........................ no
Qt Wayland Compositor .................... no
Qt Bluetooth:
  BlueZ .................................. no
  BlueZ Low Energy ....................... no
  Linux Crypto API ....................... no
Qt Sensors:
  sensorfw ............................... no
Qt Multimedia:
  ALSA ................................... no
  GStreamer 1.0 .......................... no
  GStreamer 0.10 ......................... no
  Video for Linux ........................ no
  OpenAL ................................. no
  PulseAudio ............................. no
  Resource Policy (libresourceqt5) ....... no
  Windows Audio Services ................. no
  DirectShow ............................. yes
  Windows Media Foundation ............... no
  Media player backend ................... DirectShow
Qt Quick Controls 2:
  Styles ................................. Default Material Universal
Qt Quick Templates 2:
  Hover support .......................... yes
Qt Location:
  Gypsy GPS Daemon ....................... no
  WinRT Geolocation API .................. no
Qt WebEngine:
  Embedded build ......................... no
  Pepper Plugins ......................... yes
  Printing and PDF ....................... yes
  Proprietary Codecs ..................... no
  Spellchecker ........................... yes
  WebRTC ................................. yes
  Using system ninja ..................... no

Note: Also available for Linux: linux-clang linux-kcc linux-icc linux-cxx

Note: No wayland-egl support detected. Cross-toolkit compatibility disabled.
```
