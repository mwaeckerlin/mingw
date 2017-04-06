FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

RUN apt-get update && apt-get install -y \
    mingw-w64 zip perl python xml2 \
    svn2cl subversion subversion-tools pkg-config \
    automake libtool autotools-dev \
    pandoc lsb-release doxygen graphviz mscgen \
    default-jre-headless \
    make subversion g++ git

ADD build-openssl.sh /build-openssl.sh
ADD build-icu.sh /build-icu.sh
ADD build-qt.sh /build-qt.sh
ADD build.sh /build.sh

WORKDIR /workdir
RUN chmod ugo+wrx /workdir

ENTRYPOINT ["/bin/bash"]

VOLUME /workdir
