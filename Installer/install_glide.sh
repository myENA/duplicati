#!/bin/bash

set -e
GLIDE_VERSION=0.13.1
OS=linux
ARCH=amd64

TARNAME=glide-v${GLIDE_VERSION}-${OS}-${ARCH}.tar.gz

cd /tmp
curl -OL https://github.com/Masterminds/glide/releases/download/v${GLIDE_VERSION}/${TARNAME}
tar xzf ${TARNAME}
cp ./${OS}-${ARCH}/glide /usr/local/bin
rm -rf ${TARNAME}
rm -rf ./${OS}-${ARCH}
