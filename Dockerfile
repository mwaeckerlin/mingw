FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

RUN apt-get update && apt-get install -y mingw-w64 perl make zip subversion g++

ADD build-openssl.sh /build-openssl.sh
ADD build-icu.sh /build-icu.sh

WORKDIR /workdir
ENTRYPOINT ["/bin/bash"]

VOLUME /workdir
