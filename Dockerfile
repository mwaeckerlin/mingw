FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

ENV MINGW=""
ENV PREFIX=""
ENV WORKSPACE=""
ENV TARGET=""
ENV WINREQ=""
ENV BUILD_NUMBER=""
ENV ARCH=""
ENV BINDIR=""
ENV LIBDIR=""
ENV WININC=""
ENV WINLIB=""

RUN apt-get update && apt-get install -y \
    mingw-w64 zip build-essential perl python xml2 \
    svn2cl subversion subversion-tools pkg-config \
    automake libtool autotools-dev \
    pandoc lsb-release doxygen graphviz mscgen \
    default-jre-headless \
    make subversion g++ git \
    qt5-default qtbase5-dev-tools qttools5-dev-tools \
    flex bison gperf libicu-dev libxslt-dev ruby libssl-dev \
    libxcursor-dev libxcomposite-dev libxdamage-dev libxrandr-dev \
    libdbus-1-dev libfontconfig1-dev libcap-dev libxtst-dev \
    libpulse-dev libudev-dev libpci-dev libnss3-dev libasound2-dev \
    libxss-dev libegl1-mesa-dev gperf bison \
    libasound2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev

ADD build-openssl.sh /build-openssl.sh
ADD build-icu.sh /build-icu.sh
ADD build-qt.sh /build-qt.sh
ADD build.sh /build.sh
ADD install-dll.sh /install-dll.sh

WORKDIR /workdir
RUN chmod ugo+wrx /workdir

ENTRYPOINT ["/bin/bash"]
CMD ""

VOLUME /workdir
