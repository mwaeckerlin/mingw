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

RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y \
      mingw-w64 zip build-essential perl python xml2 \
      svn2cl subversion subversion-tools pkg-config \
      automake libtool autotools-dev \
      pandoc lsb-release doxygen graphviz mscgen \
      default-jre-headless \
      make subversion g++ git \
      qt5-default qtbase5-dev-tools qttools5-dev-tools \
      flex bison gperf ruby bison wget less

ADD README.md /README.md
ADD build-openssl.sh /build-openssl.sh
ADD build-icu.sh /build-icu.sh
ADD build-qt.sh /build-qt.sh
ADD build.sh /build.sh
ADD install-dll.sh /install-dll.sh

WORKDIR /workdir
RUN chmod ugo+wrx /workdir

ENTRYPOINT ["/start.sh"]

VOLUME /workdir
