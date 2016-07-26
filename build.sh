#!/bin/bash -ex

#get script location
SCRIPTDIR=`dirname $0`
SCRIPTDIR=`(cd $SCRIPTDIR ; pwd)`

ARCHS="arm64 armhf"
VERSIONS="jessie testing"

for arch in ${ARCHS}; do
    for version in ${VERSIONS}; do
        . ${SCRIPTDIR}/build_common.sh ${arch} ${version} ${SCRIPTDIR}/${arch}-debian-${version}.tgz
    done
done

ls -la ${SCRIPTDIR}/*-debian-*
